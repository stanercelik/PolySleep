import SwiftUI

struct OnboardingTitleView: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey?
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.sizeCategory) var sizeCategory
    
    init(title: LocalizedStringKey, description: LocalizedStringKey? = nil) {
        self.title = title
        self.description = description
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: sizeCategory.isAccessibilityCategory ? 12 : 8) {
            Text(title)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(Color("TextColor"))
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.8)
                .lineLimit(3)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h1)
            
            if let description = description {
                Text(description)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Color("SecondaryTextColor"))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(NSLocalizedString("accessibility.description", comment: ""))
            }
        }
        .padding(.bottom, sizeCategory.isAccessibilityCategory ? 16 : 8)
        .animation(.easeInOut, value: description != nil)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 32) {
        OnboardingTitleView(
            title: "onboarding.sleepExperience",
            description: "onboarding.sleepExperienceQuestion"
        )
        
        OnboardingTitleView(
            title: "onboarding.sleepExperience",
            description: "This is a long description text that explains the purpose of this section and might need multiple lines to be displayed properly"
        )
        
        OnboardingTitleView(
            title: "onboarding.sleepExperience"
        )
    }
    .padding()
    .background(Color("BackgroundColor"))
}
