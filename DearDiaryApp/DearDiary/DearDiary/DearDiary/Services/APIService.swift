import Foundation

// MARK: - API Error

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case decodingError(Error)
    case networkError(Error)
    case validationError(String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Please log in again"
        case .serverError(let message):
            return message
        case .decodingError:
            return "Failed to process server response"
        case .networkError(let error):
            return error.localizedDescription
        case .validationError(let message):
            return message
        case .timeout:
            return "Request timed out. Please try again."
        }
    }
}

// MARK: - API Configuration

enum APIConfig {
    static let baseURL = "https://deardiary.vercel.app"
    static let timeoutInterval: TimeInterval = 30
    static let defaultPageLimit = 20

    enum Endpoints {
        static let csrf = "/api/auth/csrf"
        static let login = "/api/auth/callback/credentials"
        static let register = "/api/auth/register"
        static let diaries = "/api/diaries"

        static func diary(id: String) -> String {
            "/api/diaries/\(id)"
        }
    }

    enum HTTPMethod {
        static let get = "GET"
        static let post = "POST"
        static let put = "PUT"
        static let delete = "DELETE"
    }

    enum HTTPStatus {
        static let ok = 200
        static let created = 201
        static let redirect = 302
        static let unauthorized = 401
    }
}

// MARK: - API Service

final class APIService {

    // MARK: - Singleton

    static let shared = APIService()
    private init() {
        configureURLSession()
    }

    // MARK: - Private Properties

    private let keychain = KeychainService.shared
    private let logger = Logger.shared

    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.timeoutInterval
        config.timeoutIntervalForResource = APIConfig.timeoutInterval * 2
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()

    private lazy var dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private lazy var requestDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    // MARK: - Configuration

    private func configureURLSession() {
        // Enable cookie storage for session management
        urlSession.configuration.httpCookieStorage = HTTPCookieStorage.shared
        urlSession.configuration.httpCookieAcceptPolicy = .always
    }

    // MARK: - Authentication

    func login(username: String, password: String) async throws -> Bool {
        // Validate input
        try validateCredentials(username: username, password: password)

        logger.auth("Attempting login for user")

        // Get CSRF token
        let csrfToken = try await fetchCSRFToken()

        // Build login request
        guard let url = URL(string: APIConfig.baseURL + APIConfig.Endpoints.login) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = APIConfig.HTTPMethod.post
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = APIConfig.timeoutInterval

        // URL-encode credentials to prevent injection
        let encodedUsername = username.urlEncoded
        let encodedPassword = password.urlEncoded
        let encodedToken = csrfToken.urlEncoded

        let body = "username=\(encodedUsername)&password=\(encodedPassword)&csrfToken=\(encodedToken)"
        request.httpBody = body.data(using: .utf8)

        let (_, response) = try await performRequest(request)

        if let httpResponse = response as? HTTPURLResponse {
            handleSessionCookies(from: httpResponse)

            let success = httpResponse.statusCode == APIConfig.HTTPStatus.ok ||
                         httpResponse.statusCode == APIConfig.HTTPStatus.redirect

            if success {
                logger.auth("Login successful")
            } else {
                logger.auth("Login failed with status: \(httpResponse.statusCode)")
            }

            return success
        }

        return false
    }

