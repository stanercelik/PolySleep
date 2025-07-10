import SwiftUI

struct EducationView: View {
    @StateObject private var viewModel = EducationViewModel()
    @State private var selectedArticle: EducationArticle?
    @State private var showingFAQDetail = false
    @State private var selectedFAQ: FAQItem?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchSection
                
                // Category Filter
                categoryFilterSection
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewModel.shouldShowNoResults {
                            noResultsView
                        } else {
                            // Articles Section
                            if !viewModel.filteredArticles.isEmpty {
                                articlesSection
                            }
                            
                            // FAQ Section - genel görünümde veya FAQ kategorisi seçildiğinde göster
                            if !viewModel.filteredFAQs.isEmpty && (viewModel.selectedCategory == nil || viewModel.selectedCategory == .faq) {
                                faqSection
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // Tab bar spacing
                }
            }
            .navigationTitle(L("education.title", table: "Education"))
            .navigationBarTitleDisplayMode(.large)
            .background(Color.appBackground)
        }
        .sheet(item: $selectedArticle) { article in
            ArticleDetailView(article: article)
        }
        .sheet(isPresented: $showingFAQDetail) {
            if let faq = selectedFAQ {
                FAQDetailView(faq: faq)
            }
        }
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.appTextSecondary)
                
                TextField(
                    L("education.search_placeholder", table: "Education"),
                    text: $viewModel.searchText
                )
                .textFieldStyle(PlainTextFieldStyle())
                
                if !viewModel.searchText.isEmpty {
                    Button(action: viewModel.clearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.appCardBackground)
            .cornerRadius(10)
            .padding(.horizontal, 16)
        }
        .padding(.top, 8)
        .background(Color.appBackground)
    }
    
    // MARK: - Category Filter Section
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All Categories Button
                CategoryFilterChip(
                    title: L("education.all_categories", table: "Education"),
                    icon: "square.grid.2x2",
                    isSelected: viewModel.selectedCategory == nil,
                    category: nil
                ) {
                    viewModel.selectCategory(nil)
                }
                
                // Category Buttons
                ForEach(viewModel.categories, id: \.self) { category in
                    CategoryFilterChip(
                        title: category.title,
                        icon: category.icon,
                        isSelected: viewModel.selectedCategory == category,
                        category: category
                    ) {
                        viewModel.selectCategory(category)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(Color.appBackground)
    }
    
    // MARK: - Articles Section
    private var articlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.appPrimary)
                Text(L("education.articles_section", table: "Education"))
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredArticles, id: \.id) { article in
                    ArticleCard(
                        article: article,
                        readTimeText: viewModel.getReadTimeText(for: article.readTimeMinutes),
                        difficultyText: viewModel.getDifficultyText(for: article.difficulty),
                        difficultyColor: viewModel.getDifficultyColor(for: article.difficulty)
                    ) {
                        selectedArticle = article
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - FAQ Section
    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.appPrimary)
                Text(L("education.faq_section", table: "Education"))
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.filteredFAQs, id: \.id) { faq in
                    FAQCard(faq: faq) {
                        selectedFAQ = faq
                        showingFAQDetail = true
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - No Results View
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.appTextSecondary)
            
            Text(L("education.no_results_title", table: "Education"))
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(L("education.no_results_message", table: "Education"))
                .font(.body)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(L("education.clear_search", table: "Education")) {
                viewModel.clearSearch()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 60)
    }
}

// MARK: - Preview
#Preview {
    EducationView()
} 