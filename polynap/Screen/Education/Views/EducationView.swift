import SwiftUI

struct EducationView: View {
    @StateObject private var viewModel = EducationViewModel()
    @State private var selectedArticle: EducationArticle?
    @State private var showingFAQDetail = false
    @State private var selectedFAQ: FAQItem?
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Ana Sayfa (Search kaldırıldı)
                VStack(spacing: 0) {
                    categoriesGrid
                }
                .opacity(viewModel.selectedCategory == nil ? 1 : 0)
                .transition(.opacity)
                
                // Kategori Detay Sayfası
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if !viewModel.filteredArticles.isEmpty {
                            articlesSection
                        }
                        if viewModel.selectedCategory == .faq && !viewModel.filteredFAQs.isEmpty {
                            faqSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
                .opacity(viewModel.selectedCategory == nil ? 0 : 1)
                .transition(.opacity)
            }
            .navigationTitle(viewModel.selectedCategory?.title ?? L("education.title", table: "Education"))
            .navigationBarTitleDisplayMode(.large)
            .background(Color.appBackground)
            .toolbar {
                // Geri Dönüş Butonu
                if viewModel.selectedCategory != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { withAnimation(.easeInOut) { viewModel.selectCategory(nil) } }) {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedArticle) { article in
            ArticleDetailView(article: article)
        }
        .sheet(isPresented: $showingFAQDetail) {
            if let faq = selectedFAQ {
                FAQDetailView(faq: faq)
            }
        }
        .animation(.easeInOut, value: viewModel.selectedCategory)
    }
    
    // MARK: - Categories Grid
    private var categoriesGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 16
            ) {
                ForEach(viewModel.categories, id: \.self) { category in
                    CategoryCard(category: category) {
                        withAnimation(.easeInOut) { viewModel.selectCategory(category) }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100) // Tab bar spacing
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
            
            LazyVStack(spacing: 12) {
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