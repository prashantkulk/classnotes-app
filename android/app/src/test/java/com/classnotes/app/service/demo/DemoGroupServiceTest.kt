package com.classnotes.app.service.demo

import com.classnotes.app.model.ClassGroup
import com.classnotes.app.model.SubjectInfo
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class DemoGroupServiceTest {

    private lateinit var service: DemoGroupService

    @Before
    fun setUp() {
        service = DemoGroupService()
    }

    @Test
    fun `loadGroups populates demo groups`() {
        service.loadGroups("demo-user-1")
        val groups = service.groups.value

        assertEquals(2, groups.size)
        assertEquals("Class 5A", groups[0].name)
        assertEquals("Class 5B", groups[1].name)
    }

    @Test
    fun `createGroup adds new group to list`() = runTest {
        service.loadGroups("demo-user-1")
        val initialCount = service.groups.value.size

        val newGroup = ClassGroup(
            name = "Class 6A",
            school = "Test School",
            createdBy = "demo-user-1"
        )
        val created = service.createGroup(newGroup)

        assertEquals(initialCount + 1, service.groups.value.size)
        assertEquals("Class 6A", created.name)
        assertEquals(listOf("demo-user-1"), created.members)
    }

    @Test
    fun `createGroup adds group at beginning of list`() = runTest {
        service.loadGroups("demo-user-1")

        val newGroup = ClassGroup(
            name = "New Group",
            school = "New School",
            createdBy = "demo-user-1"
        )
        service.createGroup(newGroup)

        assertEquals("New Group", service.groups.value[0].name)
    }

    @Test
    fun `joinGroup with valid code adds group`() = runTest {
        service.loadGroups("demo-user-1")

        // Remove groups first so we can join DEMO01
        service.leaveGroup("demo-group-1", "demo-user-1")
        service.leaveGroup("demo-group-2", "demo-user-1")
        assertEquals(0, service.groups.value.size)

        val joined = service.joinGroup("DEMO01", "new-user")

        assertEquals("Class 5A", joined.name)
        assertTrue(joined.members.contains("new-user"))
        assertEquals(1, service.groups.value.size)
    }

    @Test
    fun `joinGroup with invalid code throws`() = runTest {
        service.loadGroups("demo-user-1")

        try {
            service.joinGroup("INVALID", "demo-user-1")
            fail("Should have thrown exception")
        } catch (e: Exception) {
            assertTrue(e.message!!.contains("No group found"))
        }
    }

    @Test
    fun `joinGroup when already member throws`() = runTest {
        service.loadGroups("demo-user-1")

        try {
            service.joinGroup("DEMO01", "demo-user-1")
            fail("Should have thrown exception")
        } catch (e: Exception) {
            assertTrue(e.message!!.contains("already a member"))
        }
    }

    @Test
    fun `leaveGroup removes group from list`() = runTest {
        service.loadGroups("demo-user-1")
        assertEquals(2, service.groups.value.size)

        service.leaveGroup("demo-group-1", "demo-user-1")

        assertEquals(1, service.groups.value.size)
        assertNull(service.groups.value.find { it.id == "demo-group-1" })
    }

    @Test
    fun `deleteGroup removes group from list`() = runTest {
        service.loadGroups("demo-user-1")
        val group = service.groups.value[0]

        service.deleteGroup(group)

        assertEquals(1, service.groups.value.size)
        assertNull(service.groups.value.find { it.id == group.id })
    }

    @Test
    fun `addCustomSubject adds subject to group`() = runTest {
        service.loadGroups("demo-user-1")

        val group = service.groups.value[0]
        val initialCustomCount = group.customSubjects.size

        val subject = SubjectInfo(name = "Art", colorName = "pink", iconName = "brush")
        service.addCustomSubject("demo-group-1", subject)

        val updated = service.groups.value.find { it.id == "demo-group-1" }!!
        assertEquals(initialCustomCount + 1, updated.customSubjects.size)

        val lastCustom = updated.customSubjects.last()
        assertEquals("Art", lastCustom["name"])
        assertEquals("pink", lastCustom["color"])
        assertEquals("brush", lastCustom["icon"])
    }

    @Test
    fun `addCustomSubject to non-existent group does nothing`() = runTest {
        service.loadGroups("demo-user-1")
        val initialGroups = service.groups.value.toList()

        val subject = SubjectInfo(name = "Art", colorName = "pink", iconName = "brush")
        service.addCustomSubject("non-existent-group", subject)

        // Groups should be unchanged
        assertEquals(initialGroups.size, service.groups.value.size)
    }
}
