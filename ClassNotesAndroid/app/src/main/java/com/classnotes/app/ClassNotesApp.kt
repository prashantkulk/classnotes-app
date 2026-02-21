package com.classnotes.app

import android.app.Application
import com.google.firebase.FirebaseApp

class ClassNotesApp : Application() {
    override fun onCreate() {
        super.onCreate()
        AppMode.initialize()

        // Always initialize Firebase — required even if demo mode might be active,
        // since the user can switch to real mode via override file
        FirebaseApp.initializeApp(this)
    }
}
