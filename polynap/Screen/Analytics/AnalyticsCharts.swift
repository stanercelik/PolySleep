import SwiftUI
import Charts

// MARK: - Total Sleep Chart (Free Users)
struct AnalyticsTotalSleepChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
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
    @ObservedObject var viewModel: AnalyticsViewModel
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
    @ObservedObject var viewModel: AnalyticsViewModel
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
                
                // Noktalar (sadece veri olan günler için)
                if day.totalHours > 0 {
                    PointMark(
                        x: .value("Tarih", day.date, unit: .day),
                        y: .value("Saat", day.totalHours)
                    )
                    .foregroundStyle(Color("PrimaryColor"))
                    .symbolSize(30)
                }
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
        .chartYScale(domain: {
            let maxValue = viewModel.sleepTrendData.compactMap { $0.totalHours.isNaN || $0.totalHours.isInfinite ? nil : $0.totalHours }.max() ?? 8
            let upperBound = max(8, maxValue) + 1
            return 0...max(1, upperBound) // En az 1 saat domain garantisi
        }())
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: getXAxisStride(for: viewModel.selectedTimeRange))) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: getDateFormat(for: viewModel.selectedTimeRange))
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
        .frame(height: 220) // Sabit boyut
        .frame(maxWidth: .infinity) // Tam genişlik
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let location = value.location
                                let xPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
                                
                                guard xPosition >= 0, xPosition < proxy.plotAreaSize.width else {
                                    selectedTrendDataPoint = nil
                                    return
                                }
                                
                                if let date = proxy.value(atX: xPosition, as: Date.self),
                                   let matchingDay = viewModel.sleepTrendData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                                    
                                    if selectedTrendDataPoint?.id != matchingDay.id {
                                        withAnimation(.easeInOut(duration: 0.1)) {
                                            selectedTrendDataPoint = matchingDay
                                            tooltipPosition = location
                                        }
                                    }
                                }
                            }
                            .onEnded { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedTrendDataPoint = nil
                                    }
                                }
                            }
                    )
                
                // Tooltip gösterimi
                if let selectedDay = selectedTrendDataPoint {
                    let xPosition = proxy.position(forX: selectedDay.date) ?? 0
                    
                    TotalSleepTooltip(for: selectedDay)
                        .offset(x: xPosition + 120 > geometry.size.width ? xPosition - 120 : xPosition + 10,
                                y: tooltipPosition.y - 70)
                        .transition(.opacity.animation(.easeInOut(duration: 0.1)))
                }
            }
        }
    }
    
    // MARK: - Helper Functions for Chart Formatting
    private func getXAxisStride(for timeRange: TimeRange) -> Int {
        switch timeRange {
        case .Week: return 1        // Her gün
        case .Month: return 5       // 5 günde bir
        case .Quarter: return 14    // 2 haftada bir
        case .Year: return 60       // 2 ayda bir
        }
    }
    
    private func getDateFormat(for timeRange: TimeRange) -> Date.FormatStyle {
        switch timeRange {
        case .Week, .Month: 
            return .dateTime.day().month(.abbreviated)
        case .Quarter: 
            return .dateTime.day().month(.abbreviated)
        case .Year: 
            return .dateTime.month(.abbreviated).year(.twoDigits)
        }
    }
}

