package com.classnotes.app.model

import java.util.Date
import java.util.UUID

data class ClassGroup(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val school: String,
    val inviteCode: String = generateInviteCode(),
    val members: List<String> = emptyList(),
    val createdBy: String,
    val createdAt: Date = Date(),
    val customSubjects: List<Map<String, String>> = emptyList()
) {
    /** Custom subjects parsed from Firestore dictionary format into [SubjectInfo] objects. */
    val customSubjectInfos: List<SubjectInfo>
        get() = customSubjects.mapNotNull { dict ->
            val n = dict["name"] ?: return@mapNotNull null
            val c = dict["color"] ?: return@mapNotNull null
            val i = dict["icon"] ?: return@mapNotNull null
            SubjectInfo(name = n, colorName = c, iconName = i)
        }

    /** All subjects available in this group: built-in subjects plus any custom ones. */
    val allSubjects: List<SubjectInfo>
        get() = SubjectInfo.builtInSubjects + customSubjectInfos

    companion object {
        /** Generate a random 6-character invite code using unambiguous characters. */
        fun generateInviteCode(): String {
            val chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
            return (1..6).map { chars.random() }.joinToString("")
        }
    }
}
