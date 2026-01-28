import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case decodingError
    case networkError(Error)

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
            return "Failed to process response"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

class APIService {
    static let shared = APIService()

    // IMPORTANT: Update this to your Vercel deployment URL
    private let baseURL = "https://deardiary.vercel.app"

    private var authToken: String? {
        get { UserDefaults.standard.string(forKey: "authToken") }
        set { UserDefaults.standard.set(newValue, forKey: "authToken") }
    }

    private var sessionCookie: String? {
        get { UserDefaults.standard.string(forKey: "sessionCookie") }
        set { UserDefaults.standard.set(newValue, forKey: "sessionCookie") }
    }

    private init() {}

    // MARK: - Auth

    func login(username: String, password: String) async throws -> Bool {
        let url = URL(string: "\(baseURL)/api/auth/callback/credentials")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // First get CSRF token
        let csrfURL = URL(string: "\(baseURL)/api/auth/csrf")!
        let (csrfData, _) = try await URLSession.shared.data(from: csrfURL)
        let csrfResponse = try JSONDecoder().decode([String: String].self, from: csrfData)
        guard let csrfToken = csrfResponse["csrfToken"] else {
            throw APIError.serverError("Failed to get CSRF token")
        }

        let body = "username=\(username)&password=\(password)&csrfToken=\(csrfToken)"
        request.httpBody = body.data(using: .utf8)

        let (_, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            // Store cookies for session
            if let headerFields = httpResponse.allHeaderFields as? [String: String],
               let url = httpResponse.url {
                let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
                for cookie in cookies {
                    HTTPCookieStorage.shared.setCookie(cookie)
                }
                if let sessionCookie = cookies.first(where: { $0.name.contains("session") }) {
                    self.sessionCookie = sessionCookie.value
                }
            }
            return httpResponse.statusCode == 200 || httpResponse.statusCode == 302
        }
        return false
    }

    func register(username: String, password: String, confirmPassword: String) async throws {
        let url = URL(string: "\(baseURL)/api/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = RegisterRequest(username: username, password: password, confirmPassword: confirmPassword)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 201 {
            return
        }

        if let errorResponse = try? JSONDecoder().decode([String: [String: String]].self, from: data),
           let errors = errorResponse["errors"],
           let firstError = errors.values.first {
            throw APIError.serverError(firstError)
        }

        if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
           let message = errorResponse["message"] {
            throw APIError.serverError(message)
        }

        throw APIError.serverError("Registration failed")
    }

    func logout() {
        sessionCookie = nil
        authToken = nil
        HTTPCookieStorage.shared.cookies?.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
    }

    // MARK: - Diaries

    func fetchDiaries(page: Int = 1, search: String = "") async throws -> DiaryListResponse {
        var urlString = "\(baseURL)/api/diaries?page=\(page)&limit=20"
        if !search.isEmpty {
            urlString += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? search)"
        }

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Failed to fetch diaries")
        }

        return try JSONDecoder().decode(DiaryListResponse.self, from: data)
    }

    func fetchDiary(id: String) async throws -> Diary {
        guard let url = URL(string: "\(baseURL)/api/diaries/\(id)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Failed to fetch diary")
        }

        return try JSONDecoder().decode(Diary.self, from: data)
    }

    func createDiary(title: String, content: String, entryDate: Date) async throws -> Diary {
        guard let url = URL(string: "\(baseURL)/api/diaries") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let body = DiaryRequest(
            title: title,
            content: content,
            entryDate: dateFormatter.string(from: entryDate)
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        if httpResponse.statusCode != 201 {
            throw APIError.serverError("Failed to create diary")
        }

        return try JSONDecoder().decode(Diary.self, from: data)
    }

    func updateDiary(id: String, title: String, content: String, entryDate: Date) async throws -> Diary {
        guard let url = URL(string: "\(baseURL)/api/diaries/\(id)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let body = DiaryRequest(
            title: title,
            content: content,
            entryDate: dateFormatter.string(from: entryDate)
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Failed to update diary")
        }

        return try JSONDecoder().decode(Diary.self, from: data)
    }

    func deleteDiary(id: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/diaries/\(id)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Failed to delete diary")
        }
    }
}
