import SwiftUI

struct ArticleDetailView: View {
    let article: EducationArticle
    @Environment(\.dismiss) private var dismiss
    @State private var scrollOffset: CGFloat = 0
    
    private var readTimeText: String {
        String(format: L("education.reading_time", table: "Education"), article.readTimeMinutes)
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
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Hero Section
                        heroSection
                        
                        // Content Section
                        contentSection
                            .padding(.top, 24)
                    }
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear {
                                    scrollOffset = proxy.frame(in: .named("scroll")).minY
                                }
                                .onChange(of: proxy.frame(in: .named("scroll")).minY) { newValue in
                                    scrollOffset = newValue
                                }
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
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
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category Badge
            HStack {
                Image(systemName: article.category.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appPrimary)
                
                Text(article.category.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appPrimary)
                
                Spacer()
            }
            
            // Title
            Text(article.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.appText)
                .multilineTextAlignment(.leading)
            
            // Summary
            if !article.summary.isEmpty {
                Text(article.summary)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.leading)
            }
            
            // Metadata
            HStack(spacing: 16) {
                // Read Time
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                    
                    Text(readTimeText)
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                }
                
                // Difficulty
                if article.difficulty != nil {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(difficultyColor)
                            .frame(width: 8, height: 8)
                        
                        Text(difficultyText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(difficultyColor)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.appCardBackground)
        )
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Content Text with Markdown Support
            MarkdownTextView(text: article.content)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.appCardBackground)
        )
    }
}

// MARK: - Markdown Text View
struct MarkdownTextView: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(parseMarkdown(text: text), id: \.id) { element in
                switch element.type {
                case .header:
                    Text(element.text)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.appText)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                        
                case .boldText:
                    Text(element.text)
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(.appText)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                case .bullet:
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.appTextSecondary)
                            .frame(width: 16, alignment: .leading)
                        
                        Text(element.text)
                            .font(.body)
                            .lineSpacing(4)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
                    
                case .paragraph:
                    Text(element.text)
                        .font(.body)
                        .lineSpacing(6)
                        .foregroundColor(.appText)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                case .warning:
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 16))
                            
                            Text(element.text.contains("Important Note") || element.text.contains("Warning") ? "Important Note" : "Önemli Not")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                        
                        Text(element.text)
                            .font(.body)
                            .lineSpacing(4)
                            .foregroundColor(.appText)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(16)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
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