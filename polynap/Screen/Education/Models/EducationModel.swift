import Foundation
import SwiftUI

// MARK: - Education Category
enum EducationCategory: String, CaseIterable, Identifiable {
    case basics = "basics"
    case schedules = "schedules" 
    case adaptation = "adaptation"
    case myths = "myths"
    case preparation = "preparation"
    case faq = "faq"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .basics:
            return L("education.categories.basics", table: "Education")
        case .schedules:
            return L("education.categories.schedules", table: "Education")
        case .adaptation:
            return L("education.categories.adaptation", table: "Education")
        case .myths:
            return L("education.categories.myths", table: "Education")
        case .preparation:
            return L("education.categories.preparation", table: "Education")
        case .faq:
            return L("education.categories.faq", table: "Education")
        }
    }
    
    var icon: String {
        switch self {
        case .basics:
            return "book.fill"
        case .schedules:
            return "clock.fill"
        case .adaptation:
            return "chart.line.uptrend.xyaxis"
        case .myths:
            return "questionmark.bubble.fill"
        case .preparation:
            return "checklist"
        case .faq:
            return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .basics:
            return .blue
        case .schedules:
            return .green
        case .adaptation:
            return .purple
        case .myths:
            return .orange
        case .preparation:
            return .cyan
        case .faq:
            return .red
        }
    }
}

// MARK: - Education Article
struct EducationArticle: Identifiable, Hashable, Equatable {
    let id = UUID()
    let titleKey: String
    let summaryKey: String?
    let contentKey: String
    let category: EducationCategory
    let readTimeMinutes: Int
    let difficulty: DifficultyLevel?
    
    var title: String {
        L(titleKey, table: "Education")
    }
    
    var summary: String {
        guard let summaryKey = summaryKey else { return "" }
        return L(summaryKey, table: "Education")
    }
    
    var content: String {
        L(contentKey, table: "Education")
    }
    
    var readTime: String {
        String(format: L("education.readTime", table: "Education"), readTimeMinutes)
    }
    
    // MARK: - Hashable & Equatable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(titleKey)
        hasher.combine(summaryKey)
        hasher.combine(contentKey)
        hasher.combine(category)
        hasher.combine(readTimeMinutes)
        hasher.combine(difficulty)
    }
    
    static func == (lhs: EducationArticle, rhs: EducationArticle) -> Bool {
        return lhs.titleKey == rhs.titleKey &&
               lhs.summaryKey == rhs.summaryKey &&
               lhs.contentKey == rhs.contentKey &&
               lhs.category == rhs.category &&
               lhs.readTimeMinutes == rhs.readTimeMinutes &&
               lhs.difficulty == rhs.difficulty
    }
}

// MARK: - FAQ Item
struct FAQItem: Identifiable, Hashable, Equatable {
    let id = UUID()
    let questionKey: String
    let answerKey: String
    
    var question: String {
        L(questionKey, table: "Education")
    }
    
    var answer: String {
        L(answerKey, table: "Education")
    }
    
    // MARK: - Hashable & Equatable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(questionKey)
        hasher.combine(answerKey)
    }
    
    static func == (lhs: FAQItem, rhs: FAQItem) -> Bool {
        return lhs.questionKey == rhs.questionKey &&
               lhs.answerKey == rhs.answerKey
    }
}

// MARK: - Education Content Provider
class EducationContentProvider: ObservableObject {
    static let shared = EducationContentProvider()
    
    private init() {}
    
