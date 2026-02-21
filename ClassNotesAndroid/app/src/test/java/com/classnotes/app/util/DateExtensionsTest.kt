package com.classnotes.app.util

import org.junit.Assert.*
import org.junit.Test
import java.util.Calendar
import java.util.Date
import java.util.Locale

class DateExtensionsTest {

    @Test
    fun `displayString formats correctly`() {
        // Create a known date: Feb 5, 2025 (Wednesday)
        val cal = Calendar.getInstance(Locale.US)
        cal.set(2025, Calendar.FEBRUARY, 5, 10, 0, 0)
        val date = cal.time
        val result = date.displayString()

        // Should contain day number and month
        assertTrue("displayString should contain '5'", result.contains("5"))
        assertTrue("displayString should contain 'Feb'", result.contains("Feb"))
    }

    @Test
    fun `shortDisplayString formats correctly`() {
        val cal = Calendar.getInstance(Locale.US)
        cal.set(2025, Calendar.FEBRUARY, 5, 10, 0, 0)
        val date = cal.time
        val result = date.shortDisplayString()

        assertTrue("shortDisplayString should contain '5'", result.contains("5"))
        assertTrue("shortDisplayString should contain 'Feb'", result.contains("Feb"))
        // shortDisplayString should NOT contain the day of week
        assertFalse("shortDisplayString should not contain day name", result.contains("Wednesday"))
    }

    @Test
    fun `relativeString returns Just now for very recent dates`() {
        val justNow = Date() // Right now
        val result = justNow.relativeString()
        assertEquals("Just now", result)
    }

    @Test
    fun `relativeString returns minutes ago`() {
        val fiveMinutesAgo = Date(System.currentTimeMillis() - 5 * 60 * 1000)
        val result = fiveMinutesAgo.relativeString()
        assertEquals("5m ago", result)
    }

    @Test
    fun `relativeString returns hours ago`() {
        val threeHoursAgo = Date(System.currentTimeMillis() - 3 * 60 * 60 * 1000)
        val result = threeHoursAgo.relativeString()
        assertEquals("3h ago", result)
    }

    @Test
    fun `relativeString returns days ago`() {
        val twoDaysAgo = Date(System.currentTimeMillis() - 2L * 24 * 60 * 60 * 1000)
        val result = twoDaysAgo.relativeString()
        assertEquals("2d ago", result)
    }

    @Test
    fun `relativeString returns short date for more than 7 days`() {
        val tenDaysAgo = Date(System.currentTimeMillis() - 10L * 24 * 60 * 60 * 1000)
        val result = tenDaysAgo.relativeString()
        // Should fall back to shortDisplayString(), not "10d ago"
        assertFalse(result.contains("ago"))
    }

    @Test
    fun `relativeString boundary at 1 minute`() {
        // 59 seconds ago should be "Just now"
        val fiftyNineSeconds = Date(System.currentTimeMillis() - 59 * 1000)
        assertEquals("Just now", fiftyNineSeconds.relativeString())
    }

    @Test
    fun `relativeString boundary at 1 hour`() {
        // 59 minutes should show as minutes
        val fiftyNineMin = Date(System.currentTimeMillis() - 59L * 60 * 1000)
        val result = fiftyNineMin.relativeString()
        assertTrue("Should show minutes", result.endsWith("m ago"))
    }

    @Test
    fun `relativeString boundary at 1 day`() {
        // 23 hours should show as hours
        val twentyThreeHours = Date(System.currentTimeMillis() - 23L * 60 * 60 * 1000)
        val result = twentyThreeHours.relativeString()
        assertTrue("Should show hours", result.endsWith("h ago"))
    }

    @Test
    fun `daysAgo returns correct date`() {
        val now = Date()
        val threeDaysAgo = now.daysAgo(3)

        val diffMs = now.time - threeDaysAgo.time
        val diffDays = diffMs / (1000 * 60 * 60 * 24)
        assertEquals(3, diffDays)
    }

    @Test
    fun `daysAgo with zero returns same day`() {
        val now = Date()
        val sameDay = now.daysAgo(0)

        // Should be very close to the same time (within same second)
        val diffMs = kotlin.math.abs(now.time - sameDay.time)
        assertTrue("Dates should be within 1 second", diffMs < 1000)
    }

    @Test
    fun `daysAgo with 1 returns yesterday`() {
        val now = Date()
        val yesterday = now.daysAgo(1)

        val diffMs = now.time - yesterday.time
        val diffDays = diffMs / (1000 * 60 * 60 * 24)
        assertEquals(1, diffDays)
    }

    @Test
    fun `daysAgo with large number works`() {
        val now = Date()
        val longAgo = now.daysAgo(365)

        val diffMs = now.time - longAgo.time
        val diffDays = diffMs / (1000 * 60 * 60 * 24)
        assertEquals(365, diffDays)
    }

    @Test
    fun `daysAgo preserves time component`() {
        val cal = Calendar.getInstance()
        cal.set(2025, Calendar.MARCH, 15, 14, 30, 0)
        val date = cal.time
        val result = date.daysAgo(5)

        val resultCal = Calendar.getInstance()
        resultCal.time = result
        assertEquals(14, resultCal.get(Calendar.HOUR_OF_DAY))
        assertEquals(30, resultCal.get(Calendar.MINUTE))
        assertEquals(10, resultCal.get(Calendar.DAY_OF_MONTH))
    }
}
