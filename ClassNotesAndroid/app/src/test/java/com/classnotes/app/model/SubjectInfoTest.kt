package com.classnotes.app.model

import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class SubjectInfoTest {

    @Test
    fun `builtInSubjects has 6 entries`() {
        assertEquals(6, SubjectInfo.builtInSubjects.size)
    }

    @Test
    fun `builtInSubjects are all marked as built-in`() {
        SubjectInfo.builtInSubjects.forEach {
            assertTrue("${it.name} should be built-in", it.isBuiltIn)
        }
    }

    @Test
    fun `builtInSubjects names match Subject enum rawValues`() {
        val expectedNames = listOf("Math", "Science", "English", "Hindi", "Social Studies", "Other")
        val actualNames = SubjectInfo.builtInSubjects.map { it.name }
        assertEquals(expectedNames, actualNames)
    }

    @Test
    fun `create custom subject from name, color, icon strings`() {
        val info = SubjectInfo(name = "Computer", colorName = "cyan", iconName = "laptop")

        assertEquals("Computer", info.name)
        assertEquals("cyan", info.colorNameString)
        assertEquals("laptop", info.iconNameString)
        assertFalse(info.isBuiltIn)
    }

    @Test
    fun `create SubjectInfo from built-in Subject enum`() {
        val info = SubjectInfo(from = Subject.MATH)

        assertEquals("Math", info.name)
        assertTrue(info.isBuiltIn)
        assertEquals("blue", info.colorNameString)
        assertEquals("function", info.iconNameString)
    }

    @Test
    fun `all Subject enum values create valid SubjectInfo`() {
        Subject.entries.forEach { subject ->
            val info = SubjectInfo(from = subject)
            assertEquals(subject.rawValue, info.name)
            assertTrue(info.isBuiltIn)
            assertTrue(info.colorNameString.isNotEmpty())
            assertTrue(info.iconNameString.isNotEmpty())
        }
    }

    @Test
    fun `firestoreDict produces correct map`() {
        val info = SubjectInfo(name = "Art", colorName = "pink", iconName = "brush")
        val dict = info.firestoreDict

        assertEquals("Art", dict["name"])
        assertEquals("pink", dict["color"])
        assertEquals("brush", dict["icon"])
        assertEquals(3, dict.size)
    }

    @Test
    fun `find returns built-in subject by name`() {
        val found = SubjectInfo.find("Math", emptyList())

        assertNotNull(found)
        assertEquals("Math", found!!.name)
        assertTrue(found.isBuiltIn)
    }

    @Test
    fun `find returns custom subject when not built-in`() {
        val custom = SubjectInfo(name = "Computer", colorName = "cyan", iconName = "laptop")
        val found = SubjectInfo.find("Computer", listOf(custom))

        assertNotNull(found)
        assertEquals("Computer", found!!.name)
        assertFalse(found.isBuiltIn)
    }

    @Test
    fun `find prefers built-in over custom with same name`() {
        val custom = SubjectInfo(name = "Math", colorName = "red", iconName = "star")
        val found = SubjectInfo.find("Math", listOf(custom))

        assertNotNull(found)
        assertEquals("Math", found!!.name)
        assertTrue(found.isBuiltIn) // Should prefer built-in
    }

    @Test
    fun `find returns null for unknown subject without custom match`() {
        val found = SubjectInfo.find("Unknown", emptyList())
        assertNull(found)
    }

    @Test
    fun `equality based on name only`() {
        val info1 = SubjectInfo(name = "Test", colorName = "red", iconName = "star")
        val info2 = SubjectInfo(name = "Test", colorName = "blue", iconName = "book")

        assertEquals(info1, info2) // Same name = equal
        assertEquals(info1.hashCode(), info2.hashCode())
    }

    @Test
    fun `inequality for different names`() {
        val info1 = SubjectInfo(name = "Test1", colorName = "red", iconName = "star")
        val info2 = SubjectInfo(name = "Test2", colorName = "red", iconName = "star")

        assertNotEquals(info1, info2)
    }

    @Test
    fun `colorFromName resolves known colors`() {
        val knownColors = listOf("red", "pink", "indigo", "teal", "cyan", "mint", "brown", "yellow")
        knownColors.forEach { colorName ->
            val color = SubjectInfo.colorFromName(colorName)
            assertNotNull("Color for '$colorName' should resolve", color)
        }
    }

    @Test
    fun `colorFromName returns default for unknown color`() {
        val color = SubjectInfo.colorFromName("nonexistent")
        assertNotNull(color) // Should return SubjectGray as default
    }

    @Test
    fun `iconFromName resolves known icons`() {
        val knownIcons = listOf("book", "architecture", "brush", "music_note", "sports_soccer",
            "language", "laptop", "build", "eco", "favorite", "star", "flag")
        knownIcons.forEach { iconName ->
            val icon = SubjectInfo.iconFromName(iconName)
            assertNotNull("Icon for '$iconName' should resolve", icon)
        }
    }

    @Test
    fun `iconFromName returns default for unknown icon`() {
        val icon = SubjectInfo.iconFromName("nonexistent")
        assertNotNull(icon) // Should return Description as default
    }

    @Test
    fun `customColorOptions has 8 entries`() {
        assertEquals(8, SubjectInfo.customColorOptions.size)
    }

    @Test
    fun `customIconOptions has 12 entries`() {
        assertEquals(12, SubjectInfo.customIconOptions.size)
    }

    @Test
    fun `customColorOptions have unique names`() {
        val names = SubjectInfo.customColorOptions.map { it.first }
        assertEquals(names.size, names.toSet().size)
    }

    @Test
    fun `customIconOptions have unique names`() {
        val names = SubjectInfo.customIconOptions.map { it.first }
        assertEquals(names.size, names.toSet().size)
    }
}
