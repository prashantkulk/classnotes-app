import XCTest
@testable import ClassNotes

final class DateExtensionsTests: XCTestCase {

    // MARK: - displayString

    func test_displayString_isNotEmpty() {
        let date = Date()
        XCTAssertFalse(date.displayString.isEmpty)
    }

    func test_displayString_containsExpectedComponents() {
        // Create a known date: Feb 14, 2024 (Wednesday)
        var components = DateComponents()
        components.year = 2024
        components.month = 2
        components.day = 14
        let date = Calendar.current.date(from: components)!

        let result = date.displayString
        // Format is "d MMM, EEEE" -> should contain "14" and "Feb"
        XCTAssertTrue(result.contains("14"), "displayString should contain day: \(result)")
        XCTAssertTrue(result.contains("Feb"), "displayString should contain month: \(result)")
    }

    func test_displayString_differentDates_produceDifferentOutput() {
        let date1 = Date(timeIntervalSince1970: 1700000000)
        let date2 = Date(timeIntervalSince1970: 1700100000)

        XCTAssertNotEqual(date1.displayString, date2.displayString)
    }

    // MARK: - shortDisplayString

    func test_shortDisplayString_isNotEmpty() {
        let date = Date()
        XCTAssertFalse(date.shortDisplayString.isEmpty)
    }

    func test_shortDisplayString_containsDayAndMonth() {
        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 5
        let date = Calendar.current.date(from: components)!

        let result = date.shortDisplayString
        XCTAssertTrue(result.contains("5"), "shortDisplayString should contain day: \(result)")
        XCTAssertTrue(result.contains("Mar"), "shortDisplayString should contain month: \(result)")
    }

    func test_shortDisplayString_isShorterThanDisplayString() {
        let date = Date()
        XCTAssertLessThan(date.shortDisplayString.count, date.displayString.count)
    }

    // MARK: - isToday

    func test_isToday_currentDate_returnsTrue() {
        XCTAssertTrue(Date().isToday)
    }

    func test_isToday_yesterday_returnsFalse() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertFalse(yesterday.isToday)
    }

    func test_isToday_tomorrow_returnsFalse() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertFalse(tomorrow.isToday)
    }

    func test_isToday_distantPast_returnsFalse() {
        XCTAssertFalse(Date.distantPast.isToday)
    }

    func test_isToday_earlierToday_returnsTrue() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        XCTAssertTrue(startOfDay.isToday)
    }

    // MARK: - isYesterday

    func test_isYesterday_yesterdayDate_returnsTrue() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertTrue(yesterday.isYesterday)
    }

    func test_isYesterday_today_returnsFalse() {
        XCTAssertFalse(Date().isYesterday)
    }

    func test_isYesterday_twoDaysAgo_returnsFalse() {
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        XCTAssertFalse(twoDaysAgo.isYesterday)
    }

    func test_isYesterday_distantPast_returnsFalse() {
        XCTAssertFalse(Date.distantPast.isYesterday)
    }

    // MARK: - relativeDisplay

    func test_relativeDisplay_today_returnsToday() {
        XCTAssertEqual(Date().relativeDisplay, "Today")
    }

    func test_relativeDisplay_yesterday_returnsYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertEqual(yesterday.relativeDisplay, "Yesterday")
    }

    func test_relativeDisplay_twoDaysAgo_returnsShortDisplayString() {
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        XCTAssertEqual(twoDaysAgo.relativeDisplay, twoDaysAgo.shortDisplayString)
    }

    func test_relativeDisplay_distantPast_returnsShortDisplayString() {
        let past = Date(timeIntervalSince1970: 1000000000)
        XCTAssertEqual(past.relativeDisplay, past.shortDisplayString)
    }

    func test_relativeDisplay_tomorrow_returnsShortDisplayString() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertEqual(tomorrow.relativeDisplay, tomorrow.shortDisplayString)
    }

    // MARK: - timeAgo

    func test_timeAgo_returnsNonEmptyString() {
        let date = Date()
        XCTAssertFalse(date.timeAgo.isEmpty)
    }

    func test_timeAgo_oneHourAgo_returnsNonEmptyString() {
        let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        let result = oneHourAgo.timeAgo
        XCTAssertFalse(result.isEmpty)
    }

    func test_timeAgo_oneDayAgo_returnsNonEmptyString() {
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let result = oneDayAgo.timeAgo
        XCTAssertFalse(result.isEmpty)
    }

    func test_timeAgo_distantPast_returnsNonEmptyString() {
        let result = Date.distantPast.timeAgo
        XCTAssertFalse(result.isEmpty)
    }
}
