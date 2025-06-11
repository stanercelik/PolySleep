import SwiftUI

// MARK: - Sleep Trends Section
struct AnalyticsSleepTrendsSection: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    let isPremiumUser: Bool
    @Binding var selectedTrendDataPoint: SleepTrendData?
    @Binding var selectedBarDataPoint: SleepTrendData?
    @Binding var tooltipPosition: CGPoint
    @State private var selectedQualityDataPoint: SleepTrendData?
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.xl) {
                PSSectionHeader(
                    L("analytics.sleepTrends.title", table: "Analytics"),
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                VStack(spacing: PSSpacing.xl) {
                    // 1. Toplam Uyku Süresi Trendi (Tüm kullanıcılar için)
                    VStack(alignment: .leading, spacing: PSSpacing.lg) {
                        PSSectionHeader(
                            L("analytics.totalSleepTrend.title", table: "Analytics"),
                            icon: "moon.circle.fill",
                            subtitle: L("analytics.totalSleepTrend.subtitle", table: "Analytics")
                        )
                        
                        SleepTrendChart(
                            viewModel: viewModel,
                            selectedTrendDataPoint: $selectedTrendDataPoint,
                            tooltipPosition: $tooltipPosition
                        )
                    }
                    
                    // 2. Uyku Kalitesi Trendi (Premium kullanıcılar için)
                    if isPremiumUser {
                        VStack(alignment: .leading, spacing: PSSpacing.lg) {
                            PSSectionHeader(
                                L("analytics.sleepQualityTrendChart.title", table: "Analytics"),
                                icon: "star.circle.fill",
                                subtitle: L("analytics.sleepQualityTrendChart.subtitle", table: "Analytics")
                            )
                            
                            SleepQualityTrendChart(
                                viewModel: viewModel,
                                selectedDataPoint: $selectedQualityDataPoint,
                                tooltipPosition: $tooltipPosition
                            )
                            
                            PSInfoBox(
                                title: L("analytics.sleepQualityTrendChart.infoTitle", table: "Analytics"),
                                message: L("analytics.sleepQualityTrendChart.infoMessage", table: "Analytics"),
                                icon: "lightbulb.fill"
                            )
                        }
                    }
                    
                    // 3. Uyku Bileşenleri Trendi (Premium kullanıcılar için)
                    if isPremiumUser {
                        VStack(alignment: .leading, spacing: PSSpacing.lg) {
                            PSSectionHeader(
                                L("analytics.sleepComponentsTrend.title", table: "Analytics"),
                                icon: "chart.bar.fill",
                                subtitle: L("analytics.sleepComponentsTrend.subtitle", table: "Analytics")
                            )
                            
                            SleepComponentsChart(
                                viewModel: viewModel,
                                selectedBarDataPoint: $selectedBarDataPoint,
                                tooltipPosition: $tooltipPosition
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, PSSpacing.lg)
    }
} 