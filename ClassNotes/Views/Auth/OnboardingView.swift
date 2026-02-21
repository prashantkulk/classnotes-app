import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authService: AuthService
    @State private var name = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 56))
                    .foregroundStyle(.teal)

                Text("What should we call you?")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Other parents will see this name")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 40)

            VStack(spacing: 16) {
                TextField("e.g. Aditi's Mom", text: $name)
                    .font(.title3)
                    .padding(16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 32)

                Button {
                    saveName()
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        Text("Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                .padding(.horizontal, 32)

                Button("Skip for now") {
                    authService.completeOnboarding(name: nil)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()
            Spacer()
        }
        .background(Color(.systemBackground))
    }

    private func saveName() {
        isLoading = true
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        authService.completeOnboarding(name: trimmedName)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthService())
}