// MARK: - Sleep Components Chart
struct SleepComponentsChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Binding var selectedBarDataPoint: SleepTrendData?
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        GeometryReader { geometry in
            Chart {
                // Gösterilecek veri aralığını zaman dilimine göre ayarla
                let displayData = getDisplayData()
                
                ForEach(displayData) { day in
                    // Ana uyku bloğu
                    BarMark(
                        x: .value(L("analytics.chart.dayLabel", table: "Analytics"), day.date, unit: .day),
                        y: .value("Core", day.coreHours),
                        width: .ratio(0.7),
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
                    
                    // Uyku skorunu nokta olarak ekle (sadece veri olan günler için)
                    if day.score > 0 {
                        let yValue = day.totalHours + 0.5
                        PointMark(
                            x: .value(L("analytics.chart.dayLabel", table: "Analytics"), day.date, unit: .day),
                            y: .value(L("analytics.chart.scoreLabel", table: "Analytics"), yValue)
                        )
                        .foregroundStyle(.white)
                        .symbolSize(60)
                        
                        PointMark(
                            x: .value(L("analytics.chart.dayLabel", table: "Analytics"), day.date, unit: .day),
                            y: .value(L("analytics.chart.scoreLabel", table: "Analytics"), yValue)
                        )
                        .foregroundStyle(scoreColor(for: day.score))
                        .symbolSize(40)
                    }
                }
            }
            .frame(width: geometry.size.width, height: 220) // Sabit yükseklik, tam genişlik
            .chartForegroundStyleScale([
                L("analytics.sleepComponentsTrend.core", table: "Analytics"): Color("AccentColor"),
                L("analytics.sleepComponentsTrend.nap1", table: "Analytics"): Color("PrimaryColor"),
                L("analytics.sleepComponentsTrend.nap2", table: "Analytics"): Color("SecondaryColor"),
                L("analytics.chart.sleepScoreLabel", table: "Analytics"): Color.yellow
            ])
            .chartLegend(position: .bottom, alignment: .center, spacing: 10) {
                HStack(spacing: 16) {
                    LegendItem(color: Color("AccentColor"), label: L("analytics.sleepComponentsTrend.core", table: "Analytics"))
                    LegendItem(color: Color("PrimaryColor"), label: L("analytics.sleepComponentsTrend.nap", table: "Analytics"))
                    
                    Divider().frame(height: 20)
                    
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
                AxisMarks(values: .stride(by: .day, count: getXAxisStrideForComponents(for: viewModel.selectedTimeRange))) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: getDateFormatForComponents(for: viewModel.selectedTimeRange))
                                .font(.system(size: 11))
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let hour = value.as(Double.self) {
                        AxisValueLabel {
                            Text("\(Int(hour))")
                                .font(.system(size: 11))
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartOverlay { proxy in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let location = value.location
                                let xPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
                                
                                guard xPosition >= 0, xPosition < proxy.plotAreaSize.width else {
                                    selectedBarDataPoint = nil
                                    return
                                }
                                
                                if let date = proxy.value(atX: xPosition, as: Date.self),
                                   let matchingDay = getDisplayData().min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                                    
                                    if selectedBarDataPoint?.id != matchingDay.id {
                                        withAnimation(.easeInOut(duration: 0.1)) {
                                            selectedBarDataPoint = matchingDay
                                            tooltipPosition = location
                                        }
                                    }
                                }
                            }
                            .onEnded { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedBarDataPoint = nil
                                    }
                                }
                            }
                    )
                
                // Tooltip gösterimi
                if let selectedDay = selectedBarDataPoint {
                    let xPosition = proxy.position(forX: selectedDay.date) ?? 0
                    
                    BarChartTooltip(for: selectedDay)
                        .offset(x: xPosition + 120 > geometry.size.width ? xPosition - 150 : xPosition + 10,
                                y: 50)
                        .transition(.opacity.animation(.easeInOut(duration: 0.1)))
                }
            }
        }
        .frame(height: 280) // Legend için ekstra yükseklik
    }
    
    private func scoreColor(for score: Double) -> Color {
        let category = SleepQualityCategory.fromRating(score)
        return category.color
    }
    
    // Gösterilecek veri aralığını belirle
    private func getDisplayData() -> [SleepTrendData] {
        let allData = viewModel.sleepTrendData
        
        switch viewModel.selectedTimeRange {
        case .Week:
            // Son 7 gün
            return Array(allData.suffix(7))
        case .Month:
            // Son 30 gün (tüm verileri göster ama daha sık stride kullan)
            return allData
        case .Quarter:
            // Son 90 gün
            return allData
        case .Year:
            // Tüm veriler
            return allData
        }
    }
    
    // MARK: - Helper Functions for Components Chart
    private func getXAxisStrideForComponents(for timeRange: TimeRange) -> Int {
        switch timeRange {
        case .Week: return 1        // Her gün
        case .Month: return 4       // 4 günde bir
        case .Quarter: return 14    // 2 haftada bir
        case .Year: return 60       // 2 ayda bir
        }
    }
    
    private func getDateFormatForComponents(for timeRange: TimeRange) -> Date.FormatStyle {
        switch timeRange {
        case .Week: 
            return .dateTime.weekday(.narrow)
        case .Month: 
            return .dateTime.day().month(.abbreviated)
        case .Quarter: 
            return .dateTime.day().month(.abbreviated)
        case .Year: 
            return .dateTime.month(.abbreviated)
        }
    }
}

