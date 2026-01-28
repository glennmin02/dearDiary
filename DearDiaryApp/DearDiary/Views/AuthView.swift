import SwiftUI

struct AuthView: View {
    @State private var showingRegister = false

    var body: some View {
        if showingRegister {
            RegisterView(showingRegister: $showingRegister)
        } else {
            LoginView(showingRegister: $showingRegister)
        }
    }
}

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showingRegister: Bool

    @State private var username = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Dear Diary")
                        .font(.system(size: 36, weight: .light, design: .serif))
                        .foregroundColor(.primary)

                    Text("Welcome back")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Sign in to continue your journey")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Error message
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                }

                // Form
                VStack(spacing: 16) {
                    TextField("Username", text: $username)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif

                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    Button(action: {
                        Task {
                            await authViewModel.login(username: username, password: password)
                        }
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign In")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundColor(Color(.systemBackground))
                    .cornerRadius(10)
                    .disabled(authViewModel.isLoading || username.isEmpty || password.isEmpty)
                }

                // Register link
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.secondary)
                    Button("Create one") {
                        showingRegister = true
                    }
                    .foregroundColor(.primary)
                }
                .font(.subheadline)
            }
            .padding(32)
            .frame(maxWidth: 400)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showingRegister: Bool

    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showSuccess = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Dear Diary")
                        .font(.system(size: 36, weight: .light, design: .serif))
                        .foregroundColor(.primary)

                    Text("Create an account")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Start your journaling journey today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Success message
                if showSuccess {
                    Text("Account created! Please sign in.")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(8)
                }

                // Error message
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                }

                // Form
                VStack(spacing: 16) {
                    TextField("Username", text: $username)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif

                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    Text("Password must be at least 6 characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: {
                        Task {
                            let success = await authViewModel.register(
                                username: username,
                                password: password,
                                confirmPassword: confirmPassword
                            )
                            if success {
                                showSuccess = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    showingRegister = false
                                }
                            }
                        }
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Create Account")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundColor(Color(.systemBackground))
                    .cornerRadius(10)
                    .disabled(authViewModel.isLoading || username.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                }

                // Login link
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.secondary)
                    Button("Sign in") {
                        showingRegister = false
                    }
                    .foregroundColor(.primary)
                }
                .font(.subheadline)
            }
            .padding(32)
            .frame(maxWidth: 400)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
