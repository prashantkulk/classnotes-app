import SwiftUI

// MARK: - Country Code

enum CountryCode: String, CaseIterable, Identifiable {
    case india = "+91"
    case us = "+1"

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .india: return "🇮🇳"
        case .us: return "🇺🇸"
        }
    }

    var placeholder: String {
        switch self {
        case .india: return "98765 43210"
        case .us: return "(555) 123-4567"
        }
    }

    var minDigits: Int {
        return 10
    }
}

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var phoneNumber = ""
    @State private var otpCode = ""
    @State private var showOTPField = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedCountry: CountryCode = .india
    @FocusState private var otpFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App branding
            VStack(spacing: 12) {
                Image(systemName: "book.pages")
                    .font(.system(size: 64))
                    .foregroundStyle(.teal)

                Text("ClassNotes")
                    .font(.system(size: 32, weight: .bold))

                Text("Share & find class notes easily")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 48)

            // Phone number input
            VStack(spacing: 16) {
                if !showOTPField {
                    phoneInputSection
                } else {
                    otpInputSection
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Phone Input

    private var phoneInputSection: some View {
        VStack(spacing: 16) {
            Text("Enter your phone number")
                .font(.headline)

            HStack(spacing: 8) {
                Menu {
                    ForEach(CountryCode.allCases) { country in
                        Button {
                            selectedCountry = country
                            phoneNumber = "" // reset when switching
                        } label: {
                            Text("\(country.flag) \(country.rawValue)")
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedCountry.flag)
                            .font(.title3)
                        Text(selectedCountry.rawValue)
                            .font(.title3)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .foregroundStyle(.primary)

                TextField(selectedCountry.placeholder, text: $phoneNumber)
                    .font(.title3)
                    .keyboardType(.phonePad)
                    .padding(14)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                sendOTP()
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                } else {
                    Text("Send OTP")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(phoneNumber.filter { $0.isNumber }.count < selectedCountry.minDigits || isLoading)
        }
    }

    // MARK: - OTP Input

    private var otpInputSection: some View {
        VStack(spacing: 16) {
            Text("Enter the OTP sent to")
                .font(.headline)

            Text("\(selectedCountry.rawValue) \(phoneNumber)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            OTPFieldView(code: $otpCode)
                .onChange(of: otpCode) { newValue in
                    if newValue.count == 6 {
                        verifyOTP()
                    }
                }

            Button {
                verifyOTP()
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                } else {
                    Text("Verify")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(otpCode.count < 6 || isLoading)

            Button("Change phone number") {
                withAnimation {
                    showOTPField = false
                    otpCode = ""
                    errorMessage = nil
                }
            }
            .font(.subheadline)
            .foregroundStyle(.teal)
        }
    }

    // MARK: - Actions

    private func sendOTP() {
        errorMessage = nil
        isLoading = true

        let fullNumber = "\(selectedCountry.rawValue)\(phoneNumber.filter { $0.isNumber })"
        authService.sendOTP(to: fullNumber) { result in
            isLoading = false
            switch result {
            case .success:
                withAnimation {
                    showOTPField = true
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private func verifyOTP() {
        errorMessage = nil
        isLoading = true

        authService.verifyOTP(otpCode) { result in
            isLoading = false
            switch result {
            case .success:
                break // AuthService updates isAuthenticated
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - OTP Field

struct OTPFieldView: View {
    @Binding var code: String
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // Hidden text field for keyboard input
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .opacity(0)
                .onChange(of: code) { newValue in
                    if newValue.count > 6 {
                        code = String(newValue.prefix(6))
                    }
                }

            // Visual OTP boxes
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    let digit = index < code.count
                        ? String(code[code.index(code.startIndex, offsetBy: index)])
                        : ""

                    Text(digit)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(width: 48, height: 56)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(index == code.count ? Color.teal : Color.clear, lineWidth: 2)
                        )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }
        }
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService())
}
