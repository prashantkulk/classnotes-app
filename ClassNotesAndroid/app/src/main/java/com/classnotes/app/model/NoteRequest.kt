package com.classnotes.app.model

import java.util.Date
import java.util.UUID

enum class RequestStatus(val rawValue: String) {
    OPEN("open"),
    FULFILLED("fulfilled");

    companion object {
        fun fromRawValue(value: String): RequestStatus? = entries.find { it.rawValue == value }
    }
}

data class RequestResponse(
    val id: String = UUID.randomUUID().toString(),
    val authorId: String,
    val authorName: String,
    val photoURLs: List<String>,
    val createdAt: Date = Date()
)

data class NoteRequest(
    val id: String = UUID.randomUUID().toString(),
    val groupId: String,
    val authorId: String,
    val authorName: String,
    val subjectName: String,
    val date: Date,
    val description: String = "",
    val targetUserId: String? = null,
    val targetUserName: String? = null,
    val status: RequestStatus = RequestStatus.OPEN,
    val responses: List<RequestResponse> = emptyList(),
    val createdAt: Date = Date()
) {
    /** The built-in [Subject] if the subject name matches, or null for custom subjects. */
    val subject: Subject? get() = Subject.fromRawValue(subjectName)

    /** Resolve the full [SubjectInfo] using the group's custom subjects for lookup. */
    fun subjectInfo(group: ClassGroup): SubjectInfo {
        return SubjectInfo.find(subjectName, group.customSubjectInfos)
            ?: SubjectInfo(name = subjectName, colorName = "gray", iconName = "description")
    }

    /** Convenience constructor taking a built-in [Subject] enum value. */
    constructor(
        id: String = UUID.randomUUID().toString(),
        groupId: String,
        authorId: String,
        authorName: String,
        subject: Subject,
        date: Date,
        description: String = "",
        targetUserId: String? = null,
        targetUserName: String? = null,
        status: RequestStatus = RequestStatus.OPEN,
        responses: List<RequestResponse> = emptyList(),
        createdAt: Date = Date()
    ) : this(
        id = id,
        groupId = groupId,
        authorId = authorId,
        authorName = authorName,
        subjectName = subject.rawValue,
        date = date,
        description = description,
        targetUserId = targetUserId,
        targetUserName = targetUserName,
        status = status,
        responses = responses,
        createdAt = createdAt
    )
}