    func register(username: String, password: String, confirmPassword: String) async throws {
        // Validate input
        try validateCredentials(username: username, password: password)
        try validatePasswordMatch(password: password, confirmPassword: confirmPassword)

        logger.auth("Attempting registration")

        guard let url = URL(string: APIConfig.baseURL + APIConfig.Endpoints.register) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = APIConfig.HTTPMethod.post
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = APIConfig.timeoutInterval

        let body = RegisterRequest(
            username: username,
            password: password,
            confirmPassword: confirmPassword
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await performRequest(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == APIConfig.HTTPStatus.created {
            logger.auth("Registration successful")
            return
        }

        // Parse error response
        throw parseErrorResponse(from: data) ?? APIError.serverError("Registration failed")
    }

    func logout() {
        logger.auth("Logging out")
        keychain.clearAll()
        HTTPCookieStorage.shared.cookies?.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
    }

    // MARK: - Diaries

    func fetchDiaries(page: Int = 1, search: String = "") async throws -> DiaryListResponse {
        var components = URLComponents(string: APIConfig.baseURL + APIConfig.Endpoints.diaries)
        components?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(APIConfig.defaultPageLimit))
        ]

        if !search.isEmpty {
            components?.queryItems?.append(URLQueryItem(name: "search", value: search))
        }

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        let request = buildRequest(url: url, method: APIConfig.HTTPMethod.get)
        let (data, _) = try await performAuthenticatedRequest(request)

        return try decodeResponse(DiaryListResponse.self, from: data)
    }

    func fetchDiary(id: String) async throws -> Diary {
        // Validate ID to prevent path traversal
        guard isValidID(id) else {
            throw APIError.validationError("Invalid diary ID")
        }

        guard let url = URL(string: APIConfig.baseURL + APIConfig.Endpoints.diary(id: id)) else {
            throw APIError.invalidURL
        }

        let request = buildRequest(url: url, method: APIConfig.HTTPMethod.get)
        let (data, _) = try await performAuthenticatedRequest(request)

        return try decodeResponse(Diary.self, from: data)
    }

