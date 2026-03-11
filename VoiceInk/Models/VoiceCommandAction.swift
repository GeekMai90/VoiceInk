import Foundation

enum VoiceCommandExecutorType: String, Codable, CaseIterable, Identifiable {
    case shortcuts
    case script
    case alfred

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .shortcuts:
            return "Apple Shortcuts"
        case .script:
            return "Script"
        case .alfred:
            return "Alfred URL"
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
            return "Argument"
        case .stdin:
            return "Standard Input"
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

    static let empty = VoiceCommandAction(
        name: "",
        spokenAliases: [],
        executorType: .shortcuts,
        target: ""
    )
}
