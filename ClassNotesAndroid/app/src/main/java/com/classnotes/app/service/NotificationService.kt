package com.classnotes.app.service

import android.util.Log
import com.classnotes.app.AppMode
import com.classnotes.app.model.AppUser
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FieldPath
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.messaging.FirebaseMessaging
import kotlinx.coroutines.tasks.await
import java.util.Date

object NotificationService {
    private const val TAG = "NotificationService"

    /**
     * Save FCM token to the user's Firestore document.
     * Called when user signs in or token refreshes.
     */
    fun updateFCMToken(userId: String) {
        if (AppMode.isDemo) return

        FirebaseMessaging.getInstance().token
            .addOnSuccessListener { token ->
                FirebaseFirestore.getInstance()
                    .collection("users")
                    .document(userId)
                    .update("fcmToken", token)
                    .addOnFailureListener { e ->
                        Log.w(TAG, "Failed to update FCM token: ${e.message}")
                    }
            }
            .addOnFailureListener { e ->
                Log.w(TAG, "Failed to get FCM token: ${e.message}")
            }
    }

    /**
     * Fetch member details for a group (for the member picker UI).
     * Firestore 'in' queries support up to 30 items — fine for class groups.
     */
    suspend fun fetchGroupMembers(memberIds: List<String>): List<AppUser> {
        if (AppMode.isDemo) return emptyList()
        if (memberIds.isEmpty()) return emptyList()

        return try {
            val ids = memberIds.take(30) // Firestore 'in' query limit
            val snapshot = FirebaseFirestore.getInstance()
                .collection("users")
                .whereIn(FieldPath.documentId(), ids)
                .get()
                .await()

            snapshot.documents.mapNotNull { doc ->
                val data = doc.data ?: return@mapNotNull null
                AppUser(
                    id = doc.id,
                    phone = data["phone"] as? String ?: "",
                    name = data["name"] as? String ?: "",
                    groups = (data["groups"] as? List<*>)?.filterIsInstance<String>() ?: emptyList(),
                    fcmToken = data["fcmToken"] as? String,
                    createdAt = (data["createdAt"] as? Timestamp)?.toDate() ?: Date()
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch group members: ${e.message}")
            emptyList()
        }
    }
}
