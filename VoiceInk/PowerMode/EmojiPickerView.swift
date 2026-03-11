import SwiftUI

struct EmojiPickerView: View {
    @StateObject private var emojiManager = EmojiManager.shared
    @Binding var selectedEmoji: String
    @Binding var isPresented: Bool
    @State private var newEmojiText: String = ""
    @State private var isAddingCustomEmoji: Bool = false
    @FocusState private var isEmojiTextFieldFocused: Bool
    @State private var inputFeedbackMessage: String = ""
    @State private var showingEmojiInUseAlert = false
    @State private var emojiForAlert: String? = nil
    private let columns: [GridItem] = [GridItem(.adaptive(minimum: 44), spacing: 10)]

    var body: some View {
        VStack(spacing: 12) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(emojiManager.allEmojis, id: \.self) { emoji in
                        EmojiButton(
                            emoji: emoji,
                            isSelected: selectedEmoji == emoji,
                            isCustom: emojiManager.isCustomEmoji(emoji),
                            removeAction: {
                                attemptToRemoveCustomEmoji(emoji)
                            }
                        ) {
                            selectedEmoji = emoji
                            inputFeedbackMessage = ""
                            isPresented = false
                        }
                    }

                    AddEmojiButton {
                        isAddingCustomEmoji.toggle()
                        newEmojiText = ""
                        inputFeedbackMessage = ""
                        if isAddingCustomEmoji {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isEmojiTextFieldFocused = true
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 200)

            if isAddingCustomEmoji {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        TextField("➕", text: $newEmojiText)
                            .textFieldStyle(.roundedBorder)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 70)
                            .focused($isEmojiTextFieldFocused)
                            .onChange(of: newEmojiText) { _, newValue in
                                inputFeedbackMessage = ""
                                let cleaned = newValue.firstValidEmojiCharacter()
                                if newEmojiText != cleaned {
                                    newEmojiText = cleaned
                                }
                                if !newEmojiText.isEmpty && emojiManager.allEmojis.contains(newEmojiText) {
                                    inputFeedbackMessage = "这个表情已存在"
                                } else if !newEmojiText.isEmpty && !newEmojiText.isValidEmoji {
                                    inputFeedbackMessage = "无效的表情"
                                } else {
                                    inputFeedbackMessage = ""
                                }
                            }
                            .onSubmit(attemptAddCustomEmoji)

                        Button("添加") {
                            attemptAddCustomEmoji()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newEmojiText.isEmpty || !newEmojiText.isValidEmoji || emojiManager.allEmojis.contains(newEmojiText))

                        Button("取消") {
                            isAddingCustomEmoji = false
                            newEmojiText = ""
                            inputFeedbackMessage = ""
                        }
                        .buttonStyle(.bordered)
                    }
                    if !inputFeedbackMessage.isEmpty {
                        Text(inputFeedbackMessage)
                            .font(.caption)
                            .foregroundColor(inputFeedbackMessage == "这个表情已存在" || inputFeedbackMessage == "无效的表情" ? .red : .secondary)
                            .transition(.opacity)
                    }
                    Text("提示：可使用 ⌃⌘Space 打开系统表情选择器。")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                .padding(.horizontal)
                .padding(.bottom, 5)
            }
        }
        .padding()
        .frame(minWidth: 260, idealWidth: 300, maxWidth: 320, minHeight: 150, idealHeight: 280, maxHeight: 350)
        .alert("表情正在使用中", isPresented: $showingEmojiInUseAlert, presenting: emojiForAlert) { emojiStr in
            Button("确定", role: .cancel) { }
        } message: { emojiStr in
            Text("表情“\(emojiStr)”正在被一个或多个场景模式使用，暂时无法删除。")
        }
    }

    private func attemptAddCustomEmoji() {
        let trimmedEmoji = newEmojiText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmoji.isEmpty else {
            inputFeedbackMessage = "表情不能为空"
            return
        }
        guard trimmedEmoji.isValidEmoji else {
            inputFeedbackMessage = "无效的表情字符"
            return
        }
        guard !emojiManager.allEmojis.contains(trimmedEmoji) else {
            inputFeedbackMessage = "这个表情已存在"
            return
        }

        if emojiManager.addCustomEmoji(trimmedEmoji) {
            selectedEmoji = trimmedEmoji
            inputFeedbackMessage = ""
            isAddingCustomEmoji = false
            newEmojiText = ""
        } else {
            inputFeedbackMessage = "无法添加表情"
        }
    }

    private func attemptToRemoveCustomEmoji(_ emojiToRemove: String) {
        guard emojiManager.isCustomEmoji(emojiToRemove) else { return }

        if PowerModeManager.shared.isEmojiInUse(emojiToRemove) {
            emojiForAlert = emojiToRemove
            showingEmojiInUseAlert = true
        } else {
            if emojiManager.removeCustomEmoji(emojiToRemove) {
                if selectedEmoji == emojiToRemove {
                }
            }
        }
    }
}

private struct EmojiButton: View {
    let emoji: String
    let isSelected: Bool
    let isCustom: Bool
    let removeAction: () -> Void
    let selectAction: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: selectAction) {
                Text(emoji)
                    .font(.largeTitle) 
                    .frame(width: 44, height: 44)
                    .overlay( 
                        Circle()
                            .strokeBorder(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )
            }
            .buttonStyle(.plain) 

            if isCustom {
                Button(action: removeAction) {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.white, Color.red)
                        .font(.caption2)
                        .background(Circle().fill(Color.white.opacity(0.8)))
                }
                .buttonStyle(.borderless) 
                .offset(x: 6, y: -6)
            }
        }
    }
}

private struct AddEmojiButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("添加表情", systemImage: "plus.circle.fill")
                .font(.title2)
                .labelStyle(.iconOnly)
                .foregroundColor(.accentColor)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help("添加自定义表情符号")
    }
}

extension String {
    var isValidEmoji: Bool {
        guard !self.isEmpty else { return false }
        return self.count == 1 && self.unicodeScalars.first?.properties.isEmoji ?? false
    }

    func firstValidEmojiCharacter() -> String {
        return self.filter { $0.unicodeScalars.allSatisfy { $0.properties.isEmoji } }.prefix(1).map(String.init).joined()
    }
}

#if DEBUG
struct EmojiPickerView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiPickerView(
            selectedEmoji: .constant("😀"),
            isPresented: .constant(true)
        )
        .environmentObject(EmojiManager.shared)
    }
}
#endif

 
