import SwiftUI

struct DiaryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let diary: Diary
    @ObservedObject var diaryViewModel: DiaryViewModel

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Date badge
                    Text(diary.entryDate.formatted(date: .complete, time: .omitted))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(16)

                    // Title
                    Text(diary.title)
                        .font(.system(size: 28, weight: .semibold, design: .serif))

                    // Metadata
                    HStack(spacing: 16) {
                        Label(
                            "Created \(diary.createdAt.formatted(date: .abbreviated, time: .shortened))",
                            systemImage: "clock"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)

                        if diary.updatedAt != diary.createdAt {
                            Label(
                                "Updated \(diary.updatedAt.formatted(date: .abbreviated, time: .shortened))",
                                systemImage: "pencil"
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // Content
                    Text(diary.content)
                        .font(.body)
                        .lineSpacing(6)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: { showingEditSheet = true }) {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                DiaryFormView(diaryViewModel: diaryViewModel, diary: diary)
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
            content: "This is a sample diary entry with some content to preview.",
            entryDate: Date(),
            createdAt: Date(),
            updatedAt: Date()
        ),
        diaryViewModel: DiaryViewModel()
    )
}
