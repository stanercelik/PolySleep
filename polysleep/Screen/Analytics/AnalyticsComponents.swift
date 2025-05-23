import SwiftUI
import Charts

// MARK: - Summary Card
struct AnalyticsSummaryCard: View {
    let viewModel: AnalyticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("analytics.summary.title", table: "Analytics"))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("TextColor"))
            
            // Mevcut ve önceki dönem karşılaştırması
            if viewModel.previousPeriodComparison.hours != 0 || viewModel.previousPeriodComparison.score != 0 {
                HStack {
                    Text(L("analytics.previousPeriodComparison.title", table: "Analytics"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("SecondaryTextColor"))
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Uyku saati değişimi
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.previousPeriodComparison.hours >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .foregroundColor(viewModel.previousPeriodComparison.hours >= 0 ? Color("SecondaryColor") : Color.red)
                            
                            Text(String(format: L("analytics.comparison.hours", table: "Analytics"), abs(viewModel.previousPeriodComparison.hours)))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color("TextColor"))
                        }
                        
                        // Uyku skoru değişimi
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.previousPeriodComparison.score >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .foregroundColor(viewModel.previousPeriodComparison.score >= 0 ? Color("SecondaryColor") : Color.red)
                            
                            Text(String(format: L("analytics.comparison.score", table: "Analytics"), abs(viewModel.previousPeriodComparison.score)))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color("TextColor"))
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(Color("CardBackground").opacity(0.5))
                .cornerRadius(8)
            }
            
            // Ana metrikler
            HStack(spacing: 15) {
                MetricCard(
                    title: L("analytics.totalSleep", table: "Analytics"),
                    value: String(format: L("analytics.value.hours", table: "Analytics"), viewModel.totalSleepHours),
                    icon: "bed.double.fill",
                    color: Color("AccentColor")
                )
                
                MetricCard(
                    title: L("analytics.dailyAverage", table: "Analytics"),
                    value: String(format: L("analytics.value.hours", table: "Analytics"), viewModel.averageDailyHours),
                    icon: "clock.fill",
                    color: Color("PrimaryColor")
                )
                
                MetricCard(
                    title: L("analytics.averageScore", table: "Analytics"),
                    value: String(format: L("analytics.value.scoreOf5", table: "Analytics"), viewModel.averageSleepScore),
                    icon: "star.fill",
                    color: Color("SecondaryColor")
                )
            }
            
            // Uyku Skoru Değerlendirmesi
            HStack {
                Text(L("analytics.sleepQuality.title", table: "Analytics"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("SecondaryTextColor"))
                
                let category = SleepQualityCategory.fromRating(viewModel.averageSleepScore)
                Text(category.localizedName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(category.color)
                
                Spacer()
                
                // Uyku Hedefi İlerleme Çubuğu
                VStack(alignment: .trailing, spacing: 4) {
                    Text(L("analytics.sleepGoal.title", table: "Analytics"))
                        .font(.system(size: 12))
                        .foregroundColor(Color("SecondaryTextColor"))
                    
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 8)
                        
                        let targetWidth = min(viewModel.averageDailyHours / 8.0 * 100, 100)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color("PrimaryColor"))
                            .frame(width: targetWidth, height: 8)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color("CardBackground"))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color("SecondaryTextColor"))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color("TextColor"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Quality Distribution
struct AnalyticsQualityDistribution: View {
    let viewModel: AnalyticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("analytics.qualityDistribution.title", table: "Analytics"))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("TextColor"))
            
            VStack(spacing: 10) {
                QualityDistributionRow(
                    category: L("analytics.sleepQuality.excellent", table: "Analytics"),
                    count: viewModel.sleepQualityStats.excellentDays,
                    percentage: viewModel.sleepQualityStats.excellentPercentage,
                    color: SleepQualityCategory.excellent.color
                )
                
                QualityDistributionRow(
                    category: L("analytics.sleepQuality.good", table: "Analytics"),
                    count: viewModel.sleepQualityStats.goodDays,
                    percentage: viewModel.sleepQualityStats.goodPercentage,
                    color: SleepQualityCategory.good.color
                )
                
                QualityDistributionRow(
                    category: L("analytics.sleepQuality.average", table: "Analytics"),
                    count: viewModel.sleepQualityStats.averageDays,
                    percentage: viewModel.sleepQualityStats.averagePercentage,
                    color: SleepQualityCategory.average.color
                )
                
                QualityDistributionRow(
                    category: L("analytics.sleepQuality.poor", table: "Analytics"),
                    count: viewModel.sleepQualityStats.poorDays,
                    percentage: viewModel.sleepQualityStats.poorPercentage,
                    color: SleepQualityCategory.poor.color
                )
                
                QualityDistributionRow(
                    category: L("analytics.sleepQuality.bad", table: "Analytics"),
                    count: viewModel.sleepQualityStats.badDays,
                    percentage: viewModel.sleepQualityStats.badPercentage,
                    color: SleepQualityCategory.bad.color
                )
            }
            
            // Trend göstergesi
            HStack {
                Text(L("analytics.sleepQualityTrend.title", table: "Analytics"))
                    .font(.system(size: 14))
                    .foregroundColor(Color("TextColor"))
                
                if abs(viewModel.sleepStatistics.trendDirection) < 0.1 {
                    Text(L("analytics.sleepQualityTrend.stable", table: "Analytics"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("TextColor"))
                } else {
                    HStack(spacing: 4) {
                        Text(viewModel.sleepStatistics.trendDirection > 0 ? L("analytics.sleepQualityTrend.improving", table: "Analytics") : L("analytics.sleepQualityTrend.deteriorating", table: "Analytics"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(viewModel.sleepStatistics.trendDirection > 0 ? Color("SecondaryColor") : Color.red)
                        
                        Image(systemName: viewModel.sleepStatistics.trendDirection > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundColor(viewModel.sleepStatistics.trendDirection > 0 ? Color("SecondaryColor") : Color.red)
                    }
                }
                
                if abs(viewModel.sleepStatistics.improvementRate) > 1 {
                    Text(String(format: L("analytics.sleepQualityTrend.improvementRate", table: "Analytics"), abs(viewModel.sleepStatistics.improvementRate)))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("SecondaryTextColor"))
                }
                
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color("CardBackground"))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Quality Distribution Row
struct QualityDistributionRow: View {
    let category: String
    let count: Int
    let percentage: Double
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(category)
                .font(.system(size: 14))
                .foregroundColor(Color("TextColor"))
            
            Text(String(format: L("analytics.qualityDistribution.daysCount", table: "Analytics"), count))
                .font(.system(size: 12))
                .foregroundColor(Color("SecondaryTextColor"))
            
            Spacer()
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(color)
                    .frame(width: percentage.isNaN ? 0 : min(percentage, 100), height: 8)
                    .cornerRadius(4)
            }
            
            Text(String(format: L("analytics.qualityDistribution.percentage", table: "Analytics"), percentage))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color("TextColor"))
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// MARK: - Consistency Section
struct AnalyticsConsistencySection: View {
    let viewModel: AnalyticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("analytics.consistency.title", table: "Analytics"))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("TextColor"))
            
            HStack(spacing: 20) {
                // Tutarlılık göstergesi
                VStack {
                    ZStack {
                        // Arkaplan daire
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                            .frame(width: 130, height: 130)
                        
                        // Değer dairesi
                        Circle()
                            .trim(from: 0, to: CGFloat(viewModel.sleepStatistics.consistencyScore / 100))
                            .stroke(
                                viewModel.sleepStatistics.consistencyScore > 70 ? Color("SecondaryColor") :
                                    viewModel.sleepStatistics.consistencyScore > 40 ? Color("PrimaryColor") : Color.orange,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 130, height: 130)
                        
                        // Değer metni
                        VStack(spacing: 0) {
                            Text(String(format: "%.0f", viewModel.sleepStatistics.consistencyScore))
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(Color("TextColor"))
                            
                            Text(L("analytics.consistency.scoreUnit", table: "Analytics"))
                                .font(.system(size: 14))
                                .foregroundColor(Color("SecondaryTextColor"))
                        }
                    }
                    
                    Text(L("analytics.consistency.description", table: "Analytics"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("TextColor"))
                        .padding(.top, 8)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L("analytics.variability.title", table: "Analytics"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color("SecondaryTextColor"))
                        
                        HStack {
                            Text(String(format: "%.0f", viewModel.sleepStatistics.variabilityScore))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color("TextColor"))
                            
                            Text(L("analytics.consistency.scoreUnit", table: "Analytics"))
                                .font(.system(size: 14))
                                .foregroundColor(Color("SecondaryTextColor"))
                        }
                        
                        Text(viewModel.sleepStatistics.variabilityScore < 30 ? L("analytics.variability.stable", table: "Analytics") :
                             viewModel.sleepStatistics.variabilityScore < 60 ? L("analytics.variability.moderate", table: "Analytics") : L("analytics.variability.high", table: "Analytics"))
                            .font(.system(size: 12))
                            .foregroundColor(Color("SecondaryTextColor"))
                    }
                    
                    Divider()
                    
                    // Başarı rozeti veya tavsiye
                    HStack {
                        if viewModel.sleepStatistics.consistencyScore > 70 {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color("SecondaryColor"))
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color.orange)
                        }
                        
                        Text(viewModel.sleepStatistics.consistencyScore > 70 ?
                             L("analytics.consistency.greatRoutine", table: "Analytics") :
                                L("analytics.consistency.improveRoutine", table: "Analytics"))
                            .font(.system(size: 12))
                            .foregroundColor(Color("TextColor"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color("CardBackground"))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Best Worst Days
struct AnalyticsBestWorstDays: View {
    let viewModel: AnalyticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("analytics.bestWorstDays.title", table: "Analytics"))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("TextColor"))
            
            HStack(spacing: 15) {
                // En iyi gün
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "medal.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color("SecondaryColor"))
                        
                        Text(L("analytics.bestWorstDays.bestDay", table: "Analytics"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("TextColor"))
                    }
                    
                    if let bestDay = viewModel.bestSleepDay {
                        Text(bestDay.date, style: .date)
                            .font(.system(size: 14))
                            .foregroundColor(Color("TextColor"))
                        
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color("SecondaryColor"))
                            
                            Text(String(format: "%.1f/5", bestDay.score))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color("TextColor"))
                        }
                        
                        HStack {
                            Image(systemName: "bed.double.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color("PrimaryColor"))
                            
                            Text(String(format: "%.1f saat", bestDay.hours))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color("TextColor"))
                        }
                    } else {
                        Text(L("analytics.bestWorstDays.noData", table: "Analytics"))
                            .font(.system(size: 14))
                            .foregroundColor(Color("SecondaryTextColor"))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("SecondaryColor").opacity(0.1))
                .cornerRadius(8)
                
                // En kötü gün
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.red)
                        
                        Text(L("analytics.bestWorstDays.worstDay", table: "Analytics"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("TextColor"))
                    }
                    
                    if let worstDay = viewModel.worstSleepDay {
                        Text(worstDay.date, style: .date)
                            .font(.system(size: 14))
                            .foregroundColor(Color("TextColor"))
                        
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color.red)
                            
                            Text(String(format: "%.1f/5", worstDay.score))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color("TextColor"))
                        }
                        
                        HStack {
                            Image(systemName: "bed.double.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color("PrimaryColor"))
                            
                            Text(String(format: "%.1f saat", worstDay.hours))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color("TextColor"))
                        }
                    } else {
                        Text(L("analytics.bestWorstDays.noData", table: "Analytics"))
                            .font(.system(size: 14))
                            .foregroundColor(Color("SecondaryTextColor"))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color("CardBackground"))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Time Gained Section
