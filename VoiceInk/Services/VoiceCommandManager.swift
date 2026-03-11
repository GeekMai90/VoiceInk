import Foundation
import AppKit
import KeyboardShortcuts

struct VoiceCommandMatch {
    let action: VoiceCommandAction
    let matchedAlias: String
    let payload: String
}

struct VoiceCommandExecutionResult {
    let action: VoiceCommandAction
    let matchedAlias: String
    let payload: String
}

enum VoiceCommandError: LocalizedError {
    case noCommandsConfigured
    case noMatchingCommand
    case unavailableCommand
    case invalidURL
    case invalidTarget(String)
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .noCommandsConfigured:
            return "还没有可用的语音命令。"
        case .noMatchingCommand:
            return "没有找到匹配的语音命令。"
        case .unavailableCommand:
            return "这条语音命令不可用。"
        case .invalidURL:
            return "Alfred 链接无效。"
        case .invalidTarget(let message):
            return message
        case .commandFailed(let message):
            return message
        }
    }
}

@MainActor
final class VoiceCommandManager: ObservableObject {
    static let shared = VoiceCommandManager()

    @Published var actions: [VoiceCommandAction] {
        didSet { save() }
    }

    private let defaultsKey = "voiceCommandActions"
    private let separatorCharacters = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)

    private init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode([VoiceCommandAction].self, from: data) {
            self.actions = decoded
        } else {
            self.actions = []
        }
    }

    func upsert(_ action: VoiceCommandAction) {
        if let index = actions.firstIndex(where: { $0.id == action.id }) {
            actions[index] = action
        } else {
            actions.append(action)
        }
    }

    func delete(_ action: VoiceCommandAction) {
        KeyboardShortcuts.setShortcut(nil, for: .voiceCommandAction(id: action.id))
        actions.removeAll { $0.id == action.id }
    }

    func execute(transcript: String) async throws -> VoiceCommandExecutionResult {
        let enabledActions = actions.filter(\.isEnabled)
        guard !enabledActions.isEmpty else {
            throw VoiceCommandError.noCommandsConfigured
        }

        guard let match = resolveMatch(from: transcript, in: enabledActions) else {
            throw VoiceCommandError.noMatchingCommand
        }

        switch match.action.executorType {
        case .alfred:
            try await executeAlfredURL(match)
        case .shortcuts:
            try await executeShortcut(match)
        case .script:
            try await executeScript(match)
        }

        return VoiceCommandExecutionResult(
            action: match.action,
            matchedAlias: match.matchedAlias,
            payload: match.payload
        )
    }

    func executeDirect(actionId: UUID, transcript: String) async throws -> VoiceCommandExecutionResult {
        let payload = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let action = actions.first(where: { $0.id == actionId && $0.isEnabled }) else {
            throw VoiceCommandError.unavailableCommand
        }

        let match = VoiceCommandMatch(action: action, matchedAlias: "", payload: payload)

        switch action.executorType {
        case .alfred:
            try await executeAlfredURL(match)
        case .shortcuts:
            try await executeShortcut(match)
        case .script:
            try await executeScript(match)
        }

        return VoiceCommandExecutionResult(
            action: action,
            matchedAlias: "",
            payload: payload
        )
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(actions) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
        NotificationCenter.default.post(name: .voiceCommandActionsDidChange, object: nil)
    }

    private func resolveMatch(from transcript: String, in actions: [VoiceCommandAction]) -> VoiceCommandMatch? {
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)

        let candidates = actions.flatMap { action in
            action.spokenAliases
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .map { alias in (action, alias) }
        }
        .sorted { $0.1.count > $1.1.count }

        for (action, alias) in candidates {
            guard trimmedTranscript.count >= alias.count else { continue }

            let prefix = String(trimmedTranscript.prefix(alias.count))
            guard prefix.compare(alias, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame else {
                continue
            }

            if trimmedTranscript.count > alias.count {
                let nextIndex = trimmedTranscript.index(trimmedTranscript.startIndex, offsetBy: alias.count)
                let nextCharacter = trimmedTranscript[nextIndex]
                let hasSeparator = String(nextCharacter).rangeOfCharacter(from: separatorCharacters) != nil
                let canOmitSeparator = alias.containsCJKCharacters

                guard hasSeparator || canOmitSeparator else {
                    continue
                }
            }

            let payload = String(trimmedTranscript.dropFirst(alias.count))
                .trimmingCharacters(in: separatorCharacters)

            return VoiceCommandMatch(action: action, matchedAlias: alias, payload: payload)
        }

        return nil
    }

    private func executeAlfredURL(_ match: VoiceCommandMatch) async throws {
        let resolvedTarget = applyPayload(match.payload, to: match.action.target, percentEncode: true)
        guard let url = URL(string: resolvedTarget) else {
            throw VoiceCommandError.invalidURL
        }

        guard NSWorkspace.shared.open(url) else {
            throw VoiceCommandError.commandFailed("无法打开 Alfred 链接。")
        }
    }

    private func executeShortcut(_ match: VoiceCommandMatch) async throws {
        let inputData = match.payload.isEmpty ? nil : Data(match.payload.utf8)
        var arguments = ["run", match.action.target]
        if inputData != nil {
            arguments += ["--input-path", "-"]
        }

        _ = try await runProcess(
            executableURL: URL(fileURLWithPath: "/usr/bin/shortcuts"),
            arguments: arguments,
            standardInputData: inputData
        )
    }

    private func executeScript(_ match: VoiceCommandMatch) async throws {
        let expandedPath = NSString(string: match.action.target).expandingTildeInPath
        let targetURL = URL(fileURLWithPath: expandedPath)
        guard FileManager.default.fileExists(atPath: targetURL.path) else {
            throw VoiceCommandError.invalidTarget("脚本路径不存在。")
        }

        let canExecuteDirectly = FileManager.default.isExecutableFile(atPath: targetURL.path)
        let scriptInput = match.payload.isEmpty ? nil : Data(match.payload.utf8)

        if canExecuteDirectly && match.action.payloadMode == .argument {
            let arguments = match.payload.isEmpty ? [] : [match.payload]
            _ = try await runProcess(
                executableURL: targetURL,
                arguments: arguments,
                standardInputData: nil
            )
            return
        }

        let executableURL = canExecuteDirectly ? targetURL : URL(fileURLWithPath: "/bin/zsh")
        let arguments: [String]

        if canExecuteDirectly {
            arguments = []
        } else {
            arguments = [targetURL.path]
        }

        switch match.action.payloadMode {
        case .argument:
            _ = try await runProcess(
                executableURL: executableURL,
                arguments: arguments + (match.payload.isEmpty ? [] : [match.payload]),
                standardInputData: nil
            )
        case .stdin:
            _ = try await runProcess(
                executableURL: executableURL,
                arguments: arguments,
                standardInputData: scriptInput
            )
        }
    }

    private func runProcess(
        executableURL: URL,
        arguments: [String],
        standardInputData: Data?
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let task = Process()
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            let inputPipe = Pipe()

            task.executableURL = executableURL
            task.arguments = arguments
            task.standardOutput = outputPipe
            task.standardError = errorPipe

            if standardInputData != nil {
                task.standardInput = inputPipe
            }

            task.terminationHandler = { process in
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(decoding: outputData, as: UTF8.self)
                let errorOutput = String(decoding: errorData, as: UTF8.self)

                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    let message = errorOutput.isEmpty ? output : errorOutput
                    continuation.resume(throwing: VoiceCommandError.commandFailed(message.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
            }

            do {
                try task.run()
                if let standardInputData {
                    inputPipe.fileHandleForWriting.write(standardInputData)
                    inputPipe.fileHandleForWriting.closeFile()
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func applyPayload(_ payload: String, to target: String, percentEncode: Bool) -> String {
        let replacement: String
        if percentEncode {
            replacement = payload.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? payload
        } else {
            replacement = payload
        }

        return target.replacingOccurrences(of: "{{payload}}", with: replacement)
    }
}

extension Notification.Name {
    static let voiceCommandActionsDidChange = Notification.Name("VoiceCommandActionsDidChange")
}

extension KeyboardShortcuts.Name {
    static func voiceCommandAction(id: UUID) -> Self {
        Self("voiceCommandAction_\(id.uuidString)")
    }
}

private extension String {
    var containsCJKCharacters: Bool {
        unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x4E00...0x9FFF, 0x3400...0x4DBF, 0x3040...0x30FF, 0xAC00...0xD7AF:
                return true
            default:
                return false
            }
        }
    }
}
