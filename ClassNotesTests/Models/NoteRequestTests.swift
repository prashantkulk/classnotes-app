import XCTest
@testable import ClassNotes

final class NoteRequestTests: XCTestCase {

    // MARK: - NoteRequest Initialization

    func test_init_withAllParameters_setsAllProperties() {
        let date = Date()
        let response = TestFixtures.makeResponse()
        let request = NoteRequest(id: "r1", groupId: "g1", authorId: "u1",
                                  authorName: "Dad", subject: .science, date: date,
                                  description: "Ch. 3", status: .fulfilled,
                                  responses: [response], createdAt: date)

        XCTAssertEqual(request.id, "r1")
        XCTAssertEqual(request.groupId, "g1")
        XCTAssertEqual(request.authorId, "u1")
        XCTAssertEqual(request.authorName, "Dad")
        XCTAssertEqual(request.subject, .science)
        XCTAssertEqual(request.description, "Ch. 3")
        XCTAssertEqual(request.status, .fulfilled)
        XCTAssertEqual(request.responses.count, 1)
    }

    func test_init_withDefaults_isOpenWithEmptyResponses() {
        let request = NoteRequest(groupId: "g1", authorId: "u1", authorName: "Dad",
                                  subject: .math, date: Date())

        XCTAssertEqual(request.status, .open)
        XCTAssertEqual(request.responses, [])
        XCTAssertEqual(request.description, "")
        XCTAssertFalse(request.id.isEmpty)
    }

    func test_init_defaultCreatedAt_isApproximatelyNow() {
        let before = Date()
        let request = NoteRequest(groupId: "g1", authorId: "u1", authorName: "Dad",
                                  subject: .math, date: Date())
        let after = Date()

        XCTAssertGreaterThanOrEqual(request.createdAt, before)
        XCTAssertLessThanOrEqual(request.createdAt, after)
    }

    // MARK: - NoteRequest Codable

