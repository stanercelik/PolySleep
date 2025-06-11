import SwiftUI

// MARK: - Adaptation Completed Card
struct AdaptationCompletedCard: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    @Binding var showingCelebration: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text(L("profile.adaptation.completed.title", table: "Profile"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(L("profile.adaptation.completed.message", table: "Profile"))
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.leading)
                
                PSPrimaryButton(
                    L("profile.adaptation.completed.celebrate", table: "Profile"),
                    customBackgroundColor: Color.green
                ) {
                    withAnimation(.spring()) {
                        showingCelebration = true
                    }
                }
                .frame(height: 44)
            }
        }
        .padding(PSSpacing.lg)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.1), Color.green.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(PSCornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: PSCornerRadius.large)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
} 