    // MARK: - Articles
    lazy var articles: [EducationArticle] = [
        // MARK: - Bölüm 1: Polifazik Uykuya Giriş ve Temel Kavramlar
        EducationArticle(
            titleKey: "education.article.whatIs.title",
            summaryKey: "education.article.whatIs.summary",
            contentKey: "education.article.whatIs.content",
            category: EducationCategory.basics,
            readTimeMinutes: 5,
            difficulty: nil
        ),
        EducationArticle(
            titleKey: "education.article.basicTheory.title",
            summaryKey: "education.article.basicTheory.summary",
            contentKey: "education.article.basicTheory.content",
            category: EducationCategory.basics,
            readTimeMinutes: 8,
            difficulty: nil
        ),
        EducationArticle(
            titleKey: "education.article.sleepStages.title",
            summaryKey: "education.article.sleepStages.summary",
            contentKey: "education.article.sleepStages.content",
            category: EducationCategory.basics,
            readTimeMinutes: 6,
            difficulty: nil
        ),
        EducationArticle(
            titleKey: "education.article.famousPeople.title",
            summaryKey: "education.article.famousPeople.summary",
            contentKey: "education.article.famousPeople.content",
            category: EducationCategory.basics,
            readTimeMinutes: 4,
            difficulty: nil
        ),
        EducationArticle(
            titleKey: "education.article.benefits.title",
            summaryKey: "education.article.benefits.summary",
            contentKey: "education.article.benefits.content",
            category: EducationCategory.basics,
            readTimeMinutes: 6,
            difficulty: nil
        ),
        
        // MARK: - Bölüm 2: En Popüler Polifazik Uyku Programları ve Yapıları
        EducationArticle(
            titleKey: "education.article.biphasic.title",
            summaryKey: "education.article.biphasic.summary",
            contentKey: "education.article.biphasic.content",
            category: EducationCategory.schedules,
            readTimeMinutes: 4,
            difficulty: DifficultyLevel.beginner
        ),
        EducationArticle(
            titleKey: "education.article.everyman.title",
            summaryKey: "education.article.everyman.summary",
            contentKey: "education.article.everyman.content",
            category: EducationCategory.schedules,
            readTimeMinutes: 6,
            difficulty: DifficultyLevel.intermediate
        ),
        EducationArticle(
            titleKey: "education.article.triphasic.title",
            summaryKey: "education.article.triphasic.summary",
            contentKey: "education.article.triphasic.content",
            category: EducationCategory.schedules,
            readTimeMinutes: 5,
            difficulty: DifficultyLevel.intermediate
        ),
        EducationArticle(
            titleKey: "education.article.uberman.title",
            summaryKey: "education.article.uberman.summary",
            contentKey: "education.article.uberman.content",
            category: EducationCategory.schedules,
            readTimeMinutes: 4,
            difficulty: DifficultyLevel.extreme
        ),
        EducationArticle(
            titleKey: "education.article.dymaxion.title",
            summaryKey: "education.article.dymaxion.summary",
            contentKey: "education.article.dymaxion.content",
            category: EducationCategory.schedules,
            readTimeMinutes: 4,
            difficulty: DifficultyLevel.extreme
        ),
        EducationArticle(
            titleKey: "education.article.scheduleComparison.title",
            summaryKey: "education.article.scheduleComparison.summary",
            contentKey: "education.article.scheduleComparison.content",
            category: EducationCategory.schedules,
            readTimeMinutes: 7,
            difficulty: nil
        ),
        EducationArticle(
            titleKey: "education.article.scheduleSelection.title",
            summaryKey: "education.article.scheduleSelection.summary",
            contentKey: "education.article.scheduleSelection.content",
            category: EducationCategory.schedules,
            readTimeMinutes: 6,
            difficulty: nil
        ),
        
        // MARK: - Bölüm 3: Adaptasyon Süreci
        EducationArticle(
            titleKey: "education.article.adaptationProcess.title",
            summaryKey: "education.article.adaptationProcess.summary",
            contentKey: "education.article.adaptationProcess.content",
            category: EducationCategory.adaptation,
            readTimeMinutes: 8,
            difficulty: nil
        ),
        EducationArticle(
            titleKey: "education.article.adaptationChallenges.title",
            summaryKey: "education.article.adaptationChallenges.summary",
            contentKey: "education.article.adaptationChallenges.content",
            category: EducationCategory.adaptation,
            readTimeMinutes: 6,
            difficulty: nil
        ),
        EducationArticle(
            titleKey: "education.article.zombieMode.title",
            summaryKey: "education.article.zombieMode.summary",
            contentKey: "education.article.zombieMode.content",
            category: EducationCategory.adaptation,
            readTimeMinutes: 5,
            difficulty: nil
        ),
        EducationArticle(
            titleKey: "education.article.adaptationSuccess.title",
            summaryKey: "education.article.adaptationSuccess.summary",
            contentKey: "education.article.adaptationSuccess.content",
            category: EducationCategory.adaptation,
            readTimeMinutes: 4,
            difficulty: nil
        ),
        EducationArticle(
            titleKey: "education.article.adaptationFailure.title",
            summaryKey: "education.article.adaptationFailure.summary",
            contentKey: "education.article.adaptationFailure.content",
            category: EducationCategory.adaptation,
            readTimeMinutes: 5,
            difficulty: nil
        ),
        
        // MARK: - Bölüm 4: Efsaneler ve Gerçekler
        EducationArticle(
            titleKey: "education.article.myth.intelligence.title",
            summaryKey: "education.article.myth.intelligence.summary",
            contentKey: "education.article.myth.intelligence.content",
            category: EducationCategory.myths,
            readTimeMinutes: 3,
            difficulty: nil
        ),
        EducationArticle(
            titleKey: "education.article.myth.sleepStages.title",
            summaryKey: "education.article.myth.sleepStages.summary",
            contentKey: "education.article.myth.sleepStages.content",
            category: EducationCategory.myths,
            readTimeMinutes: 4,
            difficulty: nil
        ),
        EducationArticle(
            titleKey: "education.article.myth.suitability.title",
            summaryKey: "education.article.myth.suitability.summary",
            contentKey: "education.article.myth.suitability.content",
            category: EducationCategory.myths,
            readTimeMinutes: 4,
            difficulty: nil
        ),
        EducationArticle(
            titleKey: "education.article.myth.flexibility.title",
            summaryKey: "education.article.myth.flexibility.summary",
            contentKey: "education.article.myth.flexibility.content",
            category: EducationCategory.myths,
            readTimeMinutes: 3,
            difficulty: nil
        ),
        EducationArticle(
            titleKey: "education.article.myth.caffeine.title",
            summaryKey: "education.article.myth.caffeine.summary",
            contentKey: "education.article.myth.caffeine.content",
            category: EducationCategory.myths,
            readTimeMinutes: 3,
            difficulty: nil
        ),
        EducationArticle(
            titleKey: "education.article.myth.productivity.title",
            summaryKey: "education.article.myth.productivity.summary",
            contentKey: "education.article.myth.productivity.content",
            category: EducationCategory.myths,
            readTimeMinutes: 4,
            difficulty: nil
        ),
        
        
        // MARK: - Bölüm 6: Hazırlık
        EducationArticle(
            titleKey: "education.article.preparation.physical.title",
            summaryKey: "education.article.preparation.physical.summary",
            contentKey: "education.article.preparation.physical.content",
            category: EducationCategory.preparation,
            readTimeMinutes: 5,
            difficulty: nil
        ),
        EducationArticle(
            titleKey: "education.article.preparation.environment.title",
            summaryKey: "education.article.preparation.environment.summary",
            contentKey: "education.article.preparation.environment.content",
            category: EducationCategory.preparation,
            readTimeMinutes: 6,
            difficulty: nil
        ),
        EducationArticle(
            titleKey: "education.article.preparation.alarms.title",
            summaryKey: "education.article.preparation.alarms.summary",
            contentKey: "education.article.preparation.alarms.content",
            category: EducationCategory.preparation,
            readTimeMinutes: 4,
            difficulty: nil
        ),
        EducationArticle(
            titleKey: "education.article.preparation.nutrition.title",
            summaryKey: "education.article.preparation.nutrition.summary",
            contentKey: "education.article.preparation.nutrition.content",
            category: EducationCategory.preparation,
            readTimeMinutes: 7,
            difficulty: nil
        ),
        EducationArticle(
            titleKey: "education.article.preparation.tracking.title",
            summaryKey: "education.article.preparation.tracking.summary",
            contentKey: "education.article.preparation.tracking.content",
            category: EducationCategory.preparation,
            readTimeMinutes: 5,
            difficulty: nil
        ),
        EducationArticle(
            titleKey: "education.article.preparation.social.title",
            summaryKey: "education.article.preparation.social.summary",
            contentKey: "education.article.preparation.social.content",
            category: EducationCategory.preparation,
            readTimeMinutes: 4,
            difficulty: nil
        ),
        
    ]
    
