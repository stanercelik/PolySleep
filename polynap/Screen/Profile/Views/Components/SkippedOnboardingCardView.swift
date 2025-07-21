import SwiftUI

struct SkippedOnboardingCardView: View {
    @Binding var isPresented: Bool

    var body: some View {
        PSCard(padding: PSSpacing.md) {
            VStack(alignment: .leading, spacing: PSSpacing.sm) {
                HStack(alignment: .top, spacing: PSSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: PSIconSize.medium, weight: .semibold))
                        .foregroundColor(.appWarning)
                    
                    VStack(alignment: .leading, spacing: PSSpacing.xs) {
                        Text(L("profile.skippedOnboarding.title", table: "Profile"))
                            .font(PSTypography.headline.weight(.semibold))
                            .foregroundColor(.appText)
                            .lineLimit(2)
                        
                        Text(L("profile.skippedOnboarding.message", table: "Profile"))
                            .font(PSTypography.body)
                            .foregroundColor(.appTextSecondary)
                            .lineSpacing(2)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(Color.appTextSecondary.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, PSSpacing.lg)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview {
    SkippedOnboardingCardView(isPresented: .constant(true))
        .padding()
        .background(Color.black)
}
