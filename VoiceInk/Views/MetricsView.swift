import SwiftUI
import SwiftData
import Charts
import KeyboardShortcuts

struct MetricsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @StateObject private var licenseViewModel = LicenseViewModel()
    
    var body: some View {
        VStack {
            // Trial Message
            if case .trial(let daysRemaining) = licenseViewModel.licenseState {
                TrialMessageView(
                    message: "试用还剩 \(daysRemaining) 天",
                    type: daysRemaining <= 2 ? .warning : .info,
                    onAddLicenseKey: {
                        // Post notification to navigate to VoiceInk Pro tab
                        NotificationCenter.default.post(
                            name: .navigateToDestination,
                            object: nil,
                            userInfo: ["destination": "VoiceInk Pro"]
                        )
                    }
                )
                .padding()
            } else if case .trialExpired = licenseViewModel.licenseState {
                TrialMessageView(
                    message: "试用已结束，升级后可继续使用 VoiceInk",
                    type: .expired,
                    onAddLicenseKey: {
                        // Also allow navigation from expired state
                        NotificationCenter.default.post(
                            name: .navigateToDestination,
                            object: nil,
                            userInfo: ["destination": "VoiceInk Pro"]
                        )
                    }
                )
                .padding()
            }

            MetricsContent(
                modelContext: modelContext,
                licenseState: licenseViewModel.licenseState
            )
        }
        .background(Color(.controlBackgroundColor))
    }
}
