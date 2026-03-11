import Foundation
import KeyboardShortcuts

@MainActor
final class VoiceCommandShortcutManager {
    private weak var engine: VoiceInkEngine?
    private weak var recorderUIManager: RecorderUIManager?
    private var registeredActionIds: Set<UUID> = []

    init(engine: VoiceInkEngine, recorderUIManager: RecorderUIManager) {
        self.engine = engine
        self.recorderUIManager = recorderUIManager

        setupVoiceCommandHotkeys()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(voiceCommandActionsDidChange),
            name: .voiceCommandActionsDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func voiceCommandActionsDidChange() {
        Task { @MainActor in
            setupVoiceCommandHotkeys()
        }
    }

    private func setupVoiceCommandHotkeys() {
        let actions = VoiceCommandManager.shared.actions
        let actionsWithShortcuts = Set(actions.filter { $0.hotkeyShortcut != nil }.map(\.id))

        let idsToRemove = registeredActionIds.subtracting(actionsWithShortcuts)
        idsToRemove.forEach { id in
            KeyboardShortcuts.setShortcut(nil, for: .voiceCommandAction(id: id))
            registeredActionIds.remove(id)
        }

        for action in actions {
            guard action.hotkeyShortcut != nil else { continue }
            guard !registeredActionIds.contains(action.id) else { continue }

            KeyboardShortcuts.onKeyUp(for: .voiceCommandAction(id: action.id)) { [weak self] in
                guard let self else { return }
                Task { @MainActor in
                    await self.handleVoiceCommandHotkey(actionId: action.id)
                }
            }

            registeredActionIds.insert(action.id)
        }
    }

    private func handleVoiceCommandHotkey(actionId: UUID) async {
        guard let engine, let recorderUIManager else { return }
        guard canProcessHotkeyAction(engine: engine) || recorderUIManager.isMiniRecorderVisible else { return }
        guard let action = VoiceCommandManager.shared.actions.first(where: { $0.id == actionId && $0.isEnabled }) else { return }
        guard action.hotkeyShortcut != nil else { return }

        await recorderUIManager.toggleMiniRecorder(
            outputMode: .voiceCommand,
            voiceCommandActionId: actionId
        )
    }

    private func canProcessHotkeyAction(engine: VoiceInkEngine) -> Bool {
        engine.recordingState != .transcribing &&
        engine.recordingState != .enhancing &&
        engine.recordingState != .busy
    }
}
