import Foundation

struct AppUser: Identifiable, Codable {
    var id: String
    var phone: String
    var name: String
    var groups: [String]
    var fcmToken: String?   // for push notifications
    var createdAt: Date

    init(id: String, phone: String, name: String = "", groups: [String] = [], fcmToken: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.phone = phone
        self.name = name
        self.groups = groups
        self.fcmToken = fcmToken
        self.createdAt = createdAt
    }
}
