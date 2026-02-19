import Foundation
@testable import ClassNotes

class MockGroupService: GroupServiceProtocol {
    var groups: [ClassGroup] = []

    var createGroupResult: Result<ClassGroup, Error> = .failure(NSError(domain: "test", code: -1))
    var joinGroupResult: Result<ClassGroup, Error> = .failure(NSError(domain: "test", code: -1))

    var loadGroupsCallCount = 0
    var loadGroupsLastUserId: String?
    var createGroupCallCount = 0
    var createGroupLastGroup: ClassGroup?
    var joinGroupCallCount = 0
    var joinGroupLastCode: String?
    var joinGroupLastUserId: String?

    func loadGroups(for userId: String) {
        loadGroupsCallCount += 1
        loadGroupsLastUserId = userId
    }

    func createGroup(_ group: ClassGroup, completion: @escaping (Result<ClassGroup, Error>) -> Void) {
        createGroupCallCount += 1
        createGroupLastGroup = group
        completion(createGroupResult)
    }

    func joinGroup(code: String, userId: String, completion: @escaping (Result<ClassGroup, Error>) -> Void) {
        joinGroupCallCount += 1
        joinGroupLastCode = code
        joinGroupLastUserId = userId
        completion(joinGroupResult)
    }
}
