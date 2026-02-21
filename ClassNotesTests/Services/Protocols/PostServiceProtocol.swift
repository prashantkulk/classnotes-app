import Foundation
import UIKit
@testable import ClassNotes

protocol PostServiceProtocol: AnyObject {
    var posts: [Post] { get set }

    func loadPosts(for groupId: String)
    func createPost(
        groupId: String,
        authorId: String,
        authorName: String,
        subjectName: String,
        date: Date,
        description: String,
        images: [UIImage],
        completion: @escaping (Result<Post, Error>) -> Void
    )
    func deletePost(_ post: Post, completion: @escaping (Result<Void, Error>) -> Void)
    func addComment(to postId: String, authorId: String, authorName: String, text: String, completion: @escaping (Result<Void, Error>) -> Void)
    func toggleReaction(postId: String, emoji: String, userId: String, currentReactions: [PostReaction], completion: @escaping (Result<Void, Error>) -> Void)
    func addPhotos(to postId: String, images: [UIImage], completion: @escaping (Result<Void, Error>) -> Void)
}
