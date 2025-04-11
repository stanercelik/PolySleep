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
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
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
                            // Ana Analiz İçeriği
                            VStack(spacing: 20) {
                                summarySectionCard
                                
                                // Trend İzleme ve Karşılaştırma
                                trendChartSection
                                
                                // Uyku Kalitesi Dağılımı
                                qualityDistributionSection
                                
                                // Uyku Bileşenleri Dağılımı
                                sleepBreakdownSection
                                
                                // Uyku Tutarlılığı Skoru
                                consistencySection
                                
                                // En İyi ve En Kötü Günler
                                bestWorstDaysSection
                                
                                // Kazanılan Zaman ve Verimlilik
                                timeGainedSection
                            }
                        } else {
                            // Yetersiz veri uyarısı - Artık sadece basit mesaj göster, bulanıklık kaldırıldı
                            insufficientDataView
                        }
                    }
                    .padding(.bottom, 30)
                }
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
                        Text(range.displayName)
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
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color("AccentColor"))
                
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
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("analytics.summary.title", tableName: "Analytics", comment: "Summary section title"))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("TextColor"))
            
            // Mevcut ve önceki dönem karşılaştırması
            if viewModel.previousPeriodComparison.hours != 0 || viewModel.previousPeriodComparison.score != 0 {
                HStack {
                    Text("Önceki döneme göre:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("SecondaryTextColor"))
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Uyku saati değişimi
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.previousPeriodComparison.hours >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .foregroundColor(viewModel.previousPeriodComparison.hours >= 0 ? Color("SecondaryColor") : Color.red)
                            
                            Text(String(format: "%.1f s", abs(viewModel.previousPeriodComparison.hours)))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color("TextColor"))
                        }
                        
                        // Uyku skoru değişimi
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.previousPeriodComparison.score >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .foregroundColor(viewModel.previousPeriodComparison.score >= 0 ? Color("SecondaryColor") : Color.red)
                            
                            Text(String(format: "%.1f puan", abs(viewModel.previousPeriodComparison.score)))
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
                metricCard(
                    title: NSLocalizedString("analytics.totalSleep", tableName: "Analytics", comment: "Total sleep time metric title"),
                    value: String(format: "%.1f saat", viewModel.totalSleepHours),
                    icon: "bed.double.fill",
                    color: Color("AccentColor")
                )
                
                metricCard(
                    title: NSLocalizedString("analytics.dailyAverage", tableName: "Analytics", comment: "Daily average sleep time metric title"),
                    value: String(format: "%.1f saat", viewModel.averageDailyHours),
                    icon: "clock.fill",
                    color: Color("PrimaryColor")
                )
                
                metricCard(
                    title: NSLocalizedString("analytics.averageScore", tableName: "Analytics", comment: "Average sleep score metric title"),
                    value: String(format: "%.1f/5", viewModel.averageSleepScore),
                    icon: "star.fill",
                    color: Color("SecondaryColor")
                )
            }
            
            // Uyku Skoru Değerlendirmesi
            HStack {
                Text("Uyku Kaliteniz:")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("SecondaryTextColor"))
                
                let category = SleepQualityCategory.fromRating(viewModel.averageSleepScore)
                Text(category.rawValue)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(category.color)
                
                Spacer()
                
                // Uyku Hedefi İlerleme Çubuğu
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Hedef: 8 saat")
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
    
    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
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
    
    // Uyku Kalitesi Dağılımı (Yeni Bölüm)
    private var qualityDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Uyku Kalitesi Dağılımı")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("TextColor"))
            
            VStack(spacing: 10) {
                // Her kalite kategorisi için bir satır
                qualityDistributionRow(
                    category: "Mükemmel",
                    count: viewModel.sleepQualityStats.excellentDays,
                    percentage: viewModel.sleepQualityStats.excellentPercentage,
                    color: SleepQualityCategory.excellent.color
                )
                
                qualityDistributionRow(
                    category: "İyi",
                    count: viewModel.sleepQualityStats.goodDays,
                    percentage: viewModel.sleepQualityStats.goodPercentage,
                    color: SleepQualityCategory.good.color
                )
                
                qualityDistributionRow(
                    category: "Ortalama",
                    count: viewModel.sleepQualityStats.averageDays,
                    percentage: viewModel.sleepQualityStats.averagePercentage,
                    color: SleepQualityCategory.average.color
                )
                
                qualityDistributionRow(
                    category: "Kötü",
                    count: viewModel.sleepQualityStats.poorDays,
                    percentage: viewModel.sleepQualityStats.poorPercentage,
                    color: SleepQualityCategory.poor.color
                )
                
                qualityDistributionRow(
                    category: "Çok Kötü",
                    count: viewModel.sleepQualityStats.badDays,
                    percentage: viewModel.sleepQualityStats.badPercentage,
                    color: SleepQualityCategory.bad.color
                )
            }
            
            // Trend göstergesi
            HStack {
                Text("Uyku kaliteniz ")
                    .font(.system(size: 14))
                    .foregroundColor(Color("TextColor"))
                
                if abs(viewModel.sleepStatistics.trendDirection) < 0.1 {
                    Text("sabit")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("TextColor"))
                } else {
                    HStack(spacing: 4) {
                        Text(viewModel.sleepStatistics.trendDirection > 0 ? "iyileşiyor" : "kötüleşiyor")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(viewModel.sleepStatistics.trendDirection > 0 ? Color("SecondaryColor") : Color.red)
                        
                        Image(systemName: viewModel.sleepStatistics.trendDirection > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundColor(viewModel.sleepStatistics.trendDirection > 0 ? Color("SecondaryColor") : Color.red)
                    }
                }
                
                if abs(viewModel.sleepStatistics.improvementRate) > 1 {
                    Text(String(format: " (%.0f%%)", abs(viewModel.sleepStatistics.improvementRate)))
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
    
    private func qualityDistributionRow(category: String, count: Int, percentage: Double, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(category)
                .font(.system(size: 14))
                .foregroundColor(Color("TextColor"))
            
            Text("(\(count) gün)")
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
            
            Text(String(format: "%.0f%%", percentage))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color("TextColor"))
                .frame(width: 40, alignment: .trailing)
        }
    }
    
    // Uyku Tutarlılığı Skoru (Yeni Bölüm)
    private var consistencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Uyku Düzeni Tutarlılığı")
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
                            
                            Text("Puan")
                                .font(.system(size: 14))
                                .foregroundColor(Color("SecondaryTextColor"))
                        }
                    }
                    
                    Text("Tutarlılık")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("TextColor"))
                        .padding(.top, 8)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Değişkenlik:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color("SecondaryTextColor"))
                        
                        HStack {
                            Text(String(format: "%.0f", viewModel.sleepStatistics.variabilityScore))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color("TextColor"))
                            
                            Text("Puan")
                                .font(.system(size: 14))
                                .foregroundColor(Color("SecondaryTextColor"))
                        }
                        
                        Text(viewModel.sleepStatistics.variabilityScore < 30 ? "Düzenli uyku saatleri" :
                             viewModel.sleepStatistics.variabilityScore < 60 ? "Orta düzeyde değişkenlik" : "Yüksek değişkenlik")
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
                             "Harika bir uyku rutininiz var!" :
                                "Daha düzenli uyku saatleri için çalışın")
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
    
    // En İyi ve En Kötü Günler (Yeni Bölüm)
    private var bestWorstDaysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("En İyi ve En Kötü Günler")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("TextColor"))
            
            HStack(spacing: 15) {
                // En iyi gün
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "medal.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color("SecondaryColor"))
                        
                        Text("En İyi Gün")
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
                        Text("Veri yok")
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
                        
                        Text("En Kötü Gün")
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
                        Text("Veri yok")
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
    
    // MARK: - Chart Components
    
    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("analytics.trend.title", tableName: "Analytics", comment: "Trend section title"))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("TextColor"))
            
            VStack(alignment: .leading, spacing: 20) {
                // Toplam Uyku Süresi Grafiği
                chartHeader(title: "Günlük Toplam Uyku", subtitle: "Son \(viewModel.sleepTrendData.count) gün")
                
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
                            Text("Hedef: 8 saat")
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
                                Text("\(Int(hour)) s")
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
                            
                            detailedTooltip(for: selectedDay, at: CGPoint(x: xPosition, y: yPosition))
                                .offset(x: xPosition + 140 > geometry.size.width ? xPosition - 150 : xPosition + 10,
                                        y: yPosition - 60 < 0 ? yPosition + 10 : yPosition - 60)
                                .transition(.opacity)
                        }
                    }
                }
                
                // Uyku Bileşenleri Çubuk Grafiği
                chartHeader(title: "Uyku Bileşenleri", subtitle: "Core ve Şekerleme dağılımı")
                
                Chart {
                    ForEach(viewModel.sleepTrendData.suffix(7)) { day in
                        // Ana uyku bloğu
                        BarMark(
                            x: .value("Gün", day.date, unit: .day),
                            y: .value("Core", day.coreHours),
                            stacking: .standard
                        )
                        .foregroundStyle(Color("AccentColor"))
                        .cornerRadius(4)
                        
                        // Şekerleme 1
                        BarMark(
                            x: .value("Gün", day.date, unit: .day),
                            y: .value("Nap 1", day.nap1Hours),
                            stacking: .standard
                        )
                        .foregroundStyle(Color("PrimaryColor"))
                        .cornerRadius(4)
                        
                        // Şekerleme 2
                        BarMark(
                            x: .value("Gün", day.date, unit: .day),
                            y: .value("Nap 2", day.nap2Hours),
                            stacking: .standard
                        )
                        .foregroundStyle(Color("SecondaryColor"))
                        .cornerRadius(4)
                        
                        // Uyku skorunu nokta olarak ekle
                        PointMark(
                            x: .value("Gün", day.date, unit: .day),
                            y: .value("Skor", day.score / 5 * 8) // 5 üzerinden skorları 8 saatlik skalaya dönüştür
                        )
                        .foregroundStyle(.white)
                        .symbolSize(60)
                        
                        PointMark(
                            x: .value("Gün", day.date, unit: .day),
                            y: .value("Skor", day.score / 5 * 8)
                        )
                        .foregroundStyle(scoreColor(for: day.score))
                        .symbolSize(40)
                    }
                }
                .chartForegroundStyleScale([
                    "Ana Uyku": Color("AccentColor"),
                    "Şekerleme 1": Color("PrimaryColor"),
                    "Şekerleme 2": Color("SecondaryColor"),
                    "Uyku Skoru": Color.yellow
                ])
                .chartLegend(position: .bottom, alignment: .center, spacing: 10) {
                    HStack(spacing: 16) {
                        legendItem(color: Color("AccentColor"), label: "Ana Uyku")
                        legendItem(color: Color("PrimaryColor"), label: "Şekerleme 1")
                        legendItem(color: Color("SecondaryColor"), label: "Şekerleme 2")
                        
                        Divider()
                            .frame(height: 20)
                        
                        HStack(spacing: 6) {
                            Circle()
                                .stroke(Color.yellow, lineWidth: 2)
                                .frame(width: 12, height: 12)
                            Text("Uyku Skoru")
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
                            
                            barChartTooltip(for: selectedDay)
                                .offset(x: xPosition + 180 > geometry.size.width ? xPosition - 180 : xPosition + 10,
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
    
    // Tooltip bileşenleri
    private func detailedTooltip(for day: SleepTrendData, at position: CGPoint) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(day.date, style: .date)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color("TextColor"))
            
            Divider()
            
            // Uyku süresi
            HStack {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Color("AccentColor"))
                
                Text("Toplam: \(String(format: "%.1f s", day.totalHours))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color("TextColor"))
            }
            
            // Uyku skoru
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(scoreColor(for: day.score))
                
                Text("Skor: \(String(format: "%.1f/5", day.score))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color("TextColor"))
            }
        }
        .padding(8)
        .background(Color("CardBackground"))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
        .frame(width: 140)
    }
    
    private func barChartTooltip(for day: SleepTrendData) -> some View {
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
                        
                        Text("Ana: \(String(format: "%.1fs", day.coreHours))")
                            .font(.system(size: 11))
                            .foregroundColor(Color("TextColor"))
                    }
                    
                    // Şekerleme 1
                    HStack(spacing: 3) {
                        Rectangle()
                            .fill(Color("PrimaryColor"))
                            .frame(width: 8, height: 8)
                            .cornerRadius(2)
                        
                        Text("Şek1: \(String(format: "%.1fs", day.nap1Hours))")
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
                        
                        Text("Şek2: \(String(format: "%.1fs", day.nap2Hours))")
                            .font(.system(size: 11))
                            .foregroundColor(Color("TextColor"))
                    }
                    
                    Text("Toplam: \(String(format: "%.1fs", day.totalHours))")
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
    
    private func pieChartTooltip(for slice: SleepBreakdownData, selectedTimeRange: TimeRange) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(slice.type)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color("TextColor"))
            
            Divider()
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Yüzde: \(String(format: "%%%.0f", slice.percentage))")
                        .font(.system(size: 11))
                        .foregroundColor(Color("TextColor"))
                    
                    Text("Toplam: \(String(format: "%.1fs", slice.hours))")
                        .font(.system(size: 11))
                        .foregroundColor(Color("TextColor"))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Günlük: \(String(format: "%.1fs", slice.averagePerDay))")
                        .font(.system(size: 11))
                        .foregroundColor(Color("TextColor"))
                    
                    Text("Gün: \(slice.daysWithThisType)")
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
    
    private func chartHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color("TextColor"))
            
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(Color("SecondaryTextColor"))
        }
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color("TextColor"))
        }
    }
    
    private func scoreColor(for score: Double) -> Color {
        let category = SleepQualityCategory.fromRating(score)
        return category.color
    }
    
    private var sleepBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("analytics.sleepBreakdown.title", tableName: "Analytics", comment: "Sleep breakdown section title"))
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color("TextColor"))
            
            VStack(spacing: 20) {
                HStack(alignment: .top, spacing: 20) {
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
                                .annotation(position: .overlay) {
                                    if item.percentage >= 15 {
                                        Text(String(format: "%.0f%%", item.percentage))
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
                                    pieChartTooltip(for: selectedSlice, selectedTimeRange: viewModel.selectedTimeRange)
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
                            
                            Text("saat/gün")
                                .font(.system(size: 12))
                                .foregroundColor(Color("SecondaryTextColor"))
                        }
                    }
                    
                    // Detaylı dağılım tablosu
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
                                            Text("Yüzde:")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color("SecondaryTextColor"))
                                            
                                            Text(String(format: "%%%.0f", item.percentage))
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(Color("TextColor"))
                                        }
                                        
                                        // Toplam süre
                                        HStack {
                                            Text("Toplam:")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color("SecondaryTextColor"))
                                            
                                            Text(String(format: "%.1f s", item.hours))
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(Color("TextColor"))
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        // Günlük ortalama
                                        HStack {
                                            Text("Günlük:")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color("SecondaryTextColor"))
                                            
                                            Text(String(format: "%.1f s", item.averagePerDay))
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(Color("TextColor"))
                                        }
                                        
                                        // Gün sayısı
                                        HStack {
                                            Text("Gün sayısı:")
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
                
                // Poliphasic uyku tavsiyesi
                InfoBox(
                    title: "Bilgi",
                    message: "Ana uyku ve şekerleme dengeniz polyphasic uyku düzeninizi optimize etmenize yardımcı olabilir. İdeal dağılım %70-80 ana uyku, %20-30 şekerleme şeklindedir.",
                    icon: "lightbulb.fill",
                    color: Color("PrimaryColor")
                )
            }
            .padding()
            .background(Color("CardBackground"))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal)
    }
    
    private var timeGainedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("analytics.timeGained.title", tableName: "Analytics", comment: "Time gained section title"))
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
                            
                            Text("saat")
                                .font(.system(size: 14))
                                .foregroundColor(Color("SecondaryColor"))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Kazanılan Zaman")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color("TextColor"))
                        
                        Text("Geleneksel uyku düzenine (günde 8 saat) kıyasla kazandığınız extra zaman")
                            .font(.system(size: 14))
                            .foregroundColor(Color("SecondaryTextColor"))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Verimlilik yüzdesi
                        HStack {
                            Text("Verimlilik:")
                                .font(.system(size: 14))
                                .foregroundColor(Color("SecondaryTextColor"))
                            
                            Text(String(format: "%%%.0f", viewModel.sleepStatistics.efficiencyPercentage))
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
                    Text("Bu zamanla neler yapabilirsiniz?")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("TextColor"))
                    
                    VStack(spacing: 10) {
                        activityRow(
                            icon: "book.fill",
                            color: .blue,
                            activity: "\(Int(viewModel.timeGained * 30)) sayfa kitap okumak",
                            note: "dakikada 1 sayfa"
                        )
                        
                        activityRow(
                            icon: "figure.walk",
                            color: .green,
                            activity: "\(Int(viewModel.timeGained * 5)) km yürümek",
                            note: "saatte 5 km hızla"
                        )
                        
                        activityRow(
                            icon: "person.crop.rectangle.stack",
                            color: .purple,
                            activity: "\(Int(viewModel.timeGained / 2)) film izlemek",
                            note: "film başına 2 saat"
                        )
                        
                        activityRow(
                            icon: "laptopcomputer",
                            color: .orange,
                            activity: "\(Int(viewModel.timeGained * 0.5)) proje tamamlamak",
                            note: "proje başına 2 gün"
                        )
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
    
    private func activityRow(icon: String, color: Color, activity: String, note: String) -> some View {
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
    
    // Yardımcı bileşenler
    private struct InfoBox: View {
        let title: String
        let message: String
        let icon: String
        let color: Color
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color("TextColor"))
                    
                    Text(message)
                        .font(.system(size: 14))
                        .foregroundColor(Color("SecondaryTextColor"))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
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
