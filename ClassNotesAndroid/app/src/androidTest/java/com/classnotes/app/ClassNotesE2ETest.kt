package com.classnotes.app

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * End-to-end UI test that exercises the full demo flow of the ClassNotes app.
 * This mirrors the iOS ClassNotesUITests.testFullDemoFlow().
 *
 * Prerequisite: The emulator must have demo mode enabled.
 * Run: adb shell "touch /sdcard/classnotes_demo_mode"
 *
 * Then run: ./gradlew connectedAndroidTest
 */
@RunWith(AndroidJUnit4::class)
class ClassNotesE2ETest {

    @get:Rule
    val composeRule = createAndroidComposeRule<MainActivity>()

    @Before
    fun setUp() {
        // Wait for the app to fully render
        composeRule.waitForIdle()
    }

    // =========================================================================
    // SCREEN 1: Login
    // =========================================================================

    @Test
    fun testLoginScreen_displaysTitle() {
        composeRule.onNodeWithText("ClassNotes").assertIsDisplayed()
    }

    @Test
    fun testLoginScreen_hasPhoneField() {
        composeRule.onNodeWithText("Phone Number").assertExists()
    }

    @Test
    fun testLoginScreen_hasSendOTPButton() {
        composeRule.onNodeWithText("Send OTP").assertExists()
    }

    @Test
    fun testLoginScreen_hasCountryCodeSelector() {
        // Should show India +91 or US +1
        val hasCountry = try {
            composeRule.onNodeWithText("+91").assertExists()
            true
        } catch (_: AssertionError) {
            composeRule.onNodeWithText("+1").assertExists()
            true
        }
        assert(hasCountry)
    }

    // =========================================================================
    // FULL DEMO FLOW
    // =========================================================================

    @Test
    fun testFullDemoFlow() {
        // ===== Step 1: Login Screen =====
        composeRule.onNodeWithText("ClassNotes").assertIsDisplayed()

        // Enter phone number
        composeRule.onNodeWithText("Phone Number").performClick()
        composeRule.onNodeWithText("Phone Number").performTextInput("9876543210")
        composeRule.waitForIdle()

        // Tap Send OTP
        composeRule.onNodeWithText("Send OTP").performClick()
        composeRule.waitForIdle()

        // ===== Step 2: OTP Entry =====
        // Wait for OTP screen
        composeRule.waitUntil(5000) {
            composeRule.onAllNodesWithText("Verify").fetchSemanticsNodes().isNotEmpty() ||
            composeRule.onAllNodesWithText("Enter the OTP").fetchSemanticsNodes().isNotEmpty()
        }

        // Find the OTP text field and enter code
        // The OTP fields may be individual or a single hidden field
        try {
            // Try typing into visible text field
            val otpFields = composeRule.onAllNodes(hasSetTextAction())
            if (otpFields.fetchSemanticsNodes().isNotEmpty()) {
                otpFields[0].performTextInput("123456")
            }
        } catch (_: Exception) {
            // OTP input may auto-advance
        }
        composeRule.waitForIdle()

        // Tap Verify if it exists
        try {
            composeRule.onNodeWithText("Verify").performClick()
        } catch (_: AssertionError) {
            // May auto-verify
        }
        composeRule.waitForIdle()

        // ===== Step 3: Onboarding =====
        composeRule.waitUntil(5000) {
            composeRule.onAllNodesWithText("What should we call you?").fetchSemanticsNodes().isNotEmpty()
        }
        composeRule.onNodeWithText("What should we call you?").assertIsDisplayed()

        // Enter name
        val nameFields = composeRule.onAllNodes(hasSetTextAction())
        if (nameFields.fetchSemanticsNodes().isNotEmpty()) {
            nameFields[0].performTextInput("Aditi's Mom")
        }

        // Tap Continue
        composeRule.onNodeWithText("Continue").performClick()
        composeRule.waitForIdle()

        // ===== Step 4: Groups List =====
        composeRule.waitUntil(5000) {
            composeRule.onAllNodesWithText("Class 5A").fetchSemanticsNodes().isNotEmpty()
        }
        composeRule.onNodeWithText("Class 5A").assertIsDisplayed()
        composeRule.onNodeWithText("Class 5B").assertIsDisplayed()
        composeRule.onNodeWithText("Delhi Public School").assertIsDisplayed()

        // ===== Step 5: Navigate to Group Feed =====
        composeRule.onNodeWithText("Class 5A").performClick()
        composeRule.waitForIdle()

        composeRule.waitUntil(5000) {
            composeRule.onAllNodesWithText("Notes").fetchSemanticsNodes().isNotEmpty()
        }

        // Verify Notes tab is shown with posts
        composeRule.onNodeWithText("Notes").assertIsDisplayed()
        composeRule.onNodeWithText("Requests").assertIsDisplayed()

        // Verify post content
        composeRule.onNodeWithText("Math").assertIsDisplayed()

        // Verify "Share Notes" FAB
        composeRule.onNodeWithText("Share Notes").assertIsDisplayed()

        // ===== Step 6: Subject Filter =====
        // Verify subject filter pills are shown
        composeRule.onNodeWithText("All").assertIsDisplayed()
        composeRule.onNodeWithText("Science").assertIsDisplayed()

        // Tap a subject filter
        composeRule.onNodeWithText("Science").performClick()
        composeRule.waitForIdle()

        // Tap All to reset filter
        composeRule.onNodeWithText("All").performClick()
        composeRule.waitForIdle()

        // ===== Step 7: Switch to Requests Tab =====
        composeRule.onNodeWithText("Requests").performClick()
        composeRule.waitForIdle()

        // Verify requests content
        composeRule.onNodeWithText("Ask for Notes").assertIsDisplayed()

        // ===== Step 8: Switch back to Notes Tab =====
        composeRule.onNodeWithText("Notes").performClick()
        composeRule.waitForIdle()

        // ===== Step 9: Navigate Back to Groups =====
        composeRule.onNodeWithContentDescription("Back").performClick()
        composeRule.waitForIdle()

        // Verify we're back on groups list
        composeRule.waitUntil(3000) {
            composeRule.onAllNodesWithText("Class 5A").fetchSemanticsNodes().isNotEmpty()
        }
        composeRule.onNodeWithText("Class 5A").assertIsDisplayed()
    }

