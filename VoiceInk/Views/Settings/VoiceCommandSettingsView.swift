import SwiftUI

struct VoiceCommandSettingsView: View {
    @StateObject private var manager = VoiceCommandManager.shared
    @State private var editingAction = VoiceCommandAction.empty
    @State private var isPresentingEditor = false

    var body: some View {
        Group {
            ForEach(manager.actions) { action in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Toggle(action.name.isEmpty ? "Untitled Command" : action.name, isOn: binding(for: action))
                            .toggleStyle(.checkbox)

                        Spacer()

                        Button("Edit") {
                            editingAction = action
                            isPresentingEditor = true
                        }
                        .buttonStyle(.link)

                        Button("Delete", role: .destructive) {
                            manager.delete(action)
                        }
                        .buttonStyle(.link)
                    }

                    Text("\(action.spokenAliases.joined(separator: ", ")) -> \(action.executorType.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(targetSummary(for: action))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Button("Add Voice Command") {
                editingAction = .empty
                isPresentingEditor = true
            }

            Text("命令词必须放在开头。脚本模式支持把 payload 当作参数或标准输入传入；Alfred URL 支持 `{{payload}}` 占位符。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .sheet(isPresented: $isPresentingEditor) {
            VoiceCommandActionEditorSheet(action: editingAction) { savedAction in
                manager.upsert(savedAction)
            }
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

private struct VoiceCommandActionEditorSheet: View {
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
        VStack(alignment: .leading, spacing: 16) {
            Text(isNewAction ? "Add Voice Command" : "Edit Voice Command")
                .font(.headline)

            Form {
                TextField("Name", text: $name)
                TextField("Spoken aliases, comma separated", text: $aliasesText)

                Picker("Executor", selection: $executorType) {
                    ForEach(VoiceCommandExecutorType.allCases) { executor in
                        Text(executor.displayName).tag(executor)
                    }
                }

                TextField(targetLabel, text: $target)

                if executorType == .script {
                    Picker("Payload", selection: $payloadMode) {
                        ForEach(VoiceCommandPayloadMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                }

                Toggle("Enabled", isOn: $isEnabled)
            }
            .formStyle(.grouped)

            Text(helpText)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Save") {
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
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
        }
        .padding(20)
        .frame(width: 480)
    }

    private var targetLabel: String {
        switch executorType {
        case .shortcuts:
            return "Shortcut name"
        case .script:
            return "Script path"
        case .alfred:
            return "alfred:// URL"
        }
    }

    private var helpText: String {
        switch executorType {
        case .shortcuts:
            return "This runs `shortcuts run <name>`. If payload exists, VoiceInk sends it through standard input."
        case .script:
            return "Use an absolute script path. Argument mode passes the payload as the first argument; Standard Input mode writes the payload to stdin."
        case .alfred:
            return "Use a full `alfred://` URL. Add `{{payload}}` if the payload should be inserted into the URL."
        }
    }
}
