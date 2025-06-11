import SwiftUI
import Charts

// MARK: - Sleep Quality Trend Chart Implementation
struct SleepQualityTrendChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Binding var selectedDataPoint: SleepTrendData?
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        Chart {
            ForEach(viewModel.sleepTrendData) { data in
                // Kalite skorunu yüzdeye çevir (1-5 → 0-100)
                let qualityPercentage = (data.score / 5.0) * 100
                
                // Kalite trendi çizgisi
                LineMark(
                    x: .value("Tarih", data.date, unit: .day),
                    y: .value("Kalite", qualityPercentage)
                )
                .foregroundStyle(Color.red)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .interpolationMethod(.catmullRom)
                
                // Kalite bandı (kırmızı renk sabit)
                AreaMark(
                    x: .value("Tarih", data.date, unit: .day),
                    yStart: .value("Alt", 0),
                    yEnd: .value("Kalite", qualityPercentage)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [Color.red.opacity(0.6), Color.red.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                // Kalite noktaları
                PointMark(
                    x: .value("Tarih", data.date, unit: .day),
                    y: .value("Kalite", qualityPercentage)
                )
                .foregroundStyle(Color.red)
                .symbolSize(40)
            }
            
            // Hedef kalite çizgileri
            RuleMark(y: .value(L("analytics.sleepQualityTrendChart.excellentTarget", table: "Analytics"), 90))
                .foregroundStyle(SleepQualityCategory.excellent.color.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .annotation(position: .top, alignment: .trailing) {
                    Text(L("analytics.sleepQualityTrendChart.excellentTarget", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                        .padding(.horizontal, PSSpacing.xs)
                        .padding(.vertical, PSSpacing.xs / 2)
                        .background(Color.appCardBackground.opacity(0.8))
                        .cornerRadius(PSCornerRadius.small)
                }
            
            RuleMark(y: .value(L("analytics.sleepQualityTrendChart.goodTarget", table: "Analytics"), 80))
                .foregroundStyle(SleepQualityCategory.good.color.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .annotation(position: .top, alignment: .trailing) {
                    Text(L("analytics.sleepQualityTrendChart.goodTarget", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                        .padding(.horizontal, PSSpacing.xs)
                        .padding(.vertical, PSSpacing.xs / 2)
                        .background(Color.appCardBackground.opacity(0.8))
                        .cornerRadius(PSCornerRadius.small)
                }
        }
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: ChartFormatUtils.getQualityXAxisStride(for: viewModel.selectedTimeRange))) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: ChartFormatUtils.getQualityDateFormat(for: viewModel.selectedTimeRange))
                            .font(PSTypography.caption)
                    }
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let percentage = value.as(Double.self) {
                        Text("\(Int(percentage))%")
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
                           let matchingData = viewModel.sleepTrendData.first(where: { 
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
                    let qualityPercentage = (selectedData.score / 5.0) * 100
                    let xPosition = proxy.position(forX: selectedData.date) ?? 0
                    let yPosition = proxy.position(forY: qualityPercentage) ?? 0
                    
                    SleepQualityTooltip(for: selectedData)
                        .offset(x: xPosition + 120 > geometry.size.width ? xPosition - 120 : xPosition + 10,
                                y: yPosition - 50 < 0 ? yPosition + 10 : yPosition - 50)
                        .transition(.opacity)
                }
            }
        }
    }
} 