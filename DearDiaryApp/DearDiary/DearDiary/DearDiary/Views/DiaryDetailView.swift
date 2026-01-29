import SwiftUI

struct DiaryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    let diary: Diary
    @ObservedObject var diaryViewModel: DiaryViewModel

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false

    private var theme: DiaryTheme { themeManager.currentTheme }

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
}

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
