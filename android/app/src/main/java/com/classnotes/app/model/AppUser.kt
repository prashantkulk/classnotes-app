package com.classnotes.app.model

import java.util.Date

data class AppUser(
    val id: String,
    val phone: String,
    val name: String = "",
    val groups: List<String> = emptyList(),
    val fcmToken: String? = null,
    val createdAt: Date = Date()
)
