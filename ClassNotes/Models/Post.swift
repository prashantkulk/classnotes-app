import Foundation

struct PostComment: Identifiable, Codable, Equatable {
    var id: String
    var authorId: String
    var authorName: String
    var text: String
    var createdAt: Date

    init(id: String = UUID().uuidString, authorId: String, authorName: String, text: String, createdAt: Date = Date()) {
        self.id = id
        self.authorId = authorId
        self.authorName = authorName
        self.text = text
        self.createdAt = createdAt
    }
}

struct PostReaction: Codable, Equatable {
    var emoji: String
    var userIds: [String]
}

struct Post: Identifiable, Codable {
    var id: String
    var groupId: String
    var authorId: String
    var authorName: String
    var subjectName: String
    var date: Date
    var description: String
    var photoURLs: [String]
    var comments: [PostComment]
    var reactions: [PostReaction]
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

    init(id: String = UUID().uuidString, groupId: String, authorId: String, authorName: String, subjectName: String, date: Date, description: String = "", photoURLs: [String] = [], comments: [PostComment] = [], reactions: [PostReaction] = [], createdAt: Date = Date()) {
        self.id = id
        self.groupId = groupId
        self.authorId = authorId
        self.authorName = authorName
        self.subjectName = subjectName
        self.date = date
        self.description = description
        self.photoURLs = photoURLs
        self.comments = comments
        self.reactions = reactions
        self.createdAt = createdAt
    }

    // Custom Decodable to default comments and reactions to [] when missing from JSON
    enum CodingKeys: String, CodingKey {
        case id, groupId, authorId, authorName, subjectName, date, description, photoURLs, comments, reactions, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        groupId = try container.decode(String.self, forKey: .groupId)
        authorId = try container.decode(String.self, forKey: .authorId)
        authorName = try container.decode(String.self, forKey: .authorName)
        subjectName = try container.decode(String.self, forKey: .subjectName)
        date = try container.decode(Date.self, forKey: .date)
        description = try container.decode(String.self, forKey: .description)
        photoURLs = try container.decode([String].self, forKey: .photoURLs)
        comments = try container.decodeIfPresent([PostComment].self, forKey: .comments) ?? []
        reactions = try container.decodeIfPresent([PostReaction].self, forKey: .reactions) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    // Backward-compat convenience init that takes Subject enum
    init(id: String = UUID().uuidString, groupId: String, authorId: String, authorName: String, subject: Subject, date: Date, description: String = "", photoURLs: [String] = [], comments: [PostComment] = [], reactions: [PostReaction] = [], createdAt: Date = Date()) {
        self.init(id: id, groupId: groupId, authorId: authorId, authorName: authorName,
                  subjectName: subject.rawValue, date: date, description: description,
                  photoURLs: photoURLs, comments: comments, reactions: reactions, createdAt: createdAt)
    }
}
