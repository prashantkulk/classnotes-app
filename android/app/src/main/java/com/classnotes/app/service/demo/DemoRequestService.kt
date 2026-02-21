package com.classnotes.app.service.demo

import android.net.Uri
import com.classnotes.app.model.NoteRequest
import com.classnotes.app.model.RequestResponse
import com.classnotes.app.model.RequestStatus
import com.classnotes.app.service.RequestService
import kotlinx.coroutines.delay
import java.util.Date
import java.util.UUID

class DemoRequestService : RequestService() {
    override fun loadRequests(groupId: String) {
        _requests.value = DemoData.requests.filter { it.groupId == groupId }
    }

    override suspend fun createRequest(
        groupId: String,
        authorId: String,
        authorName: String,
        subjectName: String,
        date: Date,
        description: String,
        targetUserId: String?,
        targetUserName: String?
    ): NoteRequest {
        delay(300)
        val request = NoteRequest(
            id = UUID.randomUUID().toString(),
            groupId = groupId,
            authorId = authorId,
            authorName = authorName,
            subjectName = subjectName,
            date = date,
            description = description,
            targetUserId = targetUserId,
            targetUserName = targetUserName
        )
        val current = _requests.value.toMutableList()
        current.add(0, request)
        _requests.value = current
        return request
    }

    override suspend fun respondToRequest(
        requestId: String,
        authorId: String,
        authorName: String,
        imageUris: List<Uri>
    ) {
        delay(500)
        val current = _requests.value.toMutableList()
        val index = current.indexOfFirst { it.id == requestId }
        if (index >= 0) {
            val photoURLs = if (imageUris.isEmpty()) {
                listOf("https://picsum.photos/seed/resp/400/600")
            } else {
                imageUris.map { "https://picsum.photos/seed/${UUID.randomUUID()}/400/600" }
            }

            val response = RequestResponse(
                authorId = authorId,
                authorName = authorName,
                photoURLs = photoURLs
            )
            current[index] = current[index].copy(
                responses = current[index].responses + response,
                status = RequestStatus.FULFILLED
            )
            _requests.value = current
        }
    }

    override suspend fun deleteRequest(request: NoteRequest) {
        delay(300)
        _requests.value = _requests.value.filter { it.id != request.id }
    }
}
