import SwiftUI

struct FAQCard: View {
    let faq: FAQItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                // Question Icon
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.appPrimary)
                    .frame(width: 24, height: 24)
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    // Question
                    Text(faq.question)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                    
                    // Answer Preview
                    Text(faq.answer)
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.appTextSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appCardBackground)
                    .shadow(
                        color: Color.black.opacity(0.05),
                        radius: 6,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(FAQCardButtonStyle())
    }
}

// MARK: - Button Style
struct FAQCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 12) {
        FAQCard(
            faq: FAQItem(
                questionKey: "education.faq.q1",
                answerKey: "education.faq.a1"
            )
        ) { }
        
        FAQCard(
            faq: FAQItem(
                questionKey: "education.faq.q2",
                answerKey: "education.faq.a2"
            )
        ) { }
    }
    .padding()
    .background(Color.appBackground)
} 