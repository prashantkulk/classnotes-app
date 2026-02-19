import Foundation
import UIKit
@testable import ClassNotes

protocol RequestServiceProtocol: AnyObject {
    var requests: [NoteRequest] { get set }

    func loadRequests(for groupId: String)
    func createRequest(
        groupId: String,
        authorId: String,
        authorName: String,
        subject: Subject,
        date: Date,
        description: String,
        targetUserId: String?,
        targetUserName: String?,
        completion: @escaping (Result<NoteRequest, Error>) -> Void
    )
    func respondToRequest(
        requestId: String,
        authorId: String,
        authorName: String,
        images: [UIImage],
        completion: @escaping (Result<Void, Error>) -> Void
    )
    func markAsFulfilled(requestId: String)
}
