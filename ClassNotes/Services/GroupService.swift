import Foundation
import SwiftUI
import FirebaseFirestore

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
                            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
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
            "createdAt": FieldValue.serverTimestamp()
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
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                )

                // Check if user is already a member
                if members.contains(userId) {
                    completion(.failure(NSError(domain: "", code: 409,
                        userInfo: [NSLocalizedDescriptionKey: "You are already a member of \(group.name)."])))
                    return
                }

                // Add user to group members
                self.db.collection("groups").document(doc.documentID).updateData([
                    "members": FieldValue.arrayUnion([userId])
                ])

                // Add group to user's groups
                self.db.collection("users").document(userId).updateData([
                    "groups": FieldValue.arrayUnion([doc.documentID])
                ])

                completion(.success(group))
            }
    }
}
