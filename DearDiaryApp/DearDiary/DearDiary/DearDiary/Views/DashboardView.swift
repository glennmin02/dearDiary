import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var diaryViewModel = DiaryViewModel()
    @State private var showingNewEntry = false
    @State private var selectedDiary: Diary?

    private var theme: DiaryTheme { themeManager.currentTheme }

    var body: some View {
        NavigationStack {
            ZStack {
                // Solid background
                theme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    SearchBar(
                        searchText: $diaryViewModel.searchText,
                        theme: theme,
                        onSubmit: {
                            Task { await diaryViewModel.search() }
                        },
                        onClear: {
                            Task { await diaryViewModel.clearSearch() }
                        }
                    )
                    .padding()

                    // Content
                    if diaryViewModel.isLoading && diaryViewModel.diaries.isEmpty {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(theme.accent)
                        Spacer()
                    } else if diaryViewModel.diaries.isEmpty {
                        Spacer()
                        EmptyStateView(
                            searchText: diaryViewModel.searchText,
                            theme: theme
                        ) {
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
                                .foregroundColor(theme.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal)

                        // Diary list
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 300), spacing: 16)
                            ], spacing: 16) {
                                ForEach(diaryViewModel.diaries) { diary in
                                    DiaryCard(diary: diary, theme: theme)
                                        .onTapGesture {
                                            selectedDiary = diary
                                        }
                                }
                            }
                            .padding()
                        }

                        // Pagination
                        if diaryViewModel.totalPages > 1 {
                            PaginationView(
                                currentPage: diaryViewModel.currentPage,
                                totalPages: diaryViewModel.totalPages,
                                theme: theme,
                                onPrevious: {
                                    Task { await diaryViewModel.previousPage() }
                                },
                                onNext: {
                                    Task { await diaryViewModel.nextPage() }
                                }
                            )
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Dear Diary")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbarBackground(theme.cardBackground, for: .navigationBar)
            .toolbarColorScheme(theme.isDark ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewEntry = true }) {
                        Image(systemName: "square.and.pencil")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .tint(theme.accent)
                    .accessibilityLabel("New entry")
                }

                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: {
                            themeManager.toggleTheme()
                        }) {
                            Label(
                                theme.isDark ? "Light Mode" : "Dark Mode",
                                systemImage: theme.isDark ? "sun.max.fill" : "moon.fill"
                            )
                        }

                        Divider()

                        Button(role: .destructive, action: {
                            authViewModel.logout()
                        }) {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                    }
                    .tint(theme.accent)
                }
                #endif
            }
            .sheet(isPresented: $showingNewEntry) {
                DiaryFormView(diaryViewModel: diaryViewModel)
                    .environmentObject(themeManager)
            }
            .sheet(item: $selectedDiary) { diary in
                DiaryDetailView(diary: diary, diaryViewModel: diaryViewModel)
                    .environmentObject(themeManager)
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

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var searchText: String
    let theme: DiaryTheme
    let onSubmit: () -> Void
    let onClear: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.textTertiary)
                .font(.body)

            TextField("Search your entries...", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundColor(theme.textPrimary)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .onSubmit(onSubmit)
                .focused($isFocused)

            if !searchText.isEmpty {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? theme.accent : theme.border, lineWidth: isFocused ? 2 : 1)
        )
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let searchText: String
    let theme: DiaryTheme
    let onCreateNew: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 48))
                .foregroundColor(theme.accent)

            Text(searchText.isEmpty ? "No entries yet" : "No entries found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(theme.textPrimary)

            Text(searchText.isEmpty
                 ? "Start writing your first diary entry"
                 : "Try a different search term")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)

            if searchText.isEmpty {
                Button(action: onCreateNew) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Write Your First Entry")
                    }
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                }
                .background(theme.accent)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
        .padding(40)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.border, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Diary Card
struct DiaryCard: View {
    let diary: Diary
    let theme: DiaryTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date badge
            Text(diary.entryDate.formatted(date: .long, time: .omitted))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(theme.accentLight)
                .clipShape(Capsule())

            // Title
            Text(diary.title)
                .font(.headline)
                .foregroundColor(theme.textPrimary)
                .lineLimit(2)

            // Content preview
            Text(diary.content)
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .lineLimit(3)

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.border, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Diary entry: \(diary.title)")
        .accessibilityHint("Double tap to view")
    }
}

// MARK: - Pagination
struct PaginationView: View {
    let currentPage: Int
    let totalPages: Int
    let theme: DiaryTheme
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .fontWeight(.semibold)
                    .frame(width: 44, height: 44)
            }
            .disabled(currentPage <= 1)
            .opacity(currentPage <= 1 ? 0.4 : 1)
            .foregroundColor(theme.textPrimary)

            Text("Page \(currentPage) of \(totalPages)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.textSecondary)

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .fontWeight(.semibold)
                    .frame(width: 44, height: 44)
            }
            .disabled(currentPage >= totalPages)
            .opacity(currentPage >= totalPages ? 0.4 : 1)
            .foregroundColor(theme.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(theme.cardBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(theme.border, lineWidth: 1)
        )
    }
}

// MARK: - Legacy Support
struct GlassSearchBar: View {
    @Binding var searchText: String
    let theme: DiaryTheme
    let onSubmit: () -> Void
    let onClear: () -> Void

    var body: some View {
        SearchBar(searchText: $searchText, theme: theme, onSubmit: onSubmit, onClear: onClear)
    }
}

struct GlassEmptyStateView: View {
    let searchText: String
    let theme: DiaryTheme
    let onCreateNew: () -> Void

    var body: some View {
        EmptyStateView(searchText: searchText, theme: theme, onCreateNew: onCreateNew)
    }
}

struct GlassDiaryCard: View {
    let diary: Diary
    let theme: DiaryTheme

    var body: some View {
        DiaryCard(diary: diary, theme: theme)
    }
}

struct GlassPagination: View {
    let currentPage: Int
    let totalPages: Int
    let theme: DiaryTheme
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        PaginationView(currentPage: currentPage, totalPages: totalPages, theme: theme, onPrevious: onPrevious, onNext: onNext)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthViewModel())
        .environmentObject(ThemeManager.shared)
}
