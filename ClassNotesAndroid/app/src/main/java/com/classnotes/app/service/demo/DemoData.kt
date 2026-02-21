package com.classnotes.app.service.demo

import com.classnotes.app.model.AppUser
import com.classnotes.app.model.ClassGroup
import com.classnotes.app.model.NoteRequest
import com.classnotes.app.model.Post
import com.classnotes.app.model.RequestResponse
import com.classnotes.app.model.RequestStatus
import com.classnotes.app.model.Subject
import java.util.Calendar
import java.util.Date

object DemoData {
    val users = listOf(
        AppUser(id = "demo-user-1", phone = "+919876543210", name = "You"),
        AppUser(id = "demo-user-2", phone = "+919876543211", name = "Aditi's Mom"),
        AppUser(id = "demo-user-3", phone = "+919876543212", name = "Rahul's Dad"),
        AppUser(id = "demo-user-4", phone = "+919876543213", name = "Ananya's Mom"),
        AppUser(id = "demo-user-5", phone = "+919876543214", name = "Vikram's Mom"),
        AppUser(id = "demo-user-6", phone = "+919876543215", name = "Neha's Dad"),
        AppUser(id = "demo-user-7", phone = "+919876543216", name = "Arjun's Mom"),
    )

    val groups = listOf(
        ClassGroup(
            id = "demo-group-1",
            name = "Class 5A",
            school = "Delhi Public School",
            inviteCode = "DEMO01",
            members = listOf("demo-user-1", "demo-user-2", "demo-user-3", "demo-user-4", "demo-user-5"),
            createdBy = "demo-user-1",
            customSubjects = listOf(mapOf("name" to "Computer", "color" to "cyan", "icon" to "laptop"))
        ),
        ClassGroup(
            id = "demo-group-2",
            name = "Class 5B",
            school = "Delhi Public School",
            inviteCode = "DEMO02",
            members = listOf("demo-user-1", "demo-user-6", "demo-user-7"),
            createdBy = "demo-user-6"
        ),
    )

    private fun daysAgo(days: Int): Date {
        val cal = Calendar.getInstance()
        cal.add(Calendar.DAY_OF_YEAR, -days)
        return cal.time
    }

    val posts = listOf(
        Post(
            id = "demo-post-1",
            groupId = "demo-group-1",
            authorId = "demo-user-2",
            authorName = "Aditi's Mom",
            subject = Subject.MATH,
            date = daysAgo(1),
            description = "Chapter 7 - Fractions and Decimals (all 4 pages)",
            photoURLs = listOf(
                "https://picsum.photos/seed/math1/400/600",
                "https://picsum.photos/seed/math2/400/600",
                "https://picsum.photos/seed/math3/400/600",
                "https://picsum.photos/seed/math4/400/600",
            )
        ),
        Post(
            id = "demo-post-2",
            groupId = "demo-group-1",
            authorId = "demo-user-3",
            authorName = "Rahul's Dad",
            subject = Subject.SCIENCE,
            date = daysAgo(1),
            description = "Water cycle diagram + notes from today's class",
            photoURLs = listOf(
                "https://picsum.photos/seed/sci1/400/600",
                "https://picsum.photos/seed/sci2/400/600",
            )
        ),
        Post(
            id = "demo-post-3",
            groupId = "demo-group-1",
            authorId = "demo-user-4",
            authorName = "Ananya's Mom",
            subject = Subject.ENGLISH,
            date = Date(),
            description = "Grammar - Tenses worksheet",
            photoURLs = listOf(
                "https://picsum.photos/seed/eng1/400/600",
            )
        ),
        Post(
            id = "demo-post-4",
            groupId = "demo-group-1",
            authorId = "demo-user-2",
            authorName = "Aditi's Mom",
            subject = Subject.HINDI,
            date = daysAgo(2),
            description = "Hindi essay topic and reference notes",
            photoURLs = listOf(
                "https://picsum.photos/seed/hindi1/400/600",
                "https://picsum.photos/seed/hindi2/400/600",
            )
        ),
        Post(
            id = "demo-post-5",
            groupId = "demo-group-1",
            authorId = "demo-user-5",
            authorName = "Vikram's Mom",
            subject = Subject.SOCIAL_STUDIES,
            date = daysAgo(3),
            description = "History - Mughal Empire timeline",
            photoURLs = listOf(
                "https://picsum.photos/seed/ss1/400/600",
            )
        ),
        Post(
            id = "demo-post-6",
            groupId = "demo-group-2",
            authorId = "demo-user-6",
            authorName = "Neha's Dad",
            subject = Subject.MATH,
            date = Date(),
            description = "Geometry homework - angles worksheet",
            photoURLs = listOf(
                "https://picsum.photos/seed/geo1/400/600",
                "https://picsum.photos/seed/geo2/400/600",
            )
        ),
    )

    val requests = listOf(
        NoteRequest(
            id = "demo-req-1",
            groupId = "demo-group-1",
            authorId = "demo-user-1",
            authorName = "You",
            subject = Subject.SCIENCE,
            date = Date(),
            description = "My child was absent today. Can someone share the Science notes from today's class?"
        ),
        NoteRequest(
            id = "demo-req-2",
            groupId = "demo-group-1",
            authorId = "demo-user-4",
            authorName = "Ananya's Mom",
            subject = Subject.MATH,
            date = daysAgo(1),
            description = "Need Math homework page - Ananya forgot to copy it",
            status = RequestStatus.FULFILLED,
            responses = listOf(
                RequestResponse(
                    id = "demo-resp-1",
                    authorId = "demo-user-2",
                    authorName = "Aditi's Mom",
                    photoURLs = listOf("https://picsum.photos/seed/resp1/400/600")
                )
            )
        ),
        NoteRequest(
            id = "demo-req-3",
            groupId = "demo-group-1",
            authorId = "demo-user-3",
            authorName = "Rahul's Dad",
            subject = Subject.ENGLISH,
            date = daysAgo(2),
            description = "English comprehension passage from Monday's class"
        ),
        NoteRequest(
            id = "demo-req-4",
            groupId = "demo-group-1",
            authorId = "demo-user-2",
            authorName = "Aditi's Mom",
            subject = Subject.HINDI,
            date = Date(),
            description = "Can you share Hindi notes from today? Aditi says your child writes very neatly!",
            targetUserId = "demo-user-1",
            targetUserName = "You"
        ),
    )
}
