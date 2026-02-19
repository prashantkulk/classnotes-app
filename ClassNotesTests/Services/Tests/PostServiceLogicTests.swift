import XCTest
import UIKit
@testable import ClassNotes

final class PostServiceLogicTests: XCTestCase {

    var mockService: MockPostService!

    override func setUp() {
        super.setUp()
        mockService = MockPostService()
    }

    override func tearDown() {
        mockService = nil
        super.tearDown()
    }

    // MARK: - loadPosts

    func testLoadPosts_incrementsCallCount() {
        mockService.loadPosts(for: "group-1")
        mockService.loadPosts(for: "group-2")
        XCTAssertEqual(mockService.loadPostsCallCount, 2)
    }

    func testLoadPosts_capturesLastGroupId() {
        mockService.loadPosts(for: "group-A")
        mockService.loadPosts(for: "group-B")
        XCTAssertEqual(mockService.loadPostsLastGroupId, "group-B")
    }

    // MARK: - createPost success

    func testCreatePost_success_returnsPost() {
        let post = TestFixtures.makePost(subject: .math, description: "Algebra chapter 5")
        mockService.createPostResult = .success(post)

        let expectation = expectation(description: "createPost")
        var receivedPost: Post?

        mockService.createPost(
            groupId: "group-1",
            authorId: "user-1",
            authorName: "Test User",
            subject: .math,
            date: Date(),
            description: "Algebra chapter 5",
            images: []
        ) { result in
            if case .success(let p) = result {
                receivedPost = p
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedPost?.subject, .math)
        XCTAssertEqual(receivedPost?.description, "Algebra chapter 5")
        XCTAssertEqual(mockService.createPostCallCount, 1)
    }

    // MARK: - createPost failure

    func testCreatePost_failure_returnsError() {
        let testError = NSError(domain: "test", code: 500)
        mockService.createPostResult = .failure(testError)

        let expectation = expectation(description: "createPost")
        var receivedError: Error?

        mockService.createPost(
            groupId: "group-1",
            authorId: "user-1",
            authorName: "Test User",
            subject: .science,
            date: Date(),
            description: "Test",
            images: []
        ) { result in
            if case .failure(let error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual((receivedError as NSError?)?.code, 500)
    }

    // MARK: - Argument capture

    func testCreatePost_capturesArguments() {
        let post = TestFixtures.makePost()
        mockService.createPostResult = .success(post)

        let testImage = UIImage()
        let exp = expectation(description: "create")

        mockService.createPost(
            groupId: "group-42",
            authorId: "user-7",
            authorName: "Parent",
            subject: .hindi,
            date: Date(),
            description: "Hindi notes",
            images: [testImage]
        ) { _ in exp.fulfill() }

        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockService.createPostLastGroupId, "group-42")
        XCTAssertEqual(mockService.createPostLastSubject, .hindi)
        XCTAssertEqual(mockService.createPostLastImages?.count, 1)
    }

    // MARK: - posts property

    func testPosts_initiallyEmpty() {
        XCTAssertTrue(mockService.posts.isEmpty)
    }

    func testPosts_canBeSetDirectly() {
        let post1 = TestFixtures.makePost(id: "p-1", subject: .math)
        let post2 = TestFixtures.makePost(id: "p-2", subject: .science)
        mockService.posts = [post1, post2]

        XCTAssertEqual(mockService.posts.count, 2)
        XCTAssertEqual(mockService.posts[0].subject, .math)
        XCTAssertEqual(mockService.posts[1].subject, .science)
    }

    // MARK: - Subject rawValue mapping

    func testCreatePost_allSubjects_canBeUsed() {
        let post = TestFixtures.makePost()
        mockService.createPostResult = .success(post)

        for subject in Subject.allCases {
            let exp = expectation(description: "subject-\(subject.rawValue)")
            mockService.createPost(
                groupId: "group-1",
                authorId: "user-1",
                authorName: "Test",
                subject: subject,
                date: Date(),
                description: "",
                images: []
            ) { _ in exp.fulfill() }
            wait(for: [exp], timeout: 1.0)
            XCTAssertEqual(mockService.createPostLastSubject, subject)
        }
    }
}
