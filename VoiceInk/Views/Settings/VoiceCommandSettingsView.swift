import SwiftUI

struct VoiceCommandSettingsView: View {
    @StateObject private var manager = VoiceCommandManager.shared
    @Binding var editingAction: VoiceCommandAction?
    @Binding var isPresentingEditor: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if manager.actions.isEmpty {
                VoiceCommandEmptyStateView {
                    editingAction = .empty
                    isPresentingEditor = true
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(manager.actions) { action in
                        VoiceCommandActionCard(
                            action: action,
                            isEnabled: binding(for: action),
                            onEdit: {
                                editingAction = action
                                isPresentingEditor = true
                            },
                            onDelete: {
                                manager.delete(action)
                            }
                        )
                    }
                }
            }

            Text("命令词必须放在开头。脚本模式支持把 payload 当作参数或标准输入传入；Alfred URL 支持 `{{payload}}` 占位符。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func binding(for action: VoiceCommandAction) -> Binding<Bool> {
        Binding(
            get: { action.isEnabled },
            set: { isEnabled in
                var updated = action
                updated.isEnabled = isEnabled
                manager.upsert(updated)
            }
        )
    }

    private func targetSummary(for action: VoiceCommandAction) -> String {
        switch action.executorType {
        case .shortcuts:
            return "Shortcut: \(action.target)"
        case .alfred:
            return "URL: \(action.target)"
        case .script:
            return "Script: \(action.target) • Payload: \(action.payloadMode.displayName)"
        }
    }
}

private struct VoiceCommandEmptyStateView: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.badge.mic")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("还没有语音命令")
                .font(.title2)
                .fontWeight(.semibold)

            Text("新增第一条语音命令，用一句话触发 Alfred、快捷指令或本地脚本。")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VoiceInkButton(
                title: "新增语音命令",
                action: action
            )
            .frame(maxWidth: 260)
        }
    }
}

