import SwiftUI
import SwiftData

// Edit existing word replacement entry
struct EditReplacementSheet: View {
    let replacement: WordReplacement
    let modelContext: ModelContext

    @Environment(\.dismiss) private var dismiss

    @State private var originalWord: String
    @State private var replacementWord: String
    @State private var showAlert = false
    @State private var alertMessage = ""

    // MARK: – Initialiser
    init(replacement: WordReplacement, modelContext: ModelContext) {
        self.replacement = replacement
        self.modelContext = modelContext
        _originalWord = State(initialValue: replacement.originalText)
        _replacementWord = State(initialValue: replacement.replacementText)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            formContent
        }
        .frame(width: 460, height: 560)
        .alert("词语替换", isPresented: $showAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: – Subviews
    private var header: some View {
        HStack {
            Button("取消", role: .cancel) { dismiss() }
                .buttonStyle(.borderless)
                .keyboardShortcut(.escape, modifiers: [])

            Spacer()

            Text("编辑替换规则")
                .font(.headline)

            Spacer()

            Button("保存") { saveChanges() }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(originalWord.isEmpty || replacementWord.isEmpty)
                .keyboardShortcut(.return, modifiers: [])
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(CardBackground(isSelected: false))
    }

    private var formContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                descriptionSection
                inputSection
            }
            .padding(.vertical)
        }
    }

    private var descriptionSection: some View {
        Text("修改需要被自动替换的词语或短语。")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 8)
    }

    private var inputSection: some View {
        VStack(spacing: 16) {
            // Original Text Field
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("原始词语")
                        .font(.headline)
                    Text("必填")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                TextField("输入要被替换的词语或短语（多个请用英文逗号分隔）", text: $originalWord)
                    .textFieldStyle(.roundedBorder)
                
            }
            .padding(.horizontal)

            // Replacement Text Field
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("替换文本")
                        .font(.headline)
                    Text("必填")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                TextEditor(text: $replacementWord)
                    .font(.body)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(.separatorColor), lineWidth: 1)
                    )
            }
            .padding(.horizontal)
        }
    }

    // MARK: – Actions
    private func saveChanges() {
        let newOriginal = originalWord.trimmingCharacters(in: .whitespacesAndNewlines)
        let newReplacement = replacementWord
        let tokens = newOriginal
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !tokens.isEmpty, !newReplacement.isEmpty else { return }

        // Check for duplicates (excluding current replacement)
        let newTokensPairs = tokens.map { (original: $0, lowercased: $0.lowercased()) }

        let descriptor = FetchDescriptor<WordReplacement>()
        if let allReplacements = try? modelContext.fetch(descriptor) {
            for existingReplacement in allReplacements {
                // Skip checking against itself
                if existingReplacement.id == replacement.id {
                    continue
                }

                let existingTokens = existingReplacement.originalText
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                    .filter { !$0.isEmpty }

                for tokenPair in newTokensPairs {
                    if existingTokens.contains(tokenPair.lowercased) {
                        alertMessage = "“\(tokenPair.original)”已经存在于替换规则中"
                        showAlert = true
                        return
                    }
                }
            }
        }

        // Update the replacement
        replacement.originalText = newOriginal
        replacement.replacementText = newReplacement

        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertMessage = "保存修改失败：\(error.localizedDescription)"
            showAlert = true
        }
    }
}
