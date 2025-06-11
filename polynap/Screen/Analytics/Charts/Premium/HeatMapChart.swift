import SwiftUI
import Charts

// MARK: - Sleep Heat Map Chart
struct SleepHeatMapChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Binding var selectedDay: SleepTrendData?
    @Binding var tooltipPosition: CGPoint
    
    private let hoursInDay = Array(0..<24)
    private let daysToShow = 14 // Son 2 hafta
    
    var body: some View {
        VStack(spacing: PSSpacing.sm) {
            // Saat başlıkları
            HStack(spacing: 2) {
                Text(L("analytics.heatMap.dayLabel", table: "Analytics"))
                    .font(PSTypography.caption)
                    .foregroundColor(.appTextSecondary)
                    .frame(width: 40, alignment: .leading)
                
                ForEach([0, 6, 12, 18, 23], id: \.self) { hour in
                    Text("\(hour)")
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                        .frame(width: 20, alignment: .center)
                    
                    if hour < 23 {
                        Spacer()
                    }
                }
            }
            
            // Heat map grid
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 2) {
                    ForEach(Array(viewModel.sleepTrendData.suffix(daysToShow).enumerated()), id: \.element.id) { index, day in
                        HStack(spacing: 2) {
                            // Gün etiketi
                            Text(day.date, format: .dateTime.day().month())
                                .font(PSTypography.caption)
                                .foregroundColor(.appText)
                                .frame(width: 40, alignment: .leading)
                            
                            // Saatlik bloklar
                            ForEach(hoursInDay, id: \.self) { hour in
                                Rectangle()
                                    .fill(ChartColorUtils.getSleepStateColor(for: day, hour: hour))
                                    .frame(width: 8, height: 20)
                                    .cornerRadius(1)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedDay = day
                                            tooltipPosition = CGPoint(x: 200, y: CGFloat(index * 22))
                                        }
                                        
                                        // 3 saniye sonra tooltip'i gizle
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedDay = nil
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .frame(height: max(100, min(300, CGFloat(viewModel.sleepTrendData.suffix(daysToShow).count * 22))))
            .frame(maxWidth: .infinity)
            
            // Renk efsanesi
            HStack(spacing: PSSpacing.lg) {
                HeatMapLegendItem(color: .appPrimary, label: L("analytics.heatMap.legend.core", table: "Analytics"))
                HeatMapLegendItem(color: .appSecondary, label: L("analytics.heatMap.legend.nap", table: "Analytics"))
                HeatMapLegendItem(color: .appAccent, label: L("analytics.heatMap.legend.light", table: "Analytics"))
                HeatMapLegendItem(color: .appBackground, label: L("analytics.heatMap.legend.awake", table: "Analytics"))
            }
            .padding(.top, PSSpacing.md)
        }
        .overlay {
            if let selectedDay = selectedDay {
                HeatMapTooltip(for: selectedDay)
                    .offset(x: tooltipPosition.x > 200 ? -100 : 50, y: tooltipPosition.y - 30)
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - Heat Map Tooltip
struct HeatMapTooltip: View {
    let day: SleepTrendData
    
    init(for day: SleepTrendData) {
        self.day = day
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.xs) {
            Text(day.date, style: .date)
                .font(PSTypography.body)
                .fontWeight(.semibold)
                .foregroundColor(.appText)
            
            Divider()
            
            HStack(spacing: PSSpacing.md) {
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text(String(format: L("analytics.heatMap.tooltip.core", table: "Analytics"), day.coreHours))
                        .font(PSTypography.caption)
                        .foregroundColor(.appText)
                    
                    Text(String(format: L("analytics.heatMap.tooltip.nap", table: "Analytics"), day.napHours))
                        .font(PSTypography.caption)
                        .foregroundColor(.appText)
                }
                
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text(String(format: L("analytics.heatMap.tooltip.total", table: "Analytics"), day.totalHours))
                        .font(PSTypography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.appText)
                    
                    Text(String(format: L("analytics.heatMap.tooltip.score", table: "Analytics"), day.score))
                        .font(PSTypography.caption)
                        .foregroundColor(day.scoreCategory.color)
                }
            }
        }
        .padding(PSSpacing.sm)
        .background(Color.appCardBackground)
        .cornerRadius(PSCornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
} 