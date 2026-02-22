package com.classnotes.app.service.demo

import com.classnotes.app.model.RequestStatus
import com.classnotes.app.model.Subject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class DemoDataTest {

    @Test
    fun `has 7 demo users`() {
        assertEquals(7, DemoData.users.size)
    }

    @Test
    fun `first user is the current demo user`() {
        val user = DemoData.users[0]
        assertEquals("demo-user-1", user.id)
        assertEquals("+919876543210", user.phone)
        assertEquals("You", user.name)
    }

    @Test
    fun `all users have unique IDs`() {
        val ids = DemoData.users.map { it.id }
        assertEquals(ids.size, ids.toSet().size)
    }

    @Test
    fun `all users have unique phone numbers`() {
        val phones = DemoData.users.map { it.phone }
        assertEquals(phones.size, phones.toSet().size)
    }

    @Test
    fun `all users have names`() {
        DemoData.users.forEach { user ->
            assertTrue("User ${user.id} should have a name", user.name.isNotEmpty())
        }
    }

    @Test
    fun `has 2 demo groups`() {
        assertEquals(2, DemoData.groups.size)
    }

    @Test
    fun `first group is Class 5A`() {
        val group = DemoData.groups[0]
        assertEquals("demo-group-1", group.id)
        assertEquals("Class 5A", group.name)
        assertEquals("Delhi Public School", group.school)
        assertEquals("DEMO01", group.inviteCode)
        assertEquals(5, group.members.size)
        assertTrue(group.members.contains("demo-user-1")) // Current user is member
    }

    @Test
    fun `second group is Class 5B`() {
        val group = DemoData.groups[1]
        assertEquals("demo-group-2", group.id)
        assertEquals("Class 5B", group.name)
        assertEquals("DEMO02", group.inviteCode)
        assertEquals(3, group.members.size)
    }

    @Test
    fun `Class 5A has a custom subject`() {
        val group = DemoData.groups[0]
        assertEquals(1, group.customSubjects.size)
        assertEquals("Computer", group.customSubjects[0]["name"])
        assertEquals("cyan", group.customSubjects[0]["color"])
        assertEquals("laptop", group.customSubjects[0]["icon"])
    }

    @Test
    fun `Class 5B has no custom subjects`() {
        val group = DemoData.groups[1]
        assertTrue(group.customSubjects.isEmpty())
    }

    @Test
    fun `has 6 demo posts`() {
        assertEquals(6, DemoData.posts.size)
    }

    @Test
    fun `posts belong to correct groups`() {
        val group1Posts = DemoData.posts.filter { it.groupId == "demo-group-1" }
        val group2Posts = DemoData.posts.filter { it.groupId == "demo-group-2" }
        assertEquals(5, group1Posts.size)
        assertEquals(1, group2Posts.size)
    }

    @Test
    fun `first post is Math with 4 photos`() {
        val post = DemoData.posts[0]
        assertEquals("demo-post-1", post.id)
        assertEquals("Aditi's Mom", post.authorName)
        assertEquals(Subject.MATH, post.subject)
        assertEquals(4, post.photoURLs.size)
        assertTrue(post.description.contains("Fractions"))
    }

    @Test
    fun `all posts have at least one photo URL`() {
        DemoData.posts.forEach { post ->
            assertTrue("Post ${post.id} should have photos", post.photoURLs.isNotEmpty())
        }
    }

    @Test
    fun `all posts have photo URLs pointing to unsplash`() {
        DemoData.posts.forEach { post ->
            post.photoURLs.forEach { url ->
                assertTrue("URL should be unsplash: $url", url.startsWith("https://images.unsplash.com/"))
            }
        }
    }

    @Test
    fun `posts cover multiple subjects`() {
        val subjects = DemoData.posts.mapNotNull { it.subject }.toSet()
        assertTrue("Should have Math", subjects.contains(Subject.MATH))
        assertTrue("Should have Science", subjects.contains(Subject.SCIENCE))
        assertTrue("Should have English", subjects.contains(Subject.ENGLISH))
        assertTrue("Should have Hindi", subjects.contains(Subject.HINDI))
        assertTrue("Should have Social Studies", subjects.contains(Subject.SOCIAL_STUDIES))
    }

    @Test
    fun `has 4 demo requests`() {
        assertEquals(4, DemoData.requests.size)
    }

    @Test
    fun `all requests belong to group 1`() {
        DemoData.requests.forEach { request ->
            assertEquals("demo-group-1", request.groupId)
        }
    }

    @Test
    fun `first request is open Science request from current user`() {
        val request = DemoData.requests[0]
        assertEquals("demo-req-1", request.id)
        assertEquals("demo-user-1", request.authorId)
        assertEquals("You", request.authorName)
        assertEquals(Subject.SCIENCE, request.subject)
        assertEquals(RequestStatus.OPEN, request.status)
    }

    @Test
    fun `second request is fulfilled with one response`() {
        val request = DemoData.requests[1]
        assertEquals("demo-req-2", request.id)
        assertEquals(RequestStatus.FULFILLED, request.status)
        assertEquals(1, request.responses.size)
        assertEquals("Aditi's Mom", request.responses[0].authorName)
    }

    @Test
    fun `fourth request is targeted at current user`() {
        val request = DemoData.requests[3]
        assertEquals("demo-req-4", request.id)
        assertEquals("demo-user-1", request.targetUserId)
        assertEquals("You", request.targetUserName)
        assertEquals(Subject.HINDI, request.subject)
    }

    @Test
    fun `requests have mixed statuses`() {
        val openCount = DemoData.requests.count { it.status == RequestStatus.OPEN }
        val fulfilledCount = DemoData.requests.count { it.status == RequestStatus.FULFILLED }
        assertTrue("Should have open requests", openCount > 0)
        assertTrue("Should have fulfilled requests", fulfilledCount > 0)
    }

    @Test
    fun `all member IDs in groups reference valid users`() {
        val userIds = DemoData.users.map { it.id }.toSet()
        DemoData.groups.forEach { group ->
            group.members.forEach { memberId ->
                assertTrue("Member $memberId should be a valid user", userIds.contains(memberId))
            }
        }
    }

    @Test
    fun `all post authorIds reference valid users`() {
        val userIds = DemoData.users.map { it.id }.toSet()
        DemoData.posts.forEach { post ->
            assertTrue("Author ${post.authorId} should be a valid user", userIds.contains(post.authorId))
        }
    }

    @Test
    fun `all request authorIds reference valid users`() {
        val userIds = DemoData.users.map { it.id }.toSet()
        DemoData.requests.forEach { request ->
            assertTrue("Author ${request.authorId} should be a valid user", userIds.contains(request.authorId))
        }
    }
}
