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
                // Glass background
                GlassBackground(theme: theme)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Date badge
                        Text(diary.entryDate.formatted(date: .complete, time: .omitted))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.accent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(theme.accent.opacity(0.15).gradient)
                            .clipShape(Capsule())

                        // Title
                        Text(diary.title)
                            .font(.playfairBold(size: 32))

                        // Metadata
                        HStack(spacing: 16) {
                            Label(
                                "Created \(diary.createdAt.formatted(date: .abbreviated, time: .shortened))",
                                systemImage: "clock"
                            )
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                            if diary.updatedAt != diary.createdAt {
                                Label(
                                    "Updated \(diary.updatedAt.formatted(date: .abbreviated, time: .shortened))",
                                    systemImage: "pencil"
                                )
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            }
                        }

                        Divider()
                            .background(.white.opacity(0.2))

                        // Content
                        Text(diary.content)
                            .font(.body)
                            .lineSpacing(8)
                    }
                    .padding(28)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(theme: theme)
                    .padding()
                }
            }
            .navigationTitle("Entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(theme.name == "Diary" ? .light : .dark, for: .navigationBar)
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
