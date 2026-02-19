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

    var body: some View {
        NavigationStack {
            List {
                // Account info
                Section {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(authService.currentUserName)
                            .foregroundStyle(.secondary)
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

                // App version
                Section {
                } footer: {
                    HStack {
                        Spacer()
                        Text("ClassNotes v\(appVersion)")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
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

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

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
