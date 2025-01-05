import SwiftUI

struct OnboardingNavigationButtons: View {
    let canMoveNext: Bool
    let currentPage: Int
    let totalPages: Int
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var body: some View {
        HStack(spacing: 16) {
            if currentPage > 0 {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onBack()
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                        Text("onboarding.back")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundStyle(Color("PrimaryColor"))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(NSLocalizedString("accessibility.previousPage", comment: ""))
            }
            
            Spacer()
            
            if currentPage < totalPages - 1 {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onNext()
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }) {
                    HStack(spacing: 8) {
                        Text(currentPage == totalPages - 2 ? "onboarding.seeResults" : "onboarding.next")
                            .font(.body.weight(.semibold))
                        
                        Image(systemName: "chevron.right")
                            .font(.body.weight(.semibold))
                    }
                    .padding(.horizontal, 16)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canMoveNext ? Color("PrimaryColor") : Color("PrimaryColor").opacity(0.5))
                    )
                    .foregroundColor(.white)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!canMoveNext)
                .accessibilityLabel(currentPage == totalPages - 2 ? 
                    NSLocalizedString("accessibility.seeResults", comment: "") :
                    NSLocalizedString("accessibility.nextPage", comment: ""))
                .accessibilityHint(canMoveNext ? "" : NSLocalizedString("accessibility.completeCurrentPage", comment: ""))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(Color("BackgroundColor"))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -4)
        )
    }
}

#Preview {
    VStack(spacing: 32) {
        OnboardingNavigationButtons(
            canMoveNext: true,
            currentPage: 0,
            totalPages: 5,
            onNext: {},
            onBack: {}
        )
        
        OnboardingNavigationButtons(
            canMoveNext: true,
            currentPage: 2,
            totalPages: 5,
            onNext: {},
            onBack: {}
        )
        
        OnboardingNavigationButtons(
            canMoveNext: false,
            currentPage: 2,
            totalPages: 5,
            onNext: {},
            onBack: {}
        )
        
        OnboardingNavigationButtons(
            canMoveNext: true,
            currentPage: 4,
            totalPages: 5,
            onNext: {},
            onBack: {}
        )
    }
    .padding()
    .background(Color("BackgroundColor"))
}
