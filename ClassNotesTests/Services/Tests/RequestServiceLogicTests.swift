import XCTest
import UIKit
@testable import ClassNotes

final class RequestServiceLogicTests: XCTestCase {

    var mockService: MockRequestService!

    override func setUp() {
        super.setUp()
        mockService = MockRequestService()
    }

    override func tearDown() {
        mockService = nil
        super.tearDown()
    }

    // MARK: - loadRequests

    func testLoadRequests_incrementsCallCount() {
        mockService.loadRequests(for: "group-1")
        mockService.loadRequests(for: "group-2")
        XCTAssertEqual(mockService.loadRequestsCallCount, 2)
    }

    func testLoadRequests_capturesLastGroupId() {
        mockService.loadRequests(for: "group-A")
        XCTAssertEqual(mockService.loadRequestsLastGroupId, "group-A")
    }

    // MARK: - createRequest

    func testCreateRequest_success_returnsRequest() {
        let request = TestFixtures.makeRequest(subject: .science, description: "Need ch3 notes")
        mockService.createRequestResult = .success(request)

        let expectation = expectation(description: "createRequest")
        var receivedRequest: NoteRequest?

        mockService.createRequest(
            groupId: "group-1",
            authorId: "user-1",
            authorName: "Test User",
            subjectName: Subject.science.rawValue,
            date: Date(),
            description: "Need ch3 notes",
            targetUserId: nil,
            targetUserName: nil
        ) { result in
            if case .success(let r) = result {
                receivedRequest = r
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedRequest?.subject, .science)
        XCTAssertEqual(receivedRequest?.description, "Need ch3 notes")
        XCTAssertEqual(mockService.createRequestCallCount, 1)
    }

    func testCreateRequest_failure_returnsError() {
        let testError = NSError(domain: "test", code: 503)
        mockService.createRequestResult = .failure(testError)

        let expectation = expectation(description: "createRequest")
        var receivedError: Error?

        mockService.createRequest(
            groupId: "group-1",
            authorId: "user-1",
            authorName: "Test",
            subjectName: Subject.math.rawValue,
            date: Date(),
            description: "",
            targetUserId: nil,
            targetUserName: nil
        ) { result in
            if case .failure(let error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual((receivedError as NSError?)?.code, 503)
    }

    func testCreateRequest_capturesArguments() {
        mockService.createRequestResult = .success(TestFixtures.makeRequest())

        let exp = expectation(description: "create")
        mockService.createRequest(
            groupId: "group-7",
            authorId: "user-3",
            authorName: "Parent",
            subjectName: Subject.english.rawValue,
            date: Date(),
            description: "Grammar exercises",
            targetUserId: nil,
            targetUserName: nil
        ) { _ in exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockService.createRequestLastGroupId, "group-7")
        XCTAssertEqual(mockService.createRequestLastSubjectName, Subject.english.rawValue)
        XCTAssertEqual(mockService.createRequestLastDescription, "Grammar exercises")
        XCTAssertNil(mockService.createRequestLastTargetUserId)
        XCTAssertNil(mockService.createRequestLastTargetUserName)
    }

    func testCreateRequest_withTarget_capturesTargetArguments() {
        mockService.createRequestResult = .success(TestFixtures.makeRequest())

        let exp = expectation(description: "create-targeted")
        mockService.createRequest(
            groupId: "group-1",
            authorId: "user-1",
            authorName: "Parent",
            subjectName: Subject.hindi.rawValue,
            date: Date(),
            description: "Need Hindi notes",
            targetUserId: "user-2",
            targetUserName: "Priya's Mom"
        ) { _ in exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockService.createRequestLastTargetUserId, "user-2")
        XCTAssertEqual(mockService.createRequestLastTargetUserName, "Priya's Mom")
        XCTAssertEqual(mockService.createRequestLastSubjectName, Subject.hindi.rawValue)
    }

    // MARK: - respondToRequest

    func testRespondToRequest_success_completesWithoutError() {
        mockService.respondToRequestResult = .success(())

        let testImage = UIImage()
        let expectation = expectation(description: "respond")

        mockService.respondToRequest(
            requestId: "req-1",
            authorId: "user-2",
            authorName: "Helper",
            images: [testImage]
        ) { result in
            switch result {
            case .success:
                break // Expected
            case .failure:
                XCTFail("Expected success")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockService.respondToRequestCallCount, 1)
        XCTAssertEqual(mockService.respondToRequestLastRequestId, "req-1")
        XCTAssertEqual(mockService.respondToRequestLastAuthorId, "user-2")
        XCTAssertEqual(mockService.respondToRequestLastAuthorName, "Helper")
        XCTAssertEqual(mockService.respondToRequestLastImages?.count, 1)
    }

    func testRespondToRequest_failure_returnsError() {
        let testError = NSError(domain: "storage", code: 413)
        mockService.respondToRequestResult = .failure(testError)

        let expectation = expectation(description: "respond")
        var receivedError: Error?

        mockService.respondToRequest(
            requestId: "req-1",
            authorId: "user-2",
            authorName: "Helper",
            images: []
        ) { result in
            if case .failure(let error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual((receivedError as NSError?)?.code, 413)
    }

    // MARK: - markAsFulfilled

    func testMarkAsFulfilled_incrementsCallCount() {
        mockService.markAsFulfilled(requestId: "req-1")
        mockService.markAsFulfilled(requestId: "req-2")
        XCTAssertEqual(mockService.markAsFulfilledCallCount, 2)
    }

    func testMarkAsFulfilled_capturesLastRequestId() {
        mockService.markAsFulfilled(requestId: "req-42")
        XCTAssertEqual(mockService.markAsFulfilledLastRequestId, "req-42")
    }

    // MARK: - requests property

    func testRequests_initiallyEmpty() {
        XCTAssertTrue(mockService.requests.isEmpty)
    }

    func testRequests_canBeSetDirectly() {
        let req1 = TestFixtures.makeRequest(id: "r-1", status: .open)
        let req2 = TestFixtures.makeRequest(id: "r-2", status: .fulfilled)
        mockService.requests = [req1, req2]

        XCTAssertEqual(mockService.requests.count, 2)
        XCTAssertEqual(mockService.requests[0].status, .open)
        XCTAssertEqual(mockService.requests[1].status, .fulfilled)
    }
}