    func test_codable_roundTrip_preservesAllFields() throws {
        let response = TestFixtures.makeResponse()
        let original = TestFixtures.makeRequest(status: .fulfilled, responses: [response])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NoteRequest.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.groupId, original.groupId)
        XCTAssertEqual(decoded.subject, original.subject)
        XCTAssertEqual(decoded.status, .fulfilled)
        XCTAssertEqual(decoded.responses.count, 1)
        XCTAssertEqual(decoded.responses[0].authorName, "Helper User")
    }

    func test_codable_roundTrip_withOpenStatus() throws {
        let original = TestFixtures.makeRequest(status: .open)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NoteRequest.self, from: data)
        XCTAssertEqual(decoded.status, .open)
    }

    func test_codable_roundTrip_withFulfilledStatus() throws {
        let original = TestFixtures.makeRequest(status: .fulfilled)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NoteRequest.self, from: data)
        XCTAssertEqual(decoded.status, .fulfilled)
    }

    func test_codable_roundTrip_withEmptyResponses() throws {
        let original = TestFixtures.makeRequest(responses: [])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NoteRequest.self, from: data)
        XCTAssertEqual(decoded.responses, [])
    }

    func test_codable_roundTrip_withMultipleResponses() throws {
        let responses = [
            TestFixtures.makeResponse(id: "r1", authorName: "User A"),
            TestFixtures.makeResponse(id: "r2", authorName: "User B"),
            TestFixtures.makeResponse(id: "r3", authorName: "User C"),
        ]
        let original = TestFixtures.makeRequest(responses: responses)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NoteRequest.self, from: data)
        XCTAssertEqual(decoded.responses.count, 3)
        XCTAssertEqual(decoded.responses[0].authorName, "User A")
        XCTAssertEqual(decoded.responses[2].authorName, "User C")
    }

    // MARK: - Targeted Request Fields

    func test_init_withDefaults_hasNilTarget() {
        let request = NoteRequest(groupId: "g1", authorId: "u1", authorName: "Dad",
                                  subject: .math, date: Date())
        XCTAssertNil(request.targetUserId)
        XCTAssertNil(request.targetUserName)
    }

    func test_init_withTargetUser_setsTargetFields() {
        let request = NoteRequest(groupId: "g1", authorId: "u1", authorName: "Dad",
                                  subject: .hindi, date: Date(),
                                  targetUserId: "u2", targetUserName: "Priya's Mom")
        XCTAssertEqual(request.targetUserId, "u2")
        XCTAssertEqual(request.targetUserName, "Priya's Mom")
    }

    func test_codable_roundTrip_withTargetFields() throws {
        let original = TestFixtures.makeRequest(targetUserId: "u3", targetUserName: "Rahul's Dad")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NoteRequest.self, from: data)
        XCTAssertEqual(decoded.targetUserId, "u3")
        XCTAssertEqual(decoded.targetUserName, "Rahul's Dad")
    }

    func test_codable_roundTrip_withNilTarget() throws {
        let original = TestFixtures.makeRequest(targetUserId: nil, targetUserName: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NoteRequest.self, from: data)
        XCTAssertNil(decoded.targetUserId)
        XCTAssertNil(decoded.targetUserName)
    }

    func test_equatable_withSameTarget_isEqual() {
        let r1 = TestFixtures.makeRequest(targetUserId: "u2", targetUserName: "Mom")
        let r2 = TestFixtures.makeRequest(targetUserId: "u2", targetUserName: "Mom")
        XCTAssertEqual(r1, r2)
    }

    func test_equatable_withDifferentTarget_isNotEqual() {
        let r1 = TestFixtures.makeRequest(targetUserId: "u2", targetUserName: "Mom")
        let r2 = TestFixtures.makeRequest(targetUserId: "u3", targetUserName: "Dad")
        XCTAssertNotEqual(r1, r2)
    }

    // MARK: - NoteRequest Edge Cases

    func test_init_withEmptyDescription() {
        let request = TestFixtures.makeRequest(description: "")
        XCTAssertEqual(request.description, "")
    }

    func test_init_withLongDescription() {
        let desc = String(repeating: "Need notes ", count: 200)
        let request = TestFixtures.makeRequest(description: desc)
        XCTAssertEqual(request.description, desc)
    }

    // MARK: - NoteRequest Value Semantics

    func test_copy_isIndependent() {
        let original = TestFixtures.makeRequest()
        var copy = original
        copy.status = .fulfilled

        XCTAssertEqual(original.status, .open)
        XCTAssertEqual(copy.status, .fulfilled)
    }

    func test_mutatingResponses_doesNotAffectOriginal() {
        let original = TestFixtures.makeRequest(responses: [])
        var copy = original
        copy.responses.append(TestFixtures.makeResponse())

        XCTAssertEqual(original.responses.count, 0)
        XCTAssertEqual(copy.responses.count, 1)
    }

    // MARK: - RequestResponse Initialization

    func test_response_init_withAllParameters() {
        let date = Date()
        let response = RequestResponse(id: "rsp1", authorId: "u2", authorName: "Helper",
                                       photoURLs: ["url1", "url2"], createdAt: date)

        XCTAssertEqual(response.id, "rsp1")
        XCTAssertEqual(response.authorId, "u2")
        XCTAssertEqual(response.authorName, "Helper")
        XCTAssertEqual(response.photoURLs, ["url1", "url2"])
        XCTAssertEqual(response.createdAt, date)
    }

    func test_response_init_withDefaults_generatesUUID() {
        let response = RequestResponse(authorId: "u2", authorName: "Helper", photoURLs: [])
        XCTAssertFalse(response.id.isEmpty)
    }

    func test_response_init_defaultCreatedAt_isApproximatelyNow() {
        let before = Date()
        let response = RequestResponse(authorId: "u2", authorName: "Helper", photoURLs: [])
        let after = Date()

        XCTAssertGreaterThanOrEqual(response.createdAt, before)
        XCTAssertLessThanOrEqual(response.createdAt, after)
    }

    // MARK: - RequestResponse Codable

    func test_response_codable_roundTrip_preservesAllFields() throws {
        let original = TestFixtures.makeResponse(photoURLs: ["url1", "url2"])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RequestResponse.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.authorId, original.authorId)
        XCTAssertEqual(decoded.authorName, original.authorName)
        XCTAssertEqual(decoded.photoURLs, original.photoURLs)
    }

    func test_response_codable_roundTrip_withEmptyPhotoURLs() throws {
        let original = TestFixtures.makeResponse(photoURLs: [])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RequestResponse.self, from: data)
        XCTAssertEqual(decoded.photoURLs, [])
    }

    // MARK: - RequestStatus

    func test_requestStatus_open_rawValue() {
        XCTAssertEqual(RequestStatus.open.rawValue, "open")
    }

    func test_requestStatus_fulfilled_rawValue() {
        XCTAssertEqual(RequestStatus.fulfilled.rawValue, "fulfilled")
    }

    func test_requestStatus_codable_open_roundTrip() throws {
        let data = try JSONEncoder().encode(RequestStatus.open)
        let decoded = try JSONDecoder().decode(RequestStatus.self, from: data)
        XCTAssertEqual(decoded, .open)
    }

    func test_requestStatus_codable_fulfilled_roundTrip() throws {
        let data = try JSONEncoder().encode(RequestStatus.fulfilled)
        let decoded = try JSONDecoder().decode(RequestStatus.self, from: data)
        XCTAssertEqual(decoded, .fulfilled)
    }

    func test_requestStatus_decodable_invalidValue_throwsError() {
        let json = "\"pending\"".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(RequestStatus.self, from: json))
    }
}
