import SwiftUI
import SwiftData

struct AudioCleanupSettingsView: View {
    @Environment(\.modelContext) private var modelContext

    // Audio cleanup settings
    @AppStorage("IsTranscriptionCleanupEnabled") private var isTranscriptionCleanupEnabled = false
    @AppStorage("TranscriptionRetentionMinutes") private var transcriptionRetentionMinutes = 24 * 60
    @AppStorage("IsAudioCleanupEnabled") private var isAudioCleanupEnabled = false
    @AppStorage("AudioRetentionPeriod") private var audioRetentionPeriod = 7
    @State private var isPerformingCleanup = false
    @State private var isShowingConfirmation = false
    @State private var cleanupInfo: (fileCount: Int, totalSize: Int64, transcriptions: [Transcription]) = (0, 0, [])
    @State private var showResultAlert = false
    @State private var cleanupResult: (deletedCount: Int, errorCount: Int) = (0, 0)
    @State private var showTranscriptCleanupResult = false

    // Expansion states - collapsed by default
    @State private var isTranscriptExpanded = false
    @State private var isAudioExpanded = false
    @State private var isHandlingTranscriptToggle = false
    @State private var isHandlingAudioToggle = false

    var body: some View {
        Group {
            // Transcript cleanup - hierarchical
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Toggle(isOn: $isTranscriptionCleanupEnabled) {
                        HStack(spacing: 4) {
                            Text("自动删除转写记录")
                            InfoTip("按照你设定的保留时长，自动清理历史转写记录。")
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isTranscriptionCleanupEnabled && isTranscriptExpanded ? 90 : 0))
                        .opacity(isTranscriptionCleanupEnabled ? 1 : 0.4)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !isHandlingTranscriptToggle else { return }
                    if isTranscriptionCleanupEnabled {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isTranscriptExpanded.toggle()
                        }
                    }
                }

                    if isTranscriptionCleanupEnabled && isTranscriptExpanded {
                        VStack(alignment: .leading, spacing: 8) {
                        Picker("删除时间", selection: $transcriptionRetentionMinutes) {
                            Text("立即").tag(0)
                            Text("1 小时").tag(60)
                            Text("1 天").tag(24 * 60)
                            Text("3 天").tag(3 * 24 * 60)
                            Text("7 天").tag(7 * 24 * 60)
                        }

                        Button("立即清理") {
                            Task {
                                await TranscriptionAutoCleanupService.shared.runManualCleanup(modelContext: modelContext)
                                await MainActor.run {
                                    showTranscriptCleanupResult = true
                                }
                            }
                        }
                    }
                    .padding(.top, 12)
                    .padding(.leading, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isTranscriptExpanded)
            .alert("转写记录清理", isPresented: $showTranscriptCleanupResult) {
                Button("确定", role: .cancel) { }
            } message: {
                Text("清理完成。")
            }
            .onChange(of: isTranscriptionCleanupEnabled) { _, newValue in
                isHandlingTranscriptToggle = true
                if newValue {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isTranscriptExpanded = true
                    }
                    AudioCleanupManager.shared.stopAutomaticCleanup()
                } else {
                    isTranscriptExpanded = false
                    if isAudioCleanupEnabled {
                        AudioCleanupManager.shared.startAutomaticCleanup(modelContext: modelContext)
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isHandlingTranscriptToggle = false
                }
            }

            // Audio cleanup - only show if transcript cleanup is disabled
            if !isTranscriptionCleanupEnabled {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Toggle(isOn: $isAudioCleanupEnabled) {
                            HStack(spacing: 4) {
                                Text("自动删除音频文件")
                                InfoTip("自动清理录音文件，同时保留对应的文字转写记录。")
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isAudioCleanupEnabled && isAudioExpanded ? 90 : 0))
                            .opacity(isAudioCleanupEnabled ? 1 : 0.4)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !isHandlingAudioToggle else { return }
                        if isAudioCleanupEnabled {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isAudioExpanded.toggle()
                            }
                        }
                    }

                    if isAudioCleanupEnabled && isAudioExpanded {
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("音频保留时长", selection: $audioRetentionPeriod) {
                                Text("1 天").tag(1)
                                Text("3 天").tag(3)
                                Text("7 天").tag(7)
                                Text("14 天").tag(14)
                                Text("30 天").tag(30)
                            }

                            Button(isPerformingCleanup ? "分析中..." : "立即清理") {
                                Task {
                                    await MainActor.run { isPerformingCleanup = true }
                                    let info = await AudioCleanupManager.shared.getCleanupInfo(modelContext: modelContext)
                                    await MainActor.run {
                                        cleanupInfo = info
                                        isPerformingCleanup = false
                                        isShowingConfirmation = true
                                    }
                                }
                            }
                            .disabled(isPerformingCleanup)
                        }
                        .padding(.top, 12)
                        .padding(.leading, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isAudioExpanded)
                .alert("音频清理", isPresented: $isShowingConfirmation) {
                    Button("取消", role: .cancel) { }

                    if cleanupInfo.fileCount > 0 {
                        Button("删除 \(cleanupInfo.fileCount) 个文件", role: .destructive) {
                            Task {
                                await MainActor.run { isPerformingCleanup = true }
                                let result = await AudioCleanupManager.shared.runCleanupForTranscriptions(
                                    modelContext: modelContext,
                                    transcriptions: cleanupInfo.transcriptions
                                )
                                await MainActor.run {
                                    cleanupResult = result
                                    isPerformingCleanup = false
                                    showResultAlert = true
                                }
                            }
                        }
                    }
                } message: {
                    if cleanupInfo.fileCount > 0 {
                        Text("这将删除 \(cleanupInfo.fileCount) 个音频文件，共 \(AudioCleanupManager.shared.formatFileSize(cleanupInfo.totalSize))。")
                    } else {
                        Text("没有找到超过 \(audioRetentionPeriod) 天的音频文件。")
                    }
                }
                .alert("清理完成", isPresented: $showResultAlert) {
                    Button("确定", role: .cancel) { }
                } message: {
                    if cleanupResult.errorCount > 0 {
                        Text("已删除 \(cleanupResult.deletedCount) 个文件，失败 \(cleanupResult.errorCount) 个。")
                    } else {
                        Text("已删除 \(cleanupResult.deletedCount) 个音频文件。")
                    }
                }
                .onChange(of: isAudioCleanupEnabled) { _, newValue in
                    isHandlingAudioToggle = true
                    if newValue {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isAudioExpanded = true
                        }
                    } else {
                        isAudioExpanded = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isHandlingAudioToggle = false
                    }
                }
            }
        }
    }
}
