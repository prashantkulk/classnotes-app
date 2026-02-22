package com.classnotes.app

import android.app.Application
import android.content.Context
import android.util.Log
import androidx.test.runner.AndroidJUnitRunner

/**
 * Custom test runner that enables demo mode before the Application is created.
 * Overrides newApplication to set SharedPreferences BEFORE Application.onCreate() runs,
 * ensuring AppMode.initialize() reads demo_mode=true.
 */
class DemoTestRunner : AndroidJUnitRunner() {
    override fun newApplication(cl: ClassLoader?, className: String?, context: Context?): Application {
        // Write demo mode pref using the base context. This runs BEFORE Application.onCreate().
        if (context != null) {
            val prefs = context.getSharedPreferences("classnotes_prefs", Context.MODE_PRIVATE)
            val result = prefs.edit().putBoolean("demo_mode", true).commit()
            Log.d("DemoTestRunner", "SharedPreferences commit result: $result, context: ${context.javaClass.name}")
        } else {
            Log.e("DemoTestRunner", "Context is null in newApplication!")
        }
        return super.newApplication(cl, className, context)
    }
}
