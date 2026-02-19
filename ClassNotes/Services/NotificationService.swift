import Foundation
import FirebaseFirestore
import FirebaseMessaging

class NotificationService {
    static let shared = NotificationService()

    private lazy var db = Firestore.firestore()

    /// Save FCM token to the user's Firestore document
    func updateFCMToken(for userId: String) {
        guard !AppMode.isDemo else { return }

        Messaging.messaging().token { [weak self] token, error in
            guard let token, error == nil else { return }
            self?.db.collection("users").document(userId).updateData([
                "fcmToken": token
            ])
        }
    }

    /// Fetch member details for a group (for the member picker UI)
    func fetchGroupMembers(memberIds: [String], completion: @escaping ([AppUser]) -> Void) {
        guard !AppMode.isDemo else {
            completion([])
            return
        }

        guard !memberIds.isEmpty else {
            completion([])
            return
        }

        // Firestore 'in' queries support up to 30 items — fine for class groups
        db.collection("users")
            .whereField(FieldPath.documentID(), in: Array(memberIds.prefix(30)))
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }

                let users = documents.compactMap { doc -> AppUser? in
                    let data = doc.data()
                    return AppUser(
                        id: doc.documentID,
                        phone: data["phone"] as? String ?? "",
                        name: data["name"] as? String ?? "",
                        groups: data["groups"] as? [String] ?? [],
                        fcmToken: data["fcmToken"] as? String,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                DispatchQueue.main.async {
                    completion(users)
                }
            }
    }
}
