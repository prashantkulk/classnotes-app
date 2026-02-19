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
        subject: Subject,
        date: Date,
        description: String,
        images: [UIImage],
        completion: @escaping (Result<Post, Error>) -> Void
    )
}
