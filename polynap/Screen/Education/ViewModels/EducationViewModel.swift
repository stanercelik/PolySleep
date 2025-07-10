import Foundation
import SwiftUI
import Combine

@MainActor
class EducationViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedCategory: EducationCategory?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let contentProvider = EducationContentProvider.shared
    private var cancellables = Set<AnyCancellable>()
    
    var filteredArticles: [EducationArticle] {
        let articles = contentProvider.articles
        
        if searchText.isEmpty && selectedCategory == nil {
            return articles
        }
        
        var filtered = articles
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            filtered = contentProvider.searchArticles(query: searchText)
            if let category = selectedCategory {
                filtered = filtered.filter { $0.category == category }
            }
        }
        
        return filtered
    }
    
    var filteredFAQs: [FAQItem] {
        // FAQ kategorisi seçilmediyse ve arama yoksa FAQ'ları göster
        if selectedCategory != nil && selectedCategory != .faq {
            return []
        }
        
        if searchText.isEmpty {
            return contentProvider.faqItems
        }
        return contentProvider.searchFAQs(query: searchText)
    }
    
    var categories: [EducationCategory] {
        EducationCategory.allCases
    }
    
    var shouldShowNoResults: Bool {
        !searchText.isEmpty && filteredArticles.isEmpty && filteredFAQs.isEmpty
    }
    
    init() {
        setupSearchDebounce()
    }
    
    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                // Trigger UI update for filtered results
            }
            .store(in: &cancellables)
    }
    
    func selectCategory(_ category: EducationCategory?) {
        selectedCategory = category
    }
    
    func clearSearch() {
        searchText = ""
        selectedCategory = nil
    }
    
    func getReadTimeText(for minutes: Int) -> String {
        String(format: L("education.readTime", table: "Education"), minutes)
    }
    
    func getDifficultyText(for difficulty: DifficultyLevel?) -> String {
        guard let difficulty = difficulty else { return "" }
        return difficulty.localizedDescription
    }
    
    func getDifficultyColor(for difficulty: DifficultyLevel?) -> Color {
        guard let difficulty = difficulty else { return .gray }
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
} 