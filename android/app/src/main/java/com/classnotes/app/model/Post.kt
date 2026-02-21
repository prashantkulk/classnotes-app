package com.classnotes.app.model

import java.util.Date
import java.util.UUID

data class PostComment(
    val id: String = UUID.randomUUID().toString(),
    val authorId: String,
    val authorName: String,
    val text: String,
    val createdAt: Date = Date()
)

data class PostReaction(
    val emoji: String,
    val userIds: List<String>
)

data class Post(
    val id: String = UUID.randomUUID().toString(),
    val groupId: String,
    val authorId: String,
    val authorName: String,
    val subjectName: String,
    val date: Date,
    val description: String = "",
    val photoURLs: List<String> = emptyList(),
    val comments: List<PostComment> = emptyList(),
    val reactions: List<PostReaction> = emptyList(),
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
        photoURLs: List<String> = emptyList(),
        comments: List<PostComment> = emptyList(),
        reactions: List<PostReaction> = emptyList(),
        createdAt: Date = Date()
    ) : this(
        id = id,
        groupId = groupId,
        authorId = authorId,
        authorName = authorName,
        subjectName = subject.rawValue,
        date = date,
        description = description,
        photoURLs = photoURLs,
        comments = comments,
        reactions = reactions,
        createdAt = createdAt
    )
}
