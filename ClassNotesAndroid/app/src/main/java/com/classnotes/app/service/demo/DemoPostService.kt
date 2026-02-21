package com.classnotes.app.service.demo

import android.net.Uri
import com.classnotes.app.model.Post
import com.classnotes.app.model.PostComment
import com.classnotes.app.model.PostReaction
import com.classnotes.app.service.PostService
import kotlinx.coroutines.delay
import java.util.Date
import java.util.UUID

class DemoPostService : PostService() {
    override fun loadPosts(groupId: String) {
        _posts.value = DemoData.posts.filter { it.groupId == groupId }
    }

    override suspend fun createPost(
        groupId: String,
        authorId: String,
        authorName: String,
        subjectName: String,
        date: Date,
        description: String,
        imageUris: List<Uri>
    ): Post {
        delay(500)
        val photoURLs = if (imageUris.isEmpty()) {
            listOf("https://picsum.photos/seed/demo/400/600")
        } else {
            imageUris.map { "https://picsum.photos/seed/${UUID.randomUUID()}/400/600" }
        }

        val post = Post(
            id = UUID.randomUUID().toString(),
            groupId = groupId,
            authorId = authorId,
            authorName = authorName,
            subjectName = subjectName,
            date = date,
            description = description,
            photoURLs = photoURLs
        )
        val current = _posts.value.toMutableList()
        current.add(0, post)
        _posts.value = current
        return post
    }

    override suspend fun deletePost(post: Post) {
        delay(300)
        _posts.value = _posts.value.filter { it.id != post.id }
    }

    override suspend fun addComment(postId: String, authorId: String, authorName: String, text: String) {
        delay(200)
        val current = _posts.value.toMutableList()
        val index = current.indexOfFirst { it.id == postId }
        if (index >= 0) {
            val comment = PostComment(authorId = authorId, authorName = authorName, text = text)
            current[index] = current[index].copy(comments = current[index].comments + comment)
            _posts.value = current
        }
    }

    override suspend fun toggleReaction(postId: String, emoji: String, userId: String, currentReactions: List<PostReaction>) {
        delay(100)
        val current = _posts.value.toMutableList()
        val index = current.indexOfFirst { it.id == postId }
        if (index >= 0) {
            val reactions = current[index].reactions.toMutableList()
            val rIdx = reactions.indexOfFirst { it.emoji == emoji }
            if (rIdx >= 0) {
                if (reactions[rIdx].userIds.contains(userId)) {
                    val newUserIds = reactions[rIdx].userIds.filter { it != userId }
                    if (newUserIds.isEmpty()) {
                        reactions.removeAt(rIdx)
                    } else {
                        reactions[rIdx] = reactions[rIdx].copy(userIds = newUserIds)
                    }
                } else {
                    reactions[rIdx] = reactions[rIdx].copy(userIds = reactions[rIdx].userIds + userId)
                }
            } else {
                reactions.add(PostReaction(emoji = emoji, userIds = listOf(userId)))
            }
            current[index] = current[index].copy(reactions = reactions)
            _posts.value = current
        }
    }

    override suspend fun addPhotos(postId: String, imageUris: List<Uri>) {
        delay(500)
        val current = _posts.value.toMutableList()
        val index = current.indexOfFirst { it.id == postId }
        if (index >= 0) {
            val newURLs = imageUris.map { "https://picsum.photos/seed/${UUID.randomUUID()}/400/600" }
            current[index] = current[index].copy(photoURLs = current[index].photoURLs + newURLs)
            _posts.value = current
        }
    }
}