struct AnalyticsTimeGained: View {
    let viewModel: AnalyticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("analytics.timeGained.title", table: "Analytics"))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("TextColor"))
            
            VStack(spacing: 20) {
                HStack(spacing: 15) {
                    // Kazanılan zaman
                    ZStack {
                        Circle()
                            .fill(Color("SecondaryColor").opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        VStack(spacing: 0) {
                            Text("\(Int(viewModel.timeGained))")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color("SecondaryColor"))
                            
                            Text(L("analytics.timeGained.hoursUnit", table: "Analytics"))
                                .font(.system(size: 14))
                                .foregroundColor(Color("SecondaryColor"))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L("analytics.timeGained.subtitle", table: "Analytics"))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color("TextColor"))
                        
                        Text(L("analytics.timeGained.description", table: "Analytics"))
                            .font(.system(size: 14))
                            .foregroundColor(Color("SecondaryTextColor"))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Verimlilik yüzdesi
                        HStack {
                            Text(L("analytics.timeGained.efficiency", table: "Analytics"))
                                .font(.system(size: 14))
                                .foregroundColor(Color("SecondaryTextColor"))
                            
                            Text(String(format: L("analytics.timeGained.efficiencyValue", table: "Analytics"), viewModel.sleepStatistics.efficiencyPercentage))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color("SecondaryColor"))
                        }
                    }
                    
                    Spacer()
                    
                    Text("🎉")
                        .font(.system(size: 36))
                }
                
                // Kazanılan zamanla yapılabilecekler
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("analytics.timeGained.actionsTitle", table: "Analytics"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("TextColor"))
                    
                    VStack(spacing: 10) {
                        ActivityRow(
                            icon: "book.fill",
                            color: .blue,
                            activity: String(format: L("analytics.timeGained.activity.reading", table: "Analytics"), Int(viewModel.timeGained * 30)),
                            note: L("analytics.timeGained.note1", table: "Analytics"))
                        
                        ActivityRow(
                            icon: "figure.walk",
                            color: .green,
                            activity: String(format: L("analytics.timeGained.activity.walking", table: "Analytics"), Int(viewModel.timeGained * 5)),
                            note: L("analytics.timeGained.note2", table: "Analytics"))
                        
                        ActivityRow(
                            icon: "person.crop.rectangle.stack",
                            color: .purple,
                            activity: String(format: L("analytics.timeGained.activity.movies", table: "Analytics"), Int(viewModel.timeGained / 2)),
                            note: L("analytics.timeGained.note3", table: "Analytics"))
                        
                        ActivityRow(
                            icon: "laptopcomputer",
                            color: .orange,
                            activity: String(format: L("analytics.timeGained.activity.projects", table: "Analytics"), Int(viewModel.timeGained * 0.5)),
                            note: L("analytics.timeGained.note4", table: "Analytics"))
                    }
                }
            }
            .padding()
            .background(Color("CardBackground"))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal)
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let icon: String
    let color: Color
    let activity: String
    let note: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(color)
                .cornerRadius(8)
            
            Text(activity)
                .font(.system(size: 14))
                .foregroundColor(Color("TextColor"))
            
            Spacer()
            
            Text(note)
                .font(.system(size: 12))
                .foregroundColor(Color("SecondaryTextColor"))
                .italic()
        }
    }
} 