// MARK: - Sleep Breakdown Section
struct AnalyticsSleepBreakdown: View {
    @ObservedObject var viewModel: AnalyticsViewModel
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
    @ObservedObject var viewModel: AnalyticsViewModel
    @Binding var selectedPieSlice: SleepBreakdownData?
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        ZStack {
            Chart(viewModel.sleepBreakdownData) { item in
                SectorMark(
                    angle: .value(L("analytics.chart.percentageLabel", table: "Analytics"), item.percentage),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .cornerRadius(5)
                .foregroundStyle(item.color)
                .opacity(selectedPieSlice == nil || selectedPieSlice?.id == item.id ? 1.0 : 0.5)
            }
            .frame(width: 150, height: 150) // Sabit boyut
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle().fill(Color.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let location = value.location
                                    if let selectedItem = findSelectedItem(at: location, proxy: proxy, geometry: geometry) {
                                        if selectedPieSlice?.id != selectedItem.id {
                                            withAnimation(.easeInOut(duration: 0.1)) {
                                                selectedPieSlice = selectedItem
                                                tooltipPosition = location
                                            }
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedPieSlice = nil
                                        }
                                    }
                                }
                        )
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
        .overlay {
            if let selectedSlice = selectedPieSlice {
                PieChartTooltip(for: selectedSlice, selectedTimeRange: viewModel.selectedTimeRange)
                    .offset(x: tooltipPosition.x - 80, y: tooltipPosition.y - 120)
                    .transition(.opacity.animation(.easeInOut(duration: 0.1)))
            }
        }
    }
    
    private func findSelectedItem(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> SleepBreakdownData? {
        let plotFrame = geometry[proxy.plotAreaFrame]
        let center = CGPoint(x: plotFrame.midX, y: plotFrame.midY)
        
        let dx = location.x - center.x
        let dy = location.y - center.y
        
        var angle = atan2(dy, dx)
        if angle < 0 { angle += 2 * .pi }
        
        let anglePercentage = angle / (2 * .pi)
        
        var cumulativePercentage: Double = 0
        for item in viewModel.sleepBreakdownData {
            let itemPercentage = item.percentage / 100.0
            if anglePercentage <= cumulativePercentage + itemPercentage {
                return item
            }
            cumulativePercentage += itemPercentage
        }
        
        return viewModel.sleepBreakdownData.last
    }
}

// MARK: - Sleep Breakdown Table
struct SleepBreakdownTable: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
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

// MARK: - Premium Analytics Features

// MARK: - Heat Map Section (Actogram)
struct AnalyticsHeatMapSection: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var selectedDay: SleepTrendData?
    @State private var tooltipPosition: CGPoint = .zero
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.lg) {
                PSSectionHeader(
                    L("analytics.heatMap.title", table: "Analytics"),
                    icon: "calendar.badge.clock",
                    subtitle: L("analytics.heatMap.subtitle", table: "Analytics")
                )
                
                SleepHeatMapChart(
                    viewModel: viewModel,
                    selectedDay: $selectedDay,
                    tooltipPosition: $tooltipPosition
                )
                
                // Açıklayıcı metin
                // Veri yetersizliği uyarısı
                if viewModel.sleepTrendData.filter({ $0.totalHours > 0 }).count < 7 {
                    PSInfoBox(
                        title: "Yetersiz Veri",
                        message: "Daha doğru analiz için en az 1 haftalık düzenli uyku verisi gereklidir. Şu anda sadece \(viewModel.sleepTrendData.filter({ $0.totalHours > 0 }).count) gün veri mevcut.",
                        icon: "exclamationmark.triangle.fill"
                    )
                }
                
                PSInfoBox(
                    title: L("analytics.heatMap.explanation.title", table: "Analytics"),
                    message: L("analytics.heatMap.explanation.message", table: "Analytics"),
                    icon: "info.circle.fill"
                )
            }
        }
        .padding(.horizontal, PSSpacing.lg)
    }
}

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
                                    .fill(getSleepStateColor(for: day, hour: hour))
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
    
    private func getSleepStateColor(for day: SleepTrendData, hour: Int) -> Color {
        // ⚠️ DİKKAT: Bu algoritma varsayımsal veriler kullanıyor
        // Gerçek uyku saatleri SleepEntry'lerden alınmalı
        
        // Temel uyku dönemlerini tahmin et
        let nightSleepStart = 22 // Gece uykusu başlangıcı
        let nightSleepEnd = 8    // Gece uykusu bitişi
        let afternoonNap = 13    // Öğle şekerlemesi
        let eveningNap = 17      // Akşam şekerlemesi
        
        // Veri varsa renklendir, yoksa açık gri
        if day.totalHours == 0 {
            return .appBackground.opacity(0.1) // Veri yok
        }
        
        // Gece uykusu saatleri (ana uyku)
        if (hour >= nightSleepStart || hour <= nightSleepEnd) && day.coreHours > 0 {
            let intensity = min(1.0, day.coreHours / 8.0) // 8 saate kadar yoğunluk
            return .appPrimary.opacity(0.3 + intensity * 0.5)
        }
        
        // Şekerleme saatleri
        if (hour == afternoonNap || hour == eveningNap) && day.napHours > 0 {
            let intensity = min(1.0, day.napHours / 2.0) // 2 saate kadar yoğunluk
            return .appSecondary.opacity(0.3 + intensity * 0.4)
        }
        
        // Uyanık zamanlar
        return .appBackground.opacity(0.15)
    }
}

