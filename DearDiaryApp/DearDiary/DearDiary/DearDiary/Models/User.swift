import Foundation

// MARK: - User Model

struct User: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let username: String

    // MARK: - Equatable

    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Auth Response

struct AuthResponse: Codable, Sendable {
    let user: User?
    let message: String?
    let errors: [String: String]?

    var isSuccess: Bool {
        user != nil && errors == nil
    }

    var firstError: String? {
        errors?.values.first ?? message
    }
}

// MARK: - Login Request

struct LoginRequest: Codable, Sendable {
    let username: String
    let password: String

    // Validation
    var isValid: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }
}

// MARK: - Register Request

struct RegisterRequest: Codable, Sendable {
    let username: String
    let password: String
    let confirmPassword: String

    // Validation
    var isValid: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }

    var validationError: String? {
        if username.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Username is required"
        }
        if password.count < 6 {
            return "Password must be at least 6 characters"
        }
        if password != confirmPassword {
            return "Passwords do not match"
        }
        return nil
    }
}
