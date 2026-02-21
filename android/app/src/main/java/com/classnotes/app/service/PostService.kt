package com.classnotes.app.service

import android.net.Uri
import android.util.Log
import com.classnotes.app.AppMode
import com.classnotes.app.model.Post
import com.classnotes.app.model.PostComment
import com.classnotes.app.model.PostReaction
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

open class PostService {
    protected val _posts = MutableStateFlow<List<Post>>(emptyList())
    val posts: StateFlow<List<Post>> = _posts

    protected val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading

    // Context needed for image loading during upload
    var appContext: android.content.Context? = null

    private val db: FirebaseFirestore? by lazy {
        if (AppMode.isDemo) null else FirebaseFirestore.getInstance()
    }

    private var listener: ListenerRegistration? = null

    open fun loadPosts(groupId: String) {
        val firestore = db ?: return
        listener?.remove()

        listener = firestore.collection("posts")
            .whereEqualTo("groupId", groupId)
            .orderBy("createdAt", Query.Direction.DESCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    Log.e("PostService", "loadPosts snapshot error: ${error.message}")
                }
                val documents = snapshot?.documents ?: return@addSnapshotListener

                _posts.value = documents.mapNotNull { doc ->
                    val data = doc.data ?: return@mapNotNull null

                    // Firestore field name is "subject" (not "subjectName")
                    val subjectName = data["subject"] as? String ?: return@mapNotNull null

                    @Suppress("UNCHECKED_CAST")
                    val commentsData = data["comments"] as? List<Map<String, Any>> ?: emptyList()
                    val comments = commentsData.map { c ->
                        PostComment(
                            id = c["id"] as? String ?: UUID.randomUUID().toString(),
                            authorId = c["authorId"] as? String ?: "",
                            authorName = c["authorName"] as? String ?: "",
                            text = c["text"] as? String ?: "",
                            createdAt = (c["createdAt"] as? Timestamp)?.toDate() ?: Date()
                        )
                    }

                    @Suppress("UNCHECKED_CAST")
                    val reactionsData = data["reactions"] as? List<Map<String, Any>> ?: emptyList()
                    val reactions = reactionsData.mapNotNull { r ->
                        val emoji = r["emoji"] as? String ?: return@mapNotNull null
                        @Suppress("UNCHECKED_CAST")
                        val userIds = r["userIds"] as? List<String> ?: return@mapNotNull null
                        PostReaction(emoji = emoji, userIds = userIds)
                    }

                    @Suppress("UNCHECKED_CAST")
                    Post(
                        id = doc.id,
                        groupId = data["groupId"] as? String ?: "",
                        authorId = data["authorId"] as? String ?: "",
                        authorName = data["authorName"] as? String ?: "",
                        subjectName = subjectName,
                        date = (data["date"] as? Timestamp)?.toDate() ?: Date(),
                        description = data["description"] as? String ?: "",
                        photoURLs = data["photoURLs"] as? List<String> ?: emptyList(),
                        comments = comments,
                        reactions = reactions,
                        createdAt = (data["createdAt"] as? Timestamp)?.toDate() ?: Date()
                    )
                }
            }
    }

    open suspend fun createPost(
        groupId: String,
        authorId: String,
        authorName: String,
        subjectName: String,
        date: Date,
        description: String,
        imageUris: List<Uri>
    ): Post {
        val firestore = db ?: throw Exception("Firestore not available")
        val context = appContext ?: throw Exception("App context not set")
        val postId = UUID.randomUUID().toString()
        val basePath = "posts/$postId"

        // Upload images first
        val photoURLs = StorageService.uploadImages(context, imageUris, basePath)

        // Write post document — Firestore field is "subject" (matching iOS)
        val data = hashMapOf<String, Any>(
            "groupId" to groupId,
            "authorId" to authorId,
            "authorName" to authorName,
            "subject" to subjectName,
            "date" to Timestamp(date),
            "description" to description,
            "photoURLs" to photoURLs,
            "comments" to listOf<Map<String, Any>>(),
            "reactions" to listOf<Map<String, Any>>(),
            "createdAt" to FieldValue.serverTimestamp()
        )

        firestore.collection("posts").document(postId).set(data).await()

        return Post(
            id = postId,
            groupId = groupId,
            authorId = authorId,
            authorName = authorName,
            subjectName = subjectName,
            date = date,
            description = description,
            photoURLs = photoURLs
        )
    }

    open suspend fun deletePost(post: Post) {
        val firestore = db ?: throw Exception("Firestore not available")
        firestore.collection("posts").document(post.id).delete().await()
        // Fire-and-forget: delete images from Storage
        StorageService.deleteImages(post.photoURLs)
    }

    open suspend fun addComment(postId: String, authorId: String, authorName: String, text: String) {
        val firestore = db ?: throw Exception("Firestore not available")
        val commentData = hashMapOf<String, Any>(
            "id" to UUID.randomUUID().toString(),
            "authorId" to authorId,
            "authorName" to authorName,
            "text" to text,
            "createdAt" to Timestamp(Date())
        )

        firestore.collection("posts").document(postId).update(
            "comments", FieldValue.arrayUnion(commentData)
        ).await()
    }

    open suspend fun toggleReaction(postId: String, emoji: String, userId: String, currentReactions: List<PostReaction>) {
        val firestore = db ?: throw Exception("Firestore not available")

        val updatedReactions = currentReactions.map { reaction ->
            hashMapOf<String, Any>("emoji" to reaction.emoji, "userIds" to reaction.userIds)
        }.toMutableList()

        val index = updatedReactions.indexOfFirst { (it["emoji"] as? String) == emoji }
        if (index >= 0) {
            @Suppress("UNCHECKED_CAST")
            val userIds = (updatedReactions[index]["userIds"] as? List<String> ?: emptyList()).toMutableList()
            if (userIds.contains(userId)) {
                userIds.remove(userId)
            } else {
                userIds.add(userId)
            }
            if (userIds.isEmpty()) {
                updatedReactions.removeAt(index)
            } else {
                updatedReactions[index] = hashMapOf("emoji" to emoji, "userIds" to userIds as Any)
            }
        } else {
            updatedReactions.add(hashMapOf("emoji" to emoji, "userIds" to listOf(userId) as Any))
        }

        firestore.collection("posts").document(postId).update(
            "reactions", updatedReactions
        ).await()
    }

    open suspend fun addPhotos(postId: String, imageUris: List<Uri>) {
        val firestore = db ?: throw Exception("Firestore not available")
        val context = appContext ?: throw Exception("App context not set")
        val basePath = "posts/$postId"

        val newURLs = StorageService.uploadImages(context, imageUris, basePath)
        firestore.collection("posts").document(postId).update(
            "photoURLs", FieldValue.arrayUnion(*newURLs.toTypedArray())
        ).await()
    }

    open fun removeListener() {
        listener?.remove()
        listener = null
    }
}
