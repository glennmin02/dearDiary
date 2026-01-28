import Foundation

struct User: Codable, Identifiable {
    let id: String
    let username: String
}

struct AuthResponse: Codable {
    let user: User?
    let message: String?
    let errors: [String: String]?
}

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct RegisterRequest: Codable {
    let username: String
    let password: String
    let confirmPassword: String
}
