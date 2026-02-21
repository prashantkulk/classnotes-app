package com.classnotes.app.model

import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.util.Date

@RunWith(RobolectricTestRunner::class)
class PostTest {

    private val testGroup = ClassGroup(
        id = "g1",
        name = "Class 5A",
        school = "DPS",
        createdBy = "u1",
        customSubjects = listOf(
            mapOf("name" to "Computer", "color" to "cyan", "icon" to "laptop")
        )
    )

    @Test
    fun `create post with Subject enum constructor`() {
        val now = Date()
        val post = Post(
            groupId = "g1",
            authorId = "u1",
            authorName = "Test User",
            subject = Subject.MATH,
            date = now,
            description = "Chapter 7"
        )

        assertEquals("Math", post.subjectName)
        assertEquals(Subject.MATH, post.subject)
        assertEquals("g1", post.groupId)
        assertEquals("Test User", post.authorName)
        assertEquals("Chapter 7", post.description)
    }

    @Test
    fun `create post with subjectName string`() {
        val post = Post(
            groupId = "g1",
            authorId = "u1",
            authorName = "Test",
            subjectName = "Science",
            date = Date()
        )

        assertEquals("Science", post.subjectName)
        assertEquals(Subject.SCIENCE, post.subject)
    }

    @Test
    fun `post with custom subject returns null for subject enum`() {
        val post = Post(
            groupId = "g1",
            authorId = "u1",
            authorName = "Test",
            subjectName = "Computer",
            date = Date()
        )

        assertNull(post.subject)
        assertEquals("Computer", post.subjectName)
    }

    @Test
    fun `subjectInfo resolves built-in subject`() {
        val post = Post(
            groupId = "g1",
            authorId = "u1",
            authorName = "Test",
            subject = Subject.MATH,
            date = Date()
        )

        val info = post.subjectInfo(testGroup)
        assertEquals("Math", info.name)
        assertTrue(info.isBuiltIn)
    }

    @Test
    fun `subjectInfo resolves custom subject from group`() {
        val post = Post(
            groupId = "g1",
            authorId = "u1",
            authorName = "Test",
            subjectName = "Computer",
            date = Date()
        )

        val info = post.subjectInfo(testGroup)
        assertEquals("Computer", info.name)
        assertFalse(info.isBuiltIn)
    }

    @Test
    fun `subjectInfo falls back to gray for unknown subject`() {
        val post = Post(
            groupId = "g1",
            authorId = "u1",
            authorName = "Test",
            subjectName = "UnknownSubject",
            date = Date()
        )

        val info = post.subjectInfo(testGroup)
        assertEquals("UnknownSubject", info.name)
        assertEquals("gray", info.colorNameString)
        assertEquals("description", info.iconNameString)
    }

    @Test
    fun `post with default values`() {
        val post = Post(
            groupId = "g1",
            authorId = "u1",
            authorName = "Test",
            subjectName = "Math",
            date = Date()
        )

        assertEquals("", post.description)
        assertTrue(post.photoURLs.isEmpty())
        assertTrue(post.comments.isEmpty())
        assertTrue(post.reactions.isEmpty())
    }

    @Test
    fun `post with photos and comments`() {
        val post = Post(
            groupId = "g1",
            authorId = "u1",
            authorName = "Test",
            subject = Subject.SCIENCE,
            date = Date(),
            photoURLs = listOf("https://example.com/1.jpg", "https://example.com/2.jpg"),
            comments = listOf(
                PostComment(authorId = "u2", authorName = "User 2", text = "Thanks!"),
                PostComment(authorId = "u3", authorName = "User 3", text = "Very helpful")
            )
        )

        assertEquals(2, post.photoURLs.size)
        assertEquals(2, post.comments.size)
        assertEquals("Thanks!", post.comments[0].text)
        assertEquals("Very helpful", post.comments[1].text)
    }

    @Test
    fun `post with reactions`() {
        val post = Post(
            groupId = "g1",
            authorId = "u1",
            authorName = "Test",
            subject = Subject.MATH,
            date = Date(),
            reactions = listOf(
                PostReaction(emoji = "\uD83D\uDC4D", userIds = listOf("u1", "u2")),
                PostReaction(emoji = "\u2764\uFE0F", userIds = listOf("u3"))
            )
        )

        assertEquals(2, post.reactions.size)
        assertEquals(2, post.reactions[0].userIds.size)
        assertEquals(1, post.reactions[1].userIds.size)
    }

    @Test
    fun `post comment has auto-generated id`() {
        val comment = PostComment(authorId = "u1", authorName = "Test", text = "Hello")
        assertNotNull(comment.id)
        assertTrue(comment.id.isNotEmpty())
    }

    @Test
    fun `post has auto-generated id`() {
        val post = Post(
            groupId = "g1",
            authorId = "u1",
            authorName = "Test",
            subjectName = "Math",
            date = Date()
        )
        assertNotNull(post.id)
        assertTrue(post.id.isNotEmpty())
    }
}
