import SwiftUI
import SwiftData
import KeyboardShortcuts

// ViewType enum with all cases
enum ViewType: String, CaseIterable, Identifiable {
    case metrics = "Dashboard"
    case transcribeAudio = "Transcribe Audio"
    case history = "History"
    case models = "AI Models"
    case enhancement = "Enhancement"
    case voiceCommand = "语音命令"
    case powerMode = "Power Mode"
    case permissions = "Permissions"
    case audioInput = "Audio Input"
    case dictionary = "Dictionary"
    case settings = "Settings"
    case license = "VoiceInk Pro"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .metrics: return "概览"
        case .transcribeAudio: return "音频转写"
        case .history: return "历史记录"
        case .models: return "AI 模型"
        case .enhancement: return "AI 增强"
        case .voiceCommand: return "语音命令"
        case .powerMode: return "场景模式"
        case .permissions: return "权限"
        case .audioInput: return "音频输入"
        case .dictionary: return "词典"
        case .settings: return "设置"
        case .license: return "Ultra 权益"
        }
    }

    var icon: String {
        switch self {
        case .metrics: return "gauge.medium"
        case .transcribeAudio: return "waveform.circle.fill"
        case .history: return "doc.text.fill"
        case .models: return "brain.head.profile"
        case .enhancement: return "wand.and.stars"
        case .voiceCommand: return "waveform.badge.mic"
        case .powerMode: return "sparkles.square.fill.on.square"
        case .permissions: return "shield.fill"
        case .audioInput: return "mic.fill"
        case .dictionary: return "character.book.closed.fill"
        case .settings: return "gearshape.fill"
        case .license: return "checkmark.seal.fill"
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var engine: VoiceInkEngine
    @EnvironmentObject private var whisperModelManager: WhisperModelManager
    @EnvironmentObject private var transcriptionModelManager: TranscriptionModelManager
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @AppStorage("powerModeUIFlag") private var powerModeUIFlag = false
    @State private var selectedView: ViewType? = .metrics
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    @StateObject private var licenseViewModel = LicenseViewModel()

    private var visibleViewTypes: [ViewType] {
        ViewType.allCases.filter { viewType in
            if viewType == .powerMode {
                return powerModeUIFlag
            }
            return true
        }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedView) {
                Section {
                    // App Header
                    HStack(spacing: 6) {
                        if let appIcon = NSImage(named: "AppIcon") {
                            Image(nsImage: appIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 28, height: 28)
                                .cornerRadius(8)
                        }

                        Text("VoiceInk")
                            .font(.system(size: 14, weight: .semibold))

                        if case .licensed = licenseViewModel.licenseState {
                            ProBadge()
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }

                ForEach(visibleViewTypes) { viewType in
                    Section {
                        if viewType == .history {
                            Button(action: {
                                HistoryWindowController.shared.showHistoryWindow(
                                    modelContainer: modelContext.container,
                                    engine: engine
                                )
                            }) {
                                SidebarItemView(viewType: viewType)
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowSeparator(.hidden)
                        } else {
                            NavigationLink(value: viewType) {
                                SidebarItemView(viewType: viewType)
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("VoiceInk")
            .navigationSplitViewColumnWidth(210)
        } detail: {
            if let selectedView = selectedView {
                detailView(for: selectedView)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle(selectedView.displayName)
            } else {
                Text("请选择一个页面")
                    .foregroundColor(.secondary)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(width: 950)
        .frame(minHeight: 730)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToDestination)) { notification in
            if let destination = notification.userInfo?["destination"] as? String {
                switch destination {
                case "Settings":
                    selectedView = .settings
                case "AI Models":
                    selectedView = .models
                case "VoiceInk Pro":
                    selectedView = .license
                case "History":
                    HistoryWindowController.shared.showHistoryWindow(
                        modelContainer: modelContext.container,
                        engine: engine
                    )
                case "Permissions":
                    selectedView = .permissions
                case "Enhancement":
                    selectedView = .enhancement
                case "语音命令":
                    selectedView = .voiceCommand
                case "Transcribe Audio":
                    selectedView = .transcribeAudio
                case "Power Mode":
                    selectedView = .powerMode
                default:
                    break
                }
            }
        }
    }
    
    @ViewBuilder
    private func detailView(for viewType: ViewType) -> some View {
        switch viewType {
        case .metrics:
            MetricsView()
        case .models:
            ModelManagementView()
        case .enhancement:
            EnhancementSettingsView()
        case .voiceCommand:
            VoiceCommandView()
        case .transcribeAudio:
            AudioTranscribeView()
        case .history:
            Text("历史记录")
                .foregroundColor(.secondary)
        case .audioInput:
            AudioInputSettingsView()
        case .dictionary:
            DictionarySettingsView(whisperPrompt: whisperModelManager.whisperPrompt)
        case .powerMode:
            PowerModeView()
        case .settings:
            SettingsView()
        case .license:
            LicenseManagementView()
        case .permissions:
            PermissionsView()
        }
    }
}

private struct SidebarItemView: View {
    let viewType: ViewType

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: viewType.icon)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 24, height: 24)

            Text(viewType.displayName)
                .font(.system(size: 14, weight: .medium))

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
    }
}
