import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseStorage

class PostService: ObservableObject {
    @Published var posts: [Post] = []

    private lazy var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    deinit {
        listener?.remove()
    }

    // MARK: - Load Posts (Real-time)

    func loadPosts(for groupId: String) {
        listener?.remove()

        listener = db.collection("posts")
            .whereField("groupId", isEqualTo: groupId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error {
                    print("[PostService] loadPosts snapshot error: \(error.localizedDescription)")
                }
                guard let self, let documents = snapshot?.documents else { return }

                DispatchQueue.main.async {
                    self.posts = documents.compactMap { doc in
                        let data = doc.data()
                        guard let subjectName = data["subject"] as? String else { return nil }

                        let commentsData = data["comments"] as? [[String: Any]] ?? []
                        let comments = commentsData.map { c in
                            PostComment(
                                id: c["id"] as? String ?? UUID().uuidString,
                                authorId: c["authorId"] as? String ?? "",
                                authorName: c["authorName"] as? String ?? "",
                                text: c["text"] as? String ?? "",
                                createdAt: (c["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                            )
                        }

                        let reactionsData = data["reactions"] as? [[String: Any]] ?? []
                        let reactions = reactionsData.compactMap { r -> PostReaction? in
                            guard let emoji = r["emoji"] as? String,
                                  let userIds = r["userIds"] as? [String] else { return nil }
                            return PostReaction(emoji: emoji, userIds: userIds)
                        }

                        return Post(
                            id: doc.documentID,
                            groupId: data["groupId"] as? String ?? "",
                            authorId: data["authorId"] as? String ?? "",
                            authorName: data["authorName"] as? String ?? "",
                            subjectName: subjectName,
                            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                            description: data["description"] as? String ?? "",
                            photoURLs: data["photoURLs"] as? [String] ?? [],
                            comments: comments,
                            reactions: reactions,
                            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                        )
                    }
                }
            }
    }

    // MARK: - Create Post

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
        let postId = UUID().uuidString
        let basePath = "posts/\(postId)"

        // Upload images first
        StorageService.shared.uploadImages(images, basePath: basePath) { [weak self] result in
            switch result {
            case .success(let photoURLs):
                let data: [String: Any] = [
                    "groupId": groupId,
                    "authorId": authorId,
                    "authorName": authorName,
                    "subject": subjectName,
                    "date": Timestamp(date: date),
                    "description": description,
                    "photoURLs": photoURLs,
                    "comments": [[String: Any]](),
                    "reactions": [[String: Any]](),
                    "createdAt": FieldValue.serverTimestamp()
                ]

                self?.db.collection("posts").document(postId).setData(data) { error in
                    DispatchQueue.main.async {
                        if let error {
                            completion(.failure(error))
                            return
                        }

                        let post = Post(
                            id: postId,
                            groupId: groupId,
                            authorId: authorId,
                            authorName: authorName,
                            subjectName: subjectName,
                            date: date,
                            description: description,
                            photoURLs: photoURLs
                        )
                        completion(.success(post))
                    }
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Delete Post

    func deletePost(_ post: Post, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("posts").document(post.id).delete { error in
            DispatchQueue.main.async {
                if let error {
                    completion(.failure(error))
                } else {
                    // Fire-and-forget: delete images from Storage
                    let storage = Storage.storage()
                    for urlString in post.photoURLs {
                        do {
                            let ref = try storage.reference(forURL: urlString)
                            ref.delete { _ in }
                        } catch {
                            // Skip invalid URLs
                        }
                    }
                    completion(.success(()))
                }
            }
        }
    }

    // MARK: - Add Comment

    func addComment(to postId: String, authorId: String, authorName: String, text: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let commentData: [String: Any] = [
            "id": UUID().uuidString,
            "authorId": authorId,
            "authorName": authorName,
            "text": text,
            "createdAt": Timestamp(date: Date())
        ]

        db.collection("posts").document(postId).updateData([
            "comments": FieldValue.arrayUnion([commentData])
        ]) { error in
            DispatchQueue.main.async {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    // MARK: - Toggle Reaction

    func toggleReaction(postId: String, emoji: String, userId: String, currentReactions: [PostReaction], completion: @escaping (Result<Void, Error>) -> Void) {
        var updatedReactions = currentReactions.map { reaction -> [String: Any] in
            ["emoji": reaction.emoji, "userIds": reaction.userIds]
        }

        if let index = updatedReactions.firstIndex(where: { ($0["emoji"] as? String) == emoji }) {
            var userIds = updatedReactions[index]["userIds"] as? [String] ?? []
            if userIds.contains(userId) {
                userIds.removeAll { $0 == userId }
            } else {
                userIds.append(userId)
            }
            if userIds.isEmpty {
                updatedReactions.remove(at: index)
            } else {
                updatedReactions[index]["userIds"] = userIds
            }
        } else {
            updatedReactions.append(["emoji": emoji, "userIds": [userId]])
        }

        db.collection("posts").document(postId).updateData([
            "reactions": updatedReactions
        ]) { error in
            DispatchQueue.main.async {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    // MARK: - Add More Photos

    func addPhotos(to postId: String, images: [UIImage], completion: @escaping (Result<Void, Error>) -> Void) {
        let basePath = "posts/\(postId)"

        StorageService.shared.uploadImages(images, basePath: basePath) { [weak self] result in
            switch result {
            case .success(let newURLs):
                self?.db.collection("posts").document(postId).updateData([
                    "photoURLs": FieldValue.arrayUnion(newURLs)
                ]) { error in
                    DispatchQueue.main.async {
                        if let error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
