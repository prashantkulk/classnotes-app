import XCTest
@testable import ClassNotes

final class PostTests: XCTestCase {

    // MARK: - Initialization

    func test_init_withAllParameters_setsAllProperties() {
        let date = Date()
        let post = Post(id: "p1", groupId: "g1", authorId: "u1", authorName: "Mom",
                        subject: .math, date: date, description: "Ch. 5",
                        photoURLs: ["url1", "url2"], createdAt: date)

        XCTAssertEqual(post.id, "p1")
        XCTAssertEqual(post.groupId, "g1")
        XCTAssertEqual(post.authorId, "u1")
        XCTAssertEqual(post.authorName, "Mom")
        XCTAssertEqual(post.subject, .math)
        XCTAssertEqual(post.date, date)
        XCTAssertEqual(post.description, "Ch. 5")
        XCTAssertEqual(post.photoURLs, ["url1", "url2"])
        XCTAssertTrue(post.comments.isEmpty)
        XCTAssertTrue(post.reactions.isEmpty)
    }

    func test_init_withDefaults_hasEmptyDescriptionAndPhotos() {
        let post = Post(groupId: "g1", authorId: "u1", authorName: "Mom",
                        subject: .science, date: Date())

        XCTAssertEqual(post.description, "")
        XCTAssertEqual(post.photoURLs, [])
        XCTAssertTrue(post.comments.isEmpty)
        XCTAssertTrue(post.reactions.isEmpty)
        XCTAssertFalse(post.id.isEmpty)
    }

    func test_init_defaultCreatedAt_isApproximatelyNow() {
        let before = Date()
        let post = Post(groupId: "g1", authorId: "u1", authorName: "Mom",
                        subject: .math, date: Date())
        let after = Date()

        XCTAssertGreaterThanOrEqual(post.createdAt, before)
        XCTAssertLessThanOrEqual(post.createdAt, after)
    }

    // MARK: - Codable Round-Trip

    func test_codable_roundTrip_preservesAllFields() throws {
        let original = TestFixtures.makePost()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Post.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.groupId, original.groupId)
        XCTAssertEqual(decoded.authorId, original.authorId)
        XCTAssertEqual(decoded.authorName, original.authorName)
        XCTAssertEqual(decoded.subject, original.subject)
        XCTAssertEqual(decoded.description, original.description)
        XCTAssertEqual(decoded.photoURLs, original.photoURLs)
    }

    func test_codable_roundTrip_withEmptyPhotoURLs() throws {
        let original = TestFixtures.makePost(photoURLs: [])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Post.self, from: data)
        XCTAssertEqual(decoded.photoURLs, [])
    }

    func test_codable_roundTrip_withMultiplePhotoURLs() throws {
        let urls = ["url1", "url2", "url3", "url4", "url5"]
        let original = TestFixtures.makePost(photoURLs: urls)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Post.self, from: data)
        XCTAssertEqual(decoded.photoURLs, urls)
    }

    // MARK: - Codable with All Subject Variants

    func test_codable_roundTrip_withMathSubject() throws {
        try assertSubjectCodableRoundTrip(.math)
    }

    func test_codable_roundTrip_withScienceSubject() throws {
        try assertSubjectCodableRoundTrip(.science)
    }

    func test_codable_roundTrip_withEnglishSubject() throws {
        try assertSubjectCodableRoundTrip(.english)
    }

    func test_codable_roundTrip_withHindiSubject() throws {
        try assertSubjectCodableRoundTrip(.hindi)
    }

    func test_codable_roundTrip_withSocialStudiesSubject() throws {
        try assertSubjectCodableRoundTrip(.socialStudies)
    }

    func test_codable_roundTrip_withOtherSubject() throws {
        try assertSubjectCodableRoundTrip(.other)
    }

    private func assertSubjectCodableRoundTrip(_ subject: Subject) throws {
        let original = TestFixtures.makePost(subject: subject)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Post.self, from: data)
        XCTAssertEqual(decoded.subject, subject)
    }

    // MARK: - Codable Decoding

    func test_decodable_fromJSON_customSubject_decodesWithNilSubjectEnum() throws {
        let json = """
        {
            "id": "p1", "groupId": "g1", "authorId": "u1", "authorName": "Mom",
            "subjectName": "Computer", "date": 1700000000,
            "description": "", "photoURLs": [], "createdAt": 1700000000
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Post.self, from: json)
        XCTAssertEqual(decoded.subjectName, "Computer")
        XCTAssertNil(decoded.subject)
        XCTAssertTrue(decoded.comments.isEmpty)
        XCTAssertTrue(decoded.reactions.isEmpty)
    }

    func test_decodable_fromJSON_missingCommentsAndReactions_defaultsToEmpty() throws {
        let json = """
        {
            "id": "p2", "groupId": "g1", "authorId": "u1", "authorName": "Mom",
            "subjectName": "Math", "date": 1700000000,
            "description": "Test", "photoURLs": ["url1"], "createdAt": 1700000000
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(Post.self, from: json)
        XCTAssertTrue(decoded.comments.isEmpty)
        XCTAssertTrue(decoded.reactions.isEmpty)
    }

    // MARK: - Edge Cases

    func test_init_withEmptyGroupId() {
        let post = Post(groupId: "", authorId: "u1", authorName: "Mom",
                        subject: .math, date: Date())
        XCTAssertEqual(post.groupId, "")
    }

    func test_init_withLongDescription() {
        let desc = String(repeating: "Notes ", count: 500)
        let post = Post(groupId: "g1", authorId: "u1", authorName: "Mom",
                        subject: .math, date: Date(), description: desc)
        XCTAssertEqual(post.description, desc)
    }

    func test_init_withManyPhotoURLs() {
        let urls = (0..<50).map { "https://example.com/photo\($0).jpg" }
        let post = Post(groupId: "g1", authorId: "u1", authorName: "Mom",
                        subject: .math, date: Date(), photoURLs: urls)
        XCTAssertEqual(post.photoURLs.count, 50)
    }

    // MARK: - Value Semantics

    func test_copy_isIndependent() {
        var original = TestFixtures.makePost()
        var copy = original
        copy.description = "Modified"

        XCTAssertEqual(original.description, "Chapter 5 notes")
        XCTAssertEqual(copy.description, "Modified")
    }
}
