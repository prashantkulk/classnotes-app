package com.classnotes.app.model

import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.util.Date

@RunWith(RobolectricTestRunner::class)
class NoteRequestTest {

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
    fun `create request with Subject enum`() {
        val request = NoteRequest(
            groupId = "g1",
            authorId = "u1",
            authorName = "Test",
            subject = Subject.SCIENCE,
            date = Date(),
            description = "Need Science notes"
        )

        assertEquals("Science", request.subjectName)
        assertEquals(Subject.SCIENCE, request.subject)
        assertEquals(RequestStatus.OPEN, request.status)
    }

    @Test
    fun `create request with subjectName string`() {
        val request = NoteRequest(
            groupId = "g1",
            authorId = "u1",
            authorName = "Test",
            subjectName = "Math",
            date = Date()
        )

        assertEquals("Math", request.subjectName)
        assertEquals(Subject.MATH, request.subject)
    }

    @Test
    fun `request with custom subject`() {
        val request = NoteRequest(
            groupId = "g1",
            authorId = "u1",
            authorName = "Test",
            subjectName = "Computer",
            date = Date()
        )

        assertNull(request.subject) // Not a built-in subject
        val info = request.subjectInfo(testGroup)
        assertEquals("Computer", info.name)
        assertFalse(info.isBuiltIn)
    }

    @Test
    fun `request with target user`() {
        val request = NoteRequest(
            groupId = "g1",
            authorId = "u1",
            authorName = "Rahul's Dad",
            subject = Subject.HINDI,
            date = Date(),
            targetUserId = "u2",
            targetUserName = "Aditi's Mom"
        )

        assertEquals("u2", request.targetUserId)
        assertEquals("Aditi's Mom", request.targetUserName)
    }

    @Test
    fun `request without target user is broadcast`() {
        val request = NoteRequest(
            groupId = "g1",
            authorId = "u1",
            authorName = "Test",
            subject = Subject.ENGLISH,
            date = Date()
        )

        assertNull(request.targetUserId)
        assertNull(request.targetUserName)
    }

    @Test
    fun `request status values`() {
        assertEquals("open", RequestStatus.OPEN.rawValue)
        assertEquals("fulfilled", RequestStatus.FULFILLED.rawValue)
    }

    @Test
    fun `request status fromRawValue`() {
        assertEquals(RequestStatus.OPEN, RequestStatus.fromRawValue("open"))
        assertEquals(RequestStatus.FULFILLED, RequestStatus.fromRawValue("fulfilled"))
        assertNull(RequestStatus.fromRawValue("invalid"))
        assertNull(RequestStatus.fromRawValue(""))
    }

    @Test
    fun `request with responses`() {
        val request = NoteRequest(
            groupId = "g1",
            authorId = "u1",
            authorName = "Test",
            subject = Subject.MATH,
            date = Date(),
            status = RequestStatus.FULFILLED,
            responses = listOf(
                RequestResponse(
                    authorId = "u2",
                    authorName = "Responder",
                    photoURLs = listOf("https://example.com/photo1.jpg")
                )
            )
        )

        assertEquals(RequestStatus.FULFILLED, request.status)
        assertEquals(1, request.responses.size)
        assertEquals("Responder", request.responses[0].authorName)
        assertEquals(1, request.responses[0].photoURLs.size)
    }

    @Test
    fun `request response has auto-generated id`() {
        val response = RequestResponse(
            authorId = "u1",
            authorName = "Test",
            photoURLs = listOf("https://example.com/1.jpg")
        )

        assertNotNull(response.id)
        assertTrue(response.id.isNotEmpty())
    }

    @Test
    fun `request has auto-generated id`() {
        val request = NoteRequest(
            groupId = "g1",
            authorId = "u1",
            authorName = "Test",
            subjectName = "Math",
            date = Date()
        )

        assertNotNull(request.id)
        assertTrue(request.id.isNotEmpty())
    }

    @Test
    fun `request default values`() {
        val request = NoteRequest(
            groupId = "g1",
            authorId = "u1",
            authorName = "Test",
            subjectName = "Math",
            date = Date()
        )

        assertEquals("", request.description)
        assertNull(request.targetUserId)
        assertNull(request.targetUserName)
        assertEquals(RequestStatus.OPEN, request.status)
        assertTrue(request.responses.isEmpty())
    }

    @Test
    fun `subjectInfo falls back for unknown subject`() {
        val request = NoteRequest(
            groupId = "g1",
            authorId = "u1",
            authorName = "Test",
            subjectName = "Nonexistent",
            date = Date()
        )

        val info = request.subjectInfo(testGroup)
        assertEquals("Nonexistent", info.name)
        assertEquals("gray", info.colorNameString)
    }
}
