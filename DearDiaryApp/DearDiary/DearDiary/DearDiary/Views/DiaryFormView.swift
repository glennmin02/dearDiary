import SwiftUI

struct DiaryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var diaryViewModel: DiaryViewModel

    var diary: Diary?

    @State private var title = ""
    @State private var content = ""
    @State private var entryDate = Date()
    @State private var isSaving = false
    @State private var errorMessage: String?

    var isEditing: Bool { diary != nil }
    private var theme: DiaryTheme { themeManager.currentTheme }

    var body: some View {
        NavigationStack {
            ZStack {
                // Glass background
                GlassBackground(theme: theme)

                ScrollView {
                    VStack(spacing: 24) {
                        // Date picker
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Date", systemImage: "calendar")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            DatePicker("", selection: $entryDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.ultraThinMaterial)
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                }
                        }

                        // Title
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("Title", systemImage: "text.quote")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(title.count)/200")
                                    .font(.caption)
                                    .foregroundColor(title.count > 200 ? theme.error : .secondary)
                            }

                            GlassTextField(
                                placeholder: "Give your entry a title...",
                                text: $title,
                                theme: theme
                            )
                            #if os(iOS)
                            .textInputAutocapitalization(.sentences)
                            #endif
                        }

                        // Content
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("Content", systemImage: "doc.text")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(content.count)/10,000 chars | \(wordCount) words")
                                    .font(.caption)
                                    .foregroundColor(content.count > 10000 ? theme.error : .secondary)
                            }

                            GlassTextEditor(
                                text: $content,
                                theme: theme
                            )
                        }

                        // Error message
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(theme.error.opacity(0.9).gradient)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle(isEditing ? "Edit Entry" : "New Entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(theme.name == "Diary" ? .light : .dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        Task { await save() }
                    }) {
                        if isSaving {
                            ProgressView()
                                .tint(theme.accent)
                        } else {
                            Text(isEditing ? "Update" : "Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving || title.isEmpty || content.isEmpty || title.count > 200 || content.count > 10000)
                    .foregroundColor(theme.accent)
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

// MARK: - Glass Text Editor
struct GlassTextEditor: View {
    @Binding var text: String
    let theme: DiaryTheme
    @FocusState private var isFocused: Bool

    var body: some View {
        TextEditor(text: $text)
            .scrollContentBackground(.hidden)
            .padding()
            .frame(minHeight: 280)
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
            .focused($isFocused)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    DiaryFormView(diaryViewModel: DiaryViewModel())
        .environmentObject(ThemeManager.shared)
}
