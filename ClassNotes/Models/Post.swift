import Foundation

struct Post: Identifiable, Codable {
    var id: String
    var groupId: String
    var authorId: String
    var authorName: String
    var subject: Subject
    var date: Date
    var description: String
    var photoURLs: [String]
    var createdAt: Date

    init(id: String = UUID().uuidString, groupId: String, authorId: String, authorName: String, subject: Subject, date: Date, description: String = "", photoURLs: [String] = [], createdAt: Date = Date()) {
        self.id = id
        self.groupId = groupId
        self.authorId = authorId
        self.authorName = authorName
        self.subject = subject
        self.date = date
        self.description = description
        self.photoURLs = photoURLs
        self.createdAt = createdAt
    }
}
