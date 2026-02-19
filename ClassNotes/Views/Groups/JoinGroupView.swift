import SwiftUI

struct JoinGroupView: View {
    @EnvironmentObject var authService: AuthService
    @ObservedObject var groupService: GroupService
    @Environment(\.dismiss) private var dismiss

    @State private var inviteCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var joinedSuccessfully = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if joinedSuccessfully {
                    successView
                } else {
                    formView
                }
            }
            .navigationTitle("Join Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Form

    private var formView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Join a Class Group")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Enter the 6-letter code shared by\nanother parent or teacher")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)

            TextField("Enter code", text: $inviteCode)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .tracking(4)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .padding(20)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 32)
                .onChange(of: inviteCode) { newValue in
                    inviteCode = String(newValue.prefix(6)).uppercased()
                }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Spacer()

            Button {
                joinGroup()
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                } else {
                    Text("Join Group")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(inviteCode.count < 6 || isLoading)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Joined!")
                .font(.title2)
                .fontWeight(.bold)

            Text("You can now see and share notes\nin this class group")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

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

    private func joinGroup() {
        errorMessage = nil
        isLoading = true

        groupService.joinGroup(code: inviteCode, userId: authService.currentUserId) { result in
            isLoading = false
            switch result {
            case .success:
                withAnimation {
                    joinedSuccessfully = true
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    JoinGroupView(groupService: GroupService())
        .environmentObject(AuthService())
}
