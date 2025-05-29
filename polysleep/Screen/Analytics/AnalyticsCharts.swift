import SwiftUI
import Charts

// MARK: - Total Sleep Chart (Free Users)
struct AnalyticsTotalSleepChart: View {
    let viewModel: AnalyticsViewModel
    @Binding var selectedTrendDataPoint: SleepTrendData?
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("analytics.trend.title", table: "Analytics"))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("TextColor"))
            
            VStack(alignment: .leading, spacing: 20) {
                // Sadece Toplam Uyku Süresi Grafiği
                ChartHeader(
                    title: L("analytics.totalSleepTrend.title", table: "Analytics"),
                    subtitle: L("analytics.totalSleepTrend.subtitle", table: "Analytics")
                )
                
                SleepTrendChart(
                    viewModel: viewModel,
                    selectedTrendDataPoint: $selectedTrendDataPoint,
                    tooltipPosition: $tooltipPosition
                )
                .allowsHitTesting(false) // Scroll sorununu çözer
            }
            .padding()
            .background(Color("CardBackground"))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - Trend Charts Section
struct AnalyticsTrendCharts: View {
    let viewModel: AnalyticsViewModel
    @Binding var selectedTrendDataPoint: SleepTrendData?
    @Binding var selectedBarDataPoint: SleepTrendData?
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("analytics.trend.title", table: "Analytics"))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("TextColor"))
            
            VStack(alignment: .leading, spacing: 20) {
                // Toplam Uyku Süresi Grafiği
                ChartHeader(
                    title: L("analytics.totalSleepTrend.title", table: "Analytics"),
                    subtitle: L("analytics.totalSleepTrend.subtitle", table: "Analytics")
                )
                
                SleepTrendChart(
                    viewModel: viewModel,
                    selectedTrendDataPoint: $selectedTrendDataPoint,
                    tooltipPosition: $tooltipPosition
                )
                .allowsHitTesting(false) // Scroll sorununu çözer
                
                // Uyku Bileşenleri Çubuk Grafiği
                ChartHeader(
                    title: L("analytics.sleepComponentsTrend.title", table: "Analytics"),
                    subtitle: L("analytics.sleepComponentsTrend.subtitle", table: "Analytics")
                )
                
                SleepComponentsChart(
                    viewModel: viewModel,
                    selectedBarDataPoint: $selectedBarDataPoint,
                    tooltipPosition: $tooltipPosition
                )
                .allowsHitTesting(false) // Scroll sorununu çözer
            }
            .padding()
            .background(Color("CardBackground"))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - Sleep Trend Chart
