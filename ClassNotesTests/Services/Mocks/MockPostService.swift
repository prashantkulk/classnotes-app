import Foundation
import UIKit
@testable import ClassNotes

class MockPostService: PostServiceProtocol {
    var posts: [Post] = []

    var createPostResult: Result<Post, Error> = .failure(NSError(domain: "test", code: -1))

    var loadPostsCallCount = 0
    var loadPostsLastGroupId: String?
    var createPostCallCount = 0
    var createPostLastGroupId: String?
    var createPostLastSubject: Subject?
    var createPostLastImages: [UIImage]?

    func loadPosts(for groupId: String) {
        loadPostsCallCount += 1
        loadPostsLastGroupId = groupId
    }

    func createPost(
        groupId: String,
        authorId: String,
        authorName: String,
        subject: Subject,
        date: Date,
        description: String,
        images: [UIImage],
        completion: @escaping (Result<Post, Error>) -> Void
    ) {
        createPostCallCount += 1
        createPostLastGroupId = groupId
        createPostLastSubject = subject
        createPostLastImages = images
        completion(createPostResult)
    }
}
