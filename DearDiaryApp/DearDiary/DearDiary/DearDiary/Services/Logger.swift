import Foundation
import os.log

/// Secure logging service that prevents sensitive data leakage
/// Uses Apple's unified logging system (os.log) for better performance and privacy
final class Logger {

    // MARK: - Singleton

    static let shared = Logger()
    private init() {}

    // MARK: - Private Properties

    private let subsystem = Bundle.main.bundleIdentifier ?? "com.deardiary.app"

    private lazy var generalLog = OSLog(subsystem: subsystem, category: "general")
    private lazy var networkLog = OSLog(subsystem: subsystem, category: "network")
    private lazy var authLog = OSLog(subsystem: subsystem, category: "auth")
    private lazy var errorLog = OSLog(subsystem: subsystem, category: "error")

    // MARK: - Configuration

    #if DEBUG
    private let isEnabled = true
    #else
    private let isEnabled = false // Disable logging in production
    #endif

    // MARK: - Public Logging Methods

    func info(_ message: String, category: LogCategory = .general) {
        guard isEnabled else { return }
        os_log(.info, log: log(for: category), "%{public}@", sanitize(message))
    }

    func debug(_ message: String, category: LogCategory = .general) {
        guard isEnabled else { return }
        os_log(.debug, log: log(for: category), "%{public}@", sanitize(message))
    }

    func warning(_ message: String, category: LogCategory = .general) {
        guard isEnabled else { return }
        os_log(.default, log: log(for: category), "⚠️ %{public}@", sanitize(message))
    }

    func error(_ message: String, category: LogCategory = .error) {
        guard isEnabled else { return }
        os_log(.error, log: log(for: category), "❌ %{public}@", sanitize(message))
    }

    func network(_ message: String) {
        info(message, category: .network)
    }

    func auth(_ message: String) {
        info(message, category: .auth)
    }

    // MARK: - Private Helpers

    private func log(for category: LogCategory) -> OSLog {
        switch category {
        case .general: return generalLog
        case .network: return networkLog
        case .auth: return authLog
        case .error: return errorLog
        }
    }

    /// Sanitizes messages to prevent sensitive data leakage
    private func sanitize(_ message: String) -> String {
        var sanitized = message

        // Patterns to redact
        let sensitivePatterns = [
            // Passwords
            "password[\"']?\\s*[:=]\\s*[\"']?[^\"'\\s,}]+",
            // Tokens
            "token[\"']?\\s*[:=]\\s*[\"']?[^\"'\\s,}]+",
            // Session cookies
            "session[^=]*=[^;\\s]+",
            // Authorization headers
            "Bearer\\s+[A-Za-z0-9\\-._~+/]+=*",
            // CSRF tokens
            "csrf[^=]*=[^&\\s]+"
        ]

        for pattern in sensitivePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(sanitized.startIndex..., in: sanitized)
                sanitized = regex.stringByReplacingMatches(
                    in: sanitized,
                    range: range,
                    withTemplate: "[REDACTED]"
                )
            }
        }

        return sanitized
    }

    // MARK: - Log Categories

    enum LogCategory {
        case general
        case network
        case auth
        case error
    }
}
