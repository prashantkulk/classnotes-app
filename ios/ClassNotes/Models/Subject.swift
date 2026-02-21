import SwiftUI

enum Subject: String, Codable, CaseIterable, Identifiable {
    case math = "Math"
    case science = "Science"
    case english = "English"
    case hindi = "Hindi"
    case socialStudies = "Social Studies"
    case other = "Other"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .math: return .blue
        case .science: return .green
        case .english: return .orange
        case .hindi: return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .socialStudies: return .purple
        case .other: return .gray
        }
    }

    var icon: String {
        switch self {
        case .math: return "function"
        case .science: return "flask"
        case .english: return "textformat.abc"
        case .hindi: return "character.textbox"
        case .socialStudies: return "globe.asia.australia"
        case .other: return "doc.text"
        }
    }
}
