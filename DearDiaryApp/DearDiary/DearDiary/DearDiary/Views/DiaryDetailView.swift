import SwiftUI
#if os(iOS)
import UIKit
#endif

struct DiaryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    let diary: Diary
    @ObservedObject var diaryViewModel: DiaryViewModel

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    @State private var showingShareSheet = false
    @State private var pdfData: Data?

    private var theme: DiaryTheme { themeManager.currentTheme }

    private var pdfFilename: String {
        let sanitizedTitle = diary.title
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .prefix(50)
        let dateString = diary.entryDate.formatted(.dateTime.year().month().day())
        return "\(sanitizedTitle) - \(dateString).pdf"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Date badge
                        Text(diary.entryDate.formatted(date: .complete, time: .omitted))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(theme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(theme.accentLight)
                            .clipShape(Capsule())

                        // Title
                        Text(diary.title)
                            .font(.playfairBold(size: 28, relativeTo: .title))
                            .foregroundColor(theme.textPrimary)

                        // Metadata
                        HStack(spacing: 16) {
                            Label(
                                "Created \(diary.createdAt.formatted(date: .abbreviated, time: .shortened))",
                                systemImage: "clock"
                            )
                            .font(.caption)
                            .foregroundColor(theme.textTertiary)

                            if diary.updatedAt != diary.createdAt {
                                Label(
                                    "Updated \(diary.updatedAt.formatted(date: .abbreviated, time: .shortened))",
                                    systemImage: "pencil"
                                )
                                .font(.caption)
                                .foregroundColor(theme.textTertiary)
                            }
                        }

                        Divider()
                            .background(theme.divider)

                        // Content
                        Text(diary.content)
                            .font(.body)
                            .foregroundColor(theme.textPrimary)
                            .lineSpacing(8)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.border, lineWidth: 1)
                    )
                    .padding()
                }
            }
            .navigationTitle("Entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbarBackground(theme.cardBackground, for: .navigationBar)
            .toolbarColorScheme(theme.isDark ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.accent)
                    .fontWeight(.medium)
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    #if os(iOS)
                    Button(action: { exportToPDF() }) {
                        Image(systemName: "square.and.arrow.up")
                            .fontWeight(.medium)
                    }
                    .tint(theme.accent)
                    #endif

                    Button(action: { showingEditSheet = true }) {
                        Image(systemName: "pencil")
                            .fontWeight(.medium)
                    }
                    .tint(theme.accent)

                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .fontWeight(.medium)
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                DiaryFormView(diaryViewModel: diaryViewModel, diary: diary)
                    .environmentObject(themeManager)
            }
            .alert("Delete Entry?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task { await deleteDiary() }
                }
            } message: {
                Text("This action cannot be undone. This entry will be permanently deleted.")
            }
            #if os(iOS)
            .sheet(isPresented: $showingShareSheet) {
                if let pdfData = pdfData {
                    ShareSheet(activityItems: [pdfData], filename: pdfFilename)
                }
            }
            #endif
        }
    }

    private func deleteDiary() async {
        isDeleting = true
        let success = await diaryViewModel.deleteDiary(id: diary.id)
        isDeleting = false

        if success {
            dismiss()
        }
    }

    #if os(iOS)
    private func exportToPDF() {
        pdfData = generatePDF()
        showingShareSheet = true
    }

    private func generatePDF() -> Data {
        // A4 dimensions in points (72 DPI)
        let pageWidth: CGFloat = 595.276
        let pageHeight: CGFloat = 841.890

        // Narrow margins (0.5 inch = 36 points)
        let margin: CGFloat = 36
        let contentWidth = pageWidth - (margin * 2)
        let footerHeight: CGFloat = 24 // Space for page numbers

        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        // First pass: calculate total pages
        let totalPages = calculateTotalPages(
            pageWidth: pageWidth,
            pageHeight: pageHeight,
            margin: margin,
            contentWidth: contentWidth,
            footerHeight: footerHeight
        )

        let data = renderer.pdfData { context in
            // Fonts
            let titleFont = UIFont(name: "PlayfairDisplay-Bold", size: 24) ?? UIFont.boldSystemFont(ofSize: 24)
            let dateFont = UIFont.systemFont(ofSize: 12, weight: .medium)
            let metadataFont = UIFont.systemFont(ofSize: 10)
            let contentFont = UIFont.systemFont(ofSize: 12)
            let pageNumberFont = UIFont.systemFont(ofSize: 10)

            // Colors
            let textColor = UIColor(red: 0.067, green: 0.094, blue: 0.153, alpha: 1) // #111827
            let accentColor = UIColor(red: 0.490, green: 0.388, blue: 0.251, alpha: 1) // #7D6340
            let metadataColor = UIColor(red: 0.420, green: 0.447, blue: 0.502, alpha: 1) // #6B7280

            // Paragraph styles
            let titleParagraphStyle = NSMutableParagraphStyle()
            titleParagraphStyle.lineSpacing = 4

            let contentParagraphStyle = NSMutableParagraphStyle()
            contentParagraphStyle.lineSpacing = 6

            // Prepare text attributes
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

            // Format strings
            let dateText = diary.entryDate.formatted(date: .complete, time: .omitted)
            let titleText = diary.title
            let createdText = "Created: \(diary.createdAt.formatted(date: .abbreviated, time: .shortened))"
            let updatedText = diary.updatedAt != diary.createdAt
                ? "  •  Updated: \(diary.updatedAt.formatted(date: .abbreviated, time: .shortened))"
                : ""
            let metadataText = createdText + updatedText

            // Calculate text sizes
            let dateSize = dateText.boundingRect(
                with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: dateAttributes,
                context: nil
            )

            let titleSize = titleText.boundingRect(
                with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: titleAttributes,
                context: nil
            )

            let metadataSize = metadataText.boundingRect(
                with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: metadataAttributes,
                context: nil
            )

            // Calculate header height (date + title + metadata + spacing)
            let headerHeight = dateSize.height + 12 + titleSize.height + 8 + metadataSize.height + 16

            // Split content into pages
            let contentText = diary.content as NSString
            var currentLocation = 0
            let totalLength = contentText.length

            // Page number attributes
            let pageNumberAttributes: [NSAttributedString.Key: Any] = [
                .font: pageNumberFont,
                .foregroundColor: metadataColor
            ]

            var currentPageNumber = 0

            // Helper function to draw page number
            func drawPageNumber(_ pageNum: Int) {
                let pageNumberText = "Page \(pageNum) of \(totalPages)"
                let pageNumberSize = pageNumberText.boundingRect(
                    with: CGSize(width: contentWidth, height: footerHeight),
                    options: .usesLineFragmentOrigin,
                    attributes: pageNumberAttributes,
                    context: nil
                )
                let xPosition = (pageWidth - pageNumberSize.width) / 2
                let yPosition = pageHeight - margin
                pageNumberText.draw(
                    at: CGPoint(x: xPosition, y: yPosition),
                    withAttributes: pageNumberAttributes
                )
            }

            // Handle empty content - still draw header on one page
            if totalLength == 0 {
                context.beginPage()
                currentPageNumber += 1

                var yPosition = margin

                // Draw date
                dateText.draw(
                    in: CGRect(x: margin, y: yPosition, width: contentWidth, height: dateSize.height),
                    withAttributes: dateAttributes
                )
                yPosition += dateSize.height + 12

                // Draw title
                titleText.draw(
                    in: CGRect(x: margin, y: yPosition, width: contentWidth, height: titleSize.height),
                    withAttributes: titleAttributes
                )
                yPosition += titleSize.height + 8

                // Draw metadata
                metadataText.draw(
                    in: CGRect(x: margin, y: yPosition, width: contentWidth, height: metadataSize.height),
                    withAttributes: metadataAttributes
                )
                yPosition += metadataSize.height + 16

                // Draw divider line
                let dividerPath = UIBezierPath()
                dividerPath.move(to: CGPoint(x: margin, y: yPosition))
                dividerPath.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
                UIColor(red: 0.910, green: 0.875, blue: 0.816, alpha: 1).setStroke()
                dividerPath.lineWidth = 1
                dividerPath.stroke()

                // Draw page number
                drawPageNumber(currentPageNumber)
            }

            while currentLocation < totalLength {
                context.beginPage()
                currentPageNumber += 1

                var yPosition = margin

                // Draw header only on first page
                if currentLocation == 0 {
                    // Draw date
                    dateText.draw(
                        in: CGRect(x: margin, y: yPosition, width: contentWidth, height: dateSize.height),
                        withAttributes: dateAttributes
                    )
                    yPosition += dateSize.height + 12

                    // Draw title
                    titleText.draw(
                        in: CGRect(x: margin, y: yPosition, width: contentWidth, height: titleSize.height),
                        withAttributes: titleAttributes
                    )
                    yPosition += titleSize.height + 8

                    // Draw metadata
                    metadataText.draw(
                        in: CGRect(x: margin, y: yPosition, width: contentWidth, height: metadataSize.height),
                        withAttributes: metadataAttributes
                    )
                    yPosition += metadataSize.height + 16

                    // Draw divider line
                    let dividerPath = UIBezierPath()
                    dividerPath.move(to: CGPoint(x: margin, y: yPosition))
                    dividerPath.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
                    UIColor(red: 0.910, green: 0.875, blue: 0.816, alpha: 1).setStroke() // #E8DFD0
                    dividerPath.lineWidth = 1
                    dividerPath.stroke()
                    yPosition += 16
                }

                // Calculate available height for content (accounting for footer)
                let availableHeight = pageHeight - yPosition - margin - footerHeight

                // Find how much text fits on this page
                let remainingText = contentText.substring(from: currentLocation)
                let layoutManager = NSLayoutManager()
                let textContainer = NSTextContainer(size: CGSize(width: contentWidth, height: availableHeight))
                let textStorage = NSTextStorage(string: remainingText, attributes: contentAttributes)

                layoutManager.addTextContainer(textContainer)
                textStorage.addLayoutManager(layoutManager)

                // Get the glyph range that fits
                let glyphRange = layoutManager.glyphRange(for: textContainer)
                let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

                // Draw the text that fits
                let textToDraw = (remainingText as NSString).substring(with: NSRange(location: 0, length: characterRange.length))
                textToDraw.draw(
                    in: CGRect(x: margin, y: yPosition, width: contentWidth, height: availableHeight),
                    withAttributes: contentAttributes
                )

                currentLocation += characterRange.length

                // Draw page number at bottom
                drawPageNumber(currentPageNumber)

                // Safety check to prevent infinite loop
                if characterRange.length == 0 {
                    break
                }
            }
        }

        return data
    }

    private func calculateTotalPages(
        pageWidth: CGFloat,
        pageHeight: CGFloat,
        margin: CGFloat,
        contentWidth: CGFloat,
        footerHeight: CGFloat
    ) -> Int {
        let contentFont = UIFont.systemFont(ofSize: 12)
        let titleFont = UIFont(name: "PlayfairDisplay-Bold", size: 24) ?? UIFont.boldSystemFont(ofSize: 24)
        let dateFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        let metadataFont = UIFont.systemFont(ofSize: 10)

        let contentParagraphStyle = NSMutableParagraphStyle()
        contentParagraphStyle.lineSpacing = 6

        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: contentFont,
            .paragraphStyle: contentParagraphStyle
        ]

        let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont]
        let dateAttributes: [NSAttributedString.Key: Any] = [.font: dateFont]
        let metadataAttributes: [NSAttributedString.Key: Any] = [.font: metadataFont]

        // Calculate header height
        let dateText = diary.entryDate.formatted(date: .complete, time: .omitted)
        let titleText = diary.title
        let createdText = "Created: \(diary.createdAt.formatted(date: .abbreviated, time: .shortened))"
        let updatedText = diary.updatedAt != diary.createdAt
            ? "  •  Updated: \(diary.updatedAt.formatted(date: .abbreviated, time: .shortened))"
            : ""
        let metadataText = createdText + updatedText

        let dateSize = dateText.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: dateAttributes,
            context: nil
        )

        let titleSize = titleText.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: titleAttributes,
            context: nil
        )

        let metadataSize = metadataText.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: metadataAttributes,
            context: nil
        )

        let headerHeight = dateSize.height + 12 + titleSize.height + 8 + metadataSize.height + 16 + 16 // +16 for divider

        let contentText = diary.content as NSString
        let totalLength = contentText.length

        if totalLength == 0 {
            return 1
        }

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

            if characterRange.length == 0 {
                break
            }
        }

        return max(1, pageCount)
    }
    #endif
}

#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let filename: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Create a temporary file with proper name for sharing
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        if let pdfData = activityItems.first as? Data {
            try? pdfData.write(to: tempURL)
        }

        let controller = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )

        // Clean up temp file after sharing is done
        controller.completionWithItemsHandler = { _, _, _, _ in
            try? FileManager.default.removeItem(at: tempURL)
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

#Preview {
    DiaryDetailView(
        diary: Diary(
            id: "1",
            title: "Sample Entry",
            content: "This is a sample diary entry with some content to preview. It contains multiple lines of text to show how the content would look in the detail view.",
            entryDate: Date(),
            createdAt: Date(),
            updatedAt: Date()
        ),
        diaryViewModel: DiaryViewModel()
    )
    .environmentObject(ThemeManager.shared)
}
