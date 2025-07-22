import SwiftUI

struct SkippedOnboardingCardView: View {
    @Binding var isPresented: Bool
    let onChooseSchedule: () -> Void
    
    var body: some View {
        // Minimal gradient background with content-fitted size
        HStack(spacing: PSSpacing.sm) {
            // Leading content with icon and text
            HStack(spacing: PSSpacing.xs) {
                // Compact icon
                ZStack {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.12))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "clock.badge")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appPrimary)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(L("profile.skippedOnboarding.title", table: "Profile"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appText)
                        .lineLimit(1)
                    
                    Text(L("profile.skippedOnboarding.shortMessage", table: "Profile"))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
            // Compact action buttons
            HStack(spacing: 6) {
                // Choose schedule button
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    onChooseSchedule()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 9, weight: .semibold))
                        
                        Text(L("profile.skippedOnboarding.chooseButton", table: "Profile"))
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.appPrimary)
                            .shadow(color: Color.appPrimary.opacity(0.2), radius: 1, x: 0, y: 0.5)
                    )
                }
                .buttonStyle(.plain)
                
                // Close button
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                        .frame(width: 18, height: 18)
                        .background(
                            Circle()
                                .fill(Color.appCardBackground)
                                .shadow(color: Color.black.opacity(0.03), radius: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appPrimary.opacity(0.06),
                            Color.appSecondary.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appPrimary.opacity(0.08), lineWidth: 0.5)
                )
                .shadow(color: Color.appPrimary.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, PSSpacing.lg)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.96)),
            removal: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.99))
        ))
    }
}

#Preview {
    SkippedOnboardingCardView(
        isPresented: .constant(true),
        onChooseSchedule: {
            print("Choose schedule tapped")
        }
    )
    .padding()
    .background(Color.appBackground)
}
