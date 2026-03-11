import SwiftUI

struct ModelSettingsView: View {
    @ObservedObject var whisperPrompt: WhisperPrompt
    @AppStorage("SelectedLanguage") private var selectedLanguage: String = "en"
    @AppStorage("IsTextFormattingEnabled") private var isTextFormattingEnabled = true
    @AppStorage("IsVADEnabled") private var isVADEnabled = true
    @AppStorage("AppendTrailingSpace") private var appendTrailingSpace = true
    @AppStorage("PrewarmModelOnWake") private var prewarmModelOnWake = true
    @State private var customPrompt: String = ""
    @State private var isEditing: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("输出格式")
                    .font(.headline)
                
                InfoTip(
                    "和 GPT 不同，语音模型（Whisper）更依赖提示词示例的风格，而不是命令式指令。请尽量用目标输出示例来引导格式。",
                    learnMoreURL: "https://cookbook.openai.com/examples/whisper_prompting_guide#comparison-with-gpt-prompting"
                )
                
                Spacer()
                
                Button(action: {
                    if isEditing {
                        // Save changes
                        whisperPrompt.setCustomPrompt(customPrompt, for: selectedLanguage)
                        isEditing = false
                    } else {
                        // Enter edit mode
                        customPrompt = whisperPrompt.getLanguagePrompt(for: selectedLanguage)
                        isEditing = true
                    }
                }) {
                    Text(isEditing ? "保存" : "编辑")
                        .font(.caption)
                }
            }
            
            if isEditing {
                TextEditor(text: $customPrompt)
                    .font(.system(size: 12))
                    .padding(8)
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                
            } else {
                Text(whisperPrompt.getLanguagePrompt(for: selectedLanguage))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.windowBackgroundColor).opacity(0.4))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }

            Divider().padding(.vertical, 4)

            Toggle(isOn: $appendTrailingSpace) {
                Text("粘贴后补一个空格")
            }
            .toggleStyle(.switch)

            HStack {
                Toggle(isOn: $isTextFormattingEnabled) {
                    Text("自动文本格式化")
                }
                .toggleStyle(.switch)
                
                InfoTip("自动整理文本格式，把大段内容拆分成更自然的段落。")
            }

            HStack {
                Toggle(isOn: $isVADEnabled) {
                    Text("语音活动检测（VAD）")
                }
                .toggleStyle(.switch)

                InfoTip("识别语音片段并过滤静音内容，提升本地模型的识别准确度。")
            }

            HStack {
                Toggle(isOn: $prewarmModelOnWake) {
                    Text("模型预热（实验性）")
                }
                .toggleStyle(.switch)

                InfoTip("如果本地模型转写速度明显偏慢，可以开启它。应用启动或唤醒时会触发一次静默后台预热。")
            }

            FillerWordsSettingsView()

        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        // Reset the editor when language changes
        .onChange(of: selectedLanguage) { oldValue, newValue in
            if isEditing {
                customPrompt = whisperPrompt.getLanguagePrompt(for: selectedLanguage)
            }
        }
    }
} 