// MARK: - Heat Map Legend Item
struct HeatMapLegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: PSSpacing.xs) {
            Rectangle()
                .fill(color.opacity(0.8))
                .frame(width: 12, height: 12)
                .cornerRadius(2)
            
            Text(label)
                .font(PSTypography.caption)
                .foregroundColor(.appText)
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

// MARK: - Consistency Trend Section
struct AnalyticsConsistencyTrendSection: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var selectedDataPoint: ConsistencyTrendData?
    @State private var tooltipPosition: CGPoint = .zero
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.lg) {
                PSSectionHeader(
                    L("analytics.consistencyTrend.title", table: "Analytics"),
                    icon: "waveform.path.ecg",
                    subtitle: L("analytics.consistencyTrend.subtitle", table: "Analytics")
                )
                
                ConsistencyTrendChart(
                    viewModel: viewModel,
                    selectedDataPoint: $selectedDataPoint,
                    tooltipPosition: $tooltipPosition
                )
                
                PSInfoBox(
                    title: L("analytics.consistencyTrend.explanation.title", table: "Analytics"),
                    message: L("analytics.consistencyTrend.explanation.message", table: "Analytics"),
                    icon: "lightbulb.fill"
                )
            }
        }
        .padding(.horizontal, PSSpacing.lg)
    }
}