struct SleepTrendChart: View {
    let viewModel: AnalyticsViewModel
    @Binding var selectedTrendDataPoint: SleepTrendData?
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        Chart {
            ForEach(viewModel.sleepTrendData) { day in
                // Alanı göstermek için alan işaretleyici
                AreaMark(
                    x: .value("Tarih", day.date, unit: .day),
                    y: .value("Saat", day.totalHours)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [Color("PrimaryColor").opacity(0.7), Color("PrimaryColor").opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                // Çizgi
                LineMark(
                    x: .value("Tarih", day.date, unit: .day),
                    y: .value("Saat", day.totalHours)
                )
                .foregroundStyle(Color("PrimaryColor"))
                .lineStyle(StrokeStyle(lineWidth: 3))
                .interpolationMethod(.catmullRom)
                
                // Noktalar
                PointMark(
                    x: .value("Tarih", day.date, unit: .day),
                    y: .value("Saat", day.totalHours)
                )
                .foregroundStyle(Color("PrimaryColor"))
                .symbolSize(30)
            }
            
            // Hedef uyku süresi - referans çizgisi
            RuleMark(y: .value("Hedef", 8))
                .foregroundStyle(Color.gray.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .annotation(position: .top, alignment: .trailing) {
                    Text(L("analytics.totalSleepTrend.goal", table: "Analytics"))
                        .font(.system(size: 12))
                        .foregroundColor(Color("SecondaryTextColor"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color("CardBackground").opacity(0.8))
                        .cornerRadius(4)
                }
        }
        .chartYScale(domain: 0...max(8, viewModel.sleepTrendData.map { $0.totalHours }.max() ?? 8) + 1)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: max(1, viewModel.sleepTrendData.count / 7))) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: .dateTime.day().month())
                            .font(.system(size: 11))
                    }
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let hour = value.as(Double.self) {
                        Text(String(format: L("analytics.chart.hoursUnit", table: "Analytics"), Int(hour)))
                            .font(.system(size: 11))
                    }
                }
                AxisGridLine()
            }
        }
        .frame(height: 220)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let xPosition = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                                guard xPosition >= 0, xPosition < proxy.plotAreaSize.width else {
                                    selectedTrendDataPoint = nil
                                    return
                                }
                                
                                let x = proxy.value(atX: xPosition, as: Date.self)
                                
                                if let x = x,
                                   let matchingDay = viewModel.sleepTrendData.first(where: { 
                                       Calendar.current.isDate($0.date, inSameDayAs: x)
                                   }) {
                                    selectedTrendDataPoint = matchingDay
                                    tooltipPosition = value.location
                                }
                            }
                            .onEnded { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                    withAnimation {
                                        selectedTrendDataPoint = nil
                                    }
                                }
                            }
                    )
                
                // Tooltip gösterimi
                if let selectedDay = selectedTrendDataPoint {
                    let xPosition = proxy.position(forX: selectedDay.date) ?? 0
                    let yPosition = proxy.position(forY: selectedDay.totalHours) ?? 0
                    
                    DetailedTooltip(for: selectedDay, at: CGPoint(x: xPosition, y: yPosition))
                        .offset(x: xPosition + 140 > geometry.size.width ? xPosition - 150 : xPosition + 10,
                                y: yPosition - 60 < 0 ? yPosition + 10 : yPosition - 60)
                        .transition(.opacity)
                }
            }
        }
    }
}

// MARK: - Sleep Components Chart
struct SleepComponentsChart: View {
    let viewModel: AnalyticsViewModel
    @Binding var selectedBarDataPoint: SleepTrendData?
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        Chart {
            ForEach(viewModel.sleepTrendData.suffix(7)) { day in
                // Ana uyku bloğu
                BarMark(
                    x: .value(L("analytics.chart.dayLabel", table: "Analytics"), day.date, unit: .day),
                    y: .value("Core", day.coreHours),
                    stacking: .standard
                )
                .foregroundStyle(Color("AccentColor"))
                .cornerRadius(4)
                
                // Şekerleme 1
                BarMark(
                    x: .value(L("analytics.chart.dayLabel", table: "Analytics"), day.date, unit: .day),
                    y: .value("Nap 1", day.nap1Hours),
                    stacking: .standard
                )
                .foregroundStyle(Color("PrimaryColor"))
                .cornerRadius(4)
                
                // Şekerleme 2
                BarMark(
                    x: .value(L("analytics.chart.dayLabel", table: "Analytics"), day.date, unit: .day),
                    y: .value("Nap 2", day.nap2Hours),
                    stacking: .standard
                )
                .foregroundStyle(Color("SecondaryColor"))
                .cornerRadius(4)
                
                // Uyku skorunu nokta olarak ekle
                PointMark(
                    x: .value(L("analytics.chart.dayLabel", table: "Analytics"), day.date, unit: .day),
                    y: .value(L("analytics.chart.scoreLabel", table: "Analytics"), day.score / 5 * 8)
                )
                .foregroundStyle(.white)
                .symbolSize(60)
                
                PointMark(
                    x: .value(L("analytics.chart.dayLabel", table: "Analytics"), day.date, unit: .day),
                    y: .value(L("analytics.chart.scoreLabel", table: "Analytics"), day.score / 5 * 8)
                )
                .foregroundStyle(scoreColor(for: day.score))
                .symbolSize(40)
            }
        }
        .chartForegroundStyleScale([
            L("analytics.sleepComponentsTrend.core", table: "Analytics"): Color("AccentColor"),
            L("analytics.sleepComponentsTrend.nap1", table: "Analytics"): Color("PrimaryColor"),
            L("analytics.sleepComponentsTrend.nap2", table: "Analytics"): Color("SecondaryColor"),
            L("analytics.chart.sleepScoreLabel", table: "Analytics"): Color.yellow
        ])
        .chartLegend(position: .bottom, alignment: .center, spacing: 10) {
            HStack(spacing: 16) {
                LegendItem(color: Color("AccentColor"), label: L("analytics.sleepComponentsTrend.core", table: "Analytics"))
                LegendItem(color: Color("PrimaryColor"), label: L("analytics.sleepComponentsTrend.nap1", table: "Analytics"))
                LegendItem(color: Color("SecondaryColor"), label: L("analytics.sleepComponentsTrend.nap2", table: "Analytics"))
                
                Divider()
                    .frame(height: 20)
                
                HStack(spacing: 6) {
                    Circle()
                        .stroke(Color.yellow, lineWidth: 2)
                        .frame(width: 12, height: 12)
                    Text(L("analytics.sleepComponentsTrend.score", table: "Analytics"))
                        .font(.system(size: 12))
                        .foregroundColor(Color("TextColor"))
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.weekday())
                            .font(.system(size: 11))
                    }
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { value in
                if let hour = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(Int(hour))")
                            .font(.system(size: 11))
                    }
                }
                AxisGridLine()
            }
        }
        .frame(height: 250)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let xPosition = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                                guard xPosition >= 0, xPosition < proxy.plotAreaSize.width else {
                                    selectedBarDataPoint = nil
                                    return
                                }
                                
                                let x = proxy.value(atX: xPosition, as: Date.self)
                                
                                if let x = x,
                                   let matchingDay = viewModel.sleepTrendData.suffix(7).first(where: { 
                                       Calendar.current.isDate($0.date, inSameDayAs: x)
                                   }) {
                                    selectedBarDataPoint = matchingDay
                                    tooltipPosition = value.location
                                }
                            }
                            .onEnded { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        selectedBarDataPoint = nil
                                    }
                                }
                            }
                    )
                
                // Tooltip gösterimi
                if let selectedDay = selectedBarDataPoint {
                    let xPosition = proxy.position(forX: selectedDay.date) ?? 0
                    
                    BarChartTooltip(for: selectedDay)
                        .offset(x: xPosition + 180 > geometry.size.width ? xPosition - 180 : xPosition + 10,
                                y: 50)
                        .transition(.opacity)
                }
            }
        }
    }
    
    private func scoreColor(for score: Double) -> Color {
        let category = SleepQualityCategory.fromRating(score)
        return category.color
    }
}

