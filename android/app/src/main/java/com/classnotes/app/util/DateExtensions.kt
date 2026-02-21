package com.classnotes.app.util

import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/** Format as "d MMM, EEEE" (e.g., "5 Feb, Wednesday"). */
fun Date.displayString(): String {
    val sdf = SimpleDateFormat("d MMM, EEEE", Locale.getDefault())
    return sdf.format(this)
}

/** Format as "d MMM" (e.g., "5 Feb"). */
fun Date.shortDisplayString(): String {
    val sdf = SimpleDateFormat("d MMM", Locale.getDefault())
    return sdf.format(this)
}

/** Human-readable relative time string (e.g., "Just now", "5m ago", "3d ago"). */
fun Date.relativeString(): String {
    val now = Date()
    val diffMs = now.time - this.time
    val diffMins = diffMs / (1000 * 60)
    val diffHours = diffMins / 60
    val diffDays = diffHours / 24

    return when {
        diffMins < 1 -> "Just now"
        diffMins < 60 -> "${diffMins}m ago"
        diffHours < 24 -> "${diffHours}h ago"
        diffDays < 7 -> "${diffDays}d ago"
        else -> shortDisplayString()
    }
}

/** Return a new [Date] that is [days] days before this date. */
fun Date.daysAgo(days: Int): Date {
    val cal = Calendar.getInstance()
    cal.time = this
    cal.add(Calendar.DAY_OF_YEAR, -days)
    return cal.time
}
