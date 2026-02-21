import XCTest
@testable import ClassNotes

final class ClassGroupTests: XCTestCase {

    // MARK: - Initialization

    func test_init_withAllParameters_setsAllProperties() {
        let date = Date()
        let group = ClassGroup(id: "g1", name: "Class 5B", school: "St. Mary's",
                               inviteCode: "XYZ789", members: ["u1", "u2"],
                               createdBy: "u1", createdAt: date)

        XCTAssertEqual(group.id, "g1")
        XCTAssertEqual(group.name, "Class 5B")
        XCTAssertEqual(group.school, "St. Mary's")
        XCTAssertEqual(group.inviteCode, "XYZ789")
        XCTAssertEqual(group.members, ["u1", "u2"])
        XCTAssertEqual(group.createdBy, "u1")
        XCTAssertEqual(group.createdAt, date)
    }

    func test_init_withEmptyInviteCode_autoGeneratesCode() {
        let group = ClassGroup(name: "Class 5B", school: "DPS", inviteCode: "", createdBy: "u1")
        XCTAssertEqual(group.inviteCode.count, 6)
        XCTAssertFalse(group.inviteCode.isEmpty)
    }

    func test_init_withNonEmptyInviteCode_usesProvidedCode() {
        let group = ClassGroup(name: "Class 5B", school: "DPS", inviteCode: "CUSTOM", createdBy: "u1")
        XCTAssertEqual(group.inviteCode, "CUSTOM")
    }

    func test_init_defaultMembers_isEmpty() {
        let group = ClassGroup(name: "Test", school: "School", createdBy: "u1")
        XCTAssertEqual(group.members, [])
    }

    func test_init_defaultCreatedAt_isApproximatelyNow() {
        let before = Date()
        let group = ClassGroup(name: "Test", school: "School", createdBy: "u1")
        let after = Date()

        XCTAssertGreaterThanOrEqual(group.createdAt, before)
        XCTAssertLessThanOrEqual(group.createdAt, after)
    }

    func test_init_defaultId_isNotEmpty() {
        let group = ClassGroup(name: "Test", school: "School", createdBy: "u1")
        XCTAssertFalse(group.id.isEmpty)
    }

    // MARK: - generateInviteCode

    func test_generateInviteCode_returnsExactlySixCharacters() {
        let code = ClassGroup.generateInviteCode()
        XCTAssertEqual(code.count, 6)
    }

    func test_generateInviteCode_containsOnlyAllowedCharacters() {
        let allowedSet = CharacterSet(charactersIn: "ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

        for _ in 0..<100 {
            let code = ClassGroup.generateInviteCode()
            let codeSet = CharacterSet(charactersIn: code)
            XCTAssertTrue(allowedSet.isSuperset(of: codeSet),
                          "Code '\(code)' contains disallowed characters")
        }
    }

    func test_generateInviteCode_excludesAmbiguousCharacters() {
        let ambiguous: [Character] = ["I", "O", "0", "1"]

        for _ in 0..<200 {
            let code = ClassGroup.generateInviteCode()
            for char in ambiguous {
                XCTAssertFalse(code.contains(char),
                               "Code '\(code)' contains ambiguous character '\(char)'")
            }
        }
    }

    func test_generateInviteCode_returnsDifferentValuesOnMultipleCalls() {
        let codes = (0..<50).map { _ in ClassGroup.generateInviteCode() }
        let uniqueCodes = Set(codes)
        // With 30 possible characters and 6 positions, collisions in 50 tries are extremely rare
        XCTAssertGreaterThan(uniqueCodes.count, 1,
                             "Expected different codes but all were identical")
    }

    // MARK: - Identifiable

    func test_identifiable_idMatchesAssignedId() {
        let group = ClassGroup(id: "custom-id", name: "Test", school: "School", createdBy: "u1")
        XCTAssertEqual(group.id, "custom-id")
    }

    // MARK: - Codable Round-Trip

    func test_codable_roundTrip_preservesAllFields() throws {
        let original = TestFixtures.makeGroup(members: ["u1", "u2", "u3"])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ClassGroup.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.school, original.school)
        XCTAssertEqual(decoded.inviteCode, original.inviteCode)
        XCTAssertEqual(decoded.members, original.members)
        XCTAssertEqual(decoded.createdBy, original.createdBy)
    }

    func test_codable_roundTrip_withEmptyMembers() throws {
        let original = TestFixtures.makeGroup(members: [])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ClassGroup.self, from: data)
        XCTAssertEqual(decoded.members, [])
    }

    func test_decodable_fromValidJSON_succeeds() throws {
        let json = """
        {
            "id": "g1", "name": "Class 5B", "school": "DPS",
            "inviteCode": "ABC123", "members": ["u1"],
            "createdBy": "u1", "createdAt": 1700000000
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(ClassGroup.self, from: json)
        XCTAssertEqual(decoded.id, "g1")
        XCTAssertEqual(decoded.name, "Class 5B")
    }

    func test_decodable_fromJSON_missingField_throwsError() {
        let json = """
        { "id": "g1", "name": "Class 5B" }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(ClassGroup.self, from: json))
    }

    // MARK: - Edge Cases

    func test_init_withEmptyName() {
        let group = ClassGroup(name: "", school: "DPS", createdBy: "u1")
        XCTAssertEqual(group.name, "")
    }

    func test_init_withEmptySchool() {
        let group = ClassGroup(name: "Class 5B", school: "", createdBy: "u1")
        XCTAssertEqual(group.school, "")
    }

    // MARK: - Value Semantics

    func test_copy_isIndependent() {
        var original = TestFixtures.makeGroup()
        var copy = original
        copy.name = "Modified"

        XCTAssertEqual(original.name, "Class 10A")
        XCTAssertEqual(copy.name, "Modified")
    }

    func test_mutatingMembers_doesNotAffectOriginal() {
        var original = TestFixtures.makeGroup(members: ["u1"])
        var copy = original
        copy.members.append("u2")

        XCTAssertEqual(original.members, ["u1"])
        XCTAssertEqual(copy.members, ["u1", "u2"])
    }
}
