import SwiftUI

struct SubjectInfo: Identifiable, Equatable, Hashable {
    let name: String
    let color: Color
    let icon: String
    let isBuiltIn: Bool

    var id: String { name }

    // Initialize from a built-in Subject enum case
    init(from subject: Subject) {
        self.name = subject.rawValue
        self.color = subject.color
        self.icon = subject.icon
        self.isBuiltIn = true
    }

    // Initialize from a custom subject (Firestore data)
    init(name: String, colorName: String, icon: String) {
        self.name = name
        self.color = SubjectInfo.color(from: colorName)
        self.icon = icon
        self.isBuiltIn = false
    }

    // All built-in subjects as SubjectInfo
    static var builtInSubjects: [SubjectInfo] {
        Subject.allCases.map { SubjectInfo(from: $0) }
    }

    // Look up a SubjectInfo by name from a combined list
    static func find(name: String, in customSubjects: [SubjectInfo]) -> SubjectInfo? {
        if let builtIn = Subject(rawValue: name) {
            return SubjectInfo(from: builtIn)
        }
        return customSubjects.first { $0.name == name }
    }

    // Predefined color palette for custom subjects
    static let customColorOptions: [(name: String, color: Color)] = [
        ("red", .red),
        ("pink", .pink),
        ("indigo", .indigo),
        ("teal", .teal),
        ("cyan", .cyan),
        ("mint", .mint),
        ("brown", .brown),
        ("yellow", .yellow),
    ]

    // Predefined icon options for custom subjects
    static let customIconOptions: [String] = [
        "book.fill", "pencil.and.ruler", "paintbrush.fill",
        "music.note", "sportscourt", "globe",
        "laptopcomputer", "wrench.and.screwdriver", "leaf.fill",
        "heart.fill", "star.fill", "flag.fill"
    ]

    static func color(from name: String) -> Color {
        customColorOptions.first { $0.name == name }?.color ?? .gray
    }

    // Convert to Firestore dict for storing in group's customSubjects array
    var firestoreDict: [String: String] {
        ["name": name, "color": colorNameString, "icon": icon]
    }

    var colorNameString: String {
        if isBuiltIn, let subject = Subject(rawValue: name) {
            switch subject {
            case .math: return "blue"
            case .science: return "green"
            case .english: return "orange"
            case .hindi: return "orange"
            case .socialStudies: return "purple"
            case .other: return "gray"
            }
        }
        return SubjectInfo.customColorOptions.first { $0.color == color }?.name ?? "gray"
    }

    // Equatable/Hashable based on name
    static func == (lhs: SubjectInfo, rhs: SubjectInfo) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
