import SwiftUI

// MARK: - Total Sleep Tooltip
struct TotalSleepTooltip: View {
    let data: SleepTrendData
    
    init(for data: SleepTrendData) {
        self.data = data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.xs) {
            Text(data.date, style: .date)
                .font(PSTypography.body)
                .fontWeight(.semibold)
                .foregroundColor(.appText)
            
            Divider()
            
            HStack(spacing: PSSpacing.lg) {
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text(L("analytics.tooltip.totalSleep", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                    
                    Text(String(format: L("analytics.sleepQualityTrendChart.tooltip.hoursFormat", table: "Analytics"), data.totalHours))
                        .font(PSTypography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.appPrimary)
                }
                
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text(L("analytics.sleepQualityTrendChart.tooltip.qualityScore", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                    
                    Text(String(format: "%.1f/5.0", data.score))
                        .font(PSTypography.caption)
                        .foregroundColor(data.scoreCategory.color)
                }
            }
        }
        .padding(PSSpacing.sm)
        .background(Color.appCardBackground)
        .cornerRadius(PSCornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .fixedSize()
    }
}

// MARK: - Detailed Tooltip
struct DetailedTooltip: View {
    let day: SleepTrendData
    let position: CGPoint
    
    init(for day: SleepTrendData, at position: CGPoint) {
        self.day = day
        self.position = position
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Tarih
            Text(day.date, style: .date)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color("TextColor"))
            
            HStack {
                // Uyku süresi
                VStack(alignment: .leading, spacing: 3) {
                    Text(String(format: L("analytics.tooltip.coreLabel", table: "Analytics"), day.coreHours))
                        .font(.system(size: 12))
                        .foregroundColor(Color("TextColor"))
                    
                    Text(String(format: L("analytics.tooltip.napLabel", table: "Analytics"), day.napHours))
                        .font(.system(size: 12))
                        .foregroundColor(Color("TextColor"))
                    
                    Text(String(format: L("analytics.tooltip.totalLabel", table: "Analytics"), day.totalHours))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color("TextColor"))
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 3) {
                    // Şekerleme 1
                    if day.nap1Hours > 0 {
                        Text(String(format: L("analytics.tooltip.nap1Label", table: "Analytics"), day.nap1Hours))
                            .font(.system(size: 11))
                            .foregroundColor(Color("TextColor"))
                    }
                    
                    // Şekerleme 2 ve Toplam
                    if day.nap2Hours > 0 {
                        Text(String(format: L("analytics.tooltip.nap2Label", table: "Analytics"), day.nap2Hours))
                            .font(.system(size: 11))
                            .foregroundColor(Color("TextColor"))
                    }
                    
                    Text(String(format: L("analytics.tooltip.scoreLabel", table: "Analytics"), day.score))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(day.scoreCategory.color)
                }
            }
        }
        .padding(8)
        .background(Color("CardBackground"))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .frame(width: 180)
    }
}

// MARK: - Bar Chart Tooltip
struct BarChartTooltip: View {
    let day: SleepTrendData
    
    init(for day: SleepTrendData) {
        self.day = day
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.xs) {
            Text(day.date, format: .dateTime.weekday(.wide).day())
                .font(PSTypography.body)
                .fontWeight(.semibold)
                .foregroundColor(.appText)
            
            Divider()
            
            HStack(spacing: PSSpacing.lg) {
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text(L("analytics.tooltip.totalSleep", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                    
                    Text(String(format: L("analytics.sleepQualityTrendChart.tooltip.hoursFormat", table: "Analytics"), day.totalHours))
                        .font(PSTypography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.appPrimary)
                }
                
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text(L("analytics.sleepQualityTrendChart.tooltip.qualityScore", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                    
                    Text(String(format: "%.1f/5.0", day.score))
                        .font(PSTypography.caption)
                        .foregroundColor(day.scoreCategory.color)
                }
            }
            
            // Bileşenler detayı (varsa göster)
            if day.coreHours > 0 || day.nap1Hours > 0 || day.nap2Hours > 0 {
                HStack(spacing: PSSpacing.sm) {
                    if day.coreHours > 0 {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(Color.appAccent)
                                .frame(width: 6, height: 6)
                            Text(String(format: "%.1fs", day.coreHours))
                                .font(PSTypography.caption)
                                .foregroundColor(.appText)
                        }
                    }
                    
                    if day.nap1Hours > 0 {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(Color.appPrimary)
                                .frame(width: 6, height: 6)
                            Text(String(format: "%.1fs", day.nap1Hours))
                                .font(PSTypography.caption)
                                .foregroundColor(.appText)
                        }
                    }
                    
                    if day.nap2Hours > 0 {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(Color.appSecondary)
                                .frame(width: 6, height: 6)
                            Text(String(format: "%.1fs", day.nap2Hours))
                                .font(PSTypography.caption)
                                .foregroundColor(.appText)
                        }
                    }
                }
            }
        }
        .padding(PSSpacing.sm)
        .background(Color.appCardBackground)
        .cornerRadius(PSCornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .fixedSize()
    }
}

