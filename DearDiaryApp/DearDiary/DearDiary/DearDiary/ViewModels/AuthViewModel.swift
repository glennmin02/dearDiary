import Foundation
import SwiftUI
import Combine

/// ViewModel responsible for authentication state management
/// Uses @MainActor to ensure all UI updates happen on the main thread
@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var currentUser: User?

    // MARK: - Private Properties

    private let apiService: APIService
    private let keychain: KeychainService
    private let logger: Logger

    // MARK: - Initialization

    init(
        apiService: APIService = .shared,
        keychain: KeychainService = .shared,
        logger: Logger = .shared
    ) {
        self.apiService = apiService
        self.keychain = keychain
        self.logger = logger
        checkAuthStatus()
    }

    // MARK: - Authentication Status

    private func checkAuthStatus() {
        // Check for existing session in Keychain (secure storage)
        if keychain.sessionCookie != nil {
            isAuthenticated = true
            logger.auth("Restored session from Keychain")
        }
    }

    // MARK: - Login

    func login(username: String, password: String) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let success = try await apiService.login(username: username, password: password)

            if success {
                isAuthenticated = true
                logger.auth("User authenticated successfully")
            } else {
                errorMessage = "Invalid username or password"
                logger.auth("Authentication failed: invalid credentials")
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription
            logger.error("Login error: \(error.errorDescription ?? "Unknown")", category: .auth)
        } catch {
            errorMessage = "An unexpected error occurred"
            logger.error("Unexpected login error: \(error.localizedDescription)", category: .auth)
        }
    }

    // MARK: - Registration

    func register(username: String, password: String, confirmPassword: String) async -> Bool {
        guard !isLoading else { return false }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            try await apiService.register(
                username: username,
                password: password,
                confirmPassword: confirmPassword
            )
            logger.auth("User registered successfully")
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            logger.error("Registration error: \(error.errorDescription ?? "Unknown")", category: .auth)
            return false
        } catch {
            errorMessage = "An unexpected error occurred"
            logger.error("Unexpected registration error: \(error.localizedDescription)", category: .auth)
            return false
        }
    }

    // MARK: - Logout

    func logout() {
        logger.auth("User logging out")
        apiService.logout()
        isAuthenticated = false
        currentUser = nil
        errorMessage = nil
    }

    // MARK: - Error Handling

    func clearError() {
        errorMessage = nil
    }
}
