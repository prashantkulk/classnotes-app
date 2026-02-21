import Foundation

struct NoteRequest: Identifiable, Codable, Equatable {
    var id: String
    var groupId: String
    var authorId: String
    var authorName: String
    var subjectName: String
    var date: Date
    var description: String
    var targetUserId: String?    // nil = whole group request
    var targetUserName: String?  // display name of targeted person
    var status: RequestStatus
    var responses: [RequestResponse]
    var createdAt: Date

    // Convenience: built-in Subject if applicable
    var subject: Subject? {
        Subject(rawValue: subjectName)
    }

    // Get SubjectInfo using group context
    func subjectInfo(for group: ClassGroup) -> SubjectInfo {
        SubjectInfo.find(name: subjectName, in: group.customSubjectInfos)
            ?? SubjectInfo(name: subjectName, colorName: "gray", icon: "doc.text")
    }

    init(id: String = UUID().uuidString, groupId: String, authorId: String, authorName: String, subjectName: String, date: Date, description: String = "", targetUserId: String? = nil, targetUserName: String? = nil, status: RequestStatus = .open, responses: [RequestResponse] = [], createdAt: Date = Date()) {
        self.id = id
        self.groupId = groupId
        self.authorId = authorId
        self.authorName = authorName
        self.subjectName = subjectName
        self.date = date
        self.description = description
        self.targetUserId = targetUserId
        self.targetUserName = targetUserName
        self.status = status
        self.responses = responses
        self.createdAt = createdAt
    }

    // Backward-compat convenience init that takes Subject enum
    init(id: String = UUID().uuidString, groupId: String, authorId: String, authorName: String, subject: Subject, date: Date, description: String = "", targetUserId: String? = nil, targetUserName: String? = nil, status: RequestStatus = .open, responses: [RequestResponse] = [], createdAt: Date = Date()) {
        self.init(id: id, groupId: groupId, authorId: authorId, authorName: authorName,
                  subjectName: subject.rawValue, date: date, description: description,
                  targetUserId: targetUserId, targetUserName: targetUserName,
                  status: status, responses: responses, createdAt: createdAt)
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
