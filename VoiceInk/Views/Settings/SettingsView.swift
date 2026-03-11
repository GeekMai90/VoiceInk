import SwiftUI
import Cocoa
import KeyboardShortcuts
import LaunchAtLogin
import AVFoundation

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var updaterViewModel: UpdaterViewModel
    @EnvironmentObject private var menuBarManager: MenuBarManager
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @EnvironmentObject private var recorderUIManager: RecorderUIManager
    @EnvironmentObject private var transcriptionModelManager: TranscriptionModelManager
    @EnvironmentObject private var enhancementService: AIEnhancementService
    @StateObject private var deviceManager = AudioDeviceManager.shared
    @ObservedObject private var soundManager = SoundManager.shared
    @ObservedObject private var mediaController = MediaController.shared
    @ObservedObject private var playbackController = PlaybackController.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("autoUpdateCheck") private var autoUpdateCheck = true
    @AppStorage("enableAnnouncements") private var enableAnnouncements = true
    @AppStorage("restoreClipboardAfterPaste") private var restoreClipboardAfterPaste = true
    @AppStorage("clipboardRestoreDelay") private var clipboardRestoreDelay = 2.0
    @AppStorage("useAppleScriptPaste") private var useAppleScriptPaste = false
    @State private var showResetOnboardingAlert = false
    @State private var currentShortcut = KeyboardShortcuts.getShortcut(for: .toggleMiniRecorder)
    @State private var isCustomCancelEnabled = KeyboardShortcuts.getShortcut(for: .cancelRecorder) != nil

    // Expansion states - all collapsed by default
    @State private var isCustomCancelExpanded = false
    @State private var isMiddleClickExpanded = false
    @State private var isSoundFeedbackExpanded = false
    @State private var isMuteSystemExpanded = false
    @State private var isRestoreClipboardExpanded = false

    var body: some View {
        Form {
            // MARK: - Shortcuts
            Section {
                LabeledContent("快捷键 1") {
                    HStack(spacing: 8) {
                        hotkeyPicker(binding: $hotkeyManager.selectedHotkey1)
                        if hotkeyManager.selectedHotkey1 == .custom {
                            KeyboardShortcuts.Recorder(for: .toggleMiniRecorder)
                                .controlSize(.small)
                        }
                    }
                }

                if hotkeyManager.selectedHotkey2 != .none {
                    LabeledContent("快捷键 2") {
                        HStack(spacing: 8) {
                            hotkeyPicker(binding: $hotkeyManager.selectedHotkey2)
                            if hotkeyManager.selectedHotkey2 == .custom {
                                KeyboardShortcuts.Recorder(for: .toggleMiniRecorder2)
                                    .controlSize(.small)
                            }
                            Button {
                                withAnimation { hotkeyManager.selectedHotkey2 = .none }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if hotkeyManager.selectedHotkey1 != .none && hotkeyManager.selectedHotkey2 == .none {
                    Button("添加第二组快捷键") {
                        withAnimation { hotkeyManager.selectedHotkey2 = .rightOption }
                    }
                }
            } header: {
                Text("快捷键")
            } footer: {
                Text("轻按可免手持开始录音，按住则进入按住说话模式。")
            }

            // MARK: - Additional Shortcuts
            Section("附加快捷键") {
                LabeledContent("翻译模式") {
                    KeyboardShortcuts.Recorder(for: .toggleTranslationRecorder)
                        .controlSize(.small)
                }

                LabeledContent("粘贴上一条原始转写") {
                    KeyboardShortcuts.Recorder(for: .pasteLastTranscription)
                        .controlSize(.small)
                }

                LabeledContent("粘贴上一条增强结果") {
                    KeyboardShortcuts.Recorder(for: .pasteLastEnhancement)
                        .controlSize(.small)
                }

                LabeledContent("重试上一条转写") {
                    KeyboardShortcuts.Recorder(for: .retryLastTranscription)
                        .controlSize(.small)
                }

                // Custom Cancel - hierarchical
                ExpandableSettingsRow(
                    isExpanded: $isCustomCancelExpanded,
                    isEnabled: $isCustomCancelEnabled,
                    label: "自定义取消快捷键"
                ) {
                    LabeledContent("快捷键") {
                        KeyboardShortcuts.Recorder(for: .cancelRecorder)
                            .controlSize(.small)
                    }
                }
                .onChange(of: isCustomCancelEnabled) { _, newValue in
                    if !newValue {
                        KeyboardShortcuts.setShortcut(nil, for: .cancelRecorder)
                        isCustomCancelExpanded = false
                    }
                }

                // Middle-Click
                ExpandableSettingsRow(
                    isExpanded: $isMiddleClickExpanded,
                    isEnabled: $hotkeyManager.isMiddleClickToggleEnabled,
                    label: "中键录音"
                ) {
                    LabeledContent("触发延迟") {
                        HStack {
                            TextField("", value: $hotkeyManager.middleClickActivationDelay, formatter: {
                                let formatter = NumberFormatter()
                                formatter.minimum = 0
                                return formatter
                            }())
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                            Text("毫秒")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // MARK: - Recording Feedback
            Section("录音反馈") {
                // Sound Feedback
                ExpandableSettingsRow(
                    isExpanded: $isSoundFeedbackExpanded,
                    isEnabled: $soundManager.isEnabled,
                    label: "声音反馈"
                ) {
                    CustomSoundSettingsView()
                }

                // Mute System Audio
                ExpandableSettingsRow(
                    isExpanded: $isMuteSystemExpanded,
                    isEnabled: $mediaController.isSystemMuteEnabled,
                    label: "录音时静音系统音频"
                ) {
                    Picker("恢复延迟", selection: $mediaController.audioResumptionDelay) {
                        Text("0 秒").tag(0.0)
                        Text("1 秒").tag(1.0)
                        Text("2 秒").tag(2.0)
                        Text("3 秒").tag(3.0)
                        Text("4 秒").tag(4.0)
                        Text("5 秒").tag(5.0)
                    }
                }

                // Restore Clipboard
                ExpandableSettingsRow(
                    isExpanded: $isRestoreClipboardExpanded,
                    isEnabled: $restoreClipboardAfterPaste,
                    label: "粘贴后恢复剪贴板"
                ) {
                    Picker("恢复延迟", selection: $clipboardRestoreDelay) {
                        Text("250 毫秒").tag(0.25)
                        Text("500 毫秒").tag(0.5)
                        Text("1 秒").tag(1.0)
                        Text("2 秒").tag(2.0)
                        Text("3 秒").tag(3.0)
                        Text("4 秒").tag(4.0)
                        Text("5 秒").tag(5.0)
                    }
                }

                // AppleScript Paste
                Toggle(isOn: $useAppleScriptPaste) {
                    HStack(spacing: 4) {
                        Text("使用 AppleScript 粘贴")
                        InfoTip("如果当前键盘布局下普通粘贴不稳定，例如 Neo2，可开启此项。开启后会使用 AppleScript，而不是模拟按键事件。")
                    }
                }
            }

            // MARK: - Power Mode
            PowerModeSection()

            // MARK: - Interface
            Section("界面") {
                Picker("录音器样式", selection: $recorderUIManager.recorderType) {
                    Text("刘海").tag("notch")
                    Text("迷你").tag("mini")
                }
                .pickerStyle(.segmented)

            }
            // MARK: - Experimental
            ExperimentalSection()

            // MARK: - General
            Section("通用") {
                Toggle("隐藏 Dock 图标", isOn: $menuBarManager.isMenuBarOnly)

                LaunchAtLogin.Toggle("登录时启动")

                Toggle("自动检查更新", isOn: $autoUpdateCheck)
                    .onChange(of: autoUpdateCheck) { _, newValue in
                        updaterViewModel.toggleAutoUpdates(newValue)
                    }

                Toggle("显示公告", isOn: $enableAnnouncements)
                    .onChange(of: enableAnnouncements) { _, newValue in
                        if newValue {
                            AnnouncementsService.shared.start()
                        } else {
                            AnnouncementsService.shared.stop()
                        }
                    }

                HStack {
                    Button("检查更新") {
                        updaterViewModel.checkForUpdates()
                    }
                    .disabled(!updaterViewModel.canCheckForUpdates)

                    Button("重置引导") {
                        showResetOnboardingAlert = true
                    }
                }
            }

            // MARK: - Privacy
            Section {
                AudioCleanupSettingsView()
            } header: {
                Text("隐私")
            } footer: {
                Text("控制 VoiceInk 如何处理你的转写记录和音频文件。")
            }

            // MARK: - Backup
            Section {
                LabeledContent("导出设置") {
                    Button("导出") {
                        ImportExportService.shared.exportSettings(
                            enhancementService: enhancementService,
                            whisperPrompt: WhisperPrompt(),
                            hotkeyManager: hotkeyManager,
                            menuBarManager: menuBarManager,
                            mediaController: mediaController,
                            playbackController: playbackController,
                            soundManager: soundManager,
                            recorderUIManager: recorderUIManager,
                            modelContext: modelContext
                        )
                    }
                }

                LabeledContent("导入设置") {
                    Button("导入") {
                        ImportExportService.shared.importSettings(
                            enhancementService: enhancementService,
                            whisperPrompt: WhisperPrompt(),
                            hotkeyManager: hotkeyManager,
                            menuBarManager: menuBarManager,
                            mediaController: mediaController,
                            playbackController: playbackController,
                            soundManager: soundManager,
                            recorderUIManager: recorderUIManager,
                            modelContext: modelContext,
                            transcriptionModelManager: transcriptionModelManager
                        )
                    }
                }
            } header: {
                Text("备份")
            } footer: {
                Text("导出或导入全部设置，包括提示词、场景模式、词典和自定义模型。")
            }

            // MARK: - Diagnostics
            Section("诊断") {
                DiagnosticsSettingsView()
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color(NSColor.controlBackgroundColor))
        .alert("重置引导", isPresented: $showResetOnboardingAlert) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) {
                DispatchQueue.main.async {
                    hasCompletedOnboarding = false
                }
            }
        } message: {
            Text("下次启动应用时，你会再次看到首次引导流程。")
        }
    }

    @ViewBuilder
    private func hotkeyPicker(binding: Binding<HotkeyManager.HotkeyOption>) -> some View {
        Picker("", selection: binding) {
            ForEach(HotkeyManager.HotkeyOption.allCases, id: \.self) { option in
                Text(option.displayName).tag(option)
            }
        }
        .labelsHidden()
        .frame(width: 140)
    }
}

// MARK: - Expandable Settings Row (entire row clickable)

struct ExpandableSettingsRow<Content: View>: View {
    @Binding var isExpanded: Bool
    @Binding var isEnabled: Bool
    let label: String
    var infoMessage: String? = nil
    var infoURL: String? = nil
    @ViewBuilder let content: () -> Content

    @State private var isHandlingToggleChange = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row - entire area is tappable
            HStack {
                Toggle(isOn: $isEnabled) {
                    HStack(spacing: 4) {
                        Text(label)
                        if let message = infoMessage {
                            if let url = infoURL {
                                InfoTip(message, learnMoreURL: url)
                            } else {
                                InfoTip(message)
                            }
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isEnabled && isExpanded ? 90 : 0))
                    .opacity(isEnabled ? 1 : 0.4)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard !isHandlingToggleChange else { return }
                if isEnabled {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
            }

            // Expanded content with proper spacing
            if isEnabled && isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    content()
                }
                .padding(.top, 12)
                .padding(.leading, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
        .onChange(of: isEnabled) { _, newValue in
            isHandlingToggleChange = true
            if newValue {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded = true
                }
            } else {
                isExpanded = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isHandlingToggleChange = false
            }
        }
    }
}

// MARK: - Power Mode Section

struct PowerModeSection: View {
    @ObservedObject private var powerModeManager = PowerModeManager.shared
    @AppStorage("powerModeUIFlag") private var powerModeUIFlag = false
    @AppStorage(PowerModeDefaults.autoRestoreKey) private var powerModeAutoRestoreEnabled = false
    @State private var showDisableAlert = false
    @State private var isExpanded = false

    var body: some View {
        Section {
            ExpandableSettingsRow(
                isExpanded: $isExpanded,
                isEnabled: toggleBinding,
                label: "场景模式",
                infoMessage: "根据当前使用的应用或网站自动套用对应设置。",
                infoURL: "https://tryvoiceink.com/docs/power-mode"
            ) {
                Toggle(isOn: $powerModeAutoRestoreEnabled) {
                    HStack(spacing: 4) {
                        Text("自动恢复偏好")
                        InfoTip("每次录音结束后，把被场景模式改动过的设置恢复到激活前的状态。")
                    }
                }
            }
        } header: {
            Text("场景模式")
        }
        .alert("场景模式仍在启用", isPresented: $showDisableAlert) {
            Button("知道了", role: .cancel) { }
        } message: {
            Text("请先停用或删除现有场景模式。")
        }
    }

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { powerModeUIFlag },
            set: { newValue in
                if newValue {
                    powerModeUIFlag = true
                } else if powerModeManager.configurations.allSatisfy({ !$0.isEnabled }) {
                    powerModeUIFlag = false
                } else {
                    showDisableAlert = true
                }
            }
        )
    }
}

// MARK: - Experimental Section

struct ExperimentalSection: View {
    @ObservedObject private var playbackController = PlaybackController.shared
    @ObservedObject private var mediaController = MediaController.shared
    @State private var isPauseMediaExpanded = false

    var body: some View {
        Section {
            ExpandableSettingsRow(
                isExpanded: $isPauseMediaExpanded,
                isEnabled: $playbackController.isPauseMediaEnabled,
                label: "录音时暂停媒体播放",
                infoMessage: "开始录音时暂停正在播放的媒体，录音结束后再恢复。"
            ) {
                Picker("恢复延迟", selection: $mediaController.audioResumptionDelay) {
                    Text("0 秒").tag(0.0)
                    Text("1 秒").tag(1.0)
                    Text("2 秒").tag(2.0)
                    Text("3 秒").tag(3.0)
                    Text("4 秒").tag(4.0)
                    Text("5 秒").tag(5.0)
                }
            }
        } header: {
            Text("实验功能")
        }
    }
}

// MARK: - Text Extension

extension Text {
    func settingsDescription() -> some View {
        self
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Power Mode Defaults

enum PowerModeDefaults {
    static let autoRestoreKey = "powerModeAutoRestoreEnabled"
}
