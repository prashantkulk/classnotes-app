package com.classnotes.app.service.demo

import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class DemoAuthServiceTest {

    private lateinit var service: DemoAuthService

    @Before
    fun setUp() {
        service = DemoAuthService()
    }

    @Test
    fun `initial state is not authenticated`() {
        assertFalse(service.isAuthenticated.value)
        assertEquals("", service.currentUserId.value)
        assertEquals("", service.currentUserName.value)
        assertFalse(service.needsOnboarding.value)
    }

    @Test
    fun `sendOTP completes without error`() = runTest {
        service.sendOTP("+919876543210")
        // Should not throw
    }

    @Test
    fun `verifyOTP authenticates user`() = runTest {
        service.verifyOTP("123456")

        assertTrue(service.isAuthenticated.value)
        assertEquals("demo-user-1", service.currentUserId.value)
        assertTrue(service.needsOnboarding.value)
    }

    @Test
    fun `completeOnboarding sets name and clears onboarding flag`() = runTest {
        service.verifyOTP("123456")
        assertTrue(service.needsOnboarding.value)

        service.completeOnboarding("Aditi's Mom")

        assertEquals("Aditi's Mom", service.currentUserName.value)
        assertFalse(service.needsOnboarding.value)
    }

    @Test
    fun `completeOnboarding with null name uses default`() = runTest {
        service.verifyOTP("123456")
        service.completeOnboarding(null)

        assertEquals("Parent", service.currentUserName.value)
        assertFalse(service.needsOnboarding.value)
    }

    @Test
    fun `completeOnboarding with empty name uses default`() = runTest {
        service.verifyOTP("123456")
        service.completeOnboarding("")

        assertEquals("Parent", service.currentUserName.value)
    }

    @Test
    fun `completeOnboarding with whitespace-only name uses default`() = runTest {
        service.verifyOTP("123456")
        service.completeOnboarding("   ")

        assertEquals("Parent", service.currentUserName.value)
    }

    @Test
    fun `completeOnboarding trims whitespace`() = runTest {
        service.verifyOTP("123456")
        service.completeOnboarding("  Test Name  ")

        assertEquals("Test Name", service.currentUserName.value)
    }

    @Test
    fun `updateName changes name`() = runTest {
        service.verifyOTP("123456")
        service.completeOnboarding("Original")

        service.updateName("New Name")

        assertEquals("New Name", service.currentUserName.value)
    }

    @Test
    fun `updateName with empty string sets error`() = runTest {
        service.verifyOTP("123456")
        service.completeOnboarding("Original")

        service.updateName("")

        assertEquals("Name cannot be empty.", service.error.value)
        assertEquals("Original", service.currentUserName.value) // Unchanged
    }

    @Test
    fun `updateName trims whitespace`() = runTest {
        service.verifyOTP("123456")
        service.completeOnboarding("Original")

        service.updateName("  Trimmed  ")

        assertEquals("Trimmed", service.currentUserName.value)
    }

    @Test
    fun `signOut resets all state`() = runTest {
        service.verifyOTP("123456")
        service.completeOnboarding("Test")

        service.signOut()

        assertFalse(service.isAuthenticated.value)
        assertEquals("", service.currentUserId.value)
        assertEquals("", service.currentUserName.value)
        assertFalse(service.needsOnboarding.value)
    }

    @Test
    fun `deleteAccount resets all state`() = runTest {
        service.verifyOTP("123456")
        service.completeOnboarding("Test")

        service.deleteAccount()

        assertFalse(service.isAuthenticated.value)
        assertEquals("", service.currentUserId.value)
        assertEquals("", service.currentUserName.value)
        assertFalse(service.needsOnboarding.value)
    }

    @Test
    fun `full login flow works end to end`() = runTest {
        // 1. Send OTP
        service.sendOTP("+919876543210")

        // 2. Verify OTP
        service.verifyOTP("123456")
        assertTrue(service.isAuthenticated.value)
        assertTrue(service.needsOnboarding.value)

        // 3. Complete onboarding
        service.completeOnboarding("Test Parent")
        assertEquals("Test Parent", service.currentUserName.value)
        assertFalse(service.needsOnboarding.value)

        // 4. Sign out
        service.signOut()
        assertFalse(service.isAuthenticated.value)
    }
}
