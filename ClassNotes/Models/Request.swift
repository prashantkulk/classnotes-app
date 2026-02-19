import Foundation

struct NoteRequest: Identifiable, Codable, Equatable {
    var id: String
    var groupId: String
    var authorId: String
    var authorName: String
    var subject: Subject
    var date: Date
    var description: String
    var targetUserId: String?    // nil = whole group request
    var targetUserName: String?  // display name of targeted person
    var status: RequestStatus
    var responses: [RequestResponse]
    var createdAt: Date

    init(id: String = UUID().uuidString, groupId: String, authorId: String, authorName: String, subject: Subject, date: Date, description: String = "", targetUserId: String? = nil, targetUserName: String? = nil, status: RequestStatus = .open, responses: [RequestResponse] = [], createdAt: Date = Date()) {
        self.id = id
        self.groupId = groupId
        self.authorId = authorId
        self.authorName = authorName
        self.subject = subject
        self.date = date
        self.description = description
        self.targetUserId = targetUserId
        self.targetUserName = targetUserName
        self.status = status
        self.responses = responses
        self.createdAt = createdAt
    }
}

struct RequestResponse: Identifiable, Codable, Equatable {
    var id: String
    var authorId: String
    var authorName: String
    var photoURLs: [String]
    var createdAt: Date

    init(id: String = UUID().uuidString, authorId: String, authorName: String, photoURLs: [String], createdAt: Date = Date()) {
        self.id = id
        self.authorId = authorId
        self.authorName = authorName
        self.photoURLs = photoURLs
        self.createdAt = createdAt
    }
}

enum RequestStatus: String, Codable {
    case open
    case fulfilled
}
