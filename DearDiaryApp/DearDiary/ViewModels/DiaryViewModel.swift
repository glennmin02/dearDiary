import Foundation
import SwiftUI

@MainActor
class DiaryViewModel: ObservableObject {
    @Published var diaries: [Diary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var currentPage = 1
    @Published var totalPages = 1
    @Published var totalEntries = 0

    func fetchDiaries(page: Int = 1) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIService.shared.fetchDiaries(page: page, search: searchText)
            diaries = response.diaries
            currentPage = response.pagination.page
            totalPages = response.pagination.totalPages
            totalEntries = response.pagination.total
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func createDiary(title: String, content: String, entryDate: Date) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let _ = try await APIService.shared.createDiary(title: title, content: content, entryDate: entryDate)
            await fetchDiaries()
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            isLoading = false
            return false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func updateDiary(id: String, title: String, content: String, entryDate: Date) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let _ = try await APIService.shared.updateDiary(id: id, title: title, content: content, entryDate: entryDate)
            await fetchDiaries()
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            isLoading = false
            return false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func deleteDiary(id: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await APIService.shared.deleteDiary(id: id)
            await fetchDiaries()
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            isLoading = false
            return false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

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
        if currentPage < totalPages {
            await fetchDiaries(page: currentPage + 1)
        }
    }

    func previousPage() async {
        if currentPage > 1 {
            await fetchDiaries(page: currentPage - 1)
        }
    }
}
