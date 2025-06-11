import SwiftUI
import Charts

// MARK: - Premium Preview Components

// MARK: - Heat Map Preview
struct AnalyticsHeatMapPreview: View {
    var body: some View {
        ZStack {
            VStack(spacing: PSSpacing.sm) {
                // Başlık satırı
                HStack(spacing: 2) {
                    Text("Gün")
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                        .frame(width: 40, alignment: .leading)
                    
                    ForEach([0, 4, 8, 12, 16, 20], id: \.self) { hour in
                        Text("\(hour)")
                            .font(PSTypography.caption)
                            .foregroundColor(.appTextSecondary)
                            .frame(width: 20, alignment: .center)
                        
                        if hour < 20 {
                            Spacer()
                        }
                    }
                }
                
                // Sample heat map
                VStack(spacing: 2) {
                    ForEach(0..<7) { dayIndex in
                        HStack(spacing: 2) {
                            Text("\(dayIndex + 1)/12")
                                .font(PSTypography.caption)
                                .foregroundColor(.appText)
                                .frame(width: 40, alignment: .leading)
                            
                            ForEach(0..<24) { hour in
                                Rectangle()
                                    .fill(ChartColorUtils.getPreviewSleepColor(day: dayIndex, hour: hour))
                                    .frame(width: 8, height: 20)
                                    .cornerRadius(1)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            
            // Blur overlay
            Rectangle()
                .fill(Color.appBackground.opacity(0.7))
                .overlay(
                    VStack(spacing: PSSpacing.sm) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: PSIconSize.large))
                            .foregroundColor(.appPrimary)
                        
                        Text(L("analytics.premium.unlockMessage", table: "Analytics"))
                            .font(PSTypography.body)
                            .foregroundColor(.appText)
                            .multilineTextAlignment(.center)
                    }
                )
                .cornerRadius(PSCornerRadius.medium)
        }
        .frame(height: 200)
    }
}

// MARK: - Consistency Trend Preview
struct AnalyticsConsistencyTrendPreview: View {
    var body: some View {
        ZStack {
            Chart {
                ForEach(0..<7, id: \.self) { index in
                    let score = Double(70 + (index * 4))
                    let day = Double(index) // Explicitly cast to Double
                    LineMark(
                        x: .value(L("analytics.chart.dayLabel", table: "Analytics"), day), // Use the casted value
                        y: .value(L("analytics.consistency.description", table: "Analytics"), score)
                    )
                    .foregroundStyle(Color.appPrimary)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    PointMark(
                        x: .value(L("analytics.chart.dayLabel", table: "Analytics"), day), // Use the casted value
                        y: .value(L("analytics.consistency.description", table: "Analytics"), score)
                    )
                    .foregroundStyle(Color.appPrimary)
                    .symbolSize(20)
                }
                
                RuleMark(y: .value(L("analytics.consistencyTrend.target", table: "Analytics"), Double(80)))
                    .foregroundStyle(Color.appSecondary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
            .chartYScale(domain: 60...100)
            .frame(height: 120)
            
            // Blur overlay
            Rectangle()
                .fill(Color.appBackground.opacity(0.7))
                .overlay(
                    VStack(spacing: PSSpacing.sm) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: PSIconSize.large))
                            .foregroundColor(.appPrimary)
                        
                        Text(L("analytics.premium.unlockMessage", table: "Analytics"))
                            .font(PSTypography.body)
                            .foregroundColor(.appText)
                            .multilineTextAlignment(.center)
                    }
                )
                .cornerRadius(PSCornerRadius.medium)
        }
        .frame(height: 120)
    }
}

// MARK: - Sleep Debt Preview
struct AnalyticsSleepDebtPreview: View {
    var body: some View {
        ZStack {
            Chart {
                ForEach(0..<7, id: \.self) { index in
                    let day = Double(index) // Explicitly cast to Double
                    let debtValue = Double(-1 + (Double(index) * 0.5)) // Explicitly define and cast
                    
                    AreaMark(
                        x: .value(L("analytics.chart.dayLabel", table: "Analytics"), day),
                        yStart: .value(L("analytics.sleepDebt.zero", table: "Analytics"), Double(0)),
                        yEnd: .value(L("analytics.sleepDebt.value", table: "Analytics"), debtValue)
                    )
                    .foregroundStyle(debtValue >= 0 ? Color.red.opacity(0.6) : Color.green.opacity(0.6))
                    
                    LineMark(
                        x: .value(L("analytics.chart.dayLabel", table: "Analytics"), day),
                        y: .value(L("analytics.sleepDebt.cumulative", table: "Analytics"), debtValue)
                    )
                    .foregroundStyle(debtValue >= 0 ? Color.red : Color.green)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                
                RuleMark(y: .value(L("analytics.sleepDebt.balance", table: "Analytics"), Double(0)))
                    .foregroundStyle(Color.appBorder)
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
            .chartYScale(domain: -2...2)
            .frame(height: 120)
            
            // Blur overlay
            Rectangle()
                .fill(Color.appBackground.opacity(0.7))
                .overlay(
                    VStack(spacing: PSSpacing.sm) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: PSIconSize.large))
                            .foregroundColor(.appPrimary)
                        
                        Text(L("analytics.premium.unlockMessage", table: "Analytics"))
                            .font(PSTypography.body)
                            .foregroundColor(.appText)
                            .multilineTextAlignment(.center)
                    }
                )
                .cornerRadius(PSCornerRadius.medium)
        }
        .frame(height: 120)
    }
}

// MARK: - Quality-Consistency Correlation Preview
struct AnalyticsQualityConsistencyCorrelationPreview: View {
    var body: some View {
        ZStack {
            Chart {
                ForEach(0..<10, id: \.self) { index in
                    let deviation = Double(index * 12)
                    let quality = Double(4.5 - (deviation / 40))
                    
                    PointMark(
                        x: .value(L("analytics.qualityConsistency.deviation", table: "Analytics"), deviation),
                        y: .value(L("analytics.qualityConsistency.quality", table: "Analytics"), quality)
                    )
                    .foregroundStyle(SleepQualityCategory.fromRating(quality).color)
                    .symbolSize(30)
                    .opacity(0.7)
                }
            }
            .chartXScale(domain: 0...120)
            .chartYScale(domain: 1...5)
            .frame(height: 120)
            
            // Blur overlay
            Rectangle()
                .fill(Color.appBackground.opacity(0.7))
                .overlay(
                    VStack(spacing: PSSpacing.sm) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: PSIconSize.large))
                            .foregroundColor(.appPrimary)
                        
                        Text(L("analytics.premium.unlockMessage", table: "Analytics"))
                            .font(PSTypography.body)
                            .foregroundColor(.appText)
                            .multilineTextAlignment(.center)
                    }
                )
                .cornerRadius(PSCornerRadius.medium)
        }
        .frame(height: 120)
    }
} 