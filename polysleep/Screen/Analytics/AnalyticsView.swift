import SwiftUI
import Charts

public struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @Environment(\.modelContext) private var modelContext
    
    // Tooltip için state değişkenleri
    @State private var selectedTrendDataPoint: SleepTrendData?
    @State private var selectedBarDataPoint: SleepTrendData?
    @State private var selectedPieSlice: SleepBreakdownData?
    @State private var tooltipPosition: CGPoint = .zero
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Başlık
                    Text(NSLocalizedString("analytics.title", tableName: "Analytics", comment: "Analytics title"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color("TextColor"))
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Zaman Aralığı Seçici
                    timeRangePicker
                    
                    if viewModel.isLoading {
                        // Yükleniyor göstergesi
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                                .padding()
                            
                            Text(NSLocalizedString("analytics.loading", tableName: "Analytics", comment: "Loading indicator text"))
                                .font(.system(size: 16))
                                .foregroundColor(Color("SecondaryTextColor"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 50)
                    } else if viewModel.hasEnoughData {
                        // Yeterli veri varsa analitik içeriği göster
                        summarySectionCard
                        trendChartSection
                        sleepBreakdownSection
                        timeGainedSection
                    } else {
                        // Yetersiz veri uyarısı
                        insufficientDataView
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: shareAnalytics) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color("PrimaryColor"))
                    }
                }
            }
            .background(Color("BackgroundColor"))
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }
    
    // MARK: - UI Components
    
    private var timeRangePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimeRange.allCases) { range in
                    Button(action: {
                        viewModel.changeTimeRange(to: range)
                    }) {
                        Text(NSLocalizedString("analytics.timeRange.\(range.rawValue.lowercased())", tableName: "Analytics", comment: "Time range button title"))
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedTimeRange == range ? Color("PrimaryColor") : Color("CardBackground"))
                            .foregroundColor(viewModel.selectedTimeRange == range ? .white : Color("TextColor"))
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var insufficientDataView: some View {
        VStack(spacing: 20) {
            // Bulanık analiz önizlemesi
            VStack {
                // Bulanık özet kartı
                summarySectionCard
                    .blur(radius: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("CardBackground").opacity(0.3))
                    )
                
                // Bulanık trend grafiği
                trendChartSection
                    .blur(radius: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("CardBackground").opacity(0.3))
                    )
                
                // Bulanık pasta grafiği
                sleepBreakdownSection
                    .blur(radius: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("CardBackground").opacity(0.3))
                    )
            }
            
            // Uyarı mesajı
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color("WarningColor"))
                
                Text(NSLocalizedString("analytics.insufficientData.title", tableName: "Analytics", comment: "Insufficient data title"))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color("TextColor"))
                
                Text(NSLocalizedString("analytics.insufficientData.message", tableName: "Analytics", comment: "Insufficient data message"))
                    .font(.system(size: 16))
                    .foregroundColor(Color("TextColor"))
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    // History sayfasına yönlendir
                }) {
                    Text(NSLocalizedString("analytics.insufficientData.button", tableName: "Analytics", comment: "Insufficient data button title"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color("PrimaryColor"))
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
            .padding()
            .background(Color("CardBackground"))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 30)
        }
    }
    
    private var summarySectionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("analytics.summary.title", tableName: "Analytics", comment: "Summary section title"))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("TextColor"))
            
            HStack(spacing: 15) {
                metricCard(
                    title: NSLocalizedString("analytics.totalSleep", tableName: "Analytics", comment: "Total sleep time metric title"),
                    value: String(format: "%.1f saat", viewModel.totalSleepHours),
                    icon: "bed.double.fill"
                )
                
                metricCard(
                    title: NSLocalizedString("analytics.dailyAverage", tableName: "Analytics", comment: "Daily average sleep time metric title"),
                    value: String(format: "%.1f saat", viewModel.averageDailyHours),
                    icon: "clock.fill"
                )
                
                metricCard(
                    title: NSLocalizedString("analytics.averageScore", tableName: "Analytics", comment: "Average sleep score metric title"),
                    value: String(format: "%.1f/5", viewModel.averageSleepScore),
                    icon: "star.fill"
                )
            }
        }
        .padding()
        .background(Color("CardBackground"))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func metricCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .center, spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color("AccentColor"))
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color("SecondaryTextColor"))
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color("TextColor"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("analytics.trend.title", tableName: "Analytics", comment: "Trend section title"))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("TextColor"))
            
            VStack(alignment: .leading, spacing: 20) {
                // Toplam Uyku Süresi Grafiği
                Chart {
                    ForEach(viewModel.sleepTrendData) { day in
                        LineMark(
                            x: .value("Tarih", day.date, unit: .day),
                            y: .value("Saat", day.totalHours)
                        )
                        .foregroundStyle(Color("PrimaryColor"))
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Tarih", day.date, unit: .day),
                            y: .value("Saat", day.totalHours)
                        )
                        .foregroundStyle(Color("PrimaryColor"))
                    }
                }
                .chartYScale(domain: 0...8)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        if value.index % (viewModel.selectedTimeRange == .Week ? 1 : 3) == 0 {
                            AxisValueLabel()
                        }
                        AxisGridLine()
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
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
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(selectedDay.date, style: .date)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color("TextColor"))
                                
                                HStack {
                                    Text(NSLocalizedString("analytics.trend.total", tableName: "Analytics", comment: "Total sleep time text"))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("SecondaryTextColor"))
                                    
                                    Text(String(format: "%.1f saat", selectedDay.totalHours))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color("TextColor"))
                                }
                                
                                HStack {
                                    Text(NSLocalizedString("analytics.trend.score", tableName: "Analytics", comment: "Sleep score text"))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("SecondaryTextColor"))
                                    
                                    Text(String(format: "%.1f/5", selectedDay.score))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color("TextColor"))
                                }
                            }
                            .padding(8)
                            .background(Color("CardBackground"))
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .offset(x: xPosition + 10 > geometry.size.width - 100 ? xPosition - 110 : xPosition + 10,
                                    y: yPosition - 70)
                            .transition(.opacity)
                        }
                    }
                }
                
                // Bar Chart - Core Sleep vs Naps
                Chart {
                    ForEach(viewModel.sleepTrendData.suffix(7)) { day in
                        BarMark(
                            x: .value("Gün", day.date, unit: .day),
                            y: .value("Core", day.coreHours)
                        )
                        .foregroundStyle(Color("AccentColor"))
                        
                        BarMark(
                            x: .value("Gün", day.date, unit: .day),
                            y: .value("Nap 1", day.nap1Hours)
                        )
                        .foregroundStyle(Color("PrimaryColor"))
                        
                        BarMark(
                            x: .value("Gün", day.date, unit: .day),
                            y: .value("Nap 2", day.nap2Hours)
                        )
                        .foregroundStyle(Color("SecondaryColor"))
                    }
                }
                .chartForegroundStyleScale([
                    "Core Sleep": Color("AccentColor"),
                    "Nap 1": Color("PrimaryColor"),
                    "Nap 2": Color("SecondaryColor")
                ])
                .frame(height: 200)
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
                                        // Tooltip'i bir süre sonra gizle (opsiyonel)
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
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(selectedDay.date, style: .date)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color("TextColor"))
                                
                                HStack {
                                    Rectangle()
                                        .fill(Color("AccentColor"))
                                        .frame(width: 8, height: 8)
                                    
                                    Text(NSLocalizedString("analytics.trend.coreSleep", tableName: "Analytics", comment: "Core sleep text"))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("SecondaryTextColor"))
                                    
                                    Text(String(format: "%.1f s", selectedDay.coreHours))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color("TextColor"))
                                }
                                
                                HStack {
                                    Rectangle()
                                        .fill(Color("PrimaryColor"))
                                        .frame(width: 8, height: 8)
                                    
                                    Text(NSLocalizedString("analytics.trend.nap1", tableName: "Analytics", comment: "Nap 1 text"))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("SecondaryTextColor"))
                                    
                                    Text(String(format: "%.1f s", selectedDay.nap1Hours))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color("TextColor"))
                                }
                                
                                HStack {
                                    Rectangle()
                                        .fill(Color("SecondaryColor"))
                                        .frame(width: 8, height: 8)
                                    
                                    Text(NSLocalizedString("analytics.trend.nap2", tableName: "Analytics", comment: "Nap 2 text"))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("SecondaryTextColor"))
                                    
                                    Text(String(format: "%.1f s", selectedDay.nap2Hours))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color("TextColor"))
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text(NSLocalizedString("analytics.trend.total", tableName: "Analytics", comment: "Total sleep time text"))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("SecondaryTextColor"))
                                    
                                    Text(String(format: "%.1f s", selectedDay.totalHours))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color("TextColor"))
                                }
                            }
                            .padding(8)
                            .background(Color("CardBackground"))
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .offset(x: xPosition + 10 > geometry.size.width - 100 ? xPosition - 110 : xPosition + 10,
                                    y: 50)
                            .transition(.opacity)
                        }
                    }
                }
            }
            .padding()
            .background(Color("CardBackground"))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private var sleepBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("analytics.sleepBreakdown.title", tableName: "Analytics", comment: "Sleep breakdown section title"))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("TextColor"))
            
            HStack(alignment: .center, spacing: 20) {
                // Pasta Grafiği
                ZStack {
                    Chart {
                        ForEach(viewModel.sleepBreakdownData) { item in
                            SectorMark(
                                angle: .value("Yüzde", item.percentage),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .cornerRadius(5)
                            .foregroundStyle(item.color)
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
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(selectedSlice.type)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color("TextColor"))
                                    
                                    HStack {
                                        Rectangle()
                                            .fill(selectedSlice.color)
                                            .frame(width: 8, height: 8)
                                        
                                        Text(String(format: "%.0f%%", selectedSlice.percentage))
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color("TextColor"))
                                    }
                                    
                                    HStack {
                                        Text(NSLocalizedString("analytics.sleepBreakdown.daily", tableName: "Analytics", comment: "Daily sleep breakdown text"))
                                            .font(.system(size: 12))
                                            .foregroundColor(Color("SecondaryTextColor"))
                                        
                                        Text(String(format: "%.1f saat", selectedSlice.hours / Double(viewModel.selectedTimeRange == .Week ? 7 : (viewModel.selectedTimeRange == .Month ? 30 : 90))))
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color("TextColor"))
                                    }
                                    
                                    HStack {
                                        Text(NSLocalizedString("analytics.sleepBreakdown.total", tableName: "Analytics", comment: "Total sleep breakdown text"))
                                            .font(.system(size: 12))
                                            .foregroundColor(Color("SecondaryTextColor"))
                                        
                                        Text(String(format: "%.1f saat", selectedSlice.hours))
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color("TextColor"))
                                    }
                                }
                                .padding(8)
                                .background(Color("CardBackground"))
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                .position(
                                    x: geometry.size.width / 2,
                                    y: geometry.size.height + 70
                                )
                                .transition(.opacity)
                            }
                        }
                    }
                    
                    VStack {
                        Text(String(format: "%.1f", viewModel.averageDailyHours))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color("TextColor"))
                        
                        Text(NSLocalizedString("analytics.sleepBreakdown.perDay", tableName: "Analytics", comment: "Sleep breakdown per day text"))
                            .font(.system(size: 12))
                            .foregroundColor(Color("SecondaryTextColor"))
                    }
                }
                
                // Açıklama
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.sleepBreakdownData) { item in
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(item.color)
                                .frame(width: 16, height: 16)
                                .cornerRadius(4)
                            
                            Text(item.type)
                                .font(.system(size: 14))
                                .foregroundColor(Color("TextColor"))
                            
                            Spacer()
                            
                            Text("\(Int(item.percentage))%")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color("TextColor"))
                            
                            Text(String(format: "(%.1f s)", item.hours))
                                .font(.system(size: 14))
                                .foregroundColor(Color("SecondaryTextColor"))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color("CardBackground"))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private var timeGainedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("analytics.timeGained.title", tableName: "Analytics", comment: "Time gained section title"))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("TextColor"))
            
            HStack(spacing: 15) {
                Image(systemName: "hourglass")
                    .font(.system(size: 36))
                    .foregroundColor(Color("SecondaryColor"))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("analytics.timeGained.message", tableName: "Analytics", comment: "Time gained message"))
                        .font(.system(size: 16))
                        .foregroundColor(Color("SecondaryTextColor"))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(viewModel.timeGained))")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color("SecondaryColor"))
                        
                        Text(NSLocalizedString("analytics.timeGained.hours", tableName: "Analytics", comment: "Time gained hours text"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color("TextColor"))
                    }
                    
                    Text(NSLocalizedString("analytics.timeGained.comparison", tableName: "Analytics", comment: "Time gained comparison text"))
                        .font(.system(size: 14))
                        .foregroundColor(Color("SecondaryTextColor"))
                }
                
                Spacer()
                
                Text("🎉")
                    .font(.system(size: 36))
            }
            .padding()
            .background(Color("SecondaryColor").opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func shareAnalytics() {
        // Paylaşım işlevi burada uygulanacak
        // iOS Share Sheet açılacak
    }
}

#Preview {
    AnalyticsView()
}
