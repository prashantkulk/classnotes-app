import XCTest
@testable import ClassNotes

final class AppUserTests: XCTestCase {

    // MARK: - Initialization

    func test_init_withAllParameters_setsAllProperties() {
        let date = Date()
        let user = AppUser(id: "u1", phone: "+91123", name: "Priya's Mom", groups: ["g1", "g2"], createdAt: date)

        XCTAssertEqual(user.id, "u1")
        XCTAssertEqual(user.phone, "+91123")
        XCTAssertEqual(user.name, "Priya's Mom")
        XCTAssertEqual(user.groups, ["g1", "g2"])
        XCTAssertEqual(user.createdAt, date)
    }

    func test_init_withDefaults_usesEmptyNameAndEmptyGroups() {
        let user = AppUser(id: "u1", phone: "+91123")

        XCTAssertEqual(user.name, "")
        XCTAssertEqual(user.groups, [])
    }

    func test_init_defaultCreatedAt_isApproximatelyNow() {
        let before = Date()
        let user = AppUser(id: "u1", phone: "+91123")
        let after = Date()

        XCTAssertGreaterThanOrEqual(user.createdAt, before)
        XCTAssertLessThanOrEqual(user.createdAt, after)
    }

    // MARK: - Identifiable

    func test_identifiable_idMatchesAssignedId() {
        let user = AppUser(id: "custom-id-123", phone: "+91123")
        XCTAssertEqual(user.id, "custom-id-123")
    }

    // MARK: - Codable Round-Trip

    func test_codable_roundTrip_preservesAllFields() throws {
        let original = TestFixtures.makeUser(groups: ["g1", "g2"])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppUser.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.phone, original.phone)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.groups, original.groups)
        XCTAssertEqual(decoded.createdAt.timeIntervalSince1970,
                       original.createdAt.timeIntervalSince1970, accuracy: 0.001)
    }

    func test_codable_roundTrip_withEmptyGroups() throws {
        let original = TestFixtures.makeUser(groups: [])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppUser.self, from: data)

        XCTAssertEqual(decoded.groups, [])
    }

    func test_codable_roundTrip_withMultipleGroups() throws {
        let groups = ["g1", "g2", "g3", "g4", "g5"]
        let original = TestFixtures.makeUser(groups: groups)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppUser.self, from: data)

        XCTAssertEqual(decoded.groups, groups)
    }

    // MARK: - Codable Decoding from JSON

    func test_decodable_fromValidJSON_succeeds() throws {
        let json = """
        {
            "id": "u1",
            "phone": "+919876543210",
            "name": "Test",
            "groups": ["g1"],
            "createdAt": 1700000000
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AppUser.self, from: json)
        XCTAssertEqual(decoded.id, "u1")
        XCTAssertEqual(decoded.phone, "+919876543210")
        XCTAssertEqual(decoded.name, "Test")
        XCTAssertEqual(decoded.groups, ["g1"])
    }

    func test_decodable_fromJSON_withExtraFields_succeeds() throws {
        let json = """
        {
            "id": "u1",
            "phone": "+91123",
            "name": "Test",
            "groups": [],
            "createdAt": 1700000000,
            "extraField": "should be ignored"
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(AppUser.self, from: json)
        XCTAssertEqual(decoded.id, "u1")
    }

    func test_decodable_fromJSON_missingRequiredField_throwsError() {
        let json = """
        {
            "id": "u1",
            "phone": "+91123"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(AppUser.self, from: json))
    }

    func test_decodable_fromJSON_wrongTypes_throwsError() {
        let json = """
        {
            "id": 123,
            "phone": "+91123",
            "name": "Test",
            "groups": [],
            "createdAt": 1700000000
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(AppUser.self, from: json))
    }

    // MARK: - FCM Token

    func test_init_withDefaults_hasNilFCMToken() {
        let user = AppUser(id: "u1", phone: "+91123")
        XCTAssertNil(user.fcmToken)
    }

    func test_init_withFCMToken_setsToken() {
        let user = AppUser(id: "u1", phone: "+91123", fcmToken: "token-abc-123")
        XCTAssertEqual(user.fcmToken, "token-abc-123")
    }

    func test_codable_roundTrip_withFCMToken() throws {
        let original = TestFixtures.makeUser(fcmToken: "fcm-token-xyz")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppUser.self, from: data)
        XCTAssertEqual(decoded.fcmToken, "fcm-token-xyz")
    }

    func test_codable_roundTrip_withNilFCMToken() throws {
        let original = TestFixtures.makeUser(fcmToken: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppUser.self, from: data)
        XCTAssertNil(decoded.fcmToken)
    }

    // MARK: - Edge Cases

    func test_init_withEmptyStringId() {
        let user = AppUser(id: "", phone: "+91123")
        XCTAssertEqual(user.id, "")
    }

    func test_init_withEmptyPhone() {
        let user = AppUser(id: "u1", phone: "")
        XCTAssertEqual(user.phone, "")
    }

    func test_init_withVeryLongName() {
        let longName = String(repeating: "A", count: 1000)
        let user = AppUser(id: "u1", phone: "+91123", name: longName)
        XCTAssertEqual(user.name.count, 1000)
    }

    func test_init_withSpecialCharactersInName() {
        let name = "Priya's Mom 🇮🇳 (Class 5B)"
        let user = AppUser(id: "u1", phone: "+91123", name: name)
        XCTAssertEqual(user.name, name)
    }

    // MARK: - Value Semantics

    func test_copy_isIndependent() {
        var original = TestFixtures.makeUser()
        var copy = original
        copy.name = "Modified Name"

        XCTAssertNotEqual(original.name, copy.name)
        XCTAssertEqual(original.name, "Test User")
    }
}
