import XCTest

final class ClassNotesUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = true
        app.launch()
    }

    // MARK: - Full Flow Test

    func testFullDemoFlow() {
        // ===== SCREEN 1: Login =====
        XCTAssertTrue(app.staticTexts["ClassNotes"].waitForExistence(timeout: 5), "App title should be visible")
        takeScreenshot(name: "01_Login_Screen")

        // Enter phone number - tap the text field and type
        let phoneField = app.textFields["98765 43210"] // placeholder text
        XCTAssertTrue(phoneField.waitForExistence(timeout: 3), "Phone field should exist")
        phoneField.tap()
        sleep(1)
        phoneField.typeText("9876543210")
        sleep(1)

        // Tap Send OTP
        let sendOTPButton = app.buttons["Send OTP"]
        XCTAssertTrue(sendOTPButton.waitForExistence(timeout: 2))
        sendOTPButton.tap()

        // Wait for OTP view (text is "Enter the OTP sent to")
        let otpLabel = app.staticTexts["Enter the OTP sent to"]
        XCTAssertTrue(otpLabel.waitForExistence(timeout: 5), "OTP entry screen should appear")

        // The OTP field uses a hidden TextField - tap the OTP boxes area then type
        sleep(1)
        let otpTextField = app.textFields.element(boundBy: 0)
        if otpTextField.exists {
            otpTextField.tap()
            sleep(1)
            otpTextField.typeText("123456")
        }

        sleep(2) // Wait for auto-verify

        // ===== SCREEN 2: Onboarding =====
        let onboardingText = app.staticTexts["What should we call you?"]
        XCTAssertTrue(onboardingText.waitForExistence(timeout: 5), "Onboarding screen should appear")

        // Enter name
        let nameField = app.textFields["e.g. Priya's Mom"]
        if nameField.waitForExistence(timeout: 3) {
            nameField.tap()
            sleep(1)
            nameField.typeText("Priya's Mom")
        }

        // Tap Continue
        let continueButton = app.buttons["Continue"]
        if continueButton.waitForExistence(timeout: 3) {
            continueButton.tap()
        }

        // ===== SCREEN 3: Groups List =====
        sleep(2)
        let class5A = app.staticTexts["Class 5A"]
        XCTAssertTrue(class5A.waitForExistence(timeout: 5), "Demo group Class 5A should be visible")
        takeScreenshot(name: "02_Groups_List")

        // ===== SCREEN 4: Navigate to group feed =====
        let class5ACoord = class5A.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        class5ACoord.tap()
        sleep(2)

        takeScreenshot(name: "03_Group_Feed")

        // ===== SCREEN 5: Switch to Requests tab =====
        let requestsButton = app.buttons["Requests"]
        if requestsButton.waitForExistence(timeout: 3) {
            requestsButton.tap()
            sleep(1)
            takeScreenshot(name: "04_Requests_Tab")
        } else if app.staticTexts["Requests"].exists {
            app.staticTexts["Requests"].tap()
            sleep(1)
            takeScreenshot(name: "04_Requests_Tab")
        }

        // Go back to groups list
        app.navigationBars.buttons.firstMatch.tap()
        sleep(1)

        // ===== SCREEN 6: Settings =====
        // The gear button is on the leading side - find it by accessibility label
        let settingsButton = app.buttons["gearshape"]
        if settingsButton.waitForExistence(timeout: 3) {
            settingsButton.tap()
            sleep(1)
            takeScreenshot(name: "05_Settings")
            // Dismiss settings
            if app.buttons["Done"].exists {
                app.buttons["Done"].tap()
            }
            sleep(1)
        }
    }

    // MARK: - Helper

    private func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        // Also save to disk for App Store screenshots
        let dir = "/Users/prashant/Projects/ClassNotes/screenshots"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let url = URL(fileURLWithPath: "\(dir)/\(name).png")
        try? screenshot.pngRepresentation.write(to: url)
    }
}
