import Foundation
@testable import ClassNotes

class MockAuthService: AuthServiceProtocol {
    var isAuthenticated = false
    var needsOnboarding = false
    var currentUserId = ""
    var currentUserName = ""

    // Configurable results
    var sendOTPResult: Result<Void, Error> = .success(())
    var verifyOTPResult: Result<Void, Error> = .success(())

    // Call tracking
    var sendOTPCallCount = 0
    var sendOTPLastPhoneNumber: String?
    var verifyOTPCallCount = 0
    var verifyOTPLastCode: String?
    var completeOnboardingCallCount = 0
    var completeOnboardingLastName: String??
    var signOutCallCount = 0

    func sendOTP(to phoneNumber: String, completion: @escaping (Result<Void, Error>) -> Void) {
        sendOTPCallCount += 1
        sendOTPLastPhoneNumber = phoneNumber
        completion(sendOTPResult)
    }

    func verifyOTP(_ code: String, completion: @escaping (Result<Void, Error>) -> Void) {
        verifyOTPCallCount += 1
        verifyOTPLastCode = code
        completion(verifyOTPResult)
    }

    func completeOnboarding(name: String?) {
        completeOnboardingCallCount += 1
        completeOnboardingLastName = name
        let userName = name ?? "Parent"
        currentUserName = userName
        needsOnboarding = false
    }

    func signOut() {
        signOutCallCount += 1
        isAuthenticated = false
        currentUserId = ""
        currentUserName = ""
    }
}
