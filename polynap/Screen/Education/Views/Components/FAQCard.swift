import SwiftUI

struct FAQCard: View {
    let faq: FAQItem
    let action: () -> Void
    
    // FAQ kategori rengini kullan
    private var categoryColor: Color {
        EducationCategory.faq.color
    }
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 16) {
                // Question Icon
                VStack {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(categoryColor)
                }
                .padding(.top, 2)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Question
                    Text(faq.question)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.appText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Answer Preview
                    Text(faq.answer)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .lineSpacing(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Arrow
                VStack {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(categoryColor)
                }
                .padding(.top, 2)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(categoryColor.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(
                        color: categoryColor.opacity(0.08),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(FAQCardButtonStyle(categoryColor: categoryColor))
    }
}

// MARK: - Button Style
struct FAQCardButtonStyle: ButtonStyle {
    let categoryColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(categoryColor.opacity(configuration.isPressed ? 0.05 : 0))
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 16) {
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
            
            FAQCard(
                faq: FAQItem(
                    questionKey: "education.faq.q3",
                    answerKey: "education.faq.a3"
                )
            ) { }
        }
        .padding()
    }
    .background(Color.appBackground)
} 