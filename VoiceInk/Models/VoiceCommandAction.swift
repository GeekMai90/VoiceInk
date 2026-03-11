import Foundation

enum VoiceCommandExecutorType: String, Codable, CaseIterable, Identifiable {
    case shortcuts
    case script
    case alfred

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .shortcuts:
            return "快捷指令"
        case .script:
            return "脚本"
        case .alfred:
            return "Alfred"
        }
    }
}

enum VoiceCommandPayloadMode: String, Codable, CaseIterable, Identifiable {
    case argument
    case stdin

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .argument:
            return "参数"
        case .stdin:
            return "标准输入"
        }
    }
}

struct VoiceCommandAction: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var spokenAliases: [String]
    var executorType: VoiceCommandExecutorType
    var target: String
    var payloadMode: VoiceCommandPayloadMode
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        spokenAliases: [String],
        executorType: VoiceCommandExecutorType,
        target: String,
        payloadMode: VoiceCommandPayloadMode = .argument,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.spokenAliases = spokenAliases
        self.executorType = executorType
        self.target = target
        self.payloadMode = payloadMode
        self.isEnabled = isEnabled
    }

    static var empty: VoiceCommandAction {
        VoiceCommandAction(
            name: "",
            spokenAliases: [],
            executorType: .shortcuts,
            target: ""
        )
    }
}
