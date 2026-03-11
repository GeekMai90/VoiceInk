import SwiftUI

struct DiagnosticsSettingsView: View {
    @State private var isExportingLogs = false
    @State private var exportedLogURL: URL?
    @State private var showLogExportError = false
    @State private var logExportError: String = ""

    var body: some View {
        LabeledContent {
            HStack(spacing: 8) {
                if let url = exportedLogURL {
                    Button("在 Finder 中显示") {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }

                Button("导出") {
                    exportDiagnosticLogs()
                }
                .disabled(isExportingLogs)
            }
        } label: {
            HStack(spacing: 4) {
                if isExportingLogs {
                    ProgressView()
                        .controlSize(.small)
                }
                Text("导出日志")
            }
        }
        .alert("导出失败", isPresented: $showLogExportError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(logExportError)
        }
    }

    private func exportDiagnosticLogs() {
        isExportingLogs = true
        exportedLogURL = nil

        Task {
            do {
                let url = try await LogExporter.shared.exportLogs()
                await MainActor.run {
                    exportedLogURL = url
                    isExportingLogs = false
                }
            } catch {
                await MainActor.run {
                    logExportError = error.localizedDescription
                    showLogExportError = true
                    isExportingLogs = false
                }
            }
        }
    }
}
