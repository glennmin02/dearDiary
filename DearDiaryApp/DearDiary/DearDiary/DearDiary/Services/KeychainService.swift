import Foundation
import Security

/// Secure storage service using iOS Keychain
/// Keychain data persists across app reinstalls and is encrypted by the system
final class KeychainService {

    // MARK: - Singleton

    static let shared = KeychainService()
    private init() {}

    // MARK: - Constants

    private enum Keys {
        static let serviceName = "com.deardiary.app"
        static let sessionCookie = "sessionCookie"
        static let authToken = "authToken"
    }

    // MARK: - Public Interface

    var sessionCookie: String? {
        get { retrieve(key: Keys.sessionCookie) }
        set {
            if let value = newValue {
                save(key: Keys.sessionCookie, value: value)
            } else {
                delete(key: Keys.sessionCookie)
            }
        }
    }

    var authToken: String? {
        get { retrieve(key: Keys.authToken) }
        set {
            if let value = newValue {
                save(key: Keys.authToken, value: value)
            } else {
                delete(key: Keys.authToken)
            }
        }
    }

    /// Clears all stored credentials securely
    func clearAll() {
        delete(key: Keys.sessionCookie)
        delete(key: Keys.authToken)
    }

    // MARK: - Private Keychain Operations

    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Delete existing item first
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            Logger.shared.error("Keychain save failed for key: \(key), status: \(status)")
        }
    }

    private func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.serviceName,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
