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

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var showingRegister: Bool

    @State private var username = ""
    @State private var password = ""

    private var theme: DiaryTheme { themeManager.currentTheme }

    var body: some View {
        ZStack {
            // Solid background
            theme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)

                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 12) {
                            Text("Dear Diary")
                                .font(.playfair(size: 42, relativeTo: .largeTitle))
                                .foregroundColor(theme.textPrimary)

                            Text("Welcome back")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.textPrimary)

                            Text("Sign in to continue your journey")
                                .font(.subheadline)
                                .foregroundColor(theme.textSecondary)
                        }

                        // Error message
                        if let error = authViewModel.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(error)
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(theme.error)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Form
                        VStack(spacing: 20) {
                            DiaryTextField(
                                placeholder: "Username",
                                text: $username,
                                theme: theme
                            )
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            #endif
                            .accessibilityLabel("Username")

                            DiarySecureField(
                                placeholder: "Password",
                                text: $password,
                                theme: theme
                            )
                            .accessibilityLabel("Password")

                            Button(action: {
                                Task {
                                    await authViewModel.login(username: username, password: password)
                                }
                            }) {
                                HStack {
                                    if authViewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Sign In")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                            }
                            .background(theme.accent)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .disabled(authViewModel.isLoading || username.isEmpty || password.isEmpty)
                            .opacity((authViewModel.isLoading || username.isEmpty || password.isEmpty) ? 0.6 : 1)
                        }

                        // Register link
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundColor(theme.textSecondary)
                            Button("Create one") {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingRegister = true
                                }
                            }
                            .foregroundColor(theme.accent)
                            .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    .padding(32)
                    .background(theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.border, lineWidth: 1)
                    )
                    .frame(maxWidth: 400)
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)

                    // Theme toggle
                    ThemeToggle()
                        .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Register View
struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var showingRegister: Bool

    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showSuccess = false

    private var theme: DiaryTheme { themeManager.currentTheme }

    var body: some View {
        ZStack {
            // Solid background
            theme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)

                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 12) {
                            Text("Dear Diary")
                                .font(.playfair(size: 42, relativeTo: .largeTitle))
                                .foregroundColor(theme.textPrimary)

                            Text("Create an account")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.textPrimary)

                            Text("Start your journaling journey today")
                                .font(.subheadline)
                                .foregroundColor(theme.textSecondary)
                        }

                        // Success message
                        if showSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Account created! Please sign in.")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(theme.success)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Error message
                        if let error = authViewModel.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(error)
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(theme.error)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Form
                        VStack(spacing: 20) {
                            DiaryTextField(
                                placeholder: "Username",
                                text: $username,
                                theme: theme
                            )
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            #endif
                            .accessibilityLabel("Username")

                            DiarySecureField(
                                placeholder: "Password",
                                text: $password,
                                theme: theme
                            )
                            .accessibilityLabel("Password")

                            DiarySecureField(
                                placeholder: "Confirm Password",
                                text: $confirmPassword,
                                theme: theme
                            )
                            .accessibilityLabel("Confirm Password")

                            Text("Password must be at least 6 characters")
                                .font(.caption)
                                .foregroundColor(theme.textTertiary)
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
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                showingRegister = false
                                            }
                                        }
                                    }
                                }
                            }) {
                                HStack {
                                    if authViewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Create Account")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                            }
                            .background(theme.accent)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .disabled(authViewModel.isLoading || username.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                            .opacity((authViewModel.isLoading || username.isEmpty || password.isEmpty || confirmPassword.isEmpty) ? 0.6 : 1)
                        }

                        // Login link
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundColor(theme.textSecondary)
                            Button("Sign in") {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingRegister = false
                                }
                            }
                            .foregroundColor(theme.accent)
                            .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    .padding(32)
                    .background(theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.border, lineWidth: 1)
                    )
                    .frame(maxWidth: 400)
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)

                    // Theme toggle
                    ThemeToggle()
                        .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Clean Text Field
struct DiaryTextField: View {
    let placeholder: String
    @Binding var text: String
    let theme: DiaryTheme
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .padding(16)
            .background(theme.cardBackground)
            .foregroundColor(theme.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? theme.accent : theme.border, lineWidth: isFocused ? 2 : 1)
            )
            .focused($isFocused)
    }
}

// MARK: - Clean Secure Field
struct DiarySecureField: View {
    let placeholder: String
    @Binding var text: String
    let theme: DiaryTheme
    @FocusState private var isFocused: Bool

    var body: some View {
        SecureField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .padding(16)
            .background(theme.cardBackground)
            .foregroundColor(theme.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? theme.accent : theme.border, lineWidth: isFocused ? 2 : 1)
            )
            .focused($isFocused)
    }
}

// MARK: - Theme Toggle
struct ThemeToggle: View {
    @EnvironmentObject var themeManager: ThemeManager
    private var theme: DiaryTheme { themeManager.currentTheme }

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                themeManager.toggleTheme()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: theme.isDark ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 16))
                Text(theme.isDark ? "Light Mode" : "Dark Mode")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(theme.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(theme.cardBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(theme.isDark ? "Switch to light mode" : "Switch to dark mode")
    }
}

// MARK: - Card Modifier (minimal, no glass)
extension View {
    func diaryCard(theme: DiaryTheme) -> some View {
        self
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.border, lineWidth: 1)
            )
    }
}

// MARK: - Legacy Support (remove glass references)
struct GlassBackground: View {
    let theme: DiaryTheme

    var body: some View {
        theme.background
            .ignoresSafeArea()
    }
}

extension View {
    func glassCard(theme: DiaryTheme) -> some View {
        self.diaryCard(theme: theme)
    }
}

struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    let theme: DiaryTheme
    var accessibilityLabel: String? = nil
    var accessibilityHint: String? = nil

    var body: some View {
        DiaryTextField(placeholder: placeholder, text: $text, theme: theme)
            .accessibilityLabel(accessibilityLabel ?? placeholder)
    }
}

struct GlassSecureField: View {
    let placeholder: String
    @Binding var text: String
    let theme: DiaryTheme
    var accessibilityLabel: String? = nil
    var accessibilityHint: String? = nil

    var body: some View {
        DiarySecureField(placeholder: placeholder, text: $text, theme: theme)
            .accessibilityLabel(accessibilityLabel ?? placeholder)
    }
}

struct GlassThemePicker: View {
    var body: some View {
        ThemeToggle()
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
        .environmentObject(ThemeManager.shared)
}