    // MARK: - FAQ Items
    lazy var faqItems: [FAQItem] = [
        FAQItem(
            questionKey: "education.faq.q1",
            answerKey: "education.faq.a1"
        ),
        FAQItem(
            questionKey: "education.faq.q2",
            answerKey: "education.faq.a2"
        ),
        FAQItem(
            questionKey: "education.faq.q3",
            answerKey: "education.faq.a3"
        ),
        FAQItem(
            questionKey: "education.faq.q4",
            answerKey: "education.faq.a4"
        ),
        FAQItem(
            questionKey: "education.faq.q5",
            answerKey: "education.faq.a5"
        ),
        FAQItem(
            questionKey: "education.faq.q6",
            answerKey: "education.faq.a6"
        ),
        FAQItem(
            questionKey: "education.faq.q7",
            answerKey: "education.faq.a7"
        ),
        FAQItem(
            questionKey: "education.faq.q8",
            answerKey: "education.faq.a8"
        ),
        FAQItem(
            questionKey: "education.faq.q9",
            answerKey: "education.faq.a9"
        ),
        FAQItem(
            questionKey: "education.faq.q10",
            answerKey: "education.faq.a10"
        )
    ]
    
    // MARK: - Helper Methods
    func articles(for category: EducationCategory) -> [EducationArticle] {
        articles.filter { $0.category == category }
    }
    
    func searchArticles(query: String) -> [EducationArticle] {
        guard !query.isEmpty else { return articles }
        
        return articles.filter { article in
            article.title.localizedCaseInsensitiveContains(query) ||
            article.content.localizedCaseInsensitiveContains(query)
        }
    }
    
    func searchFAQs(query: String) -> [FAQItem] {
        guard !query.isEmpty else { return faqItems }
        
        return faqItems.filter { item in
            item.question.localizedCaseInsensitiveContains(query) ||
            item.answer.localizedCaseInsensitiveContains(query)
        }
    }
} 
