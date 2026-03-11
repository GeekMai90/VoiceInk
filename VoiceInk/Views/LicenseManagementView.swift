import SwiftUI

struct LicenseManagementView: View {
    @StateObject private var licenseViewModel = LicenseViewModel()
    @Environment(\.colorScheme) private var colorScheme
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Section
                heroSection
                
                // Main Content
                VStack(spacing: 32) {
                    if case .licensed = licenseViewModel.licenseState {
                        activatedContent
                    } else {
                        purchaseContent
                    }
                }
                .padding(32)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var heroSection: some View {
        VStack(spacing: 24) {
            // App Icon
            AppIconView()
            
            // Title Section
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)
                    
                    HStack(alignment: .lastTextBaseline, spacing: 8) { 
                        Text(licenseViewModel.licenseState == .licensed ? "VoiceInk Ultra" : "升级到 Ultra")
                            .font(.system(size: 32, weight: .bold))
                        
                        Text("v\(appVersion)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                    }
                }
                
                Text(licenseViewModel.licenseState == .licensed ?
                     "感谢你支持 VoiceInk Ultra" :
                     "让 AI 把你的语音即时转成文字")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if case .licensed = licenseViewModel.licenseState {
                    HStack(spacing: 40) {
                        Button {
                            if let url = URL(string: "https://github.com/Beingpax/VoiceInk/releases") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            featureItem(icon: "list.bullet.clipboard.fill", title: "更新日志", color: .blue)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            if let url = URL(string: "https://discord.gg/xryDy57nYD") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            featureItem(icon: "bubble.left.and.bubble.right.fill", title: "Discord 社区", color: .purple)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            EmailSupport.openSupportEmail()
                        } label: {
                            featureItem(icon: "envelope.fill", title: "邮件支持", color: .orange)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            if let url = URL(string: "https://tryvoiceink.com/docs") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            featureItem(icon: "book.fill", title: "文档", color: .indigo)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            if let url = URL(string: "https://buymeacoffee.com/beingpax") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            animatedTipJarItem()
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(.vertical, 60)
    }
    
    private var purchaseContent: some View {
        VStack(spacing: 40) {
            // Purchase Card
            VStack(spacing: 24) {
                // Lifetime Access Badge
                HStack {
                    Image(systemName: "infinity.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.blue)
                    Text("一次购买，永久使用")
                        .font(.headline)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                // Purchase Button 
                Button(action: {
                    if let url = URL(string: "https://tryvoiceink.com/buy") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text("升级到 VoiceInk Ultra")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                
                // Features Grid
                HStack(spacing: 40) {
                    featureItem(icon: "bubble.left.and.bubble.right.fill", title: "优先支持", color: .purple)
                    featureItem(icon: "infinity.circle.fill", title: "永久使用", color: .blue)
                    featureItem(icon: "arrow.up.circle.fill", title: "免费更新", color: .green)
                    featureItem(icon: "macbook.and.iphone", title: "多设备使用", color: .orange)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(32)
            .background(CardBackground(isSelected: false))
            .shadow(color: .black.opacity(0.05), radius: 10)

            // License Activation
            VStack(spacing: 20) {
                Text("已经有许可证了？")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    TextField("输入你的许可证密钥", text: $licenseViewModel.licenseKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .textCase(.uppercase)
                    
                    Button(action: {
                        Task { await licenseViewModel.validateLicense() }
                    }) {
                        if licenseViewModel.isValidating {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("激活")
                                .frame(width: 80)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(licenseViewModel.isValidating)
                }
                
                if let message = licenseViewModel.validationMessage {
                    Text(message)
                        .foregroundColor(.red)
                        .font(.callout)
                }
            }
            .padding(32)
            .background(CardBackground(isSelected: false))
            .shadow(color: .black.opacity(0.05), radius: 10)
            
            // Already Purchased Section
            VStack(spacing: 20) {
                Text("已经购买了？")
                    .font(.headline)

                HStack(spacing: 12) {
                    Text("管理你的许可证和设备激活情况")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: {
                        if let url = URL(string: "https://polar.sh/beingpax/portal/request") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Text("许可证管理门户")
                            .frame(width: 180)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(32)
            .background(CardBackground(isSelected: false))
            .shadow(color: .black.opacity(0.05), radius: 10)
        }
    }
    
    private var activatedContent: some View {
        VStack(spacing: 32) {
            // Status Card
            VStack(spacing: 24) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.green)
                    Text("许可证已激活")
                        .font(.headline)
                    Spacer()
                    Text("已激活")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.green))
                        .foregroundStyle(.white)
                }
                
                Divider()
                
                if licenseViewModel.activationsLimit > 0 {
                    Text("这个许可证最多可在 \(licenseViewModel.activationsLimit) 台设备上激活")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("你可以在所有个人设备上使用 VoiceInk Ultra")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(32)
            .background(CardBackground(isSelected: false))
            .shadow(color: .black.opacity(0.05), radius: 10)
            
            // Deactivation Card
            VStack(alignment: .leading, spacing: 16) {
                Text("许可证管理")
                    .font(.headline)

                Button(role: .destructive, action: {
                    licenseViewModel.removeLicense()
                }) {
                    Label("停用许可证", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
            }
            .padding(32)
            .background(CardBackground(isSelected: false))
            .shadow(color: .black.opacity(0.05), radius: 10)
        }
    }
    
    private func featureItem(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
        }
    }
    
    @State private var heartPulse = false
    
    private func animatedTipJarItem() -> some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.pink)
                .scaleEffect(heartPulse ? 1.3 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true),
                    value: heartPulse
                )
                .onAppear {
                    heartPulse = true
                }
            
            Text("赞助支持")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
        }
    }
}
