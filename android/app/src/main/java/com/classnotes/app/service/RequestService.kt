package com.classnotes.app.service

import android.net.Uri
import android.util.Log
import com.classnotes.app.AppMode
import com.classnotes.app.model.NoteRequest
import com.classnotes.app.model.RequestResponse
import com.classnotes.app.model.RequestStatus
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.Query
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.tasks.await
import java.util.Date
import java.util.UUID

open class RequestService {
    protected val _requests = MutableStateFlow<List<NoteRequest>>(emptyList())
    val requests: StateFlow<List<NoteRequest>> = _requests

    protected val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading

    // Context needed for image loading during upload
    var appContext: android.content.Context? = null

    private val db: FirebaseFirestore? by lazy {
        if (AppMode.isDemo) null else FirebaseFirestore.getInstance()
    }

    private var listener: ListenerRegistration? = null

    open fun loadRequests(groupId: String) {
        val firestore = db ?: return
        listener?.remove()

        listener = firestore.collection("requests")
            .whereEqualTo("groupId", groupId)
            .orderBy("createdAt", Query.Direction.DESCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    Log.e("RequestService", "loadRequests snapshot error: ${error.message}")
                }
                val documents = snapshot?.documents ?: return@addSnapshotListener

                _requests.value = documents.mapNotNull { doc ->
                    val data = doc.data ?: return@mapNotNull null

                    // Firestore field name is "subject" (not "subjectName")
                    val subjectName = data["subject"] as? String ?: return@mapNotNull null
                    val statusRaw = data["status"] as? String ?: return@mapNotNull null
                    val status = try { RequestStatus.valueOf(statusRaw.uppercase()) } catch (_: Exception) { return@mapNotNull null }

                    @Suppress("UNCHECKED_CAST")
                    val responsesData = data["responses"] as? List<Map<String, Any>> ?: emptyList()
                    val responses = responsesData.map { respData ->
                        @Suppress("UNCHECKED_CAST")
                        RequestResponse(
                            id = respData["id"] as? String ?: UUID.randomUUID().toString(),
                            authorId = respData["authorId"] as? String ?: "",
                            authorName = respData["authorName"] as? String ?: "",
                            photoURLs = respData["photoURLs"] as? List<String> ?: emptyList(),
                            createdAt = (respData["createdAt"] as? Timestamp)?.toDate() ?: Date()
                        )
                    }

                    NoteRequest(
                        id = doc.id,
                        groupId = data["groupId"] as? String ?: "",
                        authorId = data["authorId"] as? String ?: "",
                        authorName = data["authorName"] as? String ?: "",
                        subjectName = subjectName,
                        date = (data["date"] as? Timestamp)?.toDate() ?: Date(),
                        description = data["description"] as? String ?: "",
                        targetUserId = data["targetUserId"] as? String,
                        targetUserName = data["targetUserName"] as? String,
                        status = status,
                        responses = responses,
                        createdAt = (data["createdAt"] as? Timestamp)?.toDate() ?: Date()
                    )
                }
            }
    }

    open suspend fun createRequest(
        groupId: String,
        authorId: String,
        authorName: String,
        subjectName: String,
        date: Date,
        description: String,
        targetUserId: String?,
        targetUserName: String?
    ): NoteRequest {
        val firestore = db ?: throw Exception("Firestore not available")
        val requestId = UUID.randomUUID().toString()

        // Firestore field is "subject" (matching iOS)
        val data = hashMapOf<String, Any>(
            "groupId" to groupId,
            "authorId" to authorId,
            "authorName" to authorName,
            "subject" to subjectName,
            "date" to Timestamp(date),
            "description" to description,
            "status" to RequestStatus.OPEN.name.lowercase(),
            "responses" to listOf<Map<String, Any>>(),
            "createdAt" to FieldValue.serverTimestamp()
        )

        if (targetUserId != null) data["targetUserId"] = targetUserId
        if (targetUserName != null) data["targetUserName"] = targetUserName

        firestore.collection("requests").document(requestId).set(data).await()

        return NoteRequest(
            id = requestId,
            groupId = groupId,
            authorId = authorId,
            authorName = authorName,
            subjectName = subjectName,
            date = date,
            description = description,
            targetUserId = targetUserId,
            targetUserName = targetUserName
        )
    }

    open suspend fun respondToRequest(
        requestId: String,
        authorId: String,
        authorName: String,
        imageUris: List<Uri>
    ) {
        val firestore = db ?: throw Exception("Firestore not available")
        val context = appContext ?: throw Exception("App context not set")
        val basePath = "requests/$requestId/responses"

        val photoURLs = StorageService.uploadImages(context, imageUris, basePath)

        val responseData = hashMapOf<String, Any>(
            "id" to UUID.randomUUID().toString(),
            "authorId" to authorId,
            "authorName" to authorName,
            "photoURLs" to photoURLs,
            "createdAt" to Timestamp(Date())
        )

        firestore.collection("requests").document(requestId).update(
            mapOf(
                "responses" to FieldValue.arrayUnion(responseData),
                "status" to RequestStatus.FULFILLED.name.lowercase()
            )
        ).await()
    }

    open suspend fun deleteRequest(request: NoteRequest) {
        val firestore = db ?: throw Exception("Firestore not available")

        // Collect all response image URLs for cleanup
        val allImageURLs = request.responses.flatMap { it.photoURLs }

        firestore.collection("requests").document(request.id).delete().await()

        // Fire-and-forget: delete images from Storage
        StorageService.deleteImages(allImageURLs)
    }

    open fun markAsFulfilled(requestId: String) {
        if (AppMode.isDemo) {
            val current = _requests.value.toMutableList()
            val index = current.indexOfFirst { it.id == requestId }
            if (index >= 0) {
                current[index] = current[index].copy(status = RequestStatus.FULFILLED)
                _requests.value = current
            }
        } else {
            db?.collection("requests")?.document(requestId)?.update(
                "status", RequestStatus.FULFILLED.name.lowercase()
            )
        }
    }

    open fun removeListener() {
        listener?.remove()
        listener = null
    }
}
