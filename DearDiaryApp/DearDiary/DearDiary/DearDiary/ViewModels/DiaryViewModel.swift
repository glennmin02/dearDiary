import Foundation
import SwiftUI
import Combine

/// ViewModel responsible for diary entries management
/// Uses @MainActor to ensure all UI updates happen on the main thread
@MainActor
final class DiaryViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var diaries: [Diary] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published private(set) var currentPage = 1
    @Published private(set) var totalPages = 1
    @Published private(set) var totalEntries = 0

    // MARK: - Private Properties

    private let apiService: APIService
    private let logger: Logger

    // MARK: - Initialization

    init(apiService: APIService = .shared, logger: Logger = .shared) {
        self.apiService = apiService
        self.logger = logger
    }

    // MARK: - Fetch Operations

    func fetchDiaries(page: Int = 1) async {
        await performOperation {
            let response = try await apiService.fetchDiaries(page: page, search: searchText)
            diaries = response.diaries
            currentPage = response.pagination.page
            totalPages = response.pagination.totalPages
            totalEntries = response.pagination.total
            logger.info("Fetched \(response.diaries.count) diaries", category: .network)
        }
    }

    // MARK: - CRUD Operations

    func createDiary(title: String, content: String, entryDate: Date) async -> Bool {
        await performOperation(refreshAfter: true) {
            _ = try await apiService.createDiary(title: title, content: content, entryDate: entryDate)
            logger.info("Created new diary entry", category: .network)
        }
    }

    func updateDiary(id: String, title: String, content: String, entryDate: Date) async -> Bool {
        await performOperation(refreshAfter: true) {
            _ = try await apiService.updateDiary(id: id, title: title, content: content, entryDate: entryDate)
            logger.info("Updated diary entry: \(id)", category: .network)
        }
    }

    func deleteDiary(id: String) async -> Bool {
        await performOperation(refreshAfter: true) {
            try await apiService.deleteDiary(id: id)
            logger.info("Deleted diary entry: \(id)", category: .network)
        }
    }

    // MARK: - Search & Pagination

    func search() async {
        currentPage = 1
        await fetchDiaries()
    }

    func clearSearch() async {
        searchText = ""
        currentPage = 1
        await fetchDiaries()
    }

    func nextPage() async {
        guard currentPage < totalPages else { return }
        await fetchDiaries(page: currentPage + 1)
    }

    func previousPage() async {
        guard currentPage > 1 else { return }
        await fetchDiaries(page: currentPage - 1)
    }

    // MARK: - Error Handling

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Helpers

    /// Unified operation handler that reduces code duplication
    /// - Parameters:
    ///   - refreshAfter: Whether to refresh the diary list after successful operation
    ///   - operation: The async operation to perform
    /// - Returns: Boolean indicating success
    @discardableResult
    private func performOperation(
        refreshAfter: Bool = false,
        operation: () async throws -> Void
    ) async -> Bool {
        guard !isLoading else {
            logger.warning("Operation blocked: already loading", category: .network)
            return false
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            try await operation()

            if refreshAfter {
                // Refresh the list but don't set isLoading again
                let response = try await apiService.fetchDiaries(page: currentPage, search: searchText)
                diaries = response.diaries
                currentPage = response.pagination.page
                totalPages = response.pagination.totalPages
                totalEntries = response.pagination.total
            }

            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            logger.error("Operation failed: \(error.errorDescription ?? "Unknown")", category: .network)
            return false
        } catch {
            errorMessage = "An unexpected error occurred"
            logger.error("Unexpected error: \(error.localizedDescription)", category: .network)
            return false
        }
    }
}
