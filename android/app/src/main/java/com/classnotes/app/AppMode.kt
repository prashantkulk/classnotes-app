package com.classnotes.app

import android.content.Context
import android.util.Log
import java.io.File

object AppMode {
    var isDemo: Boolean = false
        private set

    fun initialize(context: Context) {
        // Check for demo mode using SharedPreferences (persists across app restarts)
        // and file-based detection for backward compatibility.
        //
        // To enable demo mode:
        //   adb shell am start -n com.classnotes.app/.MainActivity --ez demo_mode true
        //   OR: adb shell "touch /sdcard/Android/data/com.classnotes.app/files/classnotes_demo_mode"
        // To disable demo mode:
        //   adb shell am start -n com.classnotes.app/.MainActivity --ez demo_mode false
        //   OR: adb shell "rm /sdcard/Android/data/com.classnotes.app/files/classnotes_demo_mode"
        val prefs = context.getSharedPreferences("classnotes_prefs", Context.MODE_PRIVATE)
        val prefDemo = prefs.getBoolean("demo_mode", false)
        val appFile = try {
            File(context.getExternalFilesDir(null), "classnotes_demo_mode").exists()
        } catch (_: Exception) { false }
        val legacyFile = try {
            File("/sdcard/classnotes_demo_mode").exists()
        } catch (_: Exception) { false }
        isDemo = prefDemo || appFile || legacyFile
        Log.d("AppMode", "initialize: prefDemo=$prefDemo, appFile=$appFile, legacyFile=$legacyFile, isDemo=$isDemo")
    }

    /**
     * Enable demo mode via SharedPreferences. Used by tests and adb intent extras.
     */
    fun enableDemoMode(context: Context) {
        context.getSharedPreferences("classnotes_prefs", Context.MODE_PRIVATE)
            .edit().putBoolean("demo_mode", true).apply()
        isDemo = true
    }
}
