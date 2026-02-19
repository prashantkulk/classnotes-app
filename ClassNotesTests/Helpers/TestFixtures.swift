import Foundation
@testable import ClassNotes

enum TestFixtures {
    static let referenceDate = Date(timeIntervalSince1970: 1700000000) // 2023-11-14

    static func makeUser(
        id: String = "user-1",
        phone: String = "+919876543210",
        name: String = "Test User",
        groups: [String] = [],
        fcmToken: String? = nil,
        createdAt: Date = referenceDate
    ) -> AppUser {
        AppUser(id: id, phone: phone, name: name, groups: groups, fcmToken: fcmToken, createdAt: createdAt)
    }

    static func makeGroup(
        id: String = "group-1",
        name: String = "Class 10A",
        school: String = "DPS School",
        inviteCode: String = "ABC123",
        members: [String] = ["user-1"],
        createdBy: String = "user-1",
        createdAt: Date = referenceDate
    ) -> ClassGroup {
        ClassGroup(id: id, name: name, school: school, inviteCode: inviteCode,
                   members: members, createdBy: createdBy, createdAt: createdAt)
    }

    static func makePost(
        id: String = "post-1",
        groupId: String = "group-1",
        authorId: String = "user-1",
        authorName: String = "Test User",
        subject: Subject = .math,
        date: Date = referenceDate,
        description: String = "Chapter 5 notes",
        photoURLs: [String] = ["https://example.com/photo1.jpg"],
        createdAt: Date = referenceDate
    ) -> Post {
        Post(id: id, groupId: groupId, authorId: authorId, authorName: authorName,
             subject: subject, date: date, description: description,
             photoURLs: photoURLs, createdAt: createdAt)
    }

    static func makeRequest(
        id: String = "req-1",
        groupId: String = "group-1",
        authorId: String = "user-1",
        authorName: String = "Test User",
        subject: Subject = .science,
        date: Date = referenceDate,
        description: String = "Need chapter 3 notes",
        targetUserId: String? = nil,
        targetUserName: String? = nil,
        status: RequestStatus = .open,
        responses: [RequestResponse] = [],
        createdAt: Date = referenceDate
    ) -> NoteRequest {
        NoteRequest(id: id, groupId: groupId, authorId: authorId, authorName: authorName,
                    subject: subject, date: date, description: description,
                    targetUserId: targetUserId, targetUserName: targetUserName,
                    status: status, responses: responses, createdAt: createdAt)
    }

    static func makeResponse(
        id: String = "resp-1",
        authorId: String = "user-2",
        authorName: String = "Helper User",
        photoURLs: [String] = ["https://example.com/resp1.jpg"],
        createdAt: Date = referenceDate
    ) -> RequestResponse {
        RequestResponse(id: id, authorId: authorId, authorName: authorName,
                       photoURLs: photoURLs, createdAt: createdAt)
    }
}
