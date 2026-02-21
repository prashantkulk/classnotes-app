package com.classnotes.app.service

import android.app.Activity
import com.classnotes.app.AppMode
import com.google.firebase.FirebaseException
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.PhoneAuthCredential
import com.google.firebase.auth.PhoneAuthOptions
import com.google.firebase.auth.PhoneAuthProvider
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FieldValue
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.tasks.await
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

open class AuthService {
    protected val _isAuthenticated = MutableStateFlow(false)
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated

    protected val _needsOnboarding = MutableStateFlow(false)
    val needsOnboarding: StateFlow<Boolean> = _needsOnboarding

    protected val _currentUserId = MutableStateFlow("")
    val currentUserId: StateFlow<String> = _currentUserId

    protected val _currentUserName = MutableStateFlow("")
    val currentUserName: StateFlow<String> = _currentUserName

    protected val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error

    protected val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading

    protected var verificationId: String? = null

    private val auth: FirebaseAuth? by lazy {
        if (AppMode.isDemo) null else FirebaseAuth.getInstance()
    }

    private val db: FirebaseFirestore? by lazy {
        if (AppMode.isDemo) null else FirebaseFirestore.getInstance()
    }

    // Activity reference needed for Phone Auth reCAPTCHA
    var activity: Activity? = null

    init {
        if (!AppMode.isDemo) {
            FirebaseAuth.getInstance().addAuthStateListener { firebaseAuth ->
                val user = firebaseAuth.currentUser
                if (user != null) {
                    _currentUserId.value = user.uid
                    _isAuthenticated.value = true
                    fetchUserProfile(user.uid)
                    NotificationService.updateFCMToken(user.uid)
                } else {
                    _currentUserId.value = ""
                    _currentUserName.value = ""
                    _isAuthenticated.value = false
                }
            }
        }
    }

    private fun fetchUserProfile(userId: String) {
        db?.collection("users")?.document(userId)?.get()
            ?.addOnSuccessListener { snapshot ->
                val data = snapshot.data
                if (data != null) {
                    val name = data["name"] as? String ?: ""
                    if (name.isNotEmpty()) {
                        _currentUserName.value = name
                        _needsOnboarding.value = false
                    } else {
                        _needsOnboarding.value = true
                    }
                } else {
                    _needsOnboarding.value = true
                }
            }
            ?.addOnFailureListener {
                _needsOnboarding.value = true
            }
    }

    open suspend fun sendOTP(phoneNumber: String) {
        val currentAuth = auth ?: throw Exception("Firebase not available in demo mode")
        val currentActivity = activity ?: throw Exception("Activity not set for Phone Auth")

        suspendCoroutine { continuation ->
            val options = PhoneAuthOptions.newBuilder(currentAuth)
                .setPhoneNumber(phoneNumber)
                .setTimeout(60L, TimeUnit.SECONDS)
                .setActivity(currentActivity)
                .setCallbacks(object : PhoneAuthProvider.OnVerificationStateChangedCallbacks() {
                    override fun onVerificationCompleted(credential: PhoneAuthCredential) {
                        // Auto-verification (rare on emulator, common on real devices)
                    }

                    override fun onVerificationFailed(e: FirebaseException) {
                        continuation.resumeWithException(e)
                    }

                    override fun onCodeSent(
                        verificationId: String,
                        token: PhoneAuthProvider.ForceResendingToken
                    ) {
                        this@AuthService.verificationId = verificationId
                        continuation.resume(Unit)
                    }
                })
                .build()
            PhoneAuthProvider.verifyPhoneNumber(options)
        }
    }

    open suspend fun verifyOTP(code: String) {
        val currentAuth = auth ?: throw Exception("Firebase not available in demo mode")
        val vid = verificationId ?: throw Exception("No verification ID. Please send OTP again.")

        val credential = PhoneAuthProvider.getCredential(vid, code)
        val result = currentAuth.signInWithCredential(credential).await()
        val user = result.user ?: throw Exception("Sign in failed.")

        // Create user document if it doesn't exist
        val userDoc = db?.collection("users")?.document(user.uid)?.get()?.await()
        if (userDoc?.exists() != true) {
            db?.collection("users")?.document(user.uid)?.set(
                hashMapOf(
                    "phone" to (user.phoneNumber ?: ""),
                    "name" to "",
                    "groups" to listOf<String>(),
                    "createdAt" to FieldValue.serverTimestamp()
                )
            )?.await()
        }
    }

    open fun completeOnboarding(name: String?) {
        val userName = name?.trim()?.takeIf { it.isNotEmpty() } ?: "Parent"
        _currentUserName.value = userName
        _needsOnboarding.value = false

        val userId = _currentUserId.value
        if (userId.isNotEmpty()) {
            db?.collection("users")?.document(userId)?.update("name", userName)
        }
    }

    open suspend fun updateName(name: String) {
        val trimmed = name.trim()
        if (trimmed.isEmpty()) throw Exception("Name cannot be empty.")
        val userId = _currentUserId.value
        if (userId.isEmpty()) throw Exception("Not signed in.")

        db?.collection("users")?.document(userId)?.update("name", trimmed)?.await()
        _currentUserName.value = trimmed
    }

    open fun signOut() {
        auth?.signOut()
        _isAuthenticated.value = false
        _currentUserId.value = ""
        _currentUserName.value = ""
        _needsOnboarding.value = false
    }

    open suspend fun deleteAccount() {
        val user = auth?.currentUser ?: throw Exception("No authenticated user found.")
        val userId = user.uid

        // Step 1: Delete Firestore user document
        db?.collection("users")?.document(userId)?.delete()?.await()

        // Step 2: Delete Firebase Auth account
        try {
            user.delete().await()
        } catch (e: Exception) {
            throw Exception("For security, please sign out and sign back in before deleting your account.")
        }
        // Auth state listener will reset isAuthenticated = false
    }

    fun clearError() {
        _error.value = null
    }
}