// MARK: - Sleep Breakdown Section
struct AnalyticsSleepBreakdown: View {
    let viewModel: AnalyticsViewModel
    @Binding var selectedPieSlice: SleepBreakdownData?
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("analytics.sleepBreakdown.title", table: "Analytics"))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("TextColor"))
            
            VStack(spacing: 20) {
                HStack(alignment: .top, spacing: 20) {
                    // Pasta Grafiği
                    PieChart(
                        viewModel: viewModel,
                        selectedPieSlice: $selectedPieSlice,
                        tooltipPosition: $tooltipPosition
                    )
                    
                    // Detaylı dağılım tablosu
                    SleepBreakdownTable(viewModel: viewModel)
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

// MARK: - Pie Chart
struct PieChart: View {
    let viewModel: AnalyticsViewModel
    @Binding var selectedPieSlice: SleepBreakdownData?
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        ZStack {
            Chart {
                ForEach(viewModel.sleepBreakdownData) { item in
                    SectorMark(
                        angle: .value(L("analytics.chart.percentageLabel", table: "Analytics"), item.percentage),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .cornerRadius(5)
                    .foregroundStyle(item.color)
                    .annotation(position: .overlay) {
                        if item.percentage >= 15 {
                            Text(String(format: L("analytics.chart.percentageShort", table: "Analytics"), item.percentage))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .frame(width: 150, height: 150)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    // Merkeze göre pozisyonu hesapla
                                    let centerX = geometry.size.width / 2
                                    let centerY = geometry.size.height / 2
                                    let x = value.location.x - centerX
                                    let y = value.location.y - centerY
                                    
                                    // Merkeze olan uzaklık
                                    let distance = sqrt(x*x + y*y)
                                    
                                    // Pasta grafiğinin dış ve iç yarıçapları
                                    let outerRadius = min(geometry.size.width, geometry.size.height) / 2
                                    let innerRadius = outerRadius * 0.6
                                    
                                    // Eğer dokunulan nokta pasta diliminin içindeyse
                                    if distance >= innerRadius && distance <= outerRadius {
                                        // Açıyı hesapla (radyan cinsinden)
                                        var angle = atan2(y, x)
                                        if angle < 0 {
                                            angle += 2 * .pi
                                        }
                                        
                                        // Açıyı dereceye çevir
                                        let degrees = angle * 180 / .pi
                                        
                                        // Toplam yüzde
                                        let totalPercentage = viewModel.sleepBreakdownData.reduce(0) { $0 + $1.percentage }
                                        
                                        // Açıyı yüzdeye çevir
                                        let percentage = degrees / 360 * totalPercentage
                                        
                                        // Kümülatif yüzde hesapla ve hangi dilime denk geldiğini bul
                                        var cumulativePercentage: Double = 0
                                        for item in viewModel.sleepBreakdownData {
                                            cumulativePercentage += item.percentage
                                            if percentage <= cumulativePercentage {
                                                selectedPieSlice = item
                                                tooltipPosition = value.location
                                                break
                                            }
                                        }
                                    } else {
                                        selectedPieSlice = nil
                                    }
                                }
                                .onEnded { _ in
                                    // Tooltip'i bir süre sonra gizle
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation {
                                            selectedPieSlice = nil
                                        }
                                    }
                                }
                        )
                    
                    // Tooltip gösterimi
                    if let selectedSlice = selectedPieSlice {
                        PieChartTooltip(for: selectedSlice, selectedTimeRange: viewModel.selectedTimeRange)
                            .position(
                                x: min(max(geometry.size.width / 2, 100), geometry.size.width - 100),
                                y: geometry.size.height + 70
                            )
                            .transition(.opacity)
                    }
                }
            }
            
            // Ortalama uyku süresini merkeze yerleştir
            VStack(spacing: 0) {
                Text(String(format: "%.1f", viewModel.averageDailyHours))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color("TextColor"))
                
                Text(L("analytics.sleepBreakdown.hoursPerDay", table: "Analytics"))
                    .font(.system(size: 12))
                    .foregroundColor(Color("SecondaryTextColor"))
            }
        }
    }
}

