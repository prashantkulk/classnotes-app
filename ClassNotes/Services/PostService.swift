import Foundation
import SwiftUI
import FirebaseFirestore

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
                guard let self, let documents = snapshot?.documents else { return }

                DispatchQueue.main.async {
                    self.posts = documents.compactMap { doc in
                        let data = doc.data()
                        guard let subjectRaw = data["subject"] as? String,
                              let subject = Subject(rawValue: subjectRaw) else { return nil }

                        return Post(
                            id: doc.documentID,
                            groupId: data["groupId"] as? String ?? "",
                            authorId: data["authorId"] as? String ?? "",
                            authorName: data["authorName"] as? String ?? "",
                            subject: subject,
                            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                            description: data["description"] as? String ?? "",
                            photoURLs: data["photoURLs"] as? [String] ?? [],
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
        subject: Subject,
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
                    "subject": subject.rawValue,
                    "date": Timestamp(date: date),
                    "description": description,
                    "photoURLs": photoURLs,
                    "createdAt": FieldValue.serverTimestamp()
                ]

                self?.db.collection("posts").document(postId).setData(data) { error in
                    if let error {
                        completion(.failure(error))
                        return
                    }

                    let post = Post(
                        id: postId,
                        groupId: groupId,
                        authorId: authorId,
                        authorName: authorName,
                        subject: subject,
                        date: date,
                        description: description,
                        photoURLs: photoURLs
                    )
                    completion(.success(post))
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
