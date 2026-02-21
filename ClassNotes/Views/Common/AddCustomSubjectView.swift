import SwiftUI

struct AddCustomSubjectView: View {
    let group: ClassGroup
    @ObservedObject var groupService: GroupService
    var onCreated: ((SubjectInfo) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var subjectName: String = ""
    @State private var selectedColorName: String = "teal"
    @State private var selectedIcon: String = "book.fill"
    @State private var isLoading: Bool = false
    @State private var showSuccess: Bool = false
    @State private var errorMessage: String?

    private var selectedColor: Color {
        SubjectInfo.color(from: selectedColorName)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Subject Name

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Subject Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        TextField("e.g. Art, Music, PE", text: $subjectName)
                            .font(.body)
                            .padding(16)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // MARK: - Color Picker

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Color")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(SubjectInfo.customColorOptions, id: \.name) { option in
                                    Button {
                                        selectedColorName = option.name
                                    } label: {
                                        Circle()
                                            .fill(option.color)
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.primary, lineWidth: selectedColorName == option.name ? 2.5 : 0)
                                                    .padding(-3)
                                            )
                                            .overlay(
                                                Image(systemName: "checkmark")
                                                    .font(.caption.bold())
                                                    .foregroundStyle(.white)
                                                    .opacity(selectedColorName == option.name ? 1 : 0)
                                            )
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    // MARK: - Icon Picker

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Icon")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                            ForEach(SubjectInfo.customIconOptions, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title3)
                                        .frame(width: 48, height: 48)
                                        .background(selectedIcon == icon
                                                    ? selectedColor.opacity(0.15)
                                                    : Color(.systemGray6))
                                        .foregroundStyle(selectedIcon == icon ? selectedColor : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedIcon == icon ? selectedColor : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }

                    // MARK: - Preview

                    if !subjectName.trimmingCharacters(in: .whitespaces).isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Preview")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 12) {
                                Image(systemName: selectedIcon)
                                    .font(.title2)
                                    .foregroundStyle(selectedColor)

                                Text(subjectName.trimmingCharacters(in: .whitespaces))
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(selectedColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            .navigationTitle("Add Subject")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        addSubject()
                    }
                    .fontWeight(.semibold)
                    .tint(.teal)
                    .disabled(subjectName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                }
            }
        }
        .overlay {
            if showSuccess {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.green)
                    Text("Subject Added!")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: showSuccess)
        .alert("Failed to Add Subject", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Something went wrong. Please try again.")
        }
    }

    // MARK: - Actions

    private func addSubject() {
        let trimmedName = subjectName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        // Check for duplicate names (case-insensitive) against built-in + custom subjects
        let allExistingNames = group.allSubjects.map { $0.name.lowercased() }
        if allExistingNames.contains(trimmedName.lowercased()) {
            errorMessage = "A subject named \"\(trimmedName)\" already exists."
            return
        }

        isLoading = true

        let subject = SubjectInfo(name: trimmedName, colorName: selectedColorName, icon: selectedIcon)

        groupService.addCustomSubject(to: group.id, subject: subject) { result in
            isLoading = false
            switch result {
            case .success:
                onCreated?(subject)
                showSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    dismiss()
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    AddCustomSubjectView(
        group: ClassGroup(name: "Class 5B", school: "Test School", createdBy: "user1"),
        groupService: GroupService()
    )
}
