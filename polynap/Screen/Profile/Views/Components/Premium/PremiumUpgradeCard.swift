import SwiftUI

// MARK: - Premium Upgrade Card
struct PremiumUpgradeCard: View {
    var body: some View {
        HStack(spacing: PSSpacing.md) {
            // Sol taraf - İkon ve başlık
            HStack(spacing: PSSpacing.sm) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("profile.premium.title", table: "Profile"))
                        .font(PSTypography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.appTextOnPrimary)
                    
                    Text(L("profile.premium.description", table: "Profile"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextOnPrimary.opacity(0.8))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Sağ taraf - Upgrade butonu
            Text(L("profile.premium.upgrade", table: "Profile"))
                .font(PSTypography.caption)
                .fontWeight(.medium)
                .foregroundColor(.appTextOnPrimary)
                .padding(.horizontal, PSSpacing.md)
                .padding(.vertical, PSSpacing.sm)
                .background(
                    Capsule()
                        .fill(Color.appTextOnPrimary.opacity(0.2))
                )
        }
        .padding(.horizontal, PSSpacing.md)
        .padding(.vertical, PSSpacing.md)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.appSecondary, Color.appAccent]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(PSCornerRadius.large)
        .shadow(color: Color.appSecondary.opacity(0.2), radius: PSSpacing.xs, x: 0, y: 2)
        .contentShape(Rectangle()) // Tıklama alanını genişletmek için
    }
} 