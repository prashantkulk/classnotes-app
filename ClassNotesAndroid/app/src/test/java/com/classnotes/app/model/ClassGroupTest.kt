package com.classnotes.app.model

import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class ClassGroupTest {

    @Test
    fun `create group with required fields`() {
        val group = ClassGroup(
            name = "Class 5A",
            school = "DPS",
            createdBy = "user-1"
        )

        assertEquals("Class 5A", group.name)
        assertEquals("DPS", group.school)
        assertEquals("user-1", group.createdBy)
        assertNotNull(group.id)
        assertNotNull(group.inviteCode)
        assertTrue(group.members.isEmpty())
        assertTrue(group.customSubjects.isEmpty())
    }

    @Test
    fun `invite code is 6 characters`() {
        val code = ClassGroup.generateInviteCode()
        assertEquals(6, code.length)
    }

    @Test
    fun `invite code contains only unambiguous characters`() {
        val allowedChars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        repeat(100) {
            val code = ClassGroup.generateInviteCode()
            code.forEach { char ->
                assertTrue("Character '$char' is not in allowed set", char in allowedChars)
            }
        }
    }

    @Test
    fun `invite codes are not always the same`() {
        val codes = (1..10).map { ClassGroup.generateInviteCode() }.toSet()
        assertTrue("Expected multiple unique codes, got ${codes.size}", codes.size > 1)
    }

    @Test
    fun `customSubjectInfos parses valid entries`() {
        val group = ClassGroup(
            name = "Test",
            school = "School",
            createdBy = "user-1",
            customSubjects = listOf(
                mapOf("name" to "Computer", "color" to "cyan", "icon" to "laptop"),
                mapOf("name" to "Art", "color" to "pink", "icon" to "brush")
            )
        )

        val infos = group.customSubjectInfos
        assertEquals(2, infos.size)
        assertEquals("Computer", infos[0].name)
        assertEquals("Art", infos[1].name)
        assertFalse(infos[0].isBuiltIn)
        assertFalse(infos[1].isBuiltIn)
    }

    @Test
    fun `customSubjectInfos skips invalid entries`() {
        val group = ClassGroup(
            name = "Test",
            school = "School",
            createdBy = "user-1",
            customSubjects = listOf(
                mapOf("name" to "Computer", "color" to "cyan", "icon" to "laptop"),
                mapOf("name" to "Invalid"), // missing color and icon
                mapOf("color" to "red", "icon" to "star"), // missing name
                mapOf() // empty
            )
        )

        val infos = group.customSubjectInfos
        assertEquals(1, infos.size)
        assertEquals("Computer", infos[0].name)
    }

    @Test
    fun `allSubjects includes built-in and custom subjects`() {
        val group = ClassGroup(
            name = "Test",
            school = "School",
            createdBy = "user-1",
            customSubjects = listOf(
                mapOf("name" to "Computer", "color" to "cyan", "icon" to "laptop")
            )
        )

        val all = group.allSubjects
        // 6 built-in + 1 custom
        assertEquals(7, all.size)

        // First 6 should be built-in
        assertTrue(all[0].isBuiltIn) // Math
        assertTrue(all[5].isBuiltIn) // Other

        // Last should be custom
        assertEquals("Computer", all[6].name)
        assertFalse(all[6].isBuiltIn)
    }

    @Test
    fun `allSubjects with no custom subjects returns only built-in`() {
        val group = ClassGroup(
            name = "Test",
            school = "School",
            createdBy = "user-1"
        )

        val all = group.allSubjects
        assertEquals(6, all.size)
        assertTrue(all.all { it.isBuiltIn })
    }

    @Test
    fun `group copy preserves fields`() {
        val group = ClassGroup(
            id = "g1",
            name = "Class 5A",
            school = "DPS",
            inviteCode = "ABC123",
            members = listOf("u1", "u2"),
            createdBy = "u1"
        )

        val updated = group.copy(members = group.members + "u3")
        assertEquals(3, updated.members.size)
        assertEquals("g1", updated.id)
        assertEquals("ABC123", updated.inviteCode)
    }
}
