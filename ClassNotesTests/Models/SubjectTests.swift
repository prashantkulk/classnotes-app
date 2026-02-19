import XCTest
import SwiftUI
@testable import ClassNotes

final class SubjectTests: XCTestCase {

    // MARK: - Raw Values

    func test_math_rawValue() { XCTAssertEqual(Subject.math.rawValue, "Math") }
    func test_science_rawValue() { XCTAssertEqual(Subject.science.rawValue, "Science") }
    func test_english_rawValue() { XCTAssertEqual(Subject.english.rawValue, "English") }
    func test_hindi_rawValue() { XCTAssertEqual(Subject.hindi.rawValue, "Hindi") }
    func test_socialStudies_rawValue() { XCTAssertEqual(Subject.socialStudies.rawValue, "Social Studies") }
    func test_other_rawValue() { XCTAssertEqual(Subject.other.rawValue, "Other") }

    // MARK: - CaseIterable

    func test_allCases_containsSixCases() {
        XCTAssertEqual(Subject.allCases.count, 6)
    }

    func test_allCases_containsExpectedSubjects() {
        let cases = Subject.allCases
        XCTAssertTrue(cases.contains(.math))
        XCTAssertTrue(cases.contains(.science))
        XCTAssertTrue(cases.contains(.english))
        XCTAssertTrue(cases.contains(.hindi))
        XCTAssertTrue(cases.contains(.socialStudies))
        XCTAssertTrue(cases.contains(.other))
    }

    // MARK: - Identifiable

    func test_id_equalsRawValue() {
        for subject in Subject.allCases {
            XCTAssertEqual(subject.id, subject.rawValue,
                           "id should equal rawValue for \(subject)")
        }
    }

    func test_eachCase_hasUniqueId() {
        let ids = Subject.allCases.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "All subject IDs should be unique")
    }

    // MARK: - Icon Mapping

    func test_math_icon() { XCTAssertEqual(Subject.math.icon, "function") }
    func test_science_icon() { XCTAssertEqual(Subject.science.icon, "flask") }
    func test_english_icon() { XCTAssertEqual(Subject.english.icon, "textformat.abc") }
    func test_hindi_icon() { XCTAssertEqual(Subject.hindi.icon, "character.textbox") }
    func test_socialStudies_icon() { XCTAssertEqual(Subject.socialStudies.icon, "globe.asia.australia") }
    func test_other_icon() { XCTAssertEqual(Subject.other.icon, "doc.text") }

    func test_allCases_haveNonEmptyIcon() {
        for subject in Subject.allCases {
            XCTAssertFalse(subject.icon.isEmpty, "\(subject) should have a non-empty icon")
        }
    }

    func test_allCases_haveUniqueIcons() {
        let icons = Subject.allCases.map(\.icon)
        XCTAssertEqual(icons.count, Set(icons).count, "All subject icons should be unique")
    }

    // MARK: - Color Mapping

    func test_math_color_isBlue() { XCTAssertEqual(Subject.math.color, .blue) }
    func test_science_color_isGreen() { XCTAssertEqual(Subject.science.color, .green) }
    func test_english_color_isOrange() { XCTAssertEqual(Subject.english.color, .orange) }
    func test_socialStudies_color_isPurple() { XCTAssertEqual(Subject.socialStudies.color, .purple) }
    func test_other_color_isGray() { XCTAssertEqual(Subject.other.color, .gray) }

    // Hindi color is a custom Color, so we just verify it's not nil/default
    func test_hindi_color_isNotNil() {
        let _ = Subject.hindi.color  // Should not crash
    }

    // MARK: - Codable

    func test_codable_roundTrip_eachCase() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for subject in Subject.allCases {
            let data = try encoder.encode(subject)
            let decoded = try decoder.decode(Subject.self, from: data)
            XCTAssertEqual(decoded, subject, "Round-trip failed for \(subject)")
        }
    }

    func test_decodable_fromValidRawValue_succeeds() throws {
        let json = "\"Math\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Subject.self, from: json)
        XCTAssertEqual(decoded, .math)
    }

    func test_decodable_fromInvalidRawValue_throwsError() {
        let json = "\"Biology\"".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(Subject.self, from: json))
    }

    func test_decodable_fromEmptyString_throwsError() {
        let json = "\"\"".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(Subject.self, from: json))
    }

    func test_decodable_caseSensitive_lowercase_throwsError() {
        let json = "\"math\"".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(Subject.self, from: json))
    }

    // MARK: - Init from Raw Value

    func test_initFromRawValue_validValues_succeed() {
        XCTAssertNotNil(Subject(rawValue: "Math"))
        XCTAssertNotNil(Subject(rawValue: "Science"))
        XCTAssertNotNil(Subject(rawValue: "English"))
        XCTAssertNotNil(Subject(rawValue: "Hindi"))
        XCTAssertNotNil(Subject(rawValue: "Social Studies"))
        XCTAssertNotNil(Subject(rawValue: "Other"))
    }

    func test_initFromRawValue_invalidValue_returnsNil() {
        XCTAssertNil(Subject(rawValue: "Biology"))
        XCTAssertNil(Subject(rawValue: ""))
        XCTAssertNil(Subject(rawValue: "math"))
    }

    func test_initFromRawValue_socialStudies_withSpace() {
        let subject = Subject(rawValue: "Social Studies")
        XCTAssertNotNil(subject)
        XCTAssertEqual(subject, .socialStudies)
    }
}