// MARK: - Sleep Breakdown Table
struct SleepBreakdownTable: View {
    let viewModel: AnalyticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.sleepBreakdownData) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(item.color)
                            .frame(width: 16, height: 16)
                            .cornerRadius(4)
                        
                        Text(item.type)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color("TextColor"))
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            // Yüzde
                            HStack {
                                Text(L("analytics.sleepBreakdown.percentageLabel", table: "Analytics"))
                                    .font(.system(size: 12))
                                    .foregroundColor(Color("SecondaryTextColor"))
                                
                                Text(String(format: L("analytics.sleepBreakdown.percentageValue", table: "Analytics"), item.percentage))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color("TextColor"))
                            }
                            
                            // Toplam süre
                            HStack {
                                Text(L("analytics.sleepBreakdown.totalLabel", table: "Analytics"))
                                    .font(.system(size: 12))
                                    .foregroundColor(Color("SecondaryTextColor"))
                                
                                Text(String(format: L("analytics.sleepBreakdown.totalValue", table: "Analytics"), item.hours))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color("TextColor"))
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            // Günlük ortalama
                            HStack {
                                Text(L("analytics.sleepBreakdown.dailyLabel", table: "Analytics"))
                                    .font(.system(size: 12))
                                    .foregroundColor(Color("SecondaryTextColor"))
                                
                                Text(String(format: L("analytics.sleepBreakdown.dailyValue", table: "Analytics"), item.averagePerDay))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color("TextColor"))
                            }
                            
                            // Gün sayısı
                            HStack {
                                Text(L("analytics.sleepBreakdown.daysCountLabel", table: "Analytics"))
                                    .font(.system(size: 12))
                                    .foregroundColor(Color("SecondaryTextColor"))
                                
                                Text("\(item.daysWithThisType)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color("TextColor"))
                            }
                        }
                    }
                }
                
                if viewModel.sleepBreakdownData.last?.id != item.id {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Helper Views
struct ChartHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color("TextColor"))
            
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(Color("SecondaryTextColor"))
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color("TextColor"))
        }
    }
} 