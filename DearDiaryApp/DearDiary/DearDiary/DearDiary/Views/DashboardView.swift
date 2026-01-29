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
                // Glass background
                GlassBackground(theme: theme)

                VStack(spacing: 0) {
                    // Glass search bar
                    GlassSearchBar(
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
                        GlassEmptyStateView(
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
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)

                        // Diary list with glass cards
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 300), spacing: 20)
                            ], spacing: 20) {
                                ForEach(diaryViewModel.diaries) { diary in
                                    GlassDiaryCard(diary: diary, theme: theme)
                                        .onTapGesture {
                                            selectedDiary = diary
                                        }
                                }
                            }
                            .padding()
                        }

                        // Glass pagination
                        if diaryViewModel.totalPages > 1 {
                            GlassPagination(
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
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(theme.name == "Diary" ? .light : .dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewEntry = true }) {
                        Image(systemName: "square.and.pencil")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .tint(theme.accent)
                }

                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        // Theme submenu
                        Menu {
                            ForEach(DiaryTheme.all, id: \.name) { t in
                                Button(action: {
                                    withAnimation(.spring(response: 0.4)) {
                                        themeManager.setTheme(t)
                                    }
                                }) {
                                    HStack {
                                        Text(t.name)
                                        if themeManager.currentTheme.name == t.name {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label("Theme", systemImage: "paintpalette")
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

// MARK: - Glass Search Bar
struct GlassSearchBar: View {
    @Binding var searchText: String
    let theme: DiaryTheme
    let onSubmit: () -> Void
    let onClear: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.title3)

            TextField("Search your entries...", text: $searchText)
                .textFieldStyle(.plain)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .onSubmit(onSubmit)
                .focused($isFocused)

            if !searchText.isEmpty {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isFocused ? theme.accent.opacity(0.5) : .white.opacity(0.2),
                    lineWidth: isFocused ? 2 : 1
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Glass Empty State
struct GlassEmptyStateView: View {
    let searchText: String
    let theme: DiaryTheme
    let onCreateNew: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 56))
                .foregroundStyle(theme.accent.gradient)
                .shadow(color: theme.accent.opacity(0.3), radius: 10, y: 5)

            Text(searchText.isEmpty ? "No entries yet" : "No entries found")
                .font(.title2)
                .fontWeight(.semibold)

            Text(searchText.isEmpty
                 ? "Start writing your first diary entry"
                 : "Try a different search term")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
                .background(theme.accent.gradient)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .shadow(color: theme.accent.opacity(0.4), radius: 12, y: 6)
            }
        }
        .padding(40)
        .glassCard(theme: theme)
        .padding(.horizontal, 20)
    }
}

// MARK: - Glass Diary Card
struct GlassDiaryCard: View {
    let diary: Diary
    let theme: DiaryTheme
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Date badge
            Text(diary.entryDate.formatted(date: .long, time: .omitted))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(theme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(theme.accent.opacity(0.15).gradient)
                .clipShape(Capsule())

            // Title
            Text(diary.title)
                .font(.headline)
                .lineLimit(2)

            // Content preview
            Text(diary.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.4), .white.opacity(0.1), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: theme.textPrimary.opacity(0.08), radius: 16, y: 8)
        .scaleEffect(isPressed ? 0.97 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Glass Pagination
struct GlassPagination: View {
    let currentPage: Int
    let totalPages: Int
    let theme: DiaryTheme
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .fontWeight(.semibold)
                    .frame(width: 44, height: 44)
            }
            .disabled(currentPage <= 1)
            .opacity(currentPage <= 1 ? 0.4 : 1)

            Text("Page \(currentPage) of \(totalPages)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .fontWeight(.semibold)
                    .frame(width: 44, height: 44)
            }
            .disabled(currentPage >= totalPages)
            .opacity(currentPage >= totalPages ? 0.4 : 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
        }
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.2), lineWidth: 1)
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthViewModel())
        .environmentObject(ThemeManager.shared)
}
