import Foundation
@testable import ClassNotes

protocol GroupServiceProtocol: AnyObject {
    var groups: [ClassGroup] { get set }

    func loadGroups(for userId: String)
    func createGroup(_ group: ClassGroup, completion: @escaping (Result<ClassGroup, Error>) -> Void)
    func joinGroup(code: String, userId: String, completion: @escaping (Result<ClassGroup, Error>) -> Void)
}
