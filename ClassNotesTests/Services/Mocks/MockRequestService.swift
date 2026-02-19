import Foundation
import UIKit
@testable import ClassNotes

class MockRequestService: RequestServiceProtocol {
    var requests: [NoteRequest] = []

    // Configurable results
    var createRequestResult: Result<NoteRequest, Error> = .failure(NSError(domain: "test", code: -1))
    var respondToRequestResult: Result<Void, Error> = .success(())

    // Call tracking
    var loadRequestsCallCount = 0
    var loadRequestsLastGroupId: String?
    var createRequestCallCount = 0
    var createRequestLastGroupId: String?
    var createRequestLastSubject: Subject?
    var createRequestLastDescription: String?
    var createRequestLastTargetUserId: String?
    var createRequestLastTargetUserName: String?
    var respondToRequestCallCount = 0
    var respondToRequestLastRequestId: String?
    var respondToRequestLastAuthorId: String?
    var respondToRequestLastAuthorName: String?
    var respondToRequestLastImages: [UIImage]?
    var markAsFulfilledCallCount = 0
    var markAsFulfilledLastRequestId: String?

    func loadRequests(for groupId: String) {
        loadRequestsCallCount += 1
        loadRequestsLastGroupId = groupId
    }

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
    ) {
        createRequestCallCount += 1
        createRequestLastGroupId = groupId
        createRequestLastSubject = subject
        createRequestLastDescription = description
        createRequestLastTargetUserId = targetUserId
        createRequestLastTargetUserName = targetUserName
        completion(createRequestResult)
    }

    func respondToRequest(
        requestId: String,
        authorId: String,
        authorName: String,
        images: [UIImage],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        respondToRequestCallCount += 1
        respondToRequestLastRequestId = requestId
        respondToRequestLastAuthorId = authorId
        respondToRequestLastAuthorName = authorName
        respondToRequestLastImages = images
        completion(respondToRequestResult)
    }

    func markAsFulfilled(requestId: String) {
        markAsFulfilledCallCount += 1
        markAsFulfilledLastRequestId = requestId
    }
}
