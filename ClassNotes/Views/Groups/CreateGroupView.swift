import SwiftUI

struct CreateGroupView: View {
    @EnvironmentObject var authService: AuthService
    @ObservedObject var groupService: GroupService
    @Environment(\.dismiss) private var dismiss

    @State private var className = ""
    @State private var schoolName = ""
    @State private var isLoading = false
    @State private var createdGroup: ClassGroup?

    var body: some View {
        NavigationStack {
            if let group = createdGroup {
                groupCreatedView(group: group)
            } else {
                formView
            }
        }
    }

    // MARK: - Form

    private var formView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Create a Class Group")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Invite parents and students to share notes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Class Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    TextField("e.g. Class 5B", text: $className)
                        .font(.body)
                        .padding(16)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("School Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    TextField("e.g. St. Mary's School", text: $schoolName)
                        .font(.body)
                        .padding(16)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                createGroup()
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                } else {
                    Text("Create Group")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(className.isEmpty || schoolName.isEmpty || isLoading)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .navigationTitle("New Group")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    // MARK: - Group Created

    private func groupCreatedView(group: ClassGroup) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Group Created!")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 8) {
                Text("Share this code with other parents:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(group.inviteCode)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .tracking(4)
                    .foregroundStyle(.teal)
                    .padding(20)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Button {
                    UIPasteboard.general.string = group.inviteCode
                } label: {
                    Label("Copy Code", systemImage: "doc.on.doc")
                        .font(.subheadline)
                }
                .tint(.teal)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Actions

    private func createGroup() {
        isLoading = true
        let group = ClassGroup(
            name: className.trimmingCharacters(in: .whitespaces),
            school: schoolName.trimmingCharacters(in: .whitespaces),
            createdBy: authService.currentUserId
        )

        groupService.createGroup(group) { result in
            isLoading = false
            switch result {
            case .success(let created):
                createdGroup = created
            case .failure:
                break
            }
        }
    }
}

#Preview {
    CreateGroupView(groupService: GroupService())
        .environmentObject(AuthService())
}
