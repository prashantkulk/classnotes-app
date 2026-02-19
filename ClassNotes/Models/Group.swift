import Foundation

struct ClassGroup: Identifiable, Codable {
    var id: String
    var name: String
    var school: String
    var inviteCode: String
    var members: [String]
    var createdBy: String
    var createdAt: Date

    init(id: String = UUID().uuidString, name: String, school: String, inviteCode: String = "", members: [String] = [], createdBy: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.school = school
        self.inviteCode = inviteCode.isEmpty ? ClassGroup.generateInviteCode() : inviteCode
        self.members = members
        self.createdBy = createdBy
        self.createdAt = createdAt
    }

    static func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }
}
