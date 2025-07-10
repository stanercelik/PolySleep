import SwiftUI

struct ArticleCard: View {
    let article: EducationArticle
    let readTimeText: String
    let difficultyText: String
    let difficultyColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    // Category Badge
                    HStack(spacing: 6) {
                        Image(systemName: article.category.icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(article.category.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(article.category.color)
                    )
                    
                    Spacer()
                    
                    // Difficulty Badge
                    if !difficultyText.isEmpty {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(difficultyColor)
                                .frame(width: 6, height: 6)
                            
                            Text(difficultyText)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(difficultyColor)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(difficultyColor.opacity(0.12))
                        )
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 10) {
                    // Title
                    Text(L(article.titleKey, table: "Education", fallback: article.titleKey))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.appText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Summary
                    if let summaryKey = article.summaryKey, !summaryKey.isEmpty {
                        Text(L(summaryKey, table: "Education", fallback: summaryKey))
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .lineSpacing(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // Footer
                HStack {
                    // Read Time
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 13))
                            .foregroundColor(article.category.color.opacity(0.7))
                        
                        Text(readTimeText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    Spacer()
                    
                    // Arrow
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(article.category.color)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(article.category.color.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(
                        color: article.category.color.opacity(0.08),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(ArticleCardButtonStyle(categoryColor: article.category.color))
    }
}

// MARK: - Button Style
struct ArticleCardButtonStyle: ButtonStyle {
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
        VStack(spacing: 20) {
            ArticleCard(
                article: EducationArticle(
                    titleKey: "education.article.whatIs.title",
                    summaryKey: "education.article.whatIs.summary",
                    contentKey: "education.article.whatIs.content",
                    category: .basics,
                    readTimeMinutes: 5,
                    difficulty: .beginner
                ),
                readTimeText: "5 min read",
                difficultyText: "Beginner",
                difficultyColor: .green
            ) { }
            
            ArticleCard(
                article: EducationArticle(
                    titleKey: "education.article.adaptationProcess.title",
                    summaryKey: "education.article.adaptationProcess.summary",
                    contentKey: "education.article.adaptationProcess.content",
                    category: .adaptation,
                    readTimeMinutes: 12,
                    difficulty: .advanced
                ),
                readTimeText: "12 min read",
                difficultyText: "Advanced",
                difficultyColor: .red
            ) { }
            
            ArticleCard(
                article: EducationArticle(
                    titleKey: "education.article.risks.title",
                    summaryKey: "education.article.risks.summary",
                    contentKey: "education.article.risks.content",
                    category: .risks,
                    readTimeMinutes: 8,
                    difficulty: .intermediate
                ),
                readTimeText: "8 min read",
                difficultyText: "Intermediate",
                difficultyColor: .orange
            ) { }
        }
        .padding()
    }
    .background(Color.appBackground)
} 