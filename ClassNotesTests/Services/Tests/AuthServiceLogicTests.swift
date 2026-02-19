import XCTest
@testable import ClassNotes

final class AuthServiceLogicTests: XCTestCase {

    var mockAuth: MockAuthService!

    override func setUp() {
        super.setUp()
        mockAuth = MockAuthService()
    }

    override func tearDown() {
        mockAuth = nil
        super.tearDown()
    }

    // MARK: - completeOnboarding

    func testCompleteOnboarding_withName_setsUserName() {
        mockAuth.completeOnboarding(name: "Priya's Mom")
        XCTAssertEqual(mockAuth.currentUserName, "Priya's Mom")
    }

    func testCompleteOnboarding_withNilName_defaultsToParent() {
        mockAuth.completeOnboarding(name: nil)
        XCTAssertEqual(mockAuth.currentUserName, "Parent")
    }

    func testCompleteOnboarding_setsNeedsOnboardingFalse() {
        mockAuth.needsOnboarding = true
        mockAuth.completeOnboarding(name: "Test")
        XCTAssertFalse(mockAuth.needsOnboarding)
    }

    func testCompleteOnboarding_incrementsCallCount() {
        mockAuth.completeOnboarding(name: "A")
        mockAuth.completeOnboarding(name: "B")
        XCTAssertEqual(mockAuth.completeOnboardingCallCount, 2)
    }

    func testCompleteOnboarding_capturesLastName() {
        mockAuth.completeOnboarding(name: "First")
        mockAuth.completeOnboarding(name: "Second")
        XCTAssertEqual(mockAuth.completeOnboardingLastName, "Second")
    }

    func testCompleteOnboarding_capturesNilName() {
        mockAuth.completeOnboarding(name: nil)
        XCTAssertEqual(mockAuth.completeOnboardingLastName, .some(nil))
    }

    func testCompleteOnboarding_withEmptyString_setsEmptyName() {
        mockAuth.completeOnboarding(name: "")
        XCTAssertEqual(mockAuth.currentUserName, "")
    }

    // MARK: - signOut

    func testSignOut_resetsAuthentication() {
        mockAuth.isAuthenticated = true
        mockAuth.currentUserId = "user-1"
        mockAuth.currentUserName = "Test User"

        mockAuth.signOut()

        XCTAssertFalse(mockAuth.isAuthenticated)
        XCTAssertEqual(mockAuth.currentUserId, "")
        XCTAssertEqual(mockAuth.currentUserName, "")
    }

    func testSignOut_incrementsCallCount() {
        mockAuth.signOut()
        mockAuth.signOut()
        XCTAssertEqual(mockAuth.signOutCallCount, 2)
    }

    // MARK: - sendOTP

    func testSendOTP_success_completesWithoutError() {
        mockAuth.sendOTPResult = .success(())
        let expectation = expectation(description: "sendOTP")

        mockAuth.sendOTP(to: "+919876543210") { result in
            switch result {
            case .success:
                break // Expected
            case .failure:
                XCTFail("Expected success")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockAuth.sendOTPCallCount, 1)
        XCTAssertEqual(mockAuth.sendOTPLastPhoneNumber, "+919876543210")
    }

    func testSendOTP_failure_completesWithError() {
        let testError = NSError(domain: "test", code: 42)
        mockAuth.sendOTPResult = .failure(testError)
        let expectation = expectation(description: "sendOTP")

        mockAuth.sendOTP(to: "+911234567890") { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertEqual((error as NSError).code, 42)
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - verifyOTP

    func testVerifyOTP_success_completesWithoutError() {
        mockAuth.verifyOTPResult = .success(())
        let expectation = expectation(description: "verifyOTP")

        mockAuth.verifyOTP("123456") { result in
            switch result {
            case .success:
                break // Expected
            case .failure:
                XCTFail("Expected success")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockAuth.verifyOTPCallCount, 1)
        XCTAssertEqual(mockAuth.verifyOTPLastCode, "123456")
    }

    func testVerifyOTP_failure_completesWithError() {
        let testError = NSError(domain: "test", code: 99)
        mockAuth.verifyOTPResult = .failure(testError)
        let expectation = expectation(description: "verifyOTP")

        mockAuth.verifyOTP("000000") { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertEqual((error as NSError).code, 99)
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - State transitions

    func testInitialState_isNotAuthenticated() {
        XCTAssertFalse(mockAuth.isAuthenticated)
        XCTAssertFalse(mockAuth.needsOnboarding)
        XCTAssertEqual(mockAuth.currentUserId, "")
        XCTAssertEqual(mockAuth.currentUserName, "")
    }

    func testFullFlow_sendOTP_verifyOTP_onboard_signOut() {
        // Send OTP
        mockAuth.sendOTPResult = .success(())
        let sendExp = expectation(description: "send")
        mockAuth.sendOTP(to: "+919876543210") { _ in sendExp.fulfill() }
        wait(for: [sendExp], timeout: 1.0)

        // Verify OTP
        mockAuth.verifyOTPResult = .success(())
        mockAuth.isAuthenticated = true
        mockAuth.currentUserId = "user-abc"
        mockAuth.needsOnboarding = true
        let verifyExp = expectation(description: "verify")
        mockAuth.verifyOTP("123456") { _ in verifyExp.fulfill() }
        wait(for: [verifyExp], timeout: 1.0)

        XCTAssertTrue(mockAuth.isAuthenticated)
        XCTAssertTrue(mockAuth.needsOnboarding)

        // Complete onboarding
        mockAuth.completeOnboarding(name: "Priya's Mom")
        XCTAssertFalse(mockAuth.needsOnboarding)
        XCTAssertEqual(mockAuth.currentUserName, "Priya's Mom")

        // Sign out
        mockAuth.signOut()
        XCTAssertFalse(mockAuth.isAuthenticated)
        XCTAssertEqual(mockAuth.currentUserId, "")
        XCTAssertEqual(mockAuth.currentUserName, "")
    }
}
