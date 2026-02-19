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

        takeScreenshot(name: "02_Phone_Entered")

        // Tap Send OTP
        let sendOTPButton = app.buttons["Send OTP"]
        XCTAssertTrue(sendOTPButton.waitForExistence(timeout: 2))
        sendOTPButton.tap()

        // Wait for OTP view (text is "Enter the OTP sent to")
        let otpLabel = app.staticTexts["Enter the OTP sent to"]
        XCTAssertTrue(otpLabel.waitForExistence(timeout: 5), "OTP entry screen should appear")

        takeScreenshot(name: "03_OTP_Screen")

        // The OTP field uses a hidden TextField - tap the OTP boxes area then type
        // The OTP boxes are inside an OTPFieldView
        sleep(1)
        // Type OTP - the hidden text field should auto-focus
        let otpTextField = app.textFields.element(boundBy: 0) // first text field is the hidden OTP field
        if otpTextField.exists {
            otpTextField.tap()
            sleep(1)
            otpTextField.typeText("123456")
        }

        sleep(2) // Wait for auto-verify (triggered when 6 digits entered)

        // ===== SCREEN 2: Onboarding =====
        let onboardingText = app.staticTexts["What should we call you?"]
        XCTAssertTrue(onboardingText.waitForExistence(timeout: 5), "Onboarding screen should appear")

        takeScreenshot(name: "04_Onboarding_Screen")

        // Enter name
        let nameField = app.textFields["e.g. Priya's Mom"]
        if nameField.waitForExistence(timeout: 3) {
            nameField.tap()
            sleep(1)
            nameField.typeText("Priya's Mom")
        }

        takeScreenshot(name: "05_Name_Entered")

        // Tap Continue
        let continueButton = app.buttons["Continue"]
        if continueButton.waitForExistence(timeout: 3) {
            continueButton.tap()
        }

        // ===== SCREEN 3: Groups List =====
        sleep(2)
        takeScreenshot(name: "06_Groups_List")

        let class5A = app.staticTexts["Class 5A"]
        XCTAssertTrue(class5A.waitForExistence(timeout: 5), "Demo group Class 5A should be visible")
        XCTAssertTrue(app.staticTexts["Delhi Public School"].exists, "School name should be visible")

        // ===== Test: Create Group Menu =====
        // Tap the "+" button in the navigation bar
        let plusButton = app.navigationBars["ClassNotes"].buttons.firstMatch
        if plusButton.exists {
            plusButton.tap()
            sleep(1)
            takeScreenshot(name: "07_Plus_Menu")

            // Tap "Create Group" from menu
            let createGroupButton = app.buttons["Create Group"]
            if createGroupButton.waitForExistence(timeout: 2) {
                createGroupButton.tap()
                sleep(1)
                takeScreenshot(name: "08_Create_Group_Sheet")

                // Dismiss - find and tap Cancel or close
                if app.buttons["Cancel"].exists {
                    app.buttons["Cancel"].tap()
                } else {
                    // swipe down to dismiss
                    app.swipeDown()
                }
                sleep(1)
            }
        }

        // ===== SCREEN 4: Navigate to group feed =====
        class5A.tap()
        sleep(2)

        takeScreenshot(name: "09_Group_Feed_Notes")

        // Verify feed tabs (these are Buttons, not static texts)
        let notesButton = app.buttons["Notes"]
        let requestsButton = app.buttons["Requests"]
        // They might appear as buttons or staticTexts depending on SwiftUI rendering
        let notesVisible = notesButton.exists || app.staticTexts["Notes"].exists
        let requestsVisible = requestsButton.exists || app.staticTexts["Requests"].exists
        XCTAssertTrue(notesVisible, "Notes tab should be visible")
        XCTAssertTrue(requestsVisible, "Requests tab should be visible")

        // ===== Test: Subject Filter Pills =====
        let mathButton = app.buttons["Math"]
        if mathButton.exists {
            mathButton.tap()
            sleep(1)
            takeScreenshot(name: "10_Math_Filtered")

            let allButton = app.buttons["All"]
            if allButton.exists {
                allButton.tap()
                sleep(1)
            }
        }

        // ===== SCREEN 5: Switch to Requests tab =====
        // Tab is a Button, try button first, then staticText fallback
        if requestsButton.exists {
            requestsButton.tap()
            sleep(1)
            takeScreenshot(name: "11_Requests_Tab")
        } else if app.staticTexts["Requests"].exists {
            app.staticTexts["Requests"].tap()
            sleep(1)
            takeScreenshot(name: "11_Requests_Tab")
        }

        // ===== SCREEN 6: Tap a request to see detail =====
        // Look for request text
        let requestText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'absent' OR label CONTAINS[c] 'forgot'"))
        if requestText.count > 0 {
            requestText.firstMatch.tap()
            sleep(1)
            takeScreenshot(name: "12_Request_Detail")

            // Go back
            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)
        }

        // ===== SCREEN 7: Group Info =====
        // Switch back to Notes tab
        if notesButton.exists {
            notesButton.tap()
            sleep(1)
        } else if app.staticTexts["Notes"].exists {
            app.staticTexts["Notes"].tap()
            sleep(1)
        }

        // Tap the info button in nav bar (it's an "info.circle" SF Symbol)
        let navBarButtons = app.navigationBars.buttons
        for i in 0..<navBarButtons.count {
            let button = navBarButtons.element(boundBy: i)
            let label = button.label.lowercased()
            if label.contains("info") || label.contains("more") || label.contains("detail") {
                button.tap()
                sleep(1)
                break
            }
        }

        takeScreenshot(name: "13_Group_Info")

        // Dismiss info sheet
        if app.buttons["Done"].exists {
            app.buttons["Done"].tap()
        }
        sleep(1)

        // Go back to groups list
        app.navigationBars.buttons.firstMatch.tap()
        sleep(1)

        takeScreenshot(name: "14_Back_To_Groups")

        // ===== Final validation =====
        XCTAssertTrue(app.staticTexts["Class 5A"].exists || app.staticTexts["ClassNotes"].exists,
                       "Should be back at groups list or see ClassNotes title")
    }

    // MARK: - Helper

    private func takeScreenshot(name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
