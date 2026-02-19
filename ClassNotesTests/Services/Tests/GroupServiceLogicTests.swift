import XCTest
@testable import ClassNotes

final class GroupServiceLogicTests: XCTestCase {

    var mockService: MockGroupService!

    override func setUp() {
        super.setUp()
        mockService = MockGroupService()
    }

    override func tearDown() {
        mockService = nil
        super.tearDown()
    }

    // MARK: - loadGroups

    func testLoadGroups_incrementsCallCount() {
        mockService.loadGroups(for: "user-1")
        mockService.loadGroups(for: "user-2")
        XCTAssertEqual(mockService.loadGroupsCallCount, 2)
    }

    func testLoadGroups_capturesLastUserId() {
        mockService.loadGroups(for: "user-1")
        mockService.loadGroups(for: "user-2")
        XCTAssertEqual(mockService.loadGroupsLastUserId, "user-2")
    }

    // MARK: - createGroup

    func testCreateGroup_success_returnsGroup() {
        let group = TestFixtures.makeGroup(name: "Class 5B", createdBy: "user-1")
        mockService.createGroupResult = .success(group)

        let expectation = expectation(description: "createGroup")
        var receivedGroup: ClassGroup?

        mockService.createGroup(group) { result in
            if case .success(let g) = result {
                receivedGroup = g
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedGroup?.name, "Class 5B")
        XCTAssertEqual(mockService.createGroupCallCount, 1)
        XCTAssertEqual(mockService.createGroupLastGroup?.name, "Class 5B")
    }

    func testCreateGroup_failure_returnsError() {
        let testError = NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        mockService.createGroupResult = .failure(testError)

        let group = TestFixtures.makeGroup()
        let expectation = expectation(description: "createGroup")
        var receivedError: Error?

        mockService.createGroup(group) { result in
            if case .failure(let error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual((receivedError as NSError?)?.code, 500)
    }

    func testCreateGroup_capturesGroupArgument() {
        let group = TestFixtures.makeGroup(id: "g-99", name: "Class 9C", school: "ABC School")
        mockService.createGroupResult = .success(group)

        let exp = expectation(description: "create")
        mockService.createGroup(group) { _ in exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockService.createGroupLastGroup?.id, "g-99")
        XCTAssertEqual(mockService.createGroupLastGroup?.school, "ABC School")
    }

    // MARK: - joinGroup

    func testJoinGroup_success_returnsGroup() {
        let group = TestFixtures.makeGroup(inviteCode: "XYZ789")
        mockService.joinGroupResult = .success(group)

        let expectation = expectation(description: "joinGroup")
        var receivedGroup: ClassGroup?

        mockService.joinGroup(code: "XYZ789", userId: "user-2") { result in
            if case .success(let g) = result {
                receivedGroup = g
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedGroup?.inviteCode, "XYZ789")
        XCTAssertEqual(mockService.joinGroupCallCount, 1)
        XCTAssertEqual(mockService.joinGroupLastCode, "XYZ789")
        XCTAssertEqual(mockService.joinGroupLastUserId, "user-2")
    }

    func testJoinGroup_failure_returnsError() {
        let testError = NSError(domain: "test", code: 404, userInfo: [NSLocalizedDescriptionKey: "Group not found"])
        mockService.joinGroupResult = .failure(testError)

        let expectation = expectation(description: "joinGroup")
        var receivedError: Error?

        mockService.joinGroup(code: "BADCODE", userId: "user-1") { result in
            if case .failure(let error) = result {
                receivedError = error
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual((receivedError as NSError?)?.code, 404)
    }

    func testJoinGroup_capturesArguments() {
        mockService.joinGroupResult = .success(TestFixtures.makeGroup())

        let exp = expectation(description: "join")
        mockService.joinGroup(code: "ABC123", userId: "user-5") { _ in exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockService.joinGroupLastCode, "ABC123")
        XCTAssertEqual(mockService.joinGroupLastUserId, "user-5")
    }

    // MARK: - groups property

    func testGroups_initiallyEmpty() {
        XCTAssertTrue(mockService.groups.isEmpty)
    }

    func testGroups_canBeSetDirectly() {
        let group1 = TestFixtures.makeGroup(id: "g-1", name: "Class 1A")
        let group2 = TestFixtures.makeGroup(id: "g-2", name: "Class 2B")
        mockService.groups = [group1, group2]

        XCTAssertEqual(mockService.groups.count, 2)
        XCTAssertEqual(mockService.groups[0].name, "Class 1A")
        XCTAssertEqual(mockService.groups[1].name, "Class 2B")
    }
}
