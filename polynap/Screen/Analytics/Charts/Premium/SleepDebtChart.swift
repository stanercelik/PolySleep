import SwiftUI
import Charts

// MARK: - Sleep Debt Chart
struct SleepDebtChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Binding var selectedDataPoint: SleepDebtData?
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        Chart {
            ForEach(viewModel.sleepDebtData) { data in
                // Pozitif borç (kırmızı alan)
                if data.cumulativeDebt > 0 {
                    AreaMark(
                        x: .value(L("analytics.chart.dayLabel", table: "Analytics"), data.date, unit: .day),
                        yStart: .value(L("analytics.sleepDebt.zero", table: "Analytics"), 0),
                        yEnd: .value(L("analytics.sleepDebt.legend.debt", table: "Analytics"), data.cumulativeDebt)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [Color.red.opacity(0.6), Color.red.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                
                // Negatif borç/fazla uyku (yeşil alan)
                if data.cumulativeDebt < 0 {
                    AreaMark(
                        x: .value(L("analytics.chart.dayLabel", table: "Analytics"), data.date, unit: .day),
                        yStart: .value(L("analytics.sleepDebt.zero", table: "Analytics"), 0),
                        yEnd: .value(L("analytics.sleepDebt.legend.surplus", table: "Analytics"), data.cumulativeDebt)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [Color.green.opacity(0.6), Color.green.opacity(0.2)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                
                // Kümülatif borç çizgisi
                LineMark(
                    x: .value(L("analytics.chart.dayLabel", table: "Analytics"), data.date, unit: .day),
                    y: .value(L("analytics.sleepDebt.cumulative", table: "Analytics"), data.cumulativeDebt)
                )
                .foregroundStyle(data.cumulativeDebt >= 0 ? Color.red : Color.green)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
                
                // Günlük borç noktaları
                PointMark(
                    x: .value(L("analytics.chart.dayLabel", table: "Analytics"), data.date, unit: .day),
                    y: .value(L("analytics.sleepDebt.legend.daily", table: "Analytics"), data.dailyDebt)
                )
                .foregroundStyle(data.dailyDebt >= 0 ? Color.orange : Color.blue)
                .symbolSize(15)
                
                // Sıfır çizgisi
                RuleMark(y: .value(L("analytics.sleepDebt.balance", table: "Analytics"), 0))
                    .foregroundStyle(Color.appBorder)
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
        }
        .chartLegend(position: .bottom, alignment: .center) {
            HStack(spacing: PSSpacing.lg) {
                HStack(spacing: PSSpacing.xs) {
                    Rectangle()
                        .fill(Color.red.opacity(0.6))
                        .frame(width: 12, height: 12)
                        .cornerRadius(2)
                    Text(L("analytics.sleepDebt.legend.debt", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appText)
                }
                
                HStack(spacing: PSSpacing.xs) {
                    Rectangle()
                        .fill(Color.green.opacity(0.6))
                        .frame(width: 12, height: 12)
                        .cornerRadius(2)
                    Text(L("analytics.sleepDebt.legend.surplus", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appText)
                }
                
                HStack(spacing: PSSpacing.xs) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text(L("analytics.sleepDebt.legend.daily", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appText)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: max(1, viewModel.sleepDebtData.count / 7))) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: .dateTime.day().month())
                            .font(PSTypography.caption)
                    }
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let debt = value.as(Double.self) {
                        Text(String(format: "%.1fh", debt))
                            .font(PSTypography.caption)
                    }
                }
                AxisGridLine()
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        let xPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
                        guard xPosition >= 0, xPosition < proxy.plotAreaSize.width else {
                            selectedDataPoint = nil
                            return
                        }
                        
                        let x = proxy.value(atX: xPosition, as: Date.self)
                        
                        if let x = x,
                           let matchingData = viewModel.sleepDebtData.first(where: { 
                               Calendar.current.isDate($0.date, inSameDayAs: x)
                           }) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDataPoint = matchingData
                                tooltipPosition = location
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDataPoint = nil
                                }
                            }
                        }
                    }
                
                // Tooltip gösterimi
                if let selectedData = selectedDataPoint {
                    let xPosition = proxy.position(forX: selectedData.date) ?? 0
                    let yPosition = proxy.position(forY: selectedData.cumulativeDebt) ?? 0
                    
                    SleepDebtTooltip(for: selectedData)
                        .offset(x: xPosition + 150 > geometry.size.width ? xPosition - 150 : xPosition + 10,
                                y: yPosition - 60 < 0 ? yPosition + 10 : yPosition - 60)
                        .transition(.opacity)
                }
            }
        }
    }
} 