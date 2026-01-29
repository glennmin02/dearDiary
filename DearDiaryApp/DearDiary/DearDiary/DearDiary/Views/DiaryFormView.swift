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
                theme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Date picker
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Date", systemImage: "calendar")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.textSecondary)

                            DatePicker("Entry date", selection: $entryDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(theme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(theme.border, lineWidth: 1)
                                )
                        }

                        // Title
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("Title", systemImage: "text.quote")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(theme.textSecondary)
                                Spacer()
                                Text("\(title.count)/200")
                                    .font(.caption)
                                    .foregroundColor(title.count > 200 ? theme.error : theme.textTertiary)
                            }

                            DiaryTextField(
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
                                    .foregroundColor(theme.textSecondary)
                                Spacer()
                                Text("\(content.count)/10,000 chars | \(wordCount) words")
                                    .font(.caption)
                                    .foregroundColor(content.count > 10000 ? theme.error : theme.textTertiary)
                            }

                            DiaryTextEditor(
                                text: $content,
                                theme: theme
                            )
                        }

                        // Error message
                        if let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(error)
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(theme.error)
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
            .toolbarBackground(theme.cardBackground, for: .navigationBar)
            .toolbarColorScheme(theme.isDark ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.textSecondary)
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

// MARK: - Text Editor
struct DiaryTextEditor: View {
    @Binding var text: String
    let theme: DiaryTheme
    @FocusState private var isFocused: Bool

    var body: some View {
        TextEditor(text: $text)
            .scrollContentBackground(.hidden)
            .foregroundColor(theme.textPrimary)
            .padding(14)
            .frame(minHeight: 280)
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? theme.accent : theme.border, lineWidth: isFocused ? 2 : 1)
            )
            .focused($isFocused)
    }
}

// MARK: - Legacy Support
struct GlassTextEditor: View {
    @Binding var text: String
    let theme: DiaryTheme
    var accessibilityLabel: String = "Content"
    var accessibilityHint: String = ""

    var body: some View {
        DiaryTextEditor(text: $text, theme: theme)
            .accessibilityLabel(accessibilityLabel)
    }
}

#Preview {
    DiaryFormView(diaryViewModel: DiaryViewModel())
        .environmentObject(ThemeManager.shared)
}
