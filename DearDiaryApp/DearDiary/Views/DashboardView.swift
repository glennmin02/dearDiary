import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var diaryViewModel = DiaryViewModel()
    @State private var showingNewEntry = false
    @State private var selectedDiary: Diary?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search your entries...", text: $diaryViewModel.searchText)
                        .textFieldStyle(.plain)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .onSubmit {
                            Task { await diaryViewModel.search() }
                        }

                    if !diaryViewModel.searchText.isEmpty {
                        Button(action: {
                            Task { await diaryViewModel.clearSearch() }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()

                // Content
                if diaryViewModel.isLoading && diaryViewModel.diaries.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if diaryViewModel.diaries.isEmpty {
                    Spacer()
                    EmptyStateView(searchText: diaryViewModel.searchText) {
                        showingNewEntry = true
                    }
                    Spacer()
                } else {
                    // Stats
                    HStack {
                        Text(diaryViewModel.searchText.isEmpty
                             ? "You have \(diaryViewModel.totalEntries) \(diaryViewModel.totalEntries == 1 ? "entry" : "entries")"
                             : "Found \(diaryViewModel.totalEntries) \(diaryViewModel.totalEntries == 1 ? "entry" : "entries")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Diary list
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 280), spacing: 16)
                        ], spacing: 16) {
                            ForEach(diaryViewModel.diaries) { diary in
                                DiaryCardView(diary: diary)
                                    .onTapGesture {
                                        selectedDiary = diary
                                    }
                            }
                        }
                        .padding()
                    }

                    // Pagination
                    if diaryViewModel.totalPages > 1 {
                        HStack {
                            Button(action: {
                                Task { await diaryViewModel.previousPage() }
                            }) {
                                Label("Previous", systemImage: "chevron.left")
                            }
                            .disabled(diaryViewModel.currentPage <= 1)

                            Text("Page \(diaryViewModel.currentPage) of \(diaryViewModel.totalPages)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)

                            Button(action: {
                                Task { await diaryViewModel.nextPage() }
                            }) {
                                Label("Next", systemImage: "chevron.right")
                            }
                            .disabled(diaryViewModel.currentPage >= diaryViewModel.totalPages)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Dear Diary")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewEntry = true }) {
                        Label("New Entry", systemImage: "square.and.pencil")
                    }
                }

                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(role: .destructive, action: {
                            authViewModel.logout()
                        }) {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingNewEntry) {
                DiaryFormView(diaryViewModel: diaryViewModel)
            }
            .sheet(item: $selectedDiary) { diary in
                DiaryDetailView(diary: diary, diaryViewModel: diaryViewModel)
            }
            .task {
                await diaryViewModel.fetchDiaries()
            }
            .refreshable {
                await diaryViewModel.fetchDiaries()
            }
        }
    }
}

struct EmptyStateView: View {
    let searchText: String
    let onCreateNew: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(searchText.isEmpty ? "No entries yet" : "No entries found")
                .font(.headline)

            Text(searchText.isEmpty
                 ? "Start writing your first diary entry"
                 : "Try a different search term")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if searchText.isEmpty {
                Button("Write Your First Entry", action: onCreateNew)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

struct DiaryCardView: View {
    let diary: Diary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date badge
            Text(diary.entryDate.formatted(date: .long, time: .omitted))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(12)

            // Title
            Text(diary.title)
                .font(.headline)
                .lineLimit(2)

            // Content preview
            Text(diary.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthViewModel())
}
