import SwiftUI
import KeyboardShortcuts

struct VoiceCommandView: View {
    @StateObject private var manager = VoiceCommandManager.shared
    @State private var editingAction: VoiceCommandAction?

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("语音命令")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)

                            InfoTip(
                                "用一条语音命令触发 Alfred、快捷指令或本地脚本。",
                                learnMoreURL: "https://github.com/GeekMai90/VoiceInk"
                            )
                        }

                        Text("让 VoiceInk Ultra 从转写工具变成语音动作中枢。")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: {
                        editingAction = .empty
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .medium))
                            Text("新增命令")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.windowBackgroundColor))

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("快捷键")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)

                        HStack {
                            Text("语音命令模式")
                                .font(.system(size: 14, weight: .medium))

                            Spacer()

                            KeyboardShortcuts.Recorder(for: .toggleVoiceCommandRecorder)
                                .controlSize(.small)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(CardBackground(isSelected: false))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("命令列表")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)

                        VoiceCommandSettingsView(
                            editingAction: $editingAction,
                            isPresentingEditor: Binding(
                                get: { editingAction != nil },
                                set: { isPresented in
                                    if !isPresented {
                                        editingAction = nil
                                    }
                                }
                            )
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(item: $editingAction) { action in
            VoiceCommandActionEditorSheet(action: action) { savedAction in
                manager.upsert(savedAction)
            }
        }
    }
}
