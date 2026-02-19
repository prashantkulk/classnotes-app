import Foundation

protocol AuthServiceProtocol: AnyObject {
    var isAuthenticated: Bool { get set }
    var needsOnboarding: Bool { get set }
    var currentUserId: String { get set }
    var currentUserName: String { get set }

    func sendOTP(to phoneNumber: String, completion: @escaping (Result<Void, Error>) -> Void)
    func verifyOTP(_ code: String, completion: @escaping (Result<Void, Error>) -> Void)
    func completeOnboarding(name: String?)
    func signOut()
}
