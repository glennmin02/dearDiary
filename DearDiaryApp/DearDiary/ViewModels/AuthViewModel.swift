import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?

    init() {
        // Check if user was previously logged in
        checkAuthStatus()
    }

    private func checkAuthStatus() {
        // Check for existing session
        if UserDefaults.standard.string(forKey: "sessionCookie") != nil {
            isAuthenticated = true
        }
    }

    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let success = try await APIService.shared.login(username: username, password: password)
            if success {
                isAuthenticated = true
            } else {
                errorMessage = "Invalid username or password"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func register(username: String, password: String, confirmPassword: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await APIService.shared.register(username: username, password: password, confirmPassword: confirmPassword)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func logout() {
        APIService.shared.logout()
        isAuthenticated = false
        currentUser = nil
    }
}
