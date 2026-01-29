import Foundation

// MARK: - Diary Model

struct Diary: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let content: String
    let entryDate: Date
    let createdAt: Date
    let updatedAt: Date

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id, title, content, entryDate, createdAt, updatedAt
    }

    // MARK: - Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)

        // Parse dates with proper error handling
        let entryDateString = try container.decode(String.self, forKey: .entryDate)
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)

        entryDate = try Self.parseDate(entryDateString, fieldName: "entryDate")
        createdAt = try Self.parseDate(createdAtString, fieldName: "createdAt")
        updatedAt = try Self.parseDate(updatedAtString, fieldName: "updatedAt")
    }

    // MARK: - Encoding

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        try container.encode(formatter.string(from: entryDate), forKey: .entryDate)
        try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(formatter.string(from: updatedAt), forKey: .updatedAt)
    }

    // MARK: - Manual Initialization

    init(id: String, title: String, content: String, entryDate: Date, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.title = title
        self.content = content
        self.entryDate = entryDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Date Parsing

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601FormatterNoFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    /// Parses a date string with multiple format fallbacks
    /// - Parameters:
    ///   - dateString: The date string to parse
    ///   - fieldName: The field name for error reporting
    /// - Returns: The parsed Date
    /// - Throws: DecodingError if parsing fails with all formatters
    private static func parseDate(_ dateString: String, fieldName: String) throws -> Date {
        // Try ISO8601 with fractional seconds
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }

        // Try ISO8601 without fractional seconds
        if let date = iso8601FormatterNoFractional.date(from: dateString) {
            return date
        }

        // Try date-only format
        if let date = dateOnlyFormatter.date(from: dateString) {
            return date
        }

        // All parsing attempts failed
        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [CodingKeys(stringValue: fieldName)!],
                debugDescription: "Invalid date format for \(fieldName): \(dateString)"
            )
        )
    }

    // MARK: - Equatable

    static func == (lhs: Diary, rhs: Diary) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Diary Request (for create/update)

struct DiaryRequest: Codable {
    let title: String
    let content: String
    let entryDate: String

    // Validation constants
    enum Limits {
        static let maxTitleLength = 200
        static let maxContentLength = 10_000
    }
}

// MARK: - Diary List Response

struct DiaryListResponse: Codable {
    let diaries: [Diary]
    let pagination: Pagination
}

// MARK: - Pagination

struct Pagination: Codable, Equatable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int

    var hasNextPage: Bool {
        page < totalPages
    }

    var hasPreviousPage: Bool {
        page > 1
    }
}