// MARK: - Consistency Trend Chart
struct ConsistencyTrendChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Binding var selectedDataPoint: ConsistencyTrendData?
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        Chart {
            ForEach(viewModel.consistencyTrendData) { data in
                // Tutarlılık skoru çizgisi
                LineMark(
                    x: .value(L("analytics.chart.dayLabel", table: "Analytics"), data.date, unit: .day),
                    y: .value(L("analytics.consistency.description", table: "Analytics"), data.consistencyScore)
                )
                .foregroundStyle(Color.appPrimary)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
                
                // Tutarlılık bandı (± sapma)
                AreaMark(
                    x: .value(L("analytics.chart.dayLabel", table: "Analytics"), data.date, unit: .day),
                    yStart: .value(L("analytics.consistencyTrend.lowerBound", table: "Analytics"), max(0, data.consistencyScore - data.deviation)),
                    yEnd: .value(L("analytics.consistencyTrend.upperBound", table: "Analytics"), min(100, data.consistencyScore + data.deviation))
                )
                .foregroundStyle(Color.appPrimary.opacity(0.2))
                .interpolationMethod(.catmullRom)
                
                // Hedef çizgisi
                RuleMark(y: .value(L("analytics.consistencyTrend.target", table: "Analytics"), 80))
                    .foregroundStyle(Color.appSecondary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text(L("analytics.consistencyTrend.target", table: "Analytics"))
                            .font(PSTypography.caption)
                            .foregroundColor(.appTextSecondary)
                            .padding(.horizontal, PSSpacing.xs)
                            .padding(.vertical, PSSpacing.xs / 2)
                            .background(Color.appCardBackground.opacity(0.8))
                            .cornerRadius(PSCornerRadius.small)
                    }
                
                // Noktalar
                PointMark(
                    x: .value(L("analytics.chart.dayLabel", table: "Analytics"), data.date, unit: .day),
                    y: .value(L("analytics.consistency.description", table: "Analytics"), data.consistencyScore)
                )
                .foregroundStyle(Color.appPrimary)
                .symbolSize(20)
            }
        }
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: getConsistencyXAxisStride(for: viewModel.selectedTimeRange))) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: getConsistencyDateFormat(for: viewModel.selectedTimeRange))
                            .font(PSTypography.caption)
                    }
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let score = value.as(Double.self) {
                        Text("\(Int(score))%")
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
                           let matchingData = viewModel.consistencyTrendData.first(where: { 
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
                    let yPosition = proxy.position(forY: selectedData.consistencyScore) ?? 0
                    
                    ConsistencyTrendTooltip(for: selectedData)
                        .offset(x: xPosition + 150 > geometry.size.width ? xPosition - 150 : xPosition + 10,
                                y: yPosition - 60 < 0 ? yPosition + 10 : yPosition - 60)
                        .transition(.opacity)
                }
            }
        }
    }
    
    // MARK: - Helper Functions for Consistency Chart
    private func getConsistencyXAxisStride(for timeRange: TimeRange) -> Int {
        switch timeRange {
        case .Week: return 1        // Her gün
        case .Month: return 5       // 5 günde bir
        case .Quarter: return 14    // 2 haftada bir
        case .Year: return 60       // 2 ayda bir
        }
    }
    
    private func getConsistencyDateFormat(for timeRange: TimeRange) -> Date.FormatStyle {
        switch timeRange {
        case .Week, .Month: 
            return .dateTime.day().month(.abbreviated)
        case .Quarter: 
            return .dateTime.day().month(.abbreviated)
        case .Year: 
            return .dateTime.month(.abbreviated).year(.twoDigits)
        }
    }
}

// MARK: - Sleep Debt Section
struct AnalyticsSleepDebtSection: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var selectedDataPoint: SleepDebtData?
    @State private var tooltipPosition: CGPoint = .zero
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.lg) {
                PSSectionHeader(
                    L("analytics.sleepDebt.title", table: "Analytics"),
                    icon: "chart.line.uptrend.xyaxis",
                    subtitle: L("analytics.sleepDebt.subtitle", table: "Analytics")
                )
                
                SleepDebtChart(
                    viewModel: viewModel,
                    selectedDataPoint: $selectedDataPoint,
                    tooltipPosition: $tooltipPosition
                )
                
                PSInfoBox(
                    title: L("analytics.sleepDebt.explanation.title", table: "Analytics"),
                    message: L("analytics.sleepDebt.explanation.message", table: "Analytics"),
                    icon: "exclamationmark.triangle.fill"
                )
            }
        }
        .padding(.horizontal, PSSpacing.lg)
    }
}

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