    func createDiary(title: String, content: String, entryDate: Date) async throws -> Diary {
        try validateDiaryInput(title: title, content: content)

        guard let url = URL(string: APIConfig.baseURL + APIConfig.Endpoints.diaries) else {
            throw APIError.invalidURL
        }

        var request = buildRequest(url: url, method: APIConfig.HTTPMethod.post)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = DiaryRequest(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            entryDate: requestDateFormatter.string(from: entryDate)
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await performAuthenticatedRequest(request, expectedStatus: APIConfig.HTTPStatus.created)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == APIConfig.HTTPStatus.created else {
            throw APIError.serverError("Failed to create diary")
        }

        return try decodeResponse(Diary.self, from: data)
    }

    func updateDiary(id: String, title: String, content: String, entryDate: Date) async throws -> Diary {
        guard isValidID(id) else {
            throw APIError.validationError("Invalid diary ID")
        }
        try validateDiaryInput(title: title, content: content)

        guard let url = URL(string: APIConfig.baseURL + APIConfig.Endpoints.diary(id: id)) else {
            throw APIError.invalidURL
        }

        var request = buildRequest(url: url, method: APIConfig.HTTPMethod.put)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = DiaryRequest(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            entryDate: requestDateFormatter.string(from: entryDate)
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await performAuthenticatedRequest(request)

        return try decodeResponse(Diary.self, from: data)
    }

    func deleteDiary(id: String) async throws {
        guard isValidID(id) else {
            throw APIError.validationError("Invalid diary ID")
        }

        guard let url = URL(string: APIConfig.baseURL + APIConfig.Endpoints.diary(id: id)) else {
            throw APIError.invalidURL
        }

        let request = buildRequest(url: url, method: APIConfig.HTTPMethod.delete)
        _ = try await performAuthenticatedRequest(request)
    }

    // MARK: - Private Helpers

    private func fetchCSRFToken() async throws -> String {
        guard let url = URL(string: APIConfig.baseURL + APIConfig.Endpoints.csrf) else {
            throw APIError.invalidURL
        }

        let request = buildRequest(url: url, method: APIConfig.HTTPMethod.get)
        let (data, response) = try await performRequest(request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == APIConfig.HTTPStatus.ok else {
            throw APIError.serverError("Failed to get CSRF token")
        }

        guard let json = try? JSONDecoder().decode([String: String].self, from: data),
              let token = json["csrfToken"] else {
            logger.error("Failed to parse CSRF response", category: .network)
            throw APIError.serverError("Failed to get CSRF token. Server may be unavailable.")
        }

        return token
    }

    private func buildRequest(url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = APIConfig.timeoutInterval
        return request
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await urlSession.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw APIError.timeout
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func performAuthenticatedRequest(
        _ request: URLRequest,
        expectedStatus: Int = APIConfig.HTTPStatus.ok
    ) async throws -> (Data, URLResponse) {
        let (data, response) = try await performRequest(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == APIConfig.HTTPStatus.unauthorized {
            throw APIError.unauthorized
        }

        if httpResponse.statusCode != expectedStatus && httpResponse.statusCode != APIConfig.HTTPStatus.ok {
            throw APIError.serverError("Request failed with status \(httpResponse.statusCode)")
        }

        return (data, response)
    }

    private func decodeResponse<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            logger.error("Decoding failed: \(error.localizedDescription)", category: .network)
            throw APIError.decodingError(error)
        }
    }

    private func handleSessionCookies(from response: HTTPURLResponse) {
        guard let headerFields = response.allHeaderFields as? [String: String],
              let url = response.url else { return }

        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
        cookies.forEach { HTTPCookieStorage.shared.setCookie($0) }

        if let sessionCookie = cookies.first(where: { $0.name.contains("session") }) {
            keychain.sessionCookie = sessionCookie.value
        }
    }

    private func parseErrorResponse(from data: Data) -> APIError? {
        if let errorResponse = try? JSONDecoder().decode([String: [String: String]].self, from: data),
           let errors = errorResponse["errors"],
           let firstError = errors.values.first {
            return .serverError(firstError)
        }

        if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
           let message = errorResponse["message"] {
            return .serverError(message)
        }

        return nil
    }

    // MARK: - Validation

    private func validateCredentials(username: String, password: String) throws {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUsername.isEmpty else {
            throw APIError.validationError("Username is required")
        }

        guard trimmedUsername.count >= 3 else {
            throw APIError.validationError("Username must be at least 3 characters")
        }

        guard trimmedUsername.count <= 50 else {
            throw APIError.validationError("Username must be less than 50 characters")
        }

        // Only allow alphanumeric and underscores
        let usernameRegex = "^[a-zA-Z0-9_]+$"
        guard trimmedUsername.range(of: usernameRegex, options: .regularExpression) != nil else {
            throw APIError.validationError("Username can only contain letters, numbers, and underscores")
        }

        guard !trimmedPassword.isEmpty else {
            throw APIError.validationError("Password is required")
        }

        guard trimmedPassword.count >= 6 else {
            throw APIError.validationError("Password must be at least 6 characters")
        }
    }

    private func validatePasswordMatch(password: String, confirmPassword: String) throws {
        guard password == confirmPassword else {
            throw APIError.validationError("Passwords do not match")
        }
    }

    private func validateDiaryInput(title: String, content: String) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            throw APIError.validationError("Title is required")
        }

        guard trimmedTitle.count <= 200 else {
            throw APIError.validationError("Title must be less than 200 characters")
        }

        guard !trimmedContent.isEmpty else {
            throw APIError.validationError("Content is required")
        }

        guard trimmedContent.count <= 10000 else {
            throw APIError.validationError("Content must be less than 10,000 characters")
        }
    }

    private func isValidID(_ id: String) -> Bool {
        // Validate ID format to prevent injection
        // Allow alphanumeric, hyphens, and underscores only
        let idRegex = "^[a-zA-Z0-9_-]+$"
        return id.range(of: idRegex, options: .regularExpression) != nil && !id.isEmpty
    }
}

// MARK: - String URL Encoding Extension

private extension String {
    var urlEncoded: String {
        self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
            .replacingOccurrences(of: "&", with: "%26")
            .replacingOccurrences(of: "=", with: "%3D")
            .replacingOccurrences(of: "+", with: "%2B")
            ?? self
    }
}
