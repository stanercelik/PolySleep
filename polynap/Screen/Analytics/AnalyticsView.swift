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
                        
                        // Debug bilgisi (sadece geliştirme sırasında)
                        #if DEBUG
                        VStack(alignment: .leading, spacing: PSSpacing.xs) {
                            Text("🔧 Debug Info:")
                                .font(PSTypography.caption)
                                .foregroundColor(.appTextSecondary)
                            Text("Selected Range: \(viewModel.selectedTimeRange.rawValue)")
                                .font(PSTypography.caption)
                                .foregroundColor(.appTextSecondary)
                            Text("Loading: \(viewModel.isLoading ? "✅" : "❌")")
                                .font(PSTypography.caption)
                                .foregroundColor(.appTextSecondary)
                            Text("Has Data: \(viewModel.hasEnoughData ? "✅" : "❌")")
                                .font(PSTypography.caption)
                                .foregroundColor(.appTextSecondary)
                            Text("Trend Data Count: \(viewModel.sleepTrendData.count)")
                                .font(PSTypography.caption)
                                .foregroundColor(.appTextSecondary)
                        }
                        .padding(.horizontal, PSSpacing.lg)
                        .padding(.vertical, PSSpacing.sm)
                        .background(Color.appCardBackground.opacity(0.5))
                        .cornerRadius(PSCornerRadius.small)
                        .padding(.horizontal, PSSpacing.lg)
                        #endif
                        
                        if viewModel.isLoading {
                            loadingView
                        } else if viewModel.hasEnoughData {
                            // Ana Analiz İçeriği
                            VStack(spacing: PSSpacing.xl) {
                                // Free kullanıcılar için temel özellikler
                                AnalyticsSummaryCard(viewModel: viewModel)
                                
                                // Sleep Trends Section (Tüm kullanıcılar için)
                                AnalyticsSleepTrendsSection(
                                    viewModel: viewModel,
                                    isPremiumUser: isPremiumUser,
                                    selectedTrendDataPoint: $selectedTrendDataPoint,
                                    selectedBarDataPoint: $selectedBarDataPoint,
                                    tooltipPosition: $tooltipPosition
                                )
                                
                                AnalyticsBestWorstDays(viewModel: viewModel)
                                
                                // Premium özellikler - kilitli gösterim
                                if isPremiumUser {
                                    // ✅ DOĞRU VERİLERLE ÇALIŞAN GRAFİKLER
                                    AnalyticsQualityDistribution(viewModel: viewModel)
                                    AnalyticsSleepBreakdown(
                                        viewModel: viewModel,
                                        selectedPieSlice: $selectedPieSlice,
                                        tooltipPosition: $tooltipPosition
                                    )
                                    AnalyticsTimeGained(viewModel: viewModel)
                                    
                                    // ❌ YANILTICI GRAFİKLER KALDIRILDI:
                                    // - Uyku Isı Haritası (varsayımsal saatler)
                                    // - Tutarlılık Trendi (bilinmeyen hedef saat)
                                    // - Uyku Borcu (yanlış hedef: 8 saat)  
                                    // - Kalite-Tutarlılık Korelasyonu (yetersiz veri)
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
                                        title: L("analytics.timeGained.title", table: "Analytics"),
                                        description: L("analytics.premium.timeGainedDescription", table: "Analytics")
                                    ) {
                                        AnalyticsTimeGainedPreview()
                                    }
                                    
                                    // ⚠️ UYARI: Aşağıdaki özellikler mevcut verilerle doğru sonuç vermez
                                    PSInfoBox(
                                        title: "Gelişmiş Analizler Geliştiriliyor",
                                        message: "Uyku ısı haritası, tutarlılık analizi ve uyku borcu hesaplamaları için daha detaylı veri toplama özellikleri geliştiriliyor. Bu özellikler gelecek güncellemelerde eklenecek.",
                                        icon: "wrench.and.screwdriver.fill"
                                    )
                                    .padding(.horizontal, PSSpacing.lg)
                                }
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
            print("📱 AnalyticsView appeared")
            viewModel.setModelContext(modelContext)
            loadPremiumStatus()
        }

        .id(languageManager.currentLanguage)
    }
    
    // MARK: - UI Components
    
    private var timeRangePicker: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.lg) {
                PSSectionHeader(
                    L("analytics.timeRange.title", table: "Analytics"),
                    icon: "calendar.badge.clock"
                )
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: PSSpacing.md) {
                        ForEach(TimeRange.allCases) { range in
                            ModernTimeRangeChip(
                                title: range.displayName,
                                isSelected: viewModel.selectedTimeRange == range,
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.changeTimeRange(to: range)
                                    }
                                }
                            )
                            // Loading sırasında etkileşimi devre dışı bırak
                            .disabled(viewModel.isLoading)
                            .opacity(viewModel.isLoading ? 0.6 : 1.0)
                        }
                    }
                    .padding(.horizontal, PSSpacing.xs)
                }
                
                // Loading indicator ekle
                if viewModel.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                        
                        Text(L("analytics.updating", table: "Analytics"))
                            .font(PSTypography.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    .padding(.top, PSSpacing.xs)
                    .transition(.opacity)
                }
            }
        }
        .padding(.horizontal, PSSpacing.lg)
    }
    
    private var loadingView: some View {
        VStack(spacing: PSSpacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
            
            Text(L("analytics.loading", table: "Analytics"))
                .font(PSTypography.body)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
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
        isPremiumUser = RevenueCatManager.shared.userState == .premium
    }
}

#Preview {
    AnalyticsView()
}

// MARK: - Modern Time Range Chip
struct ModernTimeRangeChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            // Haptic feedback ekle
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
            
            print("🎯 Filter seçildi: \(title)")
            action()
        }) {
            HStack(spacing: PSSpacing.xs) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextOnPrimary)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Text(title)
                    .font(PSTypography.button)
                    .foregroundColor(isSelected ? .appTextOnPrimary : .appText)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .padding(.horizontal, PSSpacing.lg)
            .padding(.vertical, PSSpacing.sm + PSSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: PSCornerRadius.button)
                    .fill(
                        isSelected ? 
                        LinearGradient(
                            gradient: Gradient(colors: [.appPrimary, .appSecondary]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.appCardBackground, Color.appCardBackground]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: PSCornerRadius.button)
                            .stroke(
                                isSelected ? Color.clear : Color.appBorder.opacity(0.5),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isSelected ? Color.appPrimary.opacity(0.3) : Color.clear,
                        radius: isSelected ? PSSpacing.sm : 0,
                        x: 0,
                        y: isSelected ? PSSpacing.xs : 0
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
