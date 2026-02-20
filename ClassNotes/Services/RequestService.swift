import Foundation
import SwiftUI
import FirebaseFirestore

class RequestService: ObservableObject {
    @Published var requests: [NoteRequest] = []

    private lazy var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    deinit {
        listener?.remove()
    }

    // MARK: - Load Requests (Real-time)

    func loadRequests(for groupId: String) {
        listener?.remove()

        listener = db.collection("requests")
            .whereField("groupId", isEqualTo: groupId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self, let documents = snapshot?.documents else { return }

                DispatchQueue.main.async {
                    self.requests = documents.compactMap { doc in
                        let data = doc.data()
                        guard let subjectRaw = data["subject"] as? String,
                              let subject = Subject(rawValue: subjectRaw),
                              let statusRaw = data["status"] as? String,
                              let status = RequestStatus(rawValue: statusRaw) else { return nil }

                        let responsesData = data["responses"] as? [[String: Any]] ?? []
                        let responses = responsesData.map { respData in
                            RequestResponse(
                                id: respData["id"] as? String ?? UUID().uuidString,
                                authorId: respData["authorId"] as? String ?? "",
                                authorName: respData["authorName"] as? String ?? "",
                                photoURLs: respData["photoURLs"] as? [String] ?? [],
                                createdAt: (respData["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                            )
                        }

                        return NoteRequest(
                            id: doc.documentID,
                            groupId: data["groupId"] as? String ?? "",
                            authorId: data["authorId"] as? String ?? "",
                            authorName: data["authorName"] as? String ?? "",
                            subject: subject,
                            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                            description: data["description"] as? String ?? "",
                            targetUserId: data["targetUserId"] as? String,
                            targetUserName: data["targetUserName"] as? String,
                            status: status,
                            responses: responses,
                            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                        )
                    }
                }
            }
    }

    // MARK: - Create Request

    func createRequest(
        groupId: String,
        authorId: String,
        authorName: String,
        subject: Subject,
        date: Date,
        description: String,
        targetUserId: String? = nil,
        targetUserName: String? = nil,
        completion: @escaping (Result<NoteRequest, Error>) -> Void
    ) {
        let requestId = UUID().uuidString

        var data: [String: Any] = [
            "groupId": groupId,
            "authorId": authorId,
            "authorName": authorName,
            "subject": subject.rawValue,
            "date": Timestamp(date: date),
            "description": description,
            "status": RequestStatus.open.rawValue,
            "responses": [[String: Any]](),
            "createdAt": FieldValue.serverTimestamp()
        ]

        if let targetUserId {
            data["targetUserId"] = targetUserId
        }
        if let targetUserName {
            data["targetUserName"] = targetUserName
        }

        db.collection("requests").document(requestId).setData(data) { error in
            DispatchQueue.main.async {
                if let error {
                    completion(.failure(error))
                    return
                }

                let request = NoteRequest(
                    id: requestId,
                    groupId: groupId,
                    authorId: authorId,
                    authorName: authorName,
                    subject: subject,
                    date: date,
                    description: description,
                    targetUserId: targetUserId,
                    targetUserName: targetUserName
                )
                completion(.success(request))
            }
        }
    }

    // MARK: - Respond to Request

    func respondToRequest(
        requestId: String,
        authorId: String,
        authorName: String,
        images: [UIImage],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let basePath = "requests/\(requestId)/responses"

        StorageService.shared.uploadImages(images, basePath: basePath) { [weak self] result in
            switch result {
            case .success(let photoURLs):
                let responseData: [String: Any] = [
                    "id": UUID().uuidString,
                    "authorId": authorId,
                    "authorName": authorName,
                    "photoURLs": photoURLs,
                    "createdAt": Timestamp(date: Date())
                ]

                self?.db.collection("requests").document(requestId).updateData([
                    "responses": FieldValue.arrayUnion([responseData]),
                    "status": RequestStatus.fulfilled.rawValue
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
                completion(.failure(error))
            }
        }
    }

    // MARK: - Mark as Fulfilled

    func markAsFulfilled(requestId: String) {
        db.collection("requests").document(requestId).updateData([
            "status": RequestStatus.fulfilled.rawValue
        ])
    }
}
