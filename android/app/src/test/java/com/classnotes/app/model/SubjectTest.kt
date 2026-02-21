package com.classnotes.app.model

import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class SubjectTest {

    @Test
    fun `all subjects have correct rawValues`() {
        assertEquals("Math", Subject.MATH.rawValue)
        assertEquals("Science", Subject.SCIENCE.rawValue)
        assertEquals("English", Subject.ENGLISH.rawValue)
        assertEquals("Hindi", Subject.HINDI.rawValue)
        assertEquals("Social Studies", Subject.SOCIAL_STUDIES.rawValue)
        assertEquals("Other", Subject.OTHER.rawValue)
    }

    @Test
    fun `there are exactly 6 subjects`() {
        assertEquals(6, Subject.entries.size)
    }

    @Test
    fun `fromRawValue finds valid subjects`() {
        assertEquals(Subject.MATH, Subject.fromRawValue("Math"))
        assertEquals(Subject.SCIENCE, Subject.fromRawValue("Science"))
        assertEquals(Subject.ENGLISH, Subject.fromRawValue("English"))
        assertEquals(Subject.HINDI, Subject.fromRawValue("Hindi"))
        assertEquals(Subject.SOCIAL_STUDIES, Subject.fromRawValue("Social Studies"))
        assertEquals(Subject.OTHER, Subject.fromRawValue("Other"))
    }

    @Test
    fun `fromRawValue returns null for invalid values`() {
        assertNull(Subject.fromRawValue("math")) // case sensitive
        assertNull(Subject.fromRawValue("MATH"))
        assertNull(Subject.fromRawValue(""))
        assertNull(Subject.fromRawValue("Computer")) // not a built-in subject
        assertNull(Subject.fromRawValue("Social_Studies"))
    }

    @Test
    fun `each subject has a non-null color`() {
        Subject.entries.forEach { subject ->
            assertNotNull("${subject.name} should have a color", subject.color)
        }
    }

    @Test
    fun `each subject has a non-null icon`() {
        Subject.entries.forEach { subject ->
            assertNotNull("${subject.name} should have an icon", subject.icon)
        }
    }

    @Test
    fun `subjects have distinct rawValues`() {
        val rawValues = Subject.entries.map { it.rawValue }
        assertEquals(rawValues.size, rawValues.toSet().size)
    }
}
