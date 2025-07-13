import SwiftUI

struct FAQDetailView: View {
    let faq: FAQItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection
                    
                    // Content
                    contentSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.appTextSecondary)
                            .font(.title2)
                    }
                }
            }
            .background(Color.appBackground)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // FAQ Badge
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.appPrimary)
                
                Text(L("education.faq_section", table: "Education"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appPrimary)
                
                Spacer()
            }
            
            // Question
            Text(faq.question)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.appText)
                .multilineTextAlignment(.leading)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Answer
            Text(faq.answer)
                .font(.body)
                .lineSpacing(6)
                .foregroundColor(.appText)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBackground)
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }
}

// MARK: - Preview
#Preview {
    FAQDetailView(
        faq: FAQItem(
            questionKey: "education.faq.q1",
            answerKey: "education.faq.a1"
        )
    )
} 