// MARK: - Quality-Consistency Correlation Section
struct AnalyticsQualityConsistencyCorrelation: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var selectedDataPoint: QualityConsistencyData?
    @State private var tooltipPosition: CGPoint = .zero
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.lg) {
                PSSectionHeader(
                    L("analytics.qualityConsistencyCorrelation.title", table: "Analytics"),
                    icon: "chart.dots.scatter",
                    subtitle: L("analytics.qualityConsistencyCorrelation.subtitle", table: "Analytics")
                )
                
                QualityConsistencyScatterChart(
                    viewModel: viewModel,
                    selectedDataPoint: $selectedDataPoint,
                    tooltipPosition: $tooltipPosition
                )
                
                // Veri güvenilirliği uyarısı
                if viewModel.qualityConsistencyData.count < 10 {
                    PSInfoBox(
                        title: "Sınırlı Veri Analizi",
                        message: "Sadece \(viewModel.qualityConsistencyData.count) gün verisiyle korelasyon analizi yapılıyor. Manuel puanlar ve varsayılan saatler kullanılıyor. Daha güvenilir sonuçlar için en az 2-3 haftalık veri gereklidir.",
                        icon: "exclamationmark.triangle.fill"
                    )
                }
                
                PSInfoBox(
                    title: L("analytics.qualityConsistencyCorrelation.explanation.title", table: "Analytics"),
                    message: L("analytics.qualityConsistencyCorrelation.explanation.message", table: "Analytics"),
                    icon: "arrow.triangle.2.circlepath"
                )
            }
        }
        .padding(.horizontal, PSSpacing.lg)
    }
}

// MARK: - Quality-Consistency Scatter Chart
struct QualityConsistencyScatterChart: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Binding var selectedDataPoint: QualityConsistencyData?
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        Chart(viewModel.qualityConsistencyData) { data in
            PointMark(
                x: .value(L("analytics.qualityConsistency.deviation", table: "Analytics"), data.consistencyDeviation),
                y: .value(L("analytics.qualityConsistency.quality", table: "Analytics"), data.sleepQuality)
            )
            .foregroundStyle(data.qualityCategory.color)
            .symbolSize(data.sleepHours * 10) // Uyku süresiyle orantılı boyut
            .opacity(0.7)
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                ZStack {
                    // Trend çizgisi overlay olarak ekle
                    let trendStartY = viewModel.qualityConsistencyCorrelation.intercept
                    let trendEndY = viewModel.qualityConsistencyCorrelation.intercept + (120 * viewModel.qualityConsistencyCorrelation.slope)
                    
                    Path { path in
                        let startPoint = proxy.position(forX: 0) ?? 0
                        let endPoint = proxy.position(forX: 120) ?? 0
                        let startYPos = proxy.position(forY: trendStartY) ?? 0
                        let endYPos = proxy.position(forY: trendEndY) ?? 0
                        
                        path.move(to: CGPoint(x: startPoint, y: startYPos))
                        path.addLine(to: CGPoint(x: endPoint, y: endYPos))
                    }
                    .stroke(Color.appSecondary.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    
                    // Touch handling
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            let xPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
                            let yPosition = location.y - geometry[proxy.plotAreaFrame].origin.y
                            
                            guard xPosition >= 0, xPosition < proxy.plotAreaSize.width,
                                  yPosition >= 0, yPosition < proxy.plotAreaSize.height else {
                                selectedDataPoint = nil
                                return
                            }
                            
                            let x = proxy.value(atX: xPosition, as: Double.self) ?? 0
                            let y = proxy.value(atY: yPosition, as: Double.self) ?? 0
                            
                            // En yakın noktayı bul
                            let closestPoint = viewModel.qualityConsistencyData.min { data1, data2 in
                                let distance1 = sqrt(pow(data1.consistencyDeviation - x, 2) + pow(data1.sleepQuality - y, 2))
                                let distance2 = sqrt(pow(data2.consistencyDeviation - x, 2) + pow(data2.sleepQuality - y, 2))
                                return distance1 < distance2
                            }
                            
                            if let closestPoint = closestPoint {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDataPoint = closestPoint
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
                        let xPosition = proxy.position(forX: selectedData.consistencyDeviation) ?? 0
                        let yPosition = proxy.position(forY: selectedData.sleepQuality) ?? 0
                        
                        QualityConsistencyTooltip(for: selectedData)
                            .offset(x: xPosition + 150 > geometry.size.width ? xPosition - 150 : xPosition + 10,
                                    y: yPosition - 60 < 0 ? yPosition + 10 : yPosition - 60)
                            .transition(.opacity)
                    }
                }
            }
        }
        .chartLegend(position: .bottom, alignment: .center) {
            HStack(spacing: PSSpacing.lg) {
                ForEach(SleepQualityCategory.allCases, id: \.self) { category in
                    HStack(spacing: PSSpacing.xs) {
                        Circle()
                            .fill(category.color)
                            .frame(width: 8, height: 8)
                        Text(category.localizedTitle)
                            .font(PSTypography.caption)
                            .foregroundColor(.appText)
                    }
                }
            }
        }
        .chartXScale(domain: 0...120)
        .chartYScale(domain: 1...5)
        .chartXAxis {
            AxisMarks(position: .bottom) { value in
                AxisValueLabel {
                    if let deviation = value.as(Double.self) {
                        Text("\(Int(deviation))dk")
                            .font(PSTypography.caption)
                    }
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let quality = value.as(Double.self) {
                        Text(String(format: "%.1f", quality))
                            .font(PSTypography.caption)
                    }
                }
                AxisGridLine()
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Premium Preview Components

// MARK: - Sleep Quality Trend Chart (Yeni - Doğru Verilerle)
struct AnalyticsSleepQualityTrendSection: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var selectedDataPoint: SleepTrendData?
    @State private var tooltipPosition: CGPoint = .zero
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.lg) {
                PSSectionHeader(
                    L("analytics.sleepQualityTrendChart.title", table: "Analytics"),
                    icon: "star.circle.fill",
                    subtitle: L("analytics.sleepQualityTrendChart.subtitle", table: "Analytics")
                )
                
                SleepQualityTrendChart(
                    viewModel: viewModel,
                    selectedDataPoint: $selectedDataPoint,
                    tooltipPosition: $tooltipPosition
                )
                
                PSInfoBox(
                    title: L("analytics.sleepQualityTrendChart.infoTitle", table: "Analytics"),
                    message: L("analytics.sleepQualityTrendChart.infoMessage", table: "Analytics"),
                    icon: "lightbulb.fill"
                )
            }
        }
        .padding(.horizontal, PSSpacing.lg)
    }
}

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
            AxisMarks(values: .stride(by: .day, count: getQualityXAxisStride(for: viewModel.selectedTimeRange))) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: getQualityDateFormat(for: viewModel.selectedTimeRange))
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
    
    // MARK: - Helper Functions for Quality Chart
    private func getQualityXAxisStride(for timeRange: TimeRange) -> Int {
        switch timeRange {
        case .Week: return 1        // Her gün
        case .Month: return 5       // 5 günde bir
        case .Quarter: return 14    // 2 haftada bir
        case .Year: return 60       // 2 ayda bir
        }
    }
    
    private func getQualityDateFormat(for timeRange: TimeRange) -> Date.FormatStyle {
        switch timeRange {
        case .Week, .Month: 
            return .dateTime.day().month(.abbreviated)
        case .Quarter: 
            return .dateTime.day().month(.abbreviated)
        case .Year: 
            return .dateTime.month(.abbreviated).year(.twoDigits)
        }
    }
}

