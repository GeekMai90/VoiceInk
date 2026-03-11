import SwiftUI
import KeyboardShortcuts

struct EnhancementShortcutsView: View {
    @ObservedObject private var shortcutSettings = EnhancementShortcutSettings.shared

    var body: some View {
        VStack(spacing: 8) {
            // Toggle AI Enhancement
            HStack(alignment: .center, spacing: 12) {
                HStack(spacing: 4) {
                    Text("切换 AI 增强")
                        .font(.system(size: 13))

                    InfoTip(
                        "录音时快速开启或关闭 AI 增强。仅在 VoiceInk 正在运行且录音器可见时生效。",
                        learnMoreURL: "https://tryvoiceink.com/docs/enhancement-shortcuts"
                    )
                }

                Spacer()

                HStack(spacing: 10) {
                    HStack(spacing: 4) {
                        KeyChip(label: "⌘")
                        KeyChip(label: "E")
                    }

                    Toggle("", isOn: $shortcutSettings.isToggleEnhancementShortcutEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
            }

            // Switch Enhancement Prompt
            HStack(alignment: .center, spacing: 12) {
                HStack(spacing: 4) {
                    Text("切换增强提示词")
                        .font(.system(size: 13))

                    InfoTip(
                        "使用 ⌘1 到 ⌘0 在已保存的提示词之间切换，按保存顺序激活对应提示词。仅在 VoiceInk 正在运行且录音器可见时生效。",
                        learnMoreURL: "https://tryvoiceink.com/docs/enhancement-shortcuts"
                    )
                }

                Spacer()

                HStack(spacing: 4) {
                    KeyChip(label: "⌘")
                    KeyChip(label: "1 – 0")
                }
            }
        }
        .background(Color.clear)
    }
}

// MARK: - Supporting Views
private struct KeyChip: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundColor(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(
                        Color(NSColor.separatorColor).opacity(0.5),
                        lineWidth: 0.5
                    )
            )
    }
}
