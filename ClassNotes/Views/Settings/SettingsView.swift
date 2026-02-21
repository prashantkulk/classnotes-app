import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var showSignOutConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var showFinalDeleteConfirmation = false
    @State private var isDeletingAccount = false
    @State private var deleteError: String?
    @State private var showDeleteError = false
    @State private var showEditName = false
    @State private var editedName: String = ""
    @State private var isSavingName = false

    var body: some View {
        NavigationStack {
            List {
                // Account info
                Section {
                    Button {
                        editedName = authService.currentUserName
                        showEditName = true
                    } label: {
                        HStack {
                            Text("Name")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(authService.currentUserName)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                // Sign out
                Section {
                    Button("Sign Out") {
                        showSignOutConfirmation = true
                    }
                }

                // Delete account
                Section {
                    Button("Delete Account", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                    .disabled(isDeletingAccount)
                } footer: {
                    Text("Permanently deletes your account and profile data. Your shared notes will remain visible to group members.")
                }

                // Credits
                Section {
                } footer: {
                    VStack(spacing: 4) {
                        HStack(spacing: 0) {
                            Text("Designed by Ritu, Rashmi and Aditi with ")
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                        }
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete My Account", role: .destructive) {
                    showFinalDeleteConfirmation = true
                }
            } message: {
                Text("This will permanently delete your account. This action cannot be undone.")
            }
            .alert("Are you absolutely sure?", isPresented: $showFinalDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Yes, Delete Everything", role: .destructive) {
                    performAccountDeletion()
                }
            } message: {
                Text("Your account and profile will be permanently deleted. You will need to create a new account to use ClassNotes again.")
            }
            .alert("Error", isPresented: $showDeleteError) {
                Button("OK") {}
            } message: {
                Text(deleteError ?? "Something went wrong. Please try again.")
            }
            .alert("Edit Name", isPresented: $showEditName) {
                TextField("Your name", text: $editedName)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    let trimmed = editedName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty, trimmed != authService.currentUserName else { return }
                    isSavingName = true
                    authService.updateName(trimmed) { result in
                        isSavingName = false
                        if case .failure(let error) = result {
                            deleteError = error.localizedDescription
                            showDeleteError = true
                        }
                    }
                }
            } message: {
                Text("What should we call you?")
            }
            .overlay {
                if isDeletingAccount {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("Deleting account...")
                                .font(.headline)
                        }
                        .padding(32)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func performAccountDeletion() {
        isDeletingAccount = true
        authService.deleteAccount { result in
            isDeletingAccount = false
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                deleteError = error.localizedDescription
                showDeleteError = true
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService())
}