private struct VoiceCommandActionCard: View {
    let action: VoiceCommandAction
    @Binding var isEnabled: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(NSColor.controlBackgroundColor))
                        .frame(width: 40, height: 40)

                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(action.name.isEmpty ? "未命名命令" : action.name)
                            .font(.system(size: 15, weight: .semibold))

                        Text(action.executorType.displayName)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.accentColor.opacity(0.16)))
                            .foregroundColor(.accentColor)

                        if !action.isEnabled {
                            Text("已停用")
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color(NSColor.controlBackgroundColor)))
                                .overlay(
                                    Capsule().stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                                )
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack(spacing: 10) {
                        Label(action.spokenAliases.joined(separator: ", "), systemImage: "mic")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if action.executorType == .script {
                            Label(action.payloadMode.displayName, systemImage: "arrow.right.to.line.compact")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                Toggle("", isOn: $isEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    .labelsHidden()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)

            Divider()

            HStack(spacing: 8) {
                Text(targetSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button("编辑", action: onEdit)
                    .buttonStyle(.link)

                Button("删除", role: .destructive, action: onDelete)
                    .buttonStyle(.link)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(CardBackground(isSelected: false))
    }

    private var iconName: String {
        switch action.executorType {
        case .shortcuts:
            return "square.stack.3d.up.fill"
        case .script:
            return "terminal.fill"
        case .alfred:
            return "bolt.horizontal.circle.fill"
        }
    }

    private var targetSummary: String {
        switch action.executorType {
        case .shortcuts:
            return "快捷指令：\(action.target)"
        case .alfred:
            return "Alfred：\(action.target)"
        case .script:
            return "脚本：\(action.target)"
        }
    }
}

struct VoiceCommandActionEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var aliasesText: String
    @State private var executorType: VoiceCommandExecutorType
    @State private var target: String
    @State private var payloadMode: VoiceCommandPayloadMode
    @State private var isEnabled: Bool

    let actionID: UUID
    let isNewAction: Bool
    let onSave: (VoiceCommandAction) -> Void

    init(action: VoiceCommandAction, onSave: @escaping (VoiceCommandAction) -> Void) {
        self.actionID = action.id
        self.isNewAction = action.name.isEmpty && action.target.isEmpty && action.spokenAliases.isEmpty
        self.onSave = onSave
        _name = State(initialValue: action.name)
        _aliasesText = State(initialValue: action.spokenAliases.joined(separator: ", "))
        _executorType = State(initialValue: action.executorType)
        _target = State(initialValue: action.target)
        _payloadMode = State(initialValue: action.payloadMode)
        _isEnabled = State(initialValue: action.isEnabled)
    }

    private var normalizedAliases: [String] {
        aliasesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !target.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !normalizedAliases.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(isNewAction ? "新增语音命令" : "编辑语音命令")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)

                Text("设置触发词、执行器和目标，让一句话直接触发动作。")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                editorField(title: "命令名称") {
                    TextField("例如：每日笔记", text: $name)
                        .textFieldStyle(.plain)
                }

                divider()

                editorField(title: "触发词") {
                    TextField("多个触发词用中文逗号或英文逗号分隔", text: $aliasesText)
                        .textFieldStyle(.plain)
                }

                divider()

                editorField(title: "执行器", contentAlignment: .trailing) {
                    Picker("", selection: $executorType) {
                        ForEach(VoiceCommandExecutorType.allCases) { executor in
                            Text(executorDisplayName(for: executor)).tag(executor)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 180, alignment: .trailing)
                    .fixedSize()
                }

                divider()

                editorField(title: targetTitle) {
                    TextField(targetPlaceholder, text: $target)
                        .textFieldStyle(.plain)
                }

                if executorType == .script {
                    divider()

                    editorField(title: "传参方式", contentAlignment: .trailing) {
                        Picker("", selection: $payloadMode) {
                            ForEach(VoiceCommandPayloadMode.allCases) { mode in
                                Text(payloadModeDisplayName(for: mode)).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 180, alignment: .trailing)
                        .fixedSize()
                    }
                }

                divider()

                editorField(title: "启用状态", contentAlignment: .trailing) {
                    Toggle("", isOn: $isEnabled)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.5), lineWidth: 0.8)
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("说明")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(helpText)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }

            HStack(spacing: 12) {
                Spacer()

                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button("保存") {
                    onSave(
                        VoiceCommandAction(
                            id: actionID,
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            spokenAliases: normalizedAliases,
                            executorType: executorType,
                            target: target.trimmingCharacters(in: .whitespacesAndNewlines),
                            payloadMode: payloadMode,
                            isEnabled: isEnabled
                        )
                    )
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(canSave ? Color.accentColor : Color.accentColor.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
        }
        .padding(28)
        .frame(width: 560)
        .background(
            LinearGradient(
                colors: [
                    Color(NSColor.windowBackgroundColor),
                    Color(NSColor.controlBackgroundColor).opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var targetTitle: String {
        switch executorType {
        case .shortcuts:
            return "快捷指令名称"
        case .script:
            return "脚本路径"
        case .alfred:
            return "Alfred URL"
        }
    }

    private var targetPlaceholder: String {
        switch executorType {
        case .shortcuts:
            return "例如：Roam Daily Capture"
        case .script:
            return "例如：/Users/geekmai/scripts/capture.sh"
        case .alfred:
            return "例如：alfred://runtrigger/..."
        }
    }

    private var helpText: String {
        switch executorType {
        case .shortcuts:
            return "会执行 `shortcuts run <名称>`。如果你在说出触发词后继续说内容，VoiceInk Ultra 会把这段内容通过标准输入传给快捷指令。"
        case .script:
            return "请填写绝对路径。参数模式会把后续语音内容作为第一个参数传入；标准输入模式会把内容写入 stdin。"
        case .alfred:
            return "请填写完整的 `alfred://` URL。如果需要把后续语音内容拼进 URL，请使用 `{{payload}}` 占位符。"
        }
    }

    @ViewBuilder
    private func editorField<Content: View>(
        title: String,
        contentAlignment: Alignment = .leading,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .center, spacing: 20) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 108, alignment: .leading)

            content()
                .font(.system(size: 15))
                .frame(maxWidth: .infinity, alignment: contentAlignment)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }

    @ViewBuilder
    private func divider() -> some View {
        Rectangle()
            .fill(Color(NSColor.separatorColor).opacity(0.45))
            .frame(height: 1)
            .padding(.horizontal, 20)
    }

    private func executorDisplayName(for executor: VoiceCommandExecutorType) -> String {
        switch executor {
        case .shortcuts:
            return "快捷指令"
        case .script:
            return "脚本"
        case .alfred:
            return "Alfred"
        }
    }

    private func payloadModeDisplayName(for mode: VoiceCommandPayloadMode) -> String {
        switch mode {
        case .argument:
            return "参数"
        case .stdin:
            return "标准输入"
        }
    }
}
