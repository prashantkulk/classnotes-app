package com.classnotes.app.model

import org.junit.Assert.*
import org.junit.Test
import java.util.Date

class AppUserTest {

    @Test
    fun `create user with all fields`() {
        val now = Date()
        val user = AppUser(
            id = "user-1",
            phone = "+919876543210",
            name = "Aditi's Mom",
            groups = listOf("group-1", "group-2"),
            fcmToken = "token-abc",
            createdAt = now
        )

        assertEquals("user-1", user.id)
        assertEquals("+919876543210", user.phone)
        assertEquals("Aditi's Mom", user.name)
        assertEquals(2, user.groups.size)
        assertEquals("token-abc", user.fcmToken)
        assertEquals(now, user.createdAt)
    }

    @Test
    fun `create user with default values`() {
        val user = AppUser(id = "user-1", phone = "+919876543210")

        assertEquals("", user.name)
        assertEquals(emptyList<String>(), user.groups)
        assertNull(user.fcmToken)
        assertNotNull(user.createdAt)
    }

    @Test
    fun `user equality based on all fields`() {
        val date = Date()
        val user1 = AppUser(id = "user-1", phone = "+91123", name = "A", createdAt = date)
        val user2 = AppUser(id = "user-1", phone = "+91123", name = "A", createdAt = date)
        val user3 = AppUser(id = "user-2", phone = "+91123", name = "A", createdAt = date)

        assertEquals(user1, user2)
        assertNotEquals(user1, user3)
    }

    @Test
    fun `user copy works correctly`() {
        val user = AppUser(id = "user-1", phone = "+919876543210", name = "Original")
        val updated = user.copy(name = "Updated Name")

        assertEquals("Updated Name", updated.name)
        assertEquals("user-1", updated.id)
        assertEquals("+919876543210", updated.phone)
    }

    @Test
    fun `user with empty groups list`() {
        val user = AppUser(id = "u1", phone = "123")
        assertTrue(user.groups.isEmpty())
    }

    @Test
    fun `user with multiple groups`() {
        val user = AppUser(id = "u1", phone = "123", groups = listOf("g1", "g2", "g3"))
        assertEquals(3, user.groups.size)
        assertTrue(user.groups.contains("g2"))
    }
}
