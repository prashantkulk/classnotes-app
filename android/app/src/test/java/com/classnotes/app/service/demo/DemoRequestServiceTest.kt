package com.classnotes.app.service.demo

import android.net.Uri
import com.classnotes.app.model.RequestStatus
import com.classnotes.app.model.Subject
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.util.Date

@RunWith(RobolectricTestRunner::class)
class DemoRequestServiceTest {

    private lateinit var service: DemoRequestService

    @Before
    fun setUp() {
        service = DemoRequestService()
    }

    @Test
    fun `loadRequests filters by groupId`() {
        service.loadRequests("demo-group-1")
        val requests = service.requests.value
        assertEquals(4, requests.size)
        assertTrue(requests.all { it.groupId == "demo-group-1" })
    }

    @Test
    fun `loadRequests for non-existent group returns empty`() {
        service.loadRequests("non-existent")
        assertTrue(service.requests.value.isEmpty())
    }

    @Test
    fun `createRequest adds request to beginning`() = runTest {
        service.loadRequests("demo-group-1")
        val initialCount = service.requests.value.size

        val request = service.createRequest(
            groupId = "demo-group-1",
            authorId = "demo-user-1",
            authorName = "Test User",
            subjectName = "Math",
            date = Date(),
            description = "Need Math notes",
            targetUserId = null,
            targetUserName = null
        )

        assertEquals(initialCount + 1, service.requests.value.size)
        assertEquals("Need Math notes", service.requests.value[0].description)
        assertEquals("Math", request.subjectName)
        assertEquals(RequestStatus.OPEN, request.status)
        assertTrue(request.responses.isEmpty())
    }

    @Test
    fun `createRequest with target user`() = runTest {
        service.loadRequests("demo-group-1")

        val request = service.createRequest(
            groupId = "demo-group-1",
            authorId = "demo-user-1",
            authorName = "Test",
            subjectName = "Science",
            date = Date(),
            description = "Need from you",
            targetUserId = "demo-user-2",
            targetUserName = "Aditi's Mom"
        )

        assertEquals("demo-user-2", request.targetUserId)
        assertEquals("Aditi's Mom", request.targetUserName)
    }

    @Test
    fun `respondToRequest adds response and marks fulfilled`() = runTest {
        service.loadRequests("demo-group-1")
        val requestId = service.requests.value[0].id // Open Science request
        val initialResponseCount = service.requests.value[0].responses.size

        service.respondToRequest(
            requestId = requestId,
            authorId = "demo-user-2",
            authorName = "Aditi's Mom",
            imageUris = listOf(Uri.parse("content://media/1"))
        )

        val updated = service.requests.value.find { it.id == requestId }!!
        assertEquals(initialResponseCount + 1, updated.responses.size)
        assertEquals(RequestStatus.FULFILLED, updated.status)
        assertEquals("Aditi's Mom", updated.responses.last().authorName)
        assertTrue(updated.responses.last().photoURLs.isNotEmpty())
    }

    @Test
    fun `respondToRequest with empty URIs still generates placeholder URL`() = runTest {
        service.loadRequests("demo-group-1")
        val requestId = service.requests.value[0].id

        service.respondToRequest(
            requestId = requestId,
            authorId = "demo-user-2",
            authorName = "Test",
            imageUris = emptyList()
        )

        val updated = service.requests.value.find { it.id == requestId }!!
        assertTrue(updated.responses.last().photoURLs.isNotEmpty())
    }

    @Test
    fun `deleteRequest removes request from list`() = runTest {
        service.loadRequests("demo-group-1")
        val request = service.requests.value[0]
        val initialCount = service.requests.value.size

        service.deleteRequest(request)

        assertEquals(initialCount - 1, service.requests.value.size)
        assertNull(service.requests.value.find { it.id == request.id })
    }

    @Test
    fun `respondToRequest to non-existent request does nothing`() = runTest {
        service.loadRequests("demo-group-1")
        val initialRequests = service.requests.value.toList()

        service.respondToRequest(
            requestId = "non-existent",
            authorId = "u1",
            authorName = "Test",
            imageUris = emptyList()
        )

        assertEquals(initialRequests, service.requests.value)
    }

    @Test
    fun `full request flow - create, respond, delete`() = runTest {
        service.loadRequests("demo-group-1")
        val initialCount = service.requests.value.size

        // Create request
        val request = service.createRequest(
            groupId = "demo-group-1",
            authorId = "demo-user-1",
            authorName = "Test",
            subjectName = "English",
            date = Date(),
            description = "Need English notes",
            targetUserId = null,
            targetUserName = null
        )
        assertEquals(initialCount + 1, service.requests.value.size)
        assertEquals(RequestStatus.OPEN, request.status)

        // Respond to request
        service.respondToRequest(
            requestId = request.id,
            authorId = "demo-user-2",
            authorName = "Responder",
            imageUris = listOf(Uri.parse("content://media/1"))
        )
        val responded = service.requests.value.find { it.id == request.id }!!
        assertEquals(RequestStatus.FULFILLED, responded.status)
        assertEquals(1, responded.responses.size)

        // Delete request
        service.deleteRequest(responded)
        assertNull(service.requests.value.find { it.id == request.id })
        assertEquals(initialCount, service.requests.value.size)
    }
}
