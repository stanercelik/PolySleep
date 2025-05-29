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
    @State private var isPremiumUser = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: PSSpacing.xl) {
                        // Başlık
                        Text(L("tabbar.analytics", table: "Common"))
                            .font(PSTypography.largeTitle)
                            .foregroundColor(.appText)
                            .padding(.horizontal, PSSpacing.lg)
                            .padding(.top, PSSpacing.sm)
                        
                        // Zaman Aralığı Seçici
                        timeRangePicker
                        
                        if viewModel.isLoading {
                            loadingView
                        } else if viewModel.hasEnoughData {
                            // Ana Analiz İçeriği
                            VStack(spacing: PSSpacing.xl) {
                                // Free kullanıcılar için temel özellikler
                                AnalyticsSummaryCard(viewModel: viewModel)
                                
                                if isPremiumUser {
                                    // Premium: Tam trend grafikleri
                                    AnalyticsTrendCharts(
                                        viewModel: viewModel,
                                        selectedTrendDataPoint: $selectedTrendDataPoint,
                                        selectedBarDataPoint: $selectedBarDataPoint,
                                        tooltipPosition: $tooltipPosition
                                    )
                                } else {
                                    // Free: Sadece toplam uyku süresi grafiği
                                    AnalyticsTotalSleepChart(
                                        viewModel: viewModel,
                                        selectedTrendDataPoint: $selectedTrendDataPoint,
                                        tooltipPosition: $tooltipPosition
                                    )
                                }
                                
                                AnalyticsBestWorstDays(viewModel: viewModel)
                                
                                // Premium özellikler - kilitli gösterim
                                if isPremiumUser {
                                    AnalyticsQualityDistribution(viewModel: viewModel)
                                    AnalyticsSleepBreakdown(
                                        viewModel: viewModel,
                                        selectedPieSlice: $selectedPieSlice,
                                        tooltipPosition: $tooltipPosition
                                    )
                                    AnalyticsConsistencySection(viewModel: viewModel)
                                    AnalyticsTimeGained(viewModel: viewModel)
                                } else {
                                    PremiumLockedAnalytics(
                                        title: L("analytics.sleepComponentsTrend.title", table: "Analytics"),
                                        description: L("analytics.premium.breakdownDescription", table: "Analytics")
                                    ) {
                                        AnalyticsSleepComponentsPreview()
                                    }
                                    
                                    PremiumLockedAnalytics(
                                        title: L("analytics.qualityDistribution.title", table: "Analytics"),
                                        description: L("analytics.premium.qualityDescription", table: "Analytics")
                                    ) {
                                        AnalyticsQualityDistributionPreview()
                                    }
                                    
                                    PremiumLockedAnalytics(
                                        title: L("analytics.sleepBreakdown.title", table: "Analytics"),
                                        description: L("analytics.premium.breakdownDescription", table: "Analytics")
                                    ) {
                                        AnalyticsSleepBreakdownPreview()
                                    }
                                    
                                    PremiumLockedAnalytics(
                                        title: L("analytics.consistency.title", table: "Analytics"),
                                        description: L("analytics.premium.consistencyDescription", table: "Analytics")
                                    ) {
                                        AnalyticsConsistencyPreview()
                                    }
                                    
                                    PremiumLockedAnalytics(
                                        title: L("analytics.timeGained.title", table: "Analytics"),
                                        description: L("analytics.premium.timeGainedDescription", table: "Analytics")
                                    ) {
                                        AnalyticsTimeGainedPreview()
                                    }
                                }
                            }
                        } else {
                            insufficientDataView
                        }
                    }
                    .padding(.bottom, PSSpacing.xxl)
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
            loadPremiumStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PremiumStatusChanged"))) { notification in
            if let isPremium = notification.userInfo?["isPremium"] as? Bool {
                isPremiumUser = isPremium
            }
        }
        .id(languageManager.currentLanguage)
    }
    
    // MARK: - UI Components
    
    private var timeRangePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PSSpacing.md) {
                ForEach(TimeRange.allCases) { range in
                    Button(action: {
                        viewModel.changeTimeRange(to: range)
                    }) {
                        Text(range.displayName)
                            .font(PSTypography.button)
                            .padding(.horizontal, PSSpacing.lg)
                            .padding(.vertical, PSSpacing.sm)
                            .background(viewModel.selectedTimeRange == range ? Color.appPrimary : Color.appCardBackground)
                            .foregroundColor(viewModel.selectedTimeRange == range ? .appTextOnPrimary : .appText)
                            .cornerRadius(PSCornerRadius.extraLarge)
                    }
                }
            }
            .padding(.horizontal, PSSpacing.lg)
        }
    }
    
    private var loadingView: some View {
        PSLoadingState(message: L("analytics.loading", table: "Analytics"))
            .padding(.vertical, PSSpacing.xxxl)
    }
    
    private var insufficientDataView: some View {
        PSEmptyState(
            icon: "exclamationmark.triangle.fill",
            title: L("analytics.insufficientData.title", table: "Analytics"),
            message: L("analytics.insufficientData.message", table: "Analytics"),
            actionTitle: L("analytics.insufficientData.button", table: "Analytics"),
            action: {
                // History sayfasına yönlendir (Navigasyon eklenecek)
            }
        )
        .padding(.horizontal, PSSpacing.lg)
        .padding(.top, PSSpacing.xxl)
    }
    
    // MARK: - Actions
    
    private func shareAnalytics() {
        // Paylaşım işlevi burada uygulanacak
        // iOS Share Sheet açılacak
    }
    
    private func loadPremiumStatus() {
        // Debug için UserDefaults kontrolü
        if UserDefaults.standard.object(forKey: "debug_premium_status") != nil {
            isPremiumUser = UserDefaults.standard.bool(forKey: "debug_premium_status")
        } else {
            isPremiumUser = AuthManager.shared.currentUser?.isPremium ?? false
        }
    }
}

#Preview {
    AnalyticsView()
}
