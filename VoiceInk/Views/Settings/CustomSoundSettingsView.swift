import SwiftUI
import UniformTypeIdentifiers

struct CustomSoundSettingsView: View {
    @StateObject private var customSoundManager = CustomSoundManager.shared
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        Group {
            LabeledContent("开始提示音") {
                soundControls(for: .start)
            }

            LabeledContent("结束提示音") {
                soundControls(for: .stop)
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    @ViewBuilder
    private func soundControls(for type: CustomSoundManager.SoundType) -> some View {
        let isCustom = type == .start ? customSoundManager.isUsingCustomStartSound : customSoundManager.isUsingCustomStopSound
        let fileName = customSoundManager.getSoundDisplayName(for: type)

        HStack(spacing: 8) {
            Text(isCustom ? (fileName ?? "自定义") : "默认")
                .foregroundColor(.secondary)
                .frame(maxWidth: 100, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.middle)

            Button {
                if type == .start {
                    SoundManager.shared.playStartSound()
                } else {
                    SoundManager.shared.playStopSound()
                }
            } label: {
                Image(systemName: "play.fill")
            }
            .buttonStyle(.borderless)
            .help("试听")

            Button {
                selectSound(for: type)
            } label: {
                Image(systemName: "folder")
            }
            .buttonStyle(.borderless)
            .help("选择文件")

            if isCustom {
                Button {
                    customSoundManager.resetSoundToDefault(for: type)
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .buttonStyle(.borderless)
                .help("恢复默认")
            }
        }
    }

    private func selectSound(for type: CustomSoundManager.SoundType) {
        let panel = NSOpenPanel()
        panel.title = "选择\(type == .start ? "开始" : "结束")提示音"
        panel.message = "请选择一个音频文件"
        panel.allowedContentTypes = [
            UTType.audio,
            UTType.mp3,
            UTType.wav,
            UTType.aiff
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            let result = customSoundManager.setCustomSound(url: url, for: type)
            if case .failure(let error) = result {
                alertTitle = "无效的音频文件"
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
}

#Preview {
    CustomSoundSettingsView()
        .frame(width: 400)
        .padding()
}
