import SwiftUI
import AppKit

struct DashboardPromotionsSection: View {
    let licenseState: LicenseViewModel.LicenseState
    @State private var isAffiliatePromotionDismissed: Bool = UserDefaults.standard.affiliatePromotionDismissed

    private var shouldShowUpgradePromotion: Bool {
        switch licenseState {
        case .trial(let daysRemaining):
            return daysRemaining <= 3
        case .trialExpired:
            return true
        case .licensed:
            return false
        }
    }

    private var shouldShowAffiliatePromotion: Bool {
        if case .licensed = licenseState {
            return !isAffiliatePromotionDismissed
        }
        return false
    }
    
    private var shouldShowPromotions: Bool {
        shouldShowUpgradePromotion || shouldShowAffiliatePromotion
    }
    
    var body: some View {
        if shouldShowPromotions {
            HStack(alignment: .top, spacing: 18) {
                if shouldShowUpgradePromotion {
                    DashboardPromotionCard(
                        badge: "30% OFF",
                        title: "分享 VoiceInk，解锁折扣",
                        message: "在社交平台分享 VoiceInk，即可立即解锁 VoiceInk Pro 七折优惠。",
                        accentSymbol: "megaphone.fill",
                        glowColor: Color(red: 0.08, green: 0.48, blue: 0.85),
                        actionTitle: "立即分享",
                        actionIcon: "arrow.up.right",
                        action: openSocialShare
                    )
                    .frame(maxWidth: .infinity)
                }
                
                if shouldShowAffiliatePromotion {
                    DashboardPromotionCard(
                        badge: "AFFILIATE 30%",
                        title: "加入 VoiceInk 推广计划",
                        message: "把 VoiceInk 分享给朋友或受众，每一次成功升级都可获得 30% 的返佣。",
                        accentSymbol: "link.badge.plus",
                        glowColor: Color(red: 0.08, green: 0.48, blue: 0.85),
                        actionTitle: "查看详情",
                        actionIcon: "arrow.up.right",
                        action: openAffiliateProgram,
                        onDismiss: dismissAffiliatePromotion
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            EmptyView()
        }
    }
    
    private func openSocialShare() {
        if let url = URL(string: "https://tryvoiceink.com/social-share") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openAffiliateProgram() {
        if let url = URL(string: "https://tryvoiceink.com/affiliate") {
            NSWorkspace.shared.open(url)
        }
    }

    private func dismissAffiliatePromotion() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isAffiliatePromotionDismissed = true
        }
        UserDefaults.standard.affiliatePromotionDismissed = true
    }
}

private struct DashboardPromotionCard: View {
    let badge: String
    let title: String
    let message: String
    let accentSymbol: String
    let glowColor: Color
    let actionTitle: String
    let actionIcon: String
    let action: () -> Void
    var onDismiss: (() -> Void)? = nil

    private static let defaultGradient: LinearGradient = LinearGradient(
        colors: [
            Color(red: 0.08, green: 0.48, blue: 0.85),
            Color(red: 0.05, green: 0.18, blue: 0.42)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 14) {
                Text(badge.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.8)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())
                    .foregroundColor(.white)

                Text(title)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: action) {
                    HStack(spacing: 6) {
                        Text(actionTitle)
                        Image(systemName: actionIcon)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(.white.opacity(0.22))
                    .clipShape(Capsule())
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .topLeading)

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .padding(12)
                .help("关闭这条推广卡片")
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Self.defaultGradient)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: glowColor.opacity(0.15), radius: 12, x: 0, y: 8)
    }
}
