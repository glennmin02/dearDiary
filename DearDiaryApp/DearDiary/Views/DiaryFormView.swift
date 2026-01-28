import SwiftUI

struct DiaryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var diaryViewModel: DiaryViewModel

    var diary: Diary?

    @State private var title = ""
    @State private var content = ""
    @State private var entryDate = Date()
    @State private var isSaving = false
    @State private var errorMessage: String?

    var isEditing: Bool { diary != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $entryDate, displayedComponents: .date)
                }

                Section("Title") {
                    TextField("Give your entry a title...", text: $title)
                        #if os(iOS)
                        .textInputAutocapitalization(.sentences)
                        #endif

                    HStack {
                        Spacer()
                        Text("\(title.count)/200")
                            .font(.caption)
                            .foregroundColor(title.count > 200 ? .red : .secondary)
                    }
                }

                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)

                    HStack {
                        Spacer()
                        Text("\(content.count)/10,000 chars | \(wordCount) words")
                            .font(.caption)
                            .foregroundColor(content.count > 10000 ? .red : .secondary)
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Entry" : "New Entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving || title.isEmpty || content.isEmpty || title.count > 200 || content.count > 10000)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .onAppear {
                if let diary = diary {
                    title = diary.title
                    content = diary.content
                    entryDate = diary.entryDate
                }
            }
        }
    }

    private var wordCount: Int {
        content.split(separator: " ").count
    }

    private func save() async {
        isSaving = true
        errorMessage = nil

        let success: Bool
        if let diary = diary {
            success = await diaryViewModel.updateDiary(
                id: diary.id,
                title: title,
                content: content,
                entryDate: entryDate
            )
        } else {
            success = await diaryViewModel.createDiary(
                title: title,
                content: content,
                entryDate: entryDate
            )
        }

        isSaving = false

        if success {
            dismiss()
        } else {
            errorMessage = diaryViewModel.errorMessage ?? "Failed to save"
        }
    }
}

#Preview {
    DiaryFormView(diaryViewModel: DiaryViewModel())
}
