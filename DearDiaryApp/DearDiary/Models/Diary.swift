import Foundation

struct Diary: Codable, Identifiable {
    let id: String
    let title: String
    let content: String
    let entryDate: Date
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, content, entryDate, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let entryDateString = try container.decode(String.self, forKey: .entryDate)
        entryDate = dateFormatter.date(from: entryDateString) ?? Date()

        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        createdAt = dateFormatter.date(from: createdAtString) ?? Date()

        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
    }

    init(id: String, title: String, content: String, entryDate: Date, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.title = title
        self.content = content
        self.entryDate = entryDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct DiaryRequest: Codable {
    let title: String
    let content: String
    let entryDate: String
}

struct DiaryListResponse: Codable {
    let diaries: [Diary]
    let pagination: Pagination
}

struct Pagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
}
