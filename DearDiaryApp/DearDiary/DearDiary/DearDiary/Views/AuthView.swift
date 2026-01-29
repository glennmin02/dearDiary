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
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var showingRegister: Bool

    @State private var username = ""
    @State private var password = ""

    private var theme: DiaryTheme { themeManager.currentTheme }

    var body: some View {
        ZStack {
            // Animated gradient background
            GlassBackground(theme: theme)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Dear Diary")
                            .font(.playfair(size: 42))
                            .foregroundStyle(.primary)

                        Text("Welcome back")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Sign in to continue your journey")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Error message
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(theme.error.opacity(0.9).gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Form with glass effect
                    VStack(spacing: 16) {
                        GlassTextField(
                            placeholder: "Username",
                            text: $username,
                            theme: theme
                        )
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif

                        GlassSecureField(
                            placeholder: "Password",
                            text: $password,
                            theme: theme
                        )

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
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(theme.accent.gradient)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: theme.accent.opacity(0.4), radius: 12, y: 6)
                        .disabled(authViewModel.isLoading || username.isEmpty || password.isEmpty)
                        .opacity((authViewModel.isLoading || username.isEmpty || password.isEmpty) ? 0.6 : 1)
                        .scaleEffect((authViewModel.isLoading || username.isEmpty || password.isEmpty) ? 0.98 : 1)
                        .animation(.spring(response: 0.3), value: username.isEmpty || password.isEmpty)
                    }

                    // Register link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundStyle(.secondary)
                        Button("Create one") {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                showingRegister = true
                            }
                        }
                        .foregroundColor(theme.accent)
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .padding(32)
                .frame(maxWidth: 400)
                .glassCard(theme: theme)

                Spacer()

                // Theme picker with glass effect
                GlassThemePicker()
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
        }
    }
}

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
            // Animated gradient background
            GlassBackground(theme: theme)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Dear Diary")
                            .font(.playfair(size: 42))
                            .foregroundStyle(.primary)

                        Text("Create an account")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Start your journaling journey today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Success message
                    if showSuccess {
                        Text("Account created! Please sign in.")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(theme.success.opacity(0.9).gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Error message
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(theme.error.opacity(0.9).gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Form with glass effect
                    VStack(spacing: 16) {
                        GlassTextField(
                            placeholder: "Username",
                            text: $username,
                            theme: theme
                        )
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif

                        GlassSecureField(
                            placeholder: "Password",
                            text: $password,
                            theme: theme
                        )

                        GlassSecureField(
                            placeholder: "Confirm Password",
                            text: $confirmPassword,
                            theme: theme
                        )

                        Text("Password must be at least 6 characters")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
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
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                            showingRegister = false
                                        }
                                    }
                                }
                            }
                        }) {
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
                        .background(theme.accent.gradient)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: theme.accent.opacity(0.4), radius: 12, y: 6)
                        .disabled(authViewModel.isLoading || username.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                        .opacity((authViewModel.isLoading || username.isEmpty || password.isEmpty || confirmPassword.isEmpty) ? 0.6 : 1)
                        .scaleEffect((authViewModel.isLoading || username.isEmpty || password.isEmpty || confirmPassword.isEmpty) ? 0.98 : 1)
                        .animation(.spring(response: 0.3), value: username.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                    }

                    // Login link
                    HStack {
                        Text("Already have an account?")
                            .foregroundStyle(.secondary)
                        Button("Sign in") {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                showingRegister = false
                            }
                        }
                        .foregroundColor(theme.accent)
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .padding(32)
                .frame(maxWidth: 400)
                .glassCard(theme: theme)

                Spacer()

                // Theme picker with glass effect
                GlassThemePicker()
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Glass Background
struct GlassBackground: View {
    let theme: DiaryTheme
    @State private var animate = false

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            // Animated gradient orbs
            GeometryReader { geometry in
                ZStack {
                    // Primary orb
                    Circle()
                        .fill(theme.accent.opacity(0.3).gradient)
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(
                            x: animate ? 50 : -50,
                            y: animate ? -100 : 100
                        )

                    // Secondary orb
                    Circle()
                        .fill(theme.accentLight.opacity(0.4).gradient)
                        .frame(width: 250, height: 250)
                        .blur(radius: 50)
                        .offset(
                            x: animate ? -80 : 80,
                            y: animate ? 150 : -50
                        )

                    // Tertiary orb
                    Circle()
                        .fill(theme.accent.opacity(0.2).gradient)
                        .frame(width: 200, height: 200)
                        .blur(radius: 40)
                        .offset(
                            x: animate ? 100 : -30,
                            y: animate ? 50 : 200
                        )
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Glass Card Modifier
extension View {
    func glassCard(theme: DiaryTheme) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .shadow(color: theme.textPrimary.opacity(0.1), radius: 20, y: 10)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.5),
                                .white.opacity(0.1),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
    }
}

// MARK: - Glass Text Field
struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    let theme: DiaryTheme
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isFocused ? theme.accent.opacity(0.6) : Color.white.opacity(0.2),
                        lineWidth: isFocused ? 2 : 1
                    )
            }
            .focused($isFocused)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Glass Secure Field
struct GlassSecureField: View {
    let placeholder: String
    @Binding var text: String
    let theme: DiaryTheme
    @FocusState private var isFocused: Bool

    var body: some View {
        SecureField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isFocused ? theme.accent.opacity(0.6) : Color.white.opacity(0.2),
                        lineWidth: isFocused ? 2 : 1
                    )
            }
            .focused($isFocused)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Glass Theme Picker
struct GlassThemePicker: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 16) {
            ForEach(DiaryTheme.all, id: \.name) { theme in
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        themeManager.setTheme(theme)
                    }
                }) {
                    Circle()
                        .fill(theme.accent.gradient)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.3), lineWidth: 2)
                        }
                        .overlay {
                            if themeManager.currentTheme.name == theme.name {
                                Circle()
                                    .stroke(.white, lineWidth: 3)
                                    .padding(-4)
                            }
                        }
                        .shadow(color: theme.accent.opacity(0.5), radius: 8, y: 4)
                        .scaleEffect(themeManager.currentTheme.name == theme.name ? 1.1 : 1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
        }
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.2), lineWidth: 1)
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
        .environmentObject(ThemeManager.shared)
}
