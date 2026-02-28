import SwiftUI
#if os(iOS)
import UIKit
#endif

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var diaryViewModel = DiaryViewModel()
    @State private var showingNewEntry = false
    @State private var selectedDiary: Diary?
    @State private var diaryToExport: Diary?
    @State private var showingExportSheet = false
    @State private var exportPDFData: Data?

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
                                    DiaryCard(diary: diary, theme: theme, onExport: {
                                        diaryToExport = diary
                                        #if os(iOS)
                                        exportPDFData = generatePDF(for: diary)
                                        showingExportSheet = true
                                        #endif
                                    })
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
            #if os(iOS)
            .sheet(isPresented: $showingExportSheet) {
                if let pdfData = exportPDFData, let diary = diaryToExport {
                    DashboardShareSheet(activityItems: [pdfData], filename: pdfFilename(for: diary))
                }
            }
            #endif
            .task {
                await diaryViewModel.fetchDiaries()
            }
            .refreshable {
                await diaryViewModel.fetchDiaries()
            }
        }
    }

    #if os(iOS)
    private func pdfFilename(for diary: Diary) -> String {
        let sanitizedTitle = diary.title
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .prefix(50)
        let dateString = diary.entryDate.formatted(.dateTime.year().month().day())
        return "\(sanitizedTitle) - \(dateString).pdf"
    }

    private func generatePDF(for diary: Diary) -> Data {
        // A4 dimensions in points (72 DPI)
        let pageWidth: CGFloat = 595.276
        let pageHeight: CGFloat = 841.890

        // Narrow margins (0.5 inch = 36 points)
        let margin: CGFloat = 36
        let contentWidth = pageWidth - (margin * 2)
        let footerHeight: CGFloat = 24

        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        // Calculate total pages first
        let totalPages = calculateTotalPages(for: diary, pageWidth: pageWidth, pageHeight: pageHeight, margin: margin, contentWidth: contentWidth, footerHeight: footerHeight)

        let data = renderer.pdfData { context in
            // Fonts
            let titleFont = UIFont(name: "PlayfairDisplay-Bold", size: 24) ?? UIFont.boldSystemFont(ofSize: 24)
            let dateFont = UIFont.systemFont(ofSize: 12, weight: .medium)
            let metadataFont = UIFont.systemFont(ofSize: 10)
            let contentFont = UIFont.systemFont(ofSize: 12)
            let pageNumberFont = UIFont.systemFont(ofSize: 10)

            // Colors
            let textColor = UIColor(red: 0.067, green: 0.094, blue: 0.153, alpha: 1)
            let accentColor = UIColor(red: 0.490, green: 0.388, blue: 0.251, alpha: 1)
            let metadataColor = UIColor(red: 0.420, green: 0.447, blue: 0.502, alpha: 1)

            // Paragraph styles
            let titleParagraphStyle = NSMutableParagraphStyle()
            titleParagraphStyle.lineSpacing = 4

            let contentParagraphStyle = NSMutableParagraphStyle()
            contentParagraphStyle.lineSpacing = 6

            // Attributes
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: textColor,
                .paragraphStyle: titleParagraphStyle
            ]

            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: dateFont,
                .foregroundColor: accentColor
            ]

            let metadataAttributes: [NSAttributedString.Key: Any] = [
                .font: metadataFont,
                .foregroundColor: metadataColor
            ]

            let contentAttributes: [NSAttributedString.Key: Any] = [
                .font: contentFont,
                .foregroundColor: textColor,
                .paragraphStyle: contentParagraphStyle
            ]

            let pageNumberAttributes: [NSAttributedString.Key: Any] = [
                .font: pageNumberFont,
                .foregroundColor: metadataColor
            ]

            // Format strings
            let dateText = diary.entryDate.formatted(date: .complete, time: .omitted)
            let titleText = diary.title
            let createdText = "Created: \(diary.createdAt.formatted(date: .abbreviated, time: .shortened))"
            let updatedText = diary.updatedAt != diary.createdAt
                ? "  •  Updated: \(diary.updatedAt.formatted(date: .abbreviated, time: .shortened))"
                : ""
            let metadataText = createdText + updatedText

            // Calculate sizes
            let dateSize = dateText.boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: dateAttributes, context: nil)
            let titleSize = titleText.boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: titleAttributes, context: nil)
            let metadataSize = metadataText.boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: metadataAttributes, context: nil)

            let contentText = diary.content as NSString
            var currentLocation = 0
            let totalLength = contentText.length
            var currentPageNumber = 0

            func drawPageNumber(_ pageNum: Int) {
                let pageNumberText = "Page \(pageNum) of \(totalPages)"
                let pageNumberSize = pageNumberText.boundingRect(with: CGSize(width: contentWidth, height: footerHeight), options: .usesLineFragmentOrigin, attributes: pageNumberAttributes, context: nil)
                let xPosition = (pageWidth - pageNumberSize.width) / 2
                let yPosition = pageHeight - margin
                pageNumberText.draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: pageNumberAttributes)
            }

            if totalLength == 0 {
                context.beginPage()
                currentPageNumber += 1
                var yPosition = margin

                dateText.draw(in: CGRect(x: margin, y: yPosition, width: contentWidth, height: dateSize.height), withAttributes: dateAttributes)
                yPosition += dateSize.height + 12
                titleText.draw(in: CGRect(x: margin, y: yPosition, width: contentWidth, height: titleSize.height), withAttributes: titleAttributes)
                yPosition += titleSize.height + 8
                metadataText.draw(in: CGRect(x: margin, y: yPosition, width: contentWidth, height: metadataSize.height), withAttributes: metadataAttributes)
                yPosition += metadataSize.height + 16

                let dividerPath = UIBezierPath()
                dividerPath.move(to: CGPoint(x: margin, y: yPosition))
                dividerPath.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
                UIColor(red: 0.910, green: 0.875, blue: 0.816, alpha: 1).setStroke()
                dividerPath.lineWidth = 1
                dividerPath.stroke()

                drawPageNumber(currentPageNumber)
            }

            while currentLocation < totalLength {
                context.beginPage()
                currentPageNumber += 1
                var yPosition = margin

                if currentLocation == 0 {
                    dateText.draw(in: CGRect(x: margin, y: yPosition, width: contentWidth, height: dateSize.height), withAttributes: dateAttributes)
                    yPosition += dateSize.height + 12
                    titleText.draw(in: CGRect(x: margin, y: yPosition, width: contentWidth, height: titleSize.height), withAttributes: titleAttributes)
                    yPosition += titleSize.height + 8
                    metadataText.draw(in: CGRect(x: margin, y: yPosition, width: contentWidth, height: metadataSize.height), withAttributes: metadataAttributes)
                    yPosition += metadataSize.height + 16

                    let dividerPath = UIBezierPath()
                    dividerPath.move(to: CGPoint(x: margin, y: yPosition))
                    dividerPath.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
                    UIColor(red: 0.910, green: 0.875, blue: 0.816, alpha: 1).setStroke()
                    dividerPath.lineWidth = 1
                    dividerPath.stroke()
                    yPosition += 16
                }

                let availableHeight = pageHeight - yPosition - margin - footerHeight
                let remainingText = contentText.substring(from: currentLocation)
                let layoutManager = NSLayoutManager()
                let textContainer = NSTextContainer(size: CGSize(width: contentWidth, height: availableHeight))
                let textStorage = NSTextStorage(string: remainingText, attributes: contentAttributes)

                layoutManager.addTextContainer(textContainer)
                textStorage.addLayoutManager(layoutManager)

                let glyphRange = layoutManager.glyphRange(for: textContainer)
                let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

                let textToDraw = (remainingText as NSString).substring(with: NSRange(location: 0, length: characterRange.length))
                textToDraw.draw(in: CGRect(x: margin, y: yPosition, width: contentWidth, height: availableHeight), withAttributes: contentAttributes)

                currentLocation += characterRange.length
                drawPageNumber(currentPageNumber)

                if characterRange.length == 0 { break }
            }
        }

        return data
    }

    private func calculateTotalPages(for diary: Diary, pageWidth: CGFloat, pageHeight: CGFloat, margin: CGFloat, contentWidth: CGFloat, footerHeight: CGFloat) -> Int {
        let contentFont = UIFont.systemFont(ofSize: 12)
        let titleFont = UIFont(name: "PlayfairDisplay-Bold", size: 24) ?? UIFont.boldSystemFont(ofSize: 24)
        let dateFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        let metadataFont = UIFont.systemFont(ofSize: 10)

        let contentParagraphStyle = NSMutableParagraphStyle()
        contentParagraphStyle.lineSpacing = 6

        let contentAttributes: [NSAttributedString.Key: Any] = [.font: contentFont, .paragraphStyle: contentParagraphStyle]
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont]
        let dateAttributes: [NSAttributedString.Key: Any] = [.font: dateFont]
        let metadataAttributes: [NSAttributedString.Key: Any] = [.font: metadataFont]

        let dateText = diary.entryDate.formatted(date: .complete, time: .omitted)
        let titleText = diary.title
        let createdText = "Created: \(diary.createdAt.formatted(date: .abbreviated, time: .shortened))"
        let updatedText = diary.updatedAt != diary.createdAt ? "  •  Updated: \(diary.updatedAt.formatted(date: .abbreviated, time: .shortened))" : ""
        let metadataText = createdText + updatedText

        let dateSize = dateText.boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: dateAttributes, context: nil)
        let titleSize = titleText.boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: titleAttributes, context: nil)
        let metadataSize = metadataText.boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: metadataAttributes, context: nil)

        let headerHeight = dateSize.height + 12 + titleSize.height + 8 + metadataSize.height + 16 + 16

        let contentText = diary.content as NSString
        let totalLength = contentText.length

        if totalLength == 0 { return 1 }

        var pageCount = 0
        var currentLocation = 0

        while currentLocation < totalLength {
            pageCount += 1
            let yPosition: CGFloat = currentLocation == 0 ? (margin + headerHeight) : margin
            let availableHeight = pageHeight - yPosition - margin - footerHeight

            let remainingText = contentText.substring(from: currentLocation)
            let layoutManager = NSLayoutManager()
            let textContainer = NSTextContainer(size: CGSize(width: contentWidth, height: availableHeight))
            let textStorage = NSTextStorage(string: remainingText, attributes: contentAttributes)

            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)

            let glyphRange = layoutManager.glyphRange(for: textContainer)
            let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

            currentLocation += characterRange.length
            if characterRange.length == 0 { break }
        }

        return max(1, pageCount)
    }
    #endif
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
    var onExport: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with date and export button
            HStack {
                // Date badge
                Text(diary.entryDate.formatted(date: .long, time: .omitted))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(theme.accentLight)
                    .clipShape(Capsule())

                Spacer()

                #if os(iOS)
                if let onExport = onExport {
                    Button(action: onExport) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.subheadline)
                            .foregroundColor(theme.accent)
                            .padding(8)
                            .background(theme.accentLight)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                #endif
            }

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
    var onExport: (() -> Void)?

    var body: some View {
        DiaryCard(diary: diary, theme: theme, onExport: onExport)
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

// MARK: - Share Sheet for Dashboard
#if os(iOS)
struct DashboardShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let filename: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        if let pdfData = activityItems.first as? Data {
            try? pdfData.write(to: tempURL)
        }

        let controller = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )

        controller.completionWithItemsHandler = { _, _, _, _ in
            try? FileManager.default.removeItem(at: tempURL)
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

#Preview {
    DashboardView()
        .environmentObject(AuthViewModel())
        .environmentObject(ThemeManager.shared)
}
