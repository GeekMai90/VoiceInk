import SwiftUI
import Combine
import AppKit

struct ParakeetModelCardRowView: View {
    let model: ParakeetModel
    @ObservedObject var parakeetModelManager: ParakeetModelManager
    @ObservedObject var transcriptionModelManager: TranscriptionModelManager

    var isCurrent: Bool {
        transcriptionModelManager.currentTranscriptionModel?.name == model.name
    }

    var isDownloaded: Bool {
        parakeetModelManager.isParakeetModelDownloaded(model)
    }

    var isDownloading: Bool {
        parakeetModelManager.isParakeetModelDownloading(model)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                headerSection
                metadataSection
                descriptionSection
                progressSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            actionSection
        }
        .padding(16)
        .background(CardBackground(isSelected: isCurrent, useAccentGradientWhenSelected: isCurrent))
    }

    private var headerSection: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(model.displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.labelColor))

            statusBadge
            Spacer()
        }
    }

    private var statusBadge: some View {
        Group {
            if isCurrent {
                Text("默认")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.accentColor))
                    .foregroundColor(.white)
            } else if isDownloaded {
                Text("已下载")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color(.quaternaryLabelColor)))
                    .foregroundColor(Color(.labelColor))
            }
        }
    }

    private var metadataSection: some View {
        HStack(spacing: 12) {
            Label(model.language, systemImage: "globe")
            Label(model.size, systemImage: "internaldrive")
            HStack(spacing: 3) {
                Text("速度")
                progressDotsWithNumber(value: model.speed * 10)
            }
            .fixedSize(horizontal: true, vertical: false)
            HStack(spacing: 3) {
                Text("准确度")
                progressDotsWithNumber(value: model.accuracy * 10)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .font(.system(size: 11))
        .foregroundColor(Color(.secondaryLabelColor))
        .lineLimit(1)
    }

    private var descriptionSection: some View {
        Text(model.description)
            .font(.system(size: 11))
            .foregroundColor(Color(.secondaryLabelColor))
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 4)
    }

    private var progressSection: some View {
        Group {
            if isDownloading {
                let progress = parakeetModelManager.downloadProgress[model.name] ?? 0.0
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            }
        }
    }

    private var actionSection: some View {
        HStack(spacing: 8) {
            if isCurrent {
                Text("当前默认模型")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.secondaryLabelColor))
            } else if isDownloaded {
                Button(action: {
                    Task {
                        transcriptionModelManager.setDefaultTranscriptionModel(model)
                    }
                }) {
                    Text("设为默认")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Button(action: {
                    Task {
                        await parakeetModelManager.downloadParakeetModel(model)
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isDownloading ? "下载中..." : "下载")
                        Image(systemName: "arrow.down.circle")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.accentColor))
                }
                .buttonStyle(.plain)
                .disabled(isDownloading)
            }

            if isDownloaded {
                Menu {
                    Button(action: {
                        parakeetModelManager.deleteParakeetModel(model)
                    }) {
                        Label("删除模型", systemImage: "trash")
                    }

                    Button {
                        parakeetModelManager.showParakeetModelInFinder(model)
                    } label: {
                        Label("在 Finder 中显示", systemImage: "folder")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 14))
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 20, height: 20)
            }
        }
    }
}
