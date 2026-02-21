package com.classnotes.app.service.demo

import android.net.Uri
import com.classnotes.app.model.Subject
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.util.Date

@RunWith(RobolectricTestRunner::class)
class DemoPostServiceTest {

    private lateinit var service: DemoPostService

    @Before
    fun setUp() {
        service = DemoPostService()
    }

    @Test
    fun `loadPosts filters by groupId`() {
        service.loadPosts("demo-group-1")
        val posts = service.posts.value
        assertEquals(5, posts.size)
        assertTrue(posts.all { it.groupId == "demo-group-1" })
    }

    @Test
    fun `loadPosts for group 2`() {
        service.loadPosts("demo-group-2")
        val posts = service.posts.value
        assertEquals(1, posts.size)
        assertEquals("demo-group-2", posts[0].groupId)
    }

    @Test
    fun `loadPosts for non-existent group returns empty`() {
        service.loadPosts("non-existent")
        assertTrue(service.posts.value.isEmpty())
    }

    @Test
    fun `createPost adds post to beginning of list`() = runTest {
        service.loadPosts("demo-group-1")
        val initialCount = service.posts.value.size

        val post = service.createPost(
            groupId = "demo-group-1",
            authorId = "demo-user-1",
            authorName = "Test User",
            subjectName = "Math",
            date = Date(),
            description = "New post",
            imageUris = emptyList()
        )

        assertEquals(initialCount + 1, service.posts.value.size)
        assertEquals("New post", service.posts.value[0].description)
        assertEquals("Test User", post.authorName)
        assertEquals("Math", post.subjectName)
        assertTrue(post.photoURLs.isNotEmpty()) // Should generate a placeholder URL
    }

    @Test
    fun `createPost with image URIs generates photo URLs`() = runTest {
        service.loadPosts("demo-group-1")

        val uris = listOf(
            Uri.parse("content://media/1"),
            Uri.parse("content://media/2")
        )

        val post = service.createPost(
            groupId = "demo-group-1",
            authorId = "demo-user-1",
            authorName = "Test",
            subjectName = "Science",
            date = Date(),
            description = "With photos",
            imageUris = uris
        )

        assertEquals(2, post.photoURLs.size)
        assertTrue(post.photoURLs.all { it.startsWith("https://picsum.photos/") })
    }

    @Test
    fun `deletePost removes post from list`() = runTest {
        service.loadPosts("demo-group-1")
        val post = service.posts.value[0]
        val initialCount = service.posts.value.size

        service.deletePost(post)

        assertEquals(initialCount - 1, service.posts.value.size)
        assertNull(service.posts.value.find { it.id == post.id })
    }

    @Test
    fun `addComment adds comment to post`() = runTest {
        service.loadPosts("demo-group-1")
        val postId = service.posts.value[0].id
        val initialComments = service.posts.value[0].comments.size

        service.addComment(postId, "demo-user-1", "Test User", "Great notes!")

        val updated = service.posts.value.find { it.id == postId }!!
        assertEquals(initialComments + 1, updated.comments.size)
        assertEquals("Great notes!", updated.comments.last().text)
        assertEquals("Test User", updated.comments.last().authorName)
    }

    @Test
    fun `addComment to non-existent post does nothing`() = runTest {
        service.loadPosts("demo-group-1")
        val initialPosts = service.posts.value.toList()

        service.addComment("non-existent", "u1", "Test", "Comment")

        // Posts should be unchanged
        assertEquals(initialPosts, service.posts.value)
    }

    @Test
    fun `toggleReaction adds new reaction`() = runTest {
        service.loadPosts("demo-group-1")
        val postId = service.posts.value[0].id

        service.toggleReaction(postId, "\uD83D\uDC4D", "demo-user-1", emptyList())

        val updated = service.posts.value.find { it.id == postId }!!
        val reaction = updated.reactions.find { it.emoji == "\uD83D\uDC4D" }
        assertNotNull(reaction)
        assertTrue(reaction!!.userIds.contains("demo-user-1"))
    }

    @Test
    fun `toggleReaction adds user to existing reaction`() = runTest {
        service.loadPosts("demo-group-1")
        val postId = service.posts.value[0].id

        // First user reacts
        service.toggleReaction(postId, "\uD83D\uDC4D", "demo-user-1", emptyList())

        // Get updated reactions
        val updatedPost = service.posts.value.find { it.id == postId }!!

        // Second user reacts to same emoji
        service.toggleReaction(postId, "\uD83D\uDC4D", "demo-user-2", updatedPost.reactions)

        val finalPost = service.posts.value.find { it.id == postId }!!
        val reaction = finalPost.reactions.find { it.emoji == "\uD83D\uDC4D" }!!
        assertEquals(2, reaction.userIds.size)
        assertTrue(reaction.userIds.contains("demo-user-1"))
        assertTrue(reaction.userIds.contains("demo-user-2"))
    }

    @Test
    fun `toggleReaction removes user from existing reaction`() = runTest {
        service.loadPosts("demo-group-1")
        val postId = service.posts.value[0].id

        // Add reaction
        service.toggleReaction(postId, "\uD83D\uDC4D", "demo-user-1", emptyList())
        // Add second user
        val post1 = service.posts.value.find { it.id == postId }!!
        service.toggleReaction(postId, "\uD83D\uDC4D", "demo-user-2", post1.reactions)

        // Remove first user
        val post2 = service.posts.value.find { it.id == postId }!!
        service.toggleReaction(postId, "\uD83D\uDC4D", "demo-user-1", post2.reactions)

        val finalPost = service.posts.value.find { it.id == postId }!!
        val reaction = finalPost.reactions.find { it.emoji == "\uD83D\uDC4D" }!!
        assertEquals(1, reaction.userIds.size)
        assertFalse(reaction.userIds.contains("demo-user-1"))
    }

    @Test
    fun `toggleReaction removes reaction entirely when last user removes`() = runTest {
        service.loadPosts("demo-group-1")
        val postId = service.posts.value[0].id

        // Add reaction
        service.toggleReaction(postId, "\uD83D\uDC4D", "demo-user-1", emptyList())
        // Remove it
        val post = service.posts.value.find { it.id == postId }!!
        service.toggleReaction(postId, "\uD83D\uDC4D", "demo-user-1", post.reactions)

        val finalPost = service.posts.value.find { it.id == postId }!!
        assertNull(finalPost.reactions.find { it.emoji == "\uD83D\uDC4D" })
    }

    @Test
    fun `addPhotos appends new photos to post`() = runTest {
        service.loadPosts("demo-group-1")
        val postId = service.posts.value[0].id
        val initialPhotoCount = service.posts.value[0].photoURLs.size

        val uris = listOf(Uri.parse("content://media/new1"))
        service.addPhotos(postId, uris)

        val updated = service.posts.value.find { it.id == postId }!!
        assertEquals(initialPhotoCount + 1, updated.photoURLs.size)
    }
}
