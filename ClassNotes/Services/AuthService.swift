import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var needsOnboarding = false
    @Published var currentUserId: String = ""
    @Published var currentUserName: String = ""

    private var verificationId: String?
    private lazy var db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var fcmTokenObserver: NSObjectProtocol?

    init() {
        guard !AppMode.isDemo else { return }
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            if let user {
                self.currentUserId = user.uid
                self.isAuthenticated = true
                self.fetchUserProfile(userId: user.uid)
                // Save FCM token for push notifications
                NotificationService.shared.updateFCMToken(for: user.uid)
            } else {
                self.currentUserId = ""
                self.currentUserName = ""
                self.isAuthenticated = false
            }
        }

        // Observe FCM token refreshes
        fcmTokenObserver = NotificationCenter.default.addObserver(
            forName: .fcmTokenRefreshed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, !self.currentUserId.isEmpty else { return }
            NotificationService.shared.updateFCMToken(for: self.currentUserId)
        }
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
        if let observer = fcmTokenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Fetch User Profile

    private func fetchUserProfile(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self else { return }
            DispatchQueue.main.async {
                if let data = snapshot?.data(), let name = data["name"] as? String, !name.isEmpty {
                    self.currentUserName = name
                    self.needsOnboarding = false
                } else {
                    self.needsOnboarding = true
                }
            }
        }
    }

    // MARK: - Send OTP

    func sendOTP(to phoneNumber: String, completion: @escaping (Result<Void, Error>) -> Void) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { [weak self] verificationID, error in
            DispatchQueue.main.async {
                if let error {
                    completion(.failure(error))
                    return
                }
                self?.verificationId = verificationID
                completion(.success(()))
            }
        }
    }

    // MARK: - Verify OTP

    func verifyOTP(_ code: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let verificationId else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No verification ID. Please send OTP again."])))
            return
        }

        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationId, verificationCode: code)

        Auth.auth().signIn(with: credential) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error {
                    completion(.failure(error))
                    return
                }

                guard let user = result?.user else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign in failed."])))
                    return
                }

                // Create user document if it doesn't exist
                self?.db.collection("users").document(user.uid).getDocument { snapshot, _ in
                    if snapshot?.exists != true {
                        self?.db.collection("users").document(user.uid).setData([
                            "phone": user.phoneNumber ?? "",
                            "name": "",
                            "groups": [String](),
                            "createdAt": FieldValue.serverTimestamp()
                        ])
                    }
                }

                completion(.success(()))
            }
        }
    }

    // MARK: - Complete Onboarding

    func completeOnboarding(name: String?) {
        let userName = name ?? "Parent"
        self.currentUserName = userName
        self.needsOnboarding = false

        guard !currentUserId.isEmpty else { return }
        db.collection("users").document(currentUserId).updateData([
            "name": userName
        ])
    }

    // MARK: - Sign Out

    func signOut() {
        try? Auth.auth().signOut()
    }

    // MARK: - Delete Account

    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user found."])))
            return
        }

        let userId = user.uid

        // Step 1: Delete Firestore user document
        db.collection("users").document(userId).delete { error in
            if let error {
                completion(.failure(error))
                return
            }

            // Step 2: Delete Firebase Auth account
            user.delete { error in
                DispatchQueue.main.async {
                    if let error = error as NSError? {
                        if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                            completion(.failure(NSError(domain: "", code: error.code,
                                userInfo: [NSLocalizedDescriptionKey:
                                "For security, please sign out and sign back in before deleting your account."])))
                        } else {
                            completion(.failure(error))
                        }
                        return
                    }
                    // Auth state listener will reset isAuthenticated = false
                    completion(.success(()))
                }
            }
        }
    }
}
