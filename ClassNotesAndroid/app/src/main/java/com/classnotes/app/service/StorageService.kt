package com.classnotes.app.service

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Log
import com.google.firebase.storage.FirebaseStorage
import com.google.firebase.storage.StorageMetadata
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.tasks.await
import java.io.ByteArrayOutputStream
import java.util.UUID
import kotlin.math.max

object StorageService {
    private const val TAG = "StorageService"
    private const val MAX_DIMENSION = 1600
    private const val JPEG_QUALITY = 60
    private const val MAX_RETRIES = 3

    private val storage: FirebaseStorage by lazy { FirebaseStorage.getInstance() }

    /**
     * Upload multiple images in parallel and return their download URLs.
     * Maintains order of URLs matching input order.
     */
    suspend fun uploadImages(context: Context, imageUris: List<Uri>, basePath: String): List<String> =
        coroutineScope {
            imageUris.mapIndexed { index, uri ->
                async {
                    val path = "$basePath/${UUID.randomUUID()}.jpg"
                    uploadImage(context, uri, path)
                }
            }.awaitAll()
        }

    /**
     * Upload a single image: load bitmap, resize, compress, upload, get download URL with retry.
     */
    private suspend fun uploadImage(context: Context, uri: Uri, path: String): String {
        val bitmap = loadBitmapFromUri(context, uri)
            ?: throw Exception("Failed to load image")

        val resized = resizeBitmap(bitmap, MAX_DIMENSION)
        val data = compressToJpeg(resized, JPEG_QUALITY)

        val sizeMB = data.size / (1024.0 * 1024.0)
        Log.d(TAG, "Uploading $path — ${"%.1f".format(sizeMB)}MB (${resized.width}x${resized.height})")

        val storageRef = storage.reference.child(path)
        val metadata = StorageMetadata.Builder()
            .setContentType("image/jpeg")
            .build()

        storageRef.putBytes(data, metadata).await()
        Log.d(TAG, "putBytes succeeded for $path, fetching download URL...")

        return fetchDownloadURL(storageRef, path)
    }

    /**
     * Retry fetching the download URL up to [MAX_RETRIES] times with increasing delays (1s, 2s, 3s).
     */
    private suspend fun fetchDownloadURL(
        ref: com.google.firebase.storage.StorageReference,
        path: String,
        attempt: Int = 0
    ): String {
        return try {
            ref.downloadUrl.await().toString()
        } catch (e: Exception) {
            Log.w(TAG, "downloadURL attempt ${attempt + 1} failed for '$path': ${e.message}")
            if (attempt < MAX_RETRIES) {
                val delayMs = (attempt + 1) * 1000L
                Log.d(TAG, "Retrying in ${delayMs}ms...")
                delay(delayMs)
                fetchDownloadURL(ref, path, attempt + 1)
            } else {
                throw Exception("Upload succeeded but failed to get download URL after ${attempt + 1} attempts: ${e.message}")
            }
        }
    }

    fun resizeBitmap(bitmap: Bitmap, maxDimension: Int = MAX_DIMENSION): Bitmap {
        val width = bitmap.width
        val height = bitmap.height
        if (width <= maxDimension && height <= maxDimension) return bitmap

        val ratio = maxDimension.toFloat() / max(width, height).toFloat()
        val newWidth = (width * ratio).toInt()
        val newHeight = (height * ratio).toInt()
        return Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
    }

    fun compressToJpeg(bitmap: Bitmap, quality: Int = JPEG_QUALITY): ByteArray {
        val baos = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, quality, baos)
        return baos.toByteArray()
    }

    fun loadBitmapFromUri(context: Context, uri: Uri): Bitmap? {
        return try {
            context.contentResolver.openInputStream(uri)?.use { inputStream ->
                BitmapFactory.decodeStream(inputStream)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load bitmap from $uri: ${e.message}")
            null
        }
    }

    /**
     * Fire-and-forget: delete images from Storage by their download URLs.
     */
    fun deleteImages(urls: List<String>) {
        for (url in urls) {
            try {
                storage.getReferenceFromUrl(url).delete()
            } catch (_: Exception) {
                // Skip invalid URLs
            }
        }
    }
}
