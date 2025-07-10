import SwiftUI

struct ArticleCard: View {
    let article: EducationArticle
    let readTimeText: String
    let difficultyText: String
    let difficultyColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    // Category Icon
                    Image(systemName: article.category.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appPrimary)
                        .frame(width: 20, height: 20)
                    
                    // Category Name
                    Text(article.category.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.appTextSecondary)
                    
                    Spacer()
                    
                    // Difficulty Badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(difficultyColor)
                            .frame(width: 6, height: 6)
                        
                        Text(difficultyText)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(difficultyColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(difficultyColor.opacity(0.1))
                    )
                }
                
                // Title
                Text(article.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                // Summary
                if !article.summary.isEmpty {
                    Text(article.summary)
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                
                // Footer
                HStack {
                    // Read Time
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                        
                        Text(readTimeText)
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    Spacer()
                    
                    // Arrow
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.appTextSecondary)
                }
            }
            .padding(16)
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
        .buttonStyle(ArticleCardButtonStyle())
    }
}

// MARK: - Button Style
struct ArticleCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
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
    }
    .padding()
    .background(Color(.systemGroupedBackground))
} 