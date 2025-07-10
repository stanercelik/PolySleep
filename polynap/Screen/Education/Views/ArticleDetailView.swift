import SwiftUI

struct ArticleDetailView: View {
    let article: EducationArticle
    @Environment(\.dismiss) private var dismiss
    @State private var scrollOffset: CGFloat = 0
    
    private var readTimeText: String {
        String(format: L("education.readTime", table: "Education"), article.readTimeMinutes)
    }
    
    private var difficultyText: String {
        guard let difficulty = article.difficulty else { return "" }
        return difficulty.localizedDescription
    }
    
    private var difficultyColor: Color {
        guard let difficulty = article.difficulty else { return .gray }
        switch difficulty {
        case .beginner:
            return .green
        case .intermediate:
            return .orange
        case .advanced:
            return .red
        case .extreme:
            return .purple
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Section
                        heroSection
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        article.category.color.opacity(0.1),
                                        Color.appBackground
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // Content Section
                        contentSection
                            .padding(.top, 32)
                    }
                }
                .coordinateSpace(name: "scroll")
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Geri")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(article.category.color)
                    }
                }
            }
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Category Badge
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: article.category.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(article.category.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(article.category.color)
                )
                
                Spacer()
            }
            
            // Title
            Text(article.title)
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundColor(.appText)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
            
            // Summary
            if !article.summary.isEmpty {
                Text(article.summary)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
            }
            
            // Metadata
            HStack(spacing: 20) {
                // Read Time
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(article.category.color)
                    
                    Text(readTimeText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                }
                
                // Difficulty
                if article.difficulty != nil {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(difficultyColor)
                            .frame(width: 8, height: 8)
                        
                        Text(difficultyText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(difficultyColor)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Content Text with Markdown Support
            MarkdownTextView(text: article.content, categoryColor: article.category.color)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 50)
    }
}

// MARK: - Markdown Text View
struct MarkdownTextView: View {
    let text: String
    let categoryColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(parseMarkdown(text: text), id: \.id) { element in
                switch element.type {
                case .header:
                    VStack(alignment: .leading, spacing: 8) {
                        Text(element.text)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.appText)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Rectangle()
                            .fill(categoryColor.opacity(0.3))
                            .frame(height: 2)
                            .frame(maxWidth: 60)
                    }
                    .padding(.top, 16)
                        
                case .boldText:
                    Text(element.text)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appText)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                case .bullet:
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(categoryColor.opacity(0.6))
                            .frame(width: 6, height: 6)
                            .padding(.top, 8)
                        
                        Text(element.text)
                            .font(.system(size: 16, weight: .regular))
                            .lineSpacing(6)
                            .foregroundColor(.appText)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 4)
                    
                case .paragraph:
                    Text(element.text)
                        .font(.system(size: 16, weight: .regular))
                        .lineSpacing(8)
                        .foregroundColor(.appText)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                case .warning:
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 18))
                            
                            Text(element.text.contains("Important Note") || element.text.contains("Warning") ? "Important Note" : "Önemli Not")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.orange)
                        }
                        
                        Text(element.text)
                            .font(.system(size: 15, weight: .regular))
                            .lineSpacing(6)
                            .foregroundColor(.appText)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.orange.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    private func parseMarkdown(text: String) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.isEmpty {
                continue
            }
            
            if trimmedLine.hasPrefix("**") && trimmedLine.hasSuffix("**") && trimmedLine.count > 4 {
                // Bold header
                let headerText = String(trimmedLine.dropFirst(2).dropLast(2))
                elements.append(MarkdownElement(type: .header, text: headerText))
            } else if trimmedLine.hasPrefix("• ") {
                // Bullet point
                let bulletText = String(trimmedLine.dropFirst(2))
                elements.append(MarkdownElement(type: .bullet, text: bulletText))
            } else if trimmedLine.hasPrefix("**Önemli Not:**") || trimmedLine.hasPrefix("**Important Note:**") || trimmedLine.hasPrefix("**Uyarı:**") || trimmedLine.hasPrefix("**Warning:**") {
                // Warning/Note
                let warningText = trimmedLine.replacingOccurrences(of: "**Önemli Not:**", with: "")
                    .replacingOccurrences(of: "**Important Note:**", with: "")
                    .replacingOccurrences(of: "**Uyarı:**", with: "")
                    .replacingOccurrences(of: "**Warning:**", with: "")
                    .trimmingCharacters(in: .whitespaces)
                elements.append(MarkdownElement(type: .warning, text: warningText))
            } else if trimmedLine.contains("**") {
                // Bold text within paragraph
                elements.append(MarkdownElement(type: .boldText, text: trimmedLine.replacingOccurrences(of: "**", with: "")))
            } else {
                // Regular paragraph
                elements.append(MarkdownElement(type: .paragraph, text: trimmedLine))
            }
        }
        
        return elements
    }
}

// MARK: - Markdown Element
struct MarkdownElement {
    let id = UUID()
    let type: MarkdownElementType
    let text: String
}

enum MarkdownElementType {
    case header
    case boldText
    case bullet
    case paragraph
    case warning
}

// MARK: - Preview
#Preview {
    ArticleDetailView(
        article: EducationArticle(
            titleKey: "education.article.whatIs.title",
            summaryKey: "education.article.whatIs.summary",
            contentKey: "education.article.whatIs.content",
            category: .basics,
            readTimeMinutes: 5,
            difficulty: .beginner
        )
    )
} 