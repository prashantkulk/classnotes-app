import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseStorage

class GroupService: ObservableObject {
    @Published var groups: [ClassGroup] = []

    private lazy var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    deinit {
        listener?.remove()
    }

    // MARK: - Load Groups (Real-time)

    func loadGroups(for userId: String) {
        listener?.remove()

        listener = db.collection("groups")
            .whereField("members", arrayContains: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error {
                    print("[GroupService] loadGroups snapshot error: \(error.localizedDescription)")
                }
                guard let self, let documents = snapshot?.documents else { return }

                DispatchQueue.main.async {
                    self.groups = documents.compactMap { doc in
                        let data = doc.data()
                        return ClassGroup(
                            id: doc.documentID,
                            name: data["name"] as? String ?? "",
                            school: data["school"] as? String ?? "",
                            inviteCode: data["inviteCode"] as? String ?? "",
                            members: data["members"] as? [String] ?? [],
                            createdBy: data["createdBy"] as? String ?? "",
                            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                            customSubjects: data["customSubjects"] as? [[String: String]] ?? []
                        )
                    }
                }
            }
    }

    // MARK: - Create Group

    func createGroup(_ group: ClassGroup, completion: @escaping (Result<ClassGroup, Error>) -> Void) {
        var newGroup = group
        newGroup.members = [group.createdBy]

        let data: [String: Any] = [
            "name": newGroup.name,
            "school": newGroup.school,
            "inviteCode": newGroup.inviteCode,
            "members": newGroup.members,
            "createdBy": newGroup.createdBy,
            "createdAt": FieldValue.serverTimestamp(),
            "customSubjects": newGroup.customSubjects
        ]

        let docRef = db.collection("groups").document(newGroup.id)
        docRef.setData(data) { error in
            if let error {
                completion(.failure(error))
                return
            }

            // Also add group ID to user's groups array
            self.db.collection("users").document(newGroup.createdBy).updateData([
                "groups": FieldValue.arrayUnion([newGroup.id])
            ])

            completion(.success(newGroup))
        }
    }

    // MARK: - Join Group

    func joinGroup(code: String, userId: String, completion: @escaping (Result<ClassGroup, Error>) -> Void) {
        db.collection("groups")
            .whereField("inviteCode", isEqualTo: code)
            .getDocuments { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    completion(.failure(error))
                    return
                }

                guard let doc = snapshot?.documents.first else {
                    completion(.failure(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "No group found with this code. Please check and try again."])))
                    return
                }

                let data = doc.data()
                let members = data["members"] as? [String] ?? []
                let group = ClassGroup(
                    id: doc.documentID,
                    name: data["name"] as? String ?? "",
                    school: data["school"] as? String ?? "",
                    inviteCode: data["inviteCode"] as? String ?? "",
                    members: members,
                    createdBy: data["createdBy"] as? String ?? "",
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    customSubjects: data["customSubjects"] as? [[String: String]] ?? []
                )

                // Check if user is already a member
                if members.contains(userId) {
                    completion(.failure(NSError(domain: "", code: 409,
                        userInfo: [NSLocalizedDescriptionKey: "You are already a member of \(group.name)."])))
                    return
                }

                // Add user to group members AND user's groups atomically
                let batch = self.db.batch()
                batch.updateData(
                    ["members": FieldValue.arrayUnion([userId])],
                    forDocument: self.db.collection("groups").document(doc.documentID)
                )
                batch.updateData(
                    ["groups": FieldValue.arrayUnion([doc.documentID])],
                    forDocument: self.db.collection("users").document(userId)
                )

                batch.commit { error in
                    DispatchQueue.main.async {
                        if let error {
                            completion(.failure(error))
                            return
                        }
                        // Return group with the joining user already included in members
                        var updatedGroup = group
                        updatedGroup.members.append(userId)
                        completion(.success(updatedGroup))
                    }
                }
            }
    }

    // MARK: - Leave Group

    func leaveGroup(groupId: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let batch = db.batch()

        let groupRef = db.collection("groups").document(groupId)
        batch.updateData(["members": FieldValue.arrayRemove([userId])], forDocument: groupRef)

        let userRef = db.collection("users").document(userId)
        batch.updateData(["groups": FieldValue.arrayRemove([groupId])], forDocument: userRef)

        batch.commit { error in
            DispatchQueue.main.async {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    // MARK: - Delete Group (Creator Only)

    func deleteGroup(_ group: ClassGroup, completion: @escaping (Result<Void, Error>) -> Void) {
        let groupId = group.id

        // Step 1: Get all posts for this group
        db.collection("posts")
            .whereField("groupId", isEqualTo: groupId)
            .getDocuments { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    DispatchQueue.main.async { completion(.failure(error)) }
                    return
                }

                let batch = self.db.batch()
                var allImageURLs: [String] = []

                for doc in snapshot?.documents ?? [] {
                    let data = doc.data()
                    let photoURLs = data["photoURLs"] as? [String] ?? []
                    allImageURLs.append(contentsOf: photoURLs)
                    batch.deleteDocument(doc.reference)
                }

                // Step 2: Get all requests for this group
                self.db.collection("requests")
                    .whereField("groupId", isEqualTo: groupId)
                    .getDocuments { snapshot, error in
                        if let error {
                            DispatchQueue.main.async { completion(.failure(error)) }
                            return
                        }

                        for doc in snapshot?.documents ?? [] {
                            let data = doc.data()
                            let responsesData = data["responses"] as? [[String: Any]] ?? []
                            for resp in responsesData {
                                let respURLs = resp["photoURLs"] as? [String] ?? []
                                allImageURLs.append(contentsOf: respURLs)
                            }
                            batch.deleteDocument(doc.reference)
                        }

                        // Step 3: Remove groupId from all members' user docs
                        for memberId in group.members {
                            let userRef = self.db.collection("users").document(memberId)
                            batch.updateData(["groups": FieldValue.arrayRemove([groupId])], forDocument: userRef)
                        }

                        // Step 4: Delete the group document
                        batch.deleteDocument(self.db.collection("groups").document(groupId))

                        // Step 5: Commit
                        batch.commit { error in
                            DispatchQueue.main.async {
                                if let error {
                                    completion(.failure(error))
                                } else {
                                    // Fire-and-forget: delete images from Storage
                                    let storage = Storage.storage()
                                    for urlString in allImageURLs {
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
            }
    }

    // MARK: - Add Custom Subject

    func addCustomSubject(to groupId: String, subject: SubjectInfo, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("groups").document(groupId).updateData([
            "customSubjects": FieldValue.arrayUnion([subject.firestoreDict])
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
}