// MARK: - Pie Chart Tooltip
struct PieChartTooltip: View {
    let slice: SleepBreakdownData
    let selectedTimeRange: TimeRange
    
    init(for slice: SleepBreakdownData, selectedTimeRange: TimeRange) {
        self.slice = slice
        self.selectedTimeRange = selectedTimeRange
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(slice.type)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color("TextColor"))
            
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(String(format: L("analytics.tooltip.percentageLabel", table: "Analytics"), slice.percentage))
                        .font(.system(size: 11))
                        .foregroundColor(Color("TextColor"))
                    
                    Text(String(format: L("analytics.tooltip.totalHoursLabel", table: "Analytics"), slice.hours))
                        .font(.system(size: 11))
                        .foregroundColor(Color("TextColor"))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(String(format: L("analytics.tooltip.dailyHoursLabel", table: "Analytics"), slice.averagePerDay))
                        .font(.system(size: 11))
                        .foregroundColor(Color("TextColor"))
                    
                    Text(String(format: L("analytics.tooltip.daysLabel", table: "Analytics"), slice.daysWithThisType))
                        .font(.system(size: 11))
                        .foregroundColor(Color("TextColor"))
                }
            }
        }
        .padding(8)
        .background(Color("CardBackground"))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .frame(width: 160)
    }
}

// MARK: - Consistency Trend Tooltip
struct ConsistencyTrendTooltip: View {
    let data: ConsistencyTrendData
    
    init(for data: ConsistencyTrendData) {
        self.data = data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.xs) {
            Text(data.date, style: .date)
                .font(PSTypography.body)
                .fontWeight(.semibold)
                .foregroundColor(.appText)
            
            Divider()
            
            VStack(alignment: .leading, spacing: PSSpacing.xs) {
                Text("Tutarlılık: \(String(format: "%.0f", data.consistencyScore))%")
                    .font(PSTypography.caption)
                    .foregroundColor(.appText)
                
                Text("Sapma: ±\(String(format: "%.0f", data.deviation))dk")
                    .font(PSTypography.caption)
                    .foregroundColor(.appTextSecondary)
                
                Text("Durum: \(data.consistencyLevel.localizedTitle)")
                    .font(PSTypography.caption)
                    .foregroundColor(data.consistencyLevel.color)
            }
        }
        .padding(PSSpacing.sm)
        .background(Color.appCardBackground)
        .cornerRadius(PSCornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Sleep Debt Tooltip
struct SleepDebtTooltip: View {
    let data: SleepDebtData
    
    init(for data: SleepDebtData) {
        self.data = data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.xs) {
            Text(data.date, style: .date)
                .font(PSTypography.body)
                .fontWeight(.semibold)
                .foregroundColor(.appText)
            
            Divider()
            
            VStack(alignment: .leading, spacing: PSSpacing.xs) {
                Text("Günlük: \(String(format: "%.1f", data.dailyDebt))h")
                    .font(PSTypography.caption)
                    .foregroundColor(data.dailyDebt >= 0 ? .red : .green)
                
                Text("Kümülatif: \(String(format: "%.1f", data.cumulativeDebt))h")
                    .font(PSTypography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(data.cumulativeDebt >= 0 ? .red : .green)
                
                Text("Hedef: \(String(format: "%.1f", data.targetSleep))h")
                    .font(PSTypography.caption)
                    .foregroundColor(.appTextSecondary)
                
                Text("Gerçek: \(String(format: "%.1f", data.actualSleep))h")
                    .font(PSTypography.caption)
                    .foregroundColor(.appText)
            }
        }
        .padding(PSSpacing.sm)
        .background(Color.appCardBackground)
        .cornerRadius(PSCornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Quality-Consistency Correlation Tooltip
struct QualityConsistencyTooltip: View {
    let data: QualityConsistencyData
    
    init(for data: QualityConsistencyData) {
        self.data = data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.xs) {
            Text(data.date, style: .date)
                .font(PSTypography.body)
                .fontWeight(.semibold)
                .foregroundColor(.appText)
            
            Divider()
            
            HStack(spacing: PSSpacing.md) {
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text("Kalite: \(String(format: "%.1f", data.sleepQuality))")
                        .font(PSTypography.caption)
                        .foregroundColor(data.qualityCategory.color)
                    
                    Text("Sapma: \(String(format: "%.0f", data.consistencyDeviation))dk")
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                }
                
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text("Süre: \(String(format: "%.1f", data.sleepHours))h")
                        .font(PSTypography.caption)
                        .foregroundColor(.appText)
                    
                    Text("Kategori: \(data.qualityCategory.localizedTitle)")
                        .font(PSTypography.caption)
                        .foregroundColor(data.qualityCategory.color)
                }
            }
        }
        .padding(PSSpacing.sm)
        .background(Color.appCardBackground)
        .cornerRadius(PSCornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
} 