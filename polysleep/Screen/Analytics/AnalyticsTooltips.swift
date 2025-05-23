import SwiftUI

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
        VStack(alignment: .leading, spacing: 4) {
            Text(day.date, format: .dateTime.weekday(.wide).day())
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color("TextColor"))
            
            Divider()
            
            HStack(spacing: 8) {
                // Ana uyku
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 3) {
                        Rectangle()
                            .fill(Color("AccentColor"))
                            .frame(width: 8, height: 8)
                            .cornerRadius(2)
                        
                        Text(String(format: L("analytics.tooltip.barChart.coreLabel", table: "Analytics"), day.coreHours))
                            .font(.system(size: 11))
                            .foregroundColor(Color("TextColor"))
                    }
                    
                    // Şekerleme 1
                    HStack(spacing: 3) {
                        Rectangle()
                            .fill(Color("PrimaryColor"))
                            .frame(width: 8, height: 8)
                            .cornerRadius(2)
                        
                        Text(String(format: L("analytics.tooltip.barChart.nap1Label", table: "Analytics"), day.nap1Hours))
                            .font(.system(size: 11))
                            .foregroundColor(Color("TextColor"))
                    }
                }
                
                // Şekerleme 2 ve Toplam
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 3) {
                        Rectangle()
                            .fill(Color("SecondaryColor"))
                            .frame(width: 8, height: 8)
                            .cornerRadius(2)
                        
                        Text(String(format: L("analytics.tooltip.barChart.nap2Label", table: "Analytics"), day.nap2Hours))
                            .font(.system(size: 11))
                            .foregroundColor(Color("TextColor"))
                    }
                    
                    Text(String(format: L("analytics.tooltip.barChart.totalLabel", table: "Analytics"), day.totalHours))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color("TextColor"))
                }
            }
        }
        .padding(8)
        .background(Color("CardBackground"))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
        .frame(width: 160)
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