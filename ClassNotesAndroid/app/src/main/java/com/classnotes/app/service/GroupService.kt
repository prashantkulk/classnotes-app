package com.classnotes.app.service

import android.util.Log
import com.classnotes.app.AppMode
import com.classnotes.app.model.ClassGroup
import com.classnotes.app.model.SubjectInfo
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.Query
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.tasks.await
import java.util.Date

open class GroupService {
    protected val _groups = MutableStateFlow<List<ClassGroup>>(emptyList())
    val groups: StateFlow<List<ClassGroup>> = _groups

    protected val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading

    private val db: FirebaseFirestore? by lazy {
        if (AppMode.isDemo) null else FirebaseFirestore.getInstance()
    }

    private var listener: ListenerRegistration? = null

    open fun loadGroups(userId: String) {
        val firestore = db ?: return
        listener?.remove()

        listener = firestore.collection("groups")
            .whereArrayContains("members", userId)
            .orderBy("createdAt", Query.Direction.DESCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    Log.e("GroupService", "loadGroups snapshot error: ${error.message}")
                }
                val documents = snapshot?.documents ?: return@addSnapshotListener

                _groups.value = documents.mapNotNull { doc ->
                    val data = doc.data ?: return@mapNotNull null
                    @Suppress("UNCHECKED_CAST")
                    ClassGroup(
                        id = doc.id,
                        name = data["name"] as? String ?: "",
                        school = data["school"] as? String ?: "",
                        inviteCode = data["inviteCode"] as? String ?: "",
                        members = data["members"] as? List<String> ?: emptyList(),
                        createdBy = data["createdBy"] as? String ?: "",
                        createdAt = (data["createdAt"] as? Timestamp)?.toDate() ?: Date(),
                        customSubjects = (data["customSubjects"] as? List<Map<String, String>>) ?: emptyList()
                    )
                }
            }
    }

    open suspend fun createGroup(group: ClassGroup): ClassGroup {
        val firestore = db ?: throw Exception("Firestore not available")
        val newGroup = group.copy(members = listOf(group.createdBy))

        val data = hashMapOf<String, Any>(
            "name" to newGroup.name,
            "school" to newGroup.school,
            "inviteCode" to newGroup.inviteCode,
            "members" to newGroup.members,
            "createdBy" to newGroup.createdBy,
            "createdAt" to FieldValue.serverTimestamp(),
            "customSubjects" to newGroup.customSubjects
        )

        firestore.collection("groups").document(newGroup.id).set(data).await()

        // Also add group ID to user's groups array
        firestore.collection("users").document(newGroup.createdBy)
            .update("groups", FieldValue.arrayUnion(newGroup.id))

        return newGroup
    }

    open suspend fun joinGroup(code: String, userId: String): ClassGroup {
        val firestore = db ?: throw Exception("Firestore not available")

        val snapshot = firestore.collection("groups")
            .whereEqualTo("inviteCode", code)
            .get()
            .await()

        val doc = snapshot.documents.firstOrNull()
            ?: throw Exception("No group found with this code. Please check and try again.")

        val data = doc.data ?: throw Exception("Invalid group data")
        @Suppress("UNCHECKED_CAST")
        val members = data["members"] as? List<String> ?: emptyList()

        if (members.contains(userId)) {
            val groupName = data["name"] as? String ?: "this group"
            throw Exception("You are already a member of $groupName.")
        }

        // Atomic batch write: add user to group AND group to user
        val batch = firestore.batch()
        batch.update(
            firestore.collection("groups").document(doc.id),
            "members", FieldValue.arrayUnion(userId)
        )
        batch.update(
            firestore.collection("users").document(userId),
            "groups", FieldValue.arrayUnion(doc.id)
        )
        batch.commit().await()

        @Suppress("UNCHECKED_CAST")
        return ClassGroup(
            id = doc.id,
            name = data["name"] as? String ?: "",
            school = data["school"] as? String ?: "",
            inviteCode = data["inviteCode"] as? String ?: "",
            members = members + userId,
            createdBy = data["createdBy"] as? String ?: "",
            createdAt = (data["createdAt"] as? Timestamp)?.toDate() ?: Date(),
            customSubjects = (data["customSubjects"] as? List<Map<String, String>>) ?: emptyList()
        )
    }

    open suspend fun leaveGroup(groupId: String, userId: String) {
        val firestore = db ?: throw Exception("Firestore not available")

        val batch = firestore.batch()
        batch.update(
            firestore.collection("groups").document(groupId),
            "members", FieldValue.arrayRemove(userId)
        )
        batch.update(
            firestore.collection("users").document(userId),
            "groups", FieldValue.arrayRemove(groupId)
        )
        batch.commit().await()
    }

    open suspend fun deleteGroup(group: ClassGroup) {
        val firestore = db ?: throw Exception("Firestore not available")
        val groupId = group.id

        // Step 1: Get all posts for this group
        val postsSnapshot = firestore.collection("posts")
            .whereEqualTo("groupId", groupId)
            .get().await()

        val batch = firestore.batch()
        val allImageURLs = mutableListOf<String>()

        for (doc in postsSnapshot.documents) {
            val data = doc.data ?: continue
            @Suppress("UNCHECKED_CAST")
            val photoURLs = data["photoURLs"] as? List<String> ?: emptyList()
            allImageURLs.addAll(photoURLs)
            batch.delete(doc.reference)
        }

        // Step 2: Get all requests for this group
        val requestsSnapshot = firestore.collection("requests")
            .whereEqualTo("groupId", groupId)
            .get().await()

        for (doc in requestsSnapshot.documents) {
            val data = doc.data ?: continue
            @Suppress("UNCHECKED_CAST")
            val responsesData = data["responses"] as? List<Map<String, Any>> ?: emptyList()
            for (resp in responsesData) {
                @Suppress("UNCHECKED_CAST")
                val respURLs = resp["photoURLs"] as? List<String> ?: emptyList()
                allImageURLs.addAll(respURLs)
            }
            batch.delete(doc.reference)
        }

        // Step 3: Remove groupId from all members' user docs
        for (memberId in group.members) {
            batch.update(
                firestore.collection("users").document(memberId),
                "groups", FieldValue.arrayRemove(groupId)
            )
        }

        // Step 4: Delete the group document
        batch.delete(firestore.collection("groups").document(groupId))

        // Step 5: Commit
        batch.commit().await()

        // Fire-and-forget: delete images from Storage
        StorageService.deleteImages(allImageURLs)
    }

    open suspend fun addCustomSubject(groupId: String, subject: SubjectInfo) {
        val firestore = db ?: throw Exception("Firestore not available")
        firestore.collection("groups").document(groupId).update(
            "customSubjects", FieldValue.arrayUnion(subject.firestoreDict)
        ).await()
    }

    open fun removeListener() {
        listener?.remove()
        listener = null
    }
}
