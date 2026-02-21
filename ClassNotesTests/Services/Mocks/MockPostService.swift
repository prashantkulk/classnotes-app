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
    var createPostLastSubjectName: String?
    var createPostLastImages: [UIImage]?

    var deletePostResult: Result<Void, Error> = .success(())
    var deletePostCallCount = 0
    var deletePostLastId: String?

    var addCommentResult: Result<Void, Error> = .success(())
    var addCommentCallCount = 0
    var addCommentLastPostId: String?
    var addCommentLastText: String?

    var toggleReactionResult: Result<Void, Error> = .success(())
    var toggleReactionCallCount = 0
    var toggleReactionLastEmoji: String?

    var addPhotosResult: Result<Void, Error> = .success(())
    var addPhotosCallCount = 0
    var addPhotosLastPostId: String?

    func loadPosts(for groupId: String) {
        loadPostsCallCount += 1
        loadPostsLastGroupId = groupId
    }

    func createPost(
        groupId: String,
        authorId: String,
        authorName: String,
        subjectName: String,
        date: Date,
        description: String,
        images: [UIImage],
        completion: @escaping (Result<Post, Error>) -> Void
    ) {
        createPostCallCount += 1
        createPostLastGroupId = groupId
        createPostLastSubjectName = subjectName
        createPostLastImages = images
        completion(createPostResult)
    }

    func deletePost(_ post: Post, completion: @escaping (Result<Void, Error>) -> Void) {
        deletePostCallCount += 1
        deletePostLastId = post.id
        if case .success = deletePostResult {
            posts.removeAll { $0.id == post.id }
        }
        completion(deletePostResult)
    }

    func addComment(to postId: String, authorId: String, authorName: String, text: String, completion: @escaping (Result<Void, Error>) -> Void) {
        addCommentCallCount += 1
        addCommentLastPostId = postId
        addCommentLastText = text
        completion(addCommentResult)
    }

    func toggleReaction(postId: String, emoji: String, userId: String, currentReactions: [PostReaction], completion: @escaping (Result<Void, Error>) -> Void) {
        toggleReactionCallCount += 1
        toggleReactionLastEmoji = emoji
        completion(toggleReactionResult)
    }

    func addPhotos(to postId: String, images: [UIImage], completion: @escaping (Result<Void, Error>) -> Void) {
        addPhotosCallCount += 1
        addPhotosLastPostId = postId
        completion(addPhotosResult)
    }
}
