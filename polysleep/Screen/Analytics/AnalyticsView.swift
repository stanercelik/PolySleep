import SwiftUI
import Charts

public struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    
    // Tooltip için state değişkenleri
    @State private var selectedTrendDataPoint: SleepTrendData?
    @State private var selectedBarDataPoint: SleepTrendData?
    @State private var selectedPieSlice: SleepBreakdownData?
    @State private var tooltipPosition: CGPoint = .zero
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Başlık
                        Text(L("tabbar.analytics", table: "Common"))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color("TextColor"))
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        // Zaman Aralığı Seçici
                        timeRangePicker
                        
                        if viewModel.isLoading {
                            loadingView
                        } else if viewModel.hasEnoughData {
                            // Ana Analiz İçeriği
                            VStack(spacing: 20) {
                                AnalyticsSummaryCard(viewModel: viewModel)
                                AnalyticsTrendCharts(
                                    viewModel: viewModel,
                                    selectedTrendDataPoint: $selectedTrendDataPoint,
                                    selectedBarDataPoint: $selectedBarDataPoint,
                                    tooltipPosition: $tooltipPosition
                                )
                                AnalyticsQualityDistribution(viewModel: viewModel)
                                AnalyticsSleepBreakdown(
                                    viewModel: viewModel,
                                    selectedPieSlice: $selectedPieSlice,
                                    tooltipPosition: $tooltipPosition
                                )
                                AnalyticsConsistencySection(viewModel: viewModel)
                                AnalyticsBestWorstDays(viewModel: viewModel)
                                AnalyticsTimeGained(viewModel: viewModel)
                            }
                        } else {
                            insufficientDataView
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: shareAnalytics) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color("PrimaryColor"))
                    }
                }
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
        .id(languageManager.currentLanguage)
    }
    
    // MARK: - UI Components
    
    private var timeRangePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimeRange.allCases) { range in
                    Button(action: {
                        viewModel.changeTimeRange(to: range)
                    }) {
                        Text(range.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedTimeRange == range ? Color("PrimaryColor") : Color("CardBackground"))
                            .foregroundColor(viewModel.selectedTimeRange == range ? .white : Color("TextColor"))
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
                .padding()
            
            Text(L("analytics.loading", table: "Analytics"))
                .font(.system(size: 16))
                .foregroundColor(Color("SecondaryTextColor"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
    
    private var insufficientDataView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color("AccentColor"))
                
                Text(L("analytics.insufficientData.title", table: "Analytics"))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color("TextColor"))
                
                Text(L("analytics.insufficientData.message", table: "Analytics"))
                    .font(.system(size: 16))
                    .foregroundColor(Color("TextColor"))
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    // History sayfasına yönlendir
                }) {
                    Text(L("analytics.insufficientData.button", table: "Analytics"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color("PrimaryColor"))
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
            .padding()
            .background(Color("CardBackground"))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 30)
        }
    }
    
    // MARK: - Actions
    
    private func shareAnalytics() {
        // Paylaşım işlevi burada uygulanacak
        // iOS Share Sheet açılacak
    }
}

#Preview {
    AnalyticsView()
}
