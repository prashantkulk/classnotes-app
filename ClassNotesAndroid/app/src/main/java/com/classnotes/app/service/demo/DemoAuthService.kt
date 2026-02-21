package com.classnotes.app.service.demo

import com.classnotes.app.service.AuthService
import kotlinx.coroutines.delay

class DemoAuthService : AuthService() {
    override suspend fun sendOTP(phoneNumber: String) {
        _isLoading.value = true
        delay(500)
        _isLoading.value = false
    }

    override suspend fun verifyOTP(code: String) {
        _isLoading.value = true
        delay(500)
        _currentUserId.value = "demo-user-1"
        _isAuthenticated.value = true
        _needsOnboarding.value = true
        _isLoading.value = false
    }

    override fun completeOnboarding(name: String?) {
        val userName = name?.trim()?.takeIf { it.isNotEmpty() } ?: "Parent"
        _currentUserName.value = userName
        _needsOnboarding.value = false
    }

    override suspend fun updateName(name: String) {
        val trimmed = name.trim()
        if (trimmed.isEmpty()) {
            _error.value = "Name cannot be empty."
            return
        }
        _isLoading.value = true
        delay(300)
        _currentUserName.value = trimmed
        _isLoading.value = false
    }

    override fun signOut() {
        _isAuthenticated.value = false
        _currentUserId.value = ""
        _currentUserName.value = ""
        _needsOnboarding.value = false
    }

    override suspend fun deleteAccount() {
        _isLoading.value = true
        delay(500)
        _isAuthenticated.value = false
        _currentUserId.value = ""
        _currentUserName.value = ""
        _needsOnboarding.value = false
        _isLoading.value = false
    }
}