// MARK: - Sleep Quality Tooltip
struct SleepQualityTooltip: View {
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
                    Text(L("analytics.sleepQualityTrendChart.tooltip.qualityScore", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                    
                    Text(String(format: "%.1f/5.0", data.score))
                        .font(PSTypography.body)
                        .fontWeight(.medium)
                        .foregroundColor(data.scoreCategory.color)
                }
                
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text(L("analytics.sleepQualityTrendChart.tooltip.category", table: "Analytics"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                    
                    Text(data.scoreCategory.localizedName)
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
                                    .fill(getPreviewSleepColor(day: dayIndex, hour: hour))
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
    
    private func getPreviewSleepColor(day: Int, hour: Int) -> Color {
        if (hour >= 23 || hour <= 7) {
            return Color.appPrimary.opacity(0.8)
        } else if hour == 13 || hour == 17 {
            return Color.appSecondary.opacity(0.6)
        }
        return Color.appBackground.opacity(0.2)
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
                
                // Trend line as simple line
                /*
                LineMark(
                    x: .value("X1", Double(0)), // Ensure Double type
                    y: .value("Y1", Double(4.5)) // Ensure Double type
                )
                .foregroundStyle(Color.appSecondary.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                
                LineMark(
                    x: .value("X2", Double(100)), // Ensure Double type
                    y: .value("Y2", Double(2.0))  // Ensure Double type
                )
                .foregroundStyle(Color.appSecondary.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                */
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