package com.classnotes.app

import java.io.File

object AppMode {
    var isDemo: Boolean = false
        private set

    fun initialize() {
        // Check for demo mode override file
        // To enable demo mode: adb shell "touch /sdcard/classnotes_demo_mode"
        // To disable demo mode: adb shell "rm /sdcard/classnotes_demo_mode"
        val demoFile = File("/sdcard/classnotes_demo_mode")
        isDemo = demoFile.exists()
    }
}
