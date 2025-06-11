import SwiftUI

// MARK: - Premium Upgrade Card
struct PremiumUpgradeCard: View {
    var body: some View {
        VStack(spacing: PSSpacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: PSSpacing.sm) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .font(PSTypography.title1)
                            .foregroundColor(.yellow)
                        
                        Text(L("profile.premium.title", table: "Profile"))
                            .font(PSTypography.headline)
                            .foregroundColor(.appTextOnPrimary)
                    }
                    
                    Text(L("profile.premium.description", table: "Profile"))
                        .font(PSTypography.body)
                        .foregroundColor(.appTextOnPrimary.opacity(0.9))
                }
                
                Spacer()
                
                VStack {
                    Text(L("profile.premium.upgrade", table: "Profile"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextOnPrimary)
                        .padding(.horizontal, PSSpacing.lg)
                        .padding(.vertical, PSSpacing.sm)
                        .background(
                            Capsule()
                                .fill(Color.appTextOnPrimary.opacity(0.25))
                        )
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(PSTypography.title1)
                        .foregroundColor(.appTextOnPrimary.opacity(0.7))
                }
            }
            
            // Premium Features
            HStack(spacing: PSSpacing.xl) {
                PremiumFeature(icon: "chart.line.uptrend.xyaxis", title: L("profile.premium.features.statistics", table: "Profile"))
                PremiumFeature(icon: "bell.badge", title: L("profile.premium.features.notifications", table: "Profile"))
                PremiumFeature(icon: "paintbrush", title: L("profile.premium.features.themes", table: "Profile"))
            }
        }
        .padding(PSSpacing.lg)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.appSecondary, Color.appAccent]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(PSCornerRadius.extraLarge)
        .shadow(color: Color.appSecondary.opacity(0.3), radius: PSSpacing.sm, x: 0, y: PSSpacing.xs)
        .contentShape(Rectangle()) // Tıklama alanını genişletmek için
    }
}

struct PremiumFeature: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: PSSpacing.xs) {
            Image(systemName: icon)
                .font(PSTypography.title1)
                .foregroundColor(.appTextOnPrimary)
            
            Text(title)
                .font(PSTypography.caption)
                .foregroundColor(.appTextOnPrimary.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
} 