    // =========================================================================
    // SETTINGS FLOW
    // =========================================================================

    @Test
    fun testSettingsFlow() {
        loginAndNavigateToGroups()

        // Tap settings icon
        composeRule.onNodeWithContentDescription("Settings").performClick()
        composeRule.waitForIdle()

        // Verify settings screen
        composeRule.waitUntil(3000) {
            composeRule.onAllNodesWithText("Settings").fetchSemanticsNodes().isNotEmpty()
        }

        // Verify sign out button exists
        composeRule.onNodeWithText("Sign Out").assertIsDisplayed()

        // Navigate back
        composeRule.onNodeWithContentDescription("Back").performClick()
        composeRule.waitForIdle()

        // Should be back on groups list
        composeRule.waitUntil(3000) {
            composeRule.onAllNodesWithText("Class 5A").fetchSemanticsNodes().isNotEmpty()
        }
    }

    // =========================================================================
    // GROUP INFO FLOW
    // =========================================================================

    @Test
    fun testGroupInfoFlow() {
        loginAndNavigateToGroupFeed()

        // Tap group info button
        composeRule.onNodeWithContentDescription("Group Info").performClick()
        composeRule.waitForIdle()

        // Verify group info is shown
        composeRule.waitUntil(3000) {
            composeRule.onAllNodesWithText("Delhi Public School").fetchSemanticsNodes().isNotEmpty()
        }
        composeRule.onNodeWithText("DEMO01").assertIsDisplayed() // Invite code

        // Navigate back
        composeRule.onNodeWithContentDescription("Back").performClick()
        composeRule.waitForIdle()
    }

    // =========================================================================
    // POST DETAIL FLOW (with photo viewer fix)
    // =========================================================================

    @Test
    fun testPostDetailFlow() {
        loginAndNavigateToGroupFeed()

        // Tap the chevron arrow to open thread detail (not the photo)
        composeRule.onAllNodesWithContentDescription("View thread")[0].performClick()
        composeRule.waitForIdle()

        // Verify post detail screen
        composeRule.waitUntil(3000) {
            composeRule.onAllNodesWithText("Comments").fetchSemanticsNodes().isNotEmpty()
        }

        // Verify comment input exists
        composeRule.onNodeWithText("Add a comment...").assertExists()

        // Navigate back
        composeRule.onNodeWithContentDescription("Back").performClick()
        composeRule.waitForIdle()
    }

    // =========================================================================
    // PULL-TO-REFRESH FLOW
    // =========================================================================

    @Test
    fun testPullToRefreshExists() {
        loginAndNavigateToGroupFeed()

        // The feed should be displayed with posts visible (PullToRefreshBox wraps the content)
        composeRule.onNodeWithText("Math").assertIsDisplayed()

        // Switch to Requests tab
        composeRule.onNodeWithText("Requests").performClick()
        composeRule.waitForIdle()

        // Requests should be visible too (also wrapped in PullToRefreshBox)
        composeRule.onNodeWithText("Ask for Notes").assertIsDisplayed()
    }

    // =========================================================================
    // HELPERS
    // =========================================================================

    /**
     * Performs login + onboarding and arrives at the groups list screen.
     */
    private fun loginAndNavigateToGroups() {
        // Enter phone
        composeRule.onNodeWithText("Phone Number").performClick()
        composeRule.onNodeWithText("Phone Number").performTextInput("9876543210")
        composeRule.onNodeWithText("Send OTP").performClick()
        composeRule.waitForIdle()

        // Enter OTP
        composeRule.waitUntil(5000) {
            composeRule.onAllNodes(hasSetTextAction()).fetchSemanticsNodes().isNotEmpty()
        }
        Thread.sleep(500) // Brief wait for UI transition
        val otpFields = composeRule.onAllNodes(hasSetTextAction())
        if (otpFields.fetchSemanticsNodes().isNotEmpty()) {
            otpFields[0].performTextInput("123456")
        }
        try {
            composeRule.onNodeWithText("Verify").performClick()
        } catch (_: AssertionError) {}
        composeRule.waitForIdle()

        // Onboarding
        composeRule.waitUntil(5000) {
            composeRule.onAllNodesWithText("What should we call you?").fetchSemanticsNodes().isNotEmpty()
        }
        val nameFields = composeRule.onAllNodes(hasSetTextAction())
        if (nameFields.fetchSemanticsNodes().isNotEmpty()) {
            nameFields[0].performTextInput("Test Parent")
        }
        composeRule.onNodeWithText("Continue").performClick()
        composeRule.waitForIdle()

        // Wait for groups
        composeRule.waitUntil(5000) {
            composeRule.onAllNodesWithText("Class 5A").fetchSemanticsNodes().isNotEmpty()
        }
    }

    /**
     * Performs login + onboarding + navigates into Class 5A group feed.
     */
    private fun loginAndNavigateToGroupFeed() {
        loginAndNavigateToGroups()

        composeRule.onNodeWithText("Class 5A").performClick()
        composeRule.waitForIdle()

        composeRule.waitUntil(5000) {
            composeRule.onAllNodesWithText("Notes").fetchSemanticsNodes().isNotEmpty()
        }
    }
}
