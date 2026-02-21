import Foundation

struct ClassGroup: Identifiable, Codable {
    var id: String
    var name: String
    var school: String
    var inviteCode: String
    var members: [String]
    var createdBy: String
    var createdAt: Date
    var customSubjects: [[String: String]]

    init(id: String = UUID().uuidString, name: String, school: String, inviteCode: String = "", members: [String] = [], createdBy: String, createdAt: Date = Date(), customSubjects: [[String: String]] = []) {
        self.id = id
        self.name = name
        self.school = school
        self.inviteCode = inviteCode.isEmpty ? ClassGroup.generateInviteCode() : inviteCode
        self.members = members
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.customSubjects = customSubjects
    }

    // Custom Decodable to default customSubjects to [] when missing from JSON
    enum CodingKeys: String, CodingKey {
        case id, name, school, inviteCode, members, createdBy, createdAt, customSubjects
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        school = try container.decode(String.self, forKey: .school)
        inviteCode = try container.decode(String.self, forKey: .inviteCode)
        members = try container.decode([String].self, forKey: .members)
        createdBy = try container.decode(String.self, forKey: .createdBy)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        customSubjects = try container.decodeIfPresent([[String: String]].self, forKey: .customSubjects) ?? []
    }

    static func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }

    // Parsed custom SubjectInfo objects
    var customSubjectInfos: [SubjectInfo] {
        customSubjects.compactMap { dict in
            guard let name = dict["name"],
                  let color = dict["color"],
                  let icon = dict["icon"] else { return nil }
            return SubjectInfo(name: name, colorName: color, icon: icon)
        }
    }

    // All subjects (built-in + custom) for this group
    var allSubjects: [SubjectInfo] {
        SubjectInfo.builtInSubjects + customSubjectInfos
    }
}
