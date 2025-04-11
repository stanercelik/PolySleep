import Foundation
import SwiftUI
import SwiftData
import Charts

enum TimeRange: String, CaseIterable, Identifiable {
    case Week = "week"
    case Month = "month"
    case Quarter = "quarter"
    case Year = "year"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .Week: return "Hafta"
        case .Month: return "Ay"
        case .Quarter: return "Çeyrek"
        case .Year: return "Yıl"
        }
    }
    
    var days: Int {
        switch self {
        case .Week: return 7
        case .Month: return 30
        case .Quarter: return 90
        case .Year: return 365
        }
    }
}

/// Uyku kalitesi kategorisi
enum SleepQualityCategory: String, CaseIterable {
    case excellent = "Mükemmel"
    case good = "İyi"
    case average = "Ortalama" 
    case poor = "Kötü"
    case bad = "Çok Kötü"
    
    var color: Color {
        switch self {
        case .excellent: return Color("SecondaryColor")
        case .good: return Color("PrimaryColor")
        case .average: return Color("AccentColor")
        case .poor: return Color.orange
        case .bad: return Color.red
        }
    }
    
    static func fromRating(_ rating: Double) -> SleepQualityCategory {
        switch rating {
        case 4.5...5: return .excellent
        case 3.5..<4.5: return .good
        case 2.5..<3.5: return .average
        case 1.5..<2.5: return .poor
        default: return .bad
        }
    }
}

/// Uyku trendi verileri
struct SleepTrendData: Identifiable {
    let id = UUID()
    let date: Date
    let totalHours: Double
    let coreHours: Double
    let napHours: Double
    let score: Double
    
    // Ayrıştırılmış şekli
    var nap1Hours: Double = 0.0
    var nap2Hours: Double = 0.0
    
    // Hesaplanmış veriler
    var scoreCategory: SleepQualityCategory {
        SleepQualityCategory.fromRating(score)
    }
    
    var percentageOfTarget: Double {
        // Hedef 8 saat kabul edilirse
        return min((totalHours / 8.0) * 100, 100)
    }
    
    /// Başlangıçta sadece ana değerleri belirle, sonra napları ayrıştır
    init(date: Date, totalHours: Double, coreHours: Double, napHours: Double, score: Double) {
        self.date = date
        self.totalHours = totalHours
        self.coreHours = coreHours 
        self.napHours = napHours
        self.score = score
    }
    
    /// Napları belirli bir dağılımla ayır
    mutating func distributeNaps(nap1: Double, nap2: Double) {
        self.nap1Hours = nap1
        self.nap2Hours = nap2
    }
}

/// Uyku dağılım verileri
struct SleepBreakdownData: Identifiable {
    let id = UUID()
    let type: String
    let hours: Double
    let percentage: Double
    let color: Color
    
    // Ek istatistikler
    var averagePerDay: Double = 0.0
    var daysWithThisType: Int = 0
    var percentageChange: Double = 0.0  // Önceki döneme göre değişim
}

/// Uyku kalitesi istatistikleri
struct SleepQualityStats {
    var excellentDays: Int = 0
    var goodDays: Int = 0
    var averageDays: Int = 0
    var poorDays: Int = 0
    var badDays: Int = 0
    
    var totalDays: Int {
        excellentDays + goodDays + averageDays + poorDays + badDays
    }
    
    var excellentPercentage: Double {
        totalDays > 0 ? Double(excellentDays) / Double(totalDays) * 100 : 0
    }
    
    var goodPercentage: Double {
        totalDays > 0 ? Double(goodDays) / Double(totalDays) * 100 : 0
    }
    
    var averagePercentage: Double {
        totalDays > 0 ? Double(averageDays) / Double(totalDays) * 100 : 0
    }
    
    var poorPercentage: Double {
        totalDays > 0 ? Double(poorDays) / Double(totalDays) * 100 : 0
    }
    
    var badPercentage: Double {
        totalDays > 0 ? Double(badDays) / Double(totalDays) * 100 : 0
    }
    
    var averageRating: Double {
        if totalDays == 0 { return 0 }
        let weightedSum = Double(excellentDays * 5 + goodDays * 4 + averageDays * 3 + poorDays * 2 + badDays * 1)
        return weightedSum / Double(totalDays)
    }
}

/// Kapsamlı uyku istatistikleri
struct SleepStatistics {
    var totalSleepHours: Double = 0.0
    var averageDailyHours: Double = 0.0
    var averageSleepScore: Double = 0.0
    var timeGained: Double = 0.0
    
    // Verimlilik
    var efficiencyPercentage: Double = 0.0  // Hedef uyku süresine kıyasla
    
    // En iyi/en kötü günler
    var bestDay: Date?
    var bestDayScore: Double = 0.0
    var worstDay: Date?
    var worstDayScore: Double = 5.0
    
    // Uyku düzeni
    var consistencyScore: Double = 0.0  // Aynı zamanda uyuma tutarlılığı
    var variabilityScore: Double = 0.0  // Günler arası değişkenlik
    
    // Trend analizi
    var trendDirection: Double = 0.0  // Pozitif değer iyileşme, negatif değer kötüleşme
    var improvementRate: Double = 0.0  // İyileşme oranı
}

class AnalyticsViewModel: ObservableObject {
    @Published var selectedTimeRange: TimeRange = .Week
    @Published var isLoading: Bool = false
    @Published var hasEnoughData: Bool = false
    
    // Ana analiz verileri
    @Published var totalSleepHours: Double = 0.0
    @Published var averageDailyHours: Double = 0.0
    @Published var averageSleepScore: Double = 0.0
    @Published var timeGained: Double = 0.0
    
    // Grafik verileri
    @Published var sleepTrendData: [SleepTrendData] = []
    @Published var sleepBreakdownData: [SleepBreakdownData] = []
    
    // Gelişmiş istatistikler
    @Published var sleepQualityStats: SleepQualityStats = SleepQualityStats()
    @Published var sleepStatistics: SleepStatistics = SleepStatistics()
    
    // En iyi/en kötü günler
    @Published var bestSleepDay: (date: Date, hours: Double, score: Double)?
    @Published var worstSleepDay: (date: Date, hours: Double, score: Double)?
    
    // Karşılaştırma istatistikleri
    @Published var previousPeriodComparison: (hours: Double, score: Double) = (0, 0)
    
    private var modelContext: ModelContext?
    private let minimumRequiredDays = 2  // Daha az veri gereksinimi
    
    // MARK: - Public Methods
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadRealData()
    }
    
    func changeTimeRange(to newRange: TimeRange) {
        selectedTimeRange = newRange
        loadRealData()
    }
    
    // MARK: - Private Methods
    
    private func loadRealData() {
        guard let modelContext = modelContext else { return }
        
        isLoading = true
        
        Task {
            do {
                let descriptor = FetchDescriptor<HistoryModel>(sortBy: [SortDescriptor(\.date, order: .forward)])
                let historyModels = try await modelContext.fetch(descriptor)
                
                // Tarih aralığını belirle
                let endDate = Date()
                let startDate = calculateStartDate(from: endDate)
                let previousStartDate = calculatePreviousPeriodStartDate(from: startDate, endDate: endDate)
                
                // Tarih aralığındaki verileri filtrele
                let filteredHistoryModels = historyModels.filter { historyModel in
                    return historyModel.date >= startDate && historyModel.date <= endDate
                }
                
                // Önceki dönem verileri
                let previousPeriodModels = historyModels.filter { historyModel in
                    return historyModel.date >= previousStartDate && historyModel.date < startDate
                }
                
                // Yeterli veri var mı kontrol et
                let uniqueDays = Set(filteredHistoryModels.map { Calendar.current.startOfDay(for: $0.date) })
                
                await MainActor.run {
                    hasEnoughData = uniqueDays.count >= minimumRequiredDays
                    
                    if hasEnoughData {
                        // Yeterli veri varsa analiz et
                        analyzeData(historyModels: filteredHistoryModels, startDate: startDate, endDate: endDate)
                        
                        // Önceki dönemle karşılaştırma
                        compareToPreviousPeriod(currentModels: filteredHistoryModels, previousModels: previousPeriodModels)
                    } else if !filteredHistoryModels.isEmpty {
                        // Az veri varsa bile göster
                        analyzeData(historyModels: filteredHistoryModels, startDate: startDate, endDate: endDate)
                        hasEnoughData = true
                    }
                    
                    isLoading = false
                }
            } catch {
                print("Veri yüklenirken hata oluştu: \(error)")
                await MainActor.run {
                    isLoading = false
                    hasEnoughData = false
                }
            }
        }
    }
    
    private func calculateStartDate(from endDate: Date) -> Date {
        switch selectedTimeRange {
        case .Week:
            return Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        case .Month:
            return Calendar.current.date(byAdding: .month, value: -1, to: endDate)!
        case .Quarter:
            return Calendar.current.date(byAdding: .month, value: -3, to: endDate)!
        case .Year:
            return Calendar.current.date(byAdding: .year, value: -1, to: endDate)!
        }
    }
    
    private func calculatePreviousPeriodStartDate(from startDate: Date, endDate: Date) -> Date {
        let timeSpan = endDate.timeIntervalSince(startDate)
        return startDate.addingTimeInterval(-timeSpan)
    }
    
    private func analyzeData(historyModels: [HistoryModel], startDate: Date, endDate: Date) {
        // Tüm uyku kayıtları
        let allSleepEntries = historyModels.flatMap { $0.sleepEntries }
        
        // Veri olan günler
        let calendar = Calendar.current
        let daysWithData = Set(historyModels.map { calendar.startOfDay(for: $0.date) }).sorted()
        let daysWithDataCount = daysWithData.count
        
        // SleepStatistics oluştur
        var stats = SleepStatistics()
        
        // Toplam uyku saati
        stats.totalSleepHours = allSleepEntries.reduce(0.0) { result, entry in
            return result + (entry.duration / 3600.0)
        }
        
        // Günlük ortalama uyku saati (sadece veri olan günler için)
        stats.averageDailyHours = daysWithDataCount > 0 ? stats.totalSleepHours / Double(daysWithDataCount) : 0
        
        // Ortalama uyku skoru
        let totalScore = allSleepEntries.reduce(0) { result, entry in
            return result + entry.rating
        }
        stats.averageSleepScore = allSleepEntries.isEmpty ? 0 : Double(totalScore) / Double(allSleepEntries.count)
        
        // Kazanılan zaman (geleneksel uyku düzenine göre)
        let traditionalSleepHours = 8.0 * Double(daysWithDataCount)
        stats.timeGained = max(0, traditionalSleepHours - stats.totalSleepHours)
        
        // Verimlilik
        stats.efficiencyPercentage = traditionalSleepHours > 0 ? 
            ((traditionalSleepHours - stats.totalSleepHours) / traditionalSleepHours) * 100 : 0
            
        // En iyi ve en kötü günleri hesapla
        var bestDay: (date: Date, hours: Double, score: Double)?
        var worstDay: (date: Date, hours: Double, score: Double)?
        
        // Her gün için veri toplayarak en iyi/en kötü günleri belirle
        for day in daysWithData {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: day)!
            
            let dayEntries = historyModels
                .filter { $0.date >= day && $0.date < dayEnd }
                .flatMap { $0.sleepEntries }
            
            if dayEntries.isEmpty { continue }
            
            let dayTotalHours = dayEntries.reduce(0.0) { $0 + $1.duration / 3600.0 }
            let dayScore = dayEntries.reduce(0) { $0 + $1.rating } / dayEntries.count
            
            // En iyi gün (en yüksek skorlu)
            if bestDay == nil || Double(dayScore) > bestDay!.score {
                bestDay = (day, dayTotalHours, Double(dayScore))
            }
            
            // En kötü gün (en düşük skorlu)
            if worstDay == nil || Double(dayScore) < worstDay!.score {
                worstDay = (day, dayTotalHours, Double(dayScore))
            }
        }
        
        stats.bestDay = bestDay?.date
        stats.bestDayScore = bestDay?.score ?? 0
        stats.worstDay = worstDay?.date
        stats.worstDayScore = worstDay?.score ?? 0
        
        // Tutarlılık skorunu hesapla (uyku zamanlarının standart sapması kullanılarak)
        if daysWithDataCount > 1 {
            var sleepTimes: [TimeInterval] = []
            
            for day in daysWithData {
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: day)!
                let dayEntries = historyModels.filter { $0.date >= day && $0.date < dayEnd }.flatMap { $0.sleepEntries }
                
                for entry in dayEntries {
                    let components = calendar.dateComponents([.hour, .minute], from: entry.startTime)
                    let totalMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
                    sleepTimes.append(TimeInterval(totalMinutes * 60))
                }
            }
            
            // Standart sapma hesapla
            if sleepTimes.count > 1 {
                let mean = sleepTimes.reduce(0, +) / Double(sleepTimes.count)
                let variance = sleepTimes.reduce(0) { $0 + pow($1 - mean, 2) } / Double(sleepTimes.count - 1)
                let standardDeviation = sqrt(variance)
                
                // Tutarlılık skoru (daha düşük standart sapma = daha yüksek tutarlılık)
                stats.consistencyScore = max(0, 100 - min(100, standardDeviation / 3600))
                
                // Değişkenlik skoru
                stats.variabilityScore = min(100, standardDeviation / 3600)
            }
        }
        
        // Trend analizi (iyileşme veya kötüleşme)
        if daysWithDataCount > 2 {
            // Zaman içinde skorları analiz et
            let sortedDays = historyModels.sorted(by: { $0.date < $1.date })
            let firstHalf = sortedDays.prefix(sortedDays.count / 2)
            let secondHalf = sortedDays.suffix(sortedDays.count - sortedDays.count / 2)
            
            let firstHalfScore = firstHalf.flatMap { $0.sleepEntries }.reduce(0) { $0 + $1.rating }
            let secondHalfScore = secondHalf.flatMap { $0.sleepEntries }.reduce(0) { $0 + $1.rating }
            
            let firstHalfEntryCount = firstHalf.flatMap { $0.sleepEntries }.count
            let secondHalfEntryCount = secondHalf.flatMap { $0.sleepEntries }.count
            
            let firstHalfAvg = firstHalfEntryCount > 0 ? Double(firstHalfScore) / Double(firstHalfEntryCount) : 0
            let secondHalfAvg = secondHalfEntryCount > 0 ? Double(secondHalfScore) / Double(secondHalfEntryCount) : 0
            
            // Trend yönü ve iyileşme oranı
            stats.trendDirection = secondHalfAvg - firstHalfAvg
            stats.improvementRate = firstHalfAvg > 0 ? (secondHalfAvg - firstHalfAvg) / firstHalfAvg * 100 : 0
        }
        
        // Sınıflandırma istatistiklerini güncelle
        var qualityStats = SleepQualityStats()
        
        for day in daysWithData {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: day)!
            let dayEntries = historyModels.filter { $0.date >= day && $0.date < dayEnd }.flatMap { $0.sleepEntries }
            
            if dayEntries.isEmpty { continue }
            
            let dayScore = dayEntries.reduce(0) { $0 + $1.rating } / dayEntries.count
            let category = SleepQualityCategory.fromRating(Double(dayScore))
            
            switch category {
            case .excellent: qualityStats.excellentDays += 1
            case .good: qualityStats.goodDays += 1
            case .average: qualityStats.averageDays += 1
            case .poor: qualityStats.poorDays += 1
            case .bad: qualityStats.badDays += 1
            }
        }
        
        // ViewModel'deki değişkenleri güncelle
        totalSleepHours = stats.totalSleepHours
        averageDailyHours = stats.averageDailyHours
        averageSleepScore = stats.averageSleepScore
        timeGained = stats.timeGained
        
        sleepStatistics = stats
        sleepQualityStats = qualityStats
        
        bestSleepDay = bestDay
        worstSleepDay = worstDay
        
        createTrendData(from: historyModels, startDate: startDate, endDate: endDate)
        createBreakdownData(from: allSleepEntries, timeRangeDays: selectedTimeRange.days)
    }
    
    private func compareToPreviousPeriod(currentModels: [HistoryModel], previousModels: [HistoryModel]) {
        // Eğer önceki dönem verisi yoksa karşılaştırma yapma
        if previousModels.isEmpty {
            previousPeriodComparison = (0, 0)
            return
        }
        
        // Önceki dönem uyku kayıtları
        let prevSleepEntries = previousModels.flatMap { $0.sleepEntries }
        
        // Önceki dönem toplam uyku saati
        let prevTotalHours = prevSleepEntries.reduce(0.0) { result, entry in
            return result + (entry.duration / 3600.0)
        }
        
        // Önceki dönem ortalama uyku skoru
        let prevTotalScore = prevSleepEntries.reduce(0) { result, entry in
            return result + entry.rating
        }
        let prevAvgScore = prevSleepEntries.isEmpty ? 0 : Double(prevTotalScore) / Double(prevSleepEntries.count)
        
        // Mevcut dönem değerleriyle karşılaştırma
        let hoursDiff = totalSleepHours - prevTotalHours
        let scoreDiff = averageSleepScore - prevAvgScore
        
        previousPeriodComparison = (hoursDiff, scoreDiff)
    }
    
    private func createTrendData(from historyModels: [HistoryModel], startDate: Date, endDate: Date) {
        sleepTrendData = []
        let calendar = Calendar.current
        
        // Seçilen zaman aralığına göre gösterilecek veri sayısını belirle
        let maxDataPoints = selectedTimeRange.days
        
        // Veri noktalarını oluştur
        let dayCount = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? maxDataPoints
        let dataPointCount = min(dayCount + 1, maxDataPoints)
        
        for dayOffset in 0..<dataPointCount {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) {
                let dayStart = calendar.startOfDay(for: date)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                
                let dayEntries = historyModels
                    .filter { $0.date >= dayStart && $0.date < dayEnd }
                    .flatMap { $0.sleepEntries }
                
                let coreEntries = dayEntries.filter { $0.type == .core }
                let napEntries = dayEntries.filter { $0.type == .powerNap }
                
                let totalHours = dayEntries.reduce(0.0) { $0 + $1.duration / 3600.0 }
                let coreHours = coreEntries.reduce(0.0) { $0 + $1.duration / 3600.0 }
                let napHours = napEntries.reduce(0.0) { $0 + $1.duration / 3600.0 }
                
                let totalScore = dayEntries.reduce(0) { result, entry in
                    return result + entry.rating
                }
                let score = dayEntries.isEmpty ? 0.0 : Double(totalScore) / Double(dayEntries.count)
                
                var sleepData = SleepTrendData(
                    date: date,
                    totalHours: totalHours,
                    coreHours: coreHours,
                    napHours: napHours,
                    score: score
                )
                
                // Napları dağıt
                let sortedNaps = napEntries.sorted { $0.startTime < $1.startTime }
                let napCount = sortedNaps.count
                
                var nap1Hours = 0.0
                var nap2Hours = 0.0
                
                if napCount > 0 {
                    if napCount == 1 {
                        nap1Hours = sortedNaps[0].duration / 3600.0
                    } else {
                        let halfIndex = napCount / 2
                        
                        let firstHalfNaps = Array(sortedNaps.prefix(halfIndex))
                        let secondHalfNaps = Array(sortedNaps.suffix(napCount - halfIndex))
                        
                        nap1Hours = firstHalfNaps.reduce(0.0) { $0 + $1.duration / 3600.0 }
                        nap2Hours = secondHalfNaps.reduce(0.0) { $0 + $1.duration / 3600.0 }
                    }
                }
                
                sleepData.distributeNaps(nap1: nap1Hours, nap2: nap2Hours)
                sleepTrendData.append(sleepData)
            }
        }
    }
    
    private func createBreakdownData(from entries: [SleepEntry], timeRangeDays: Int) {
        sleepBreakdownData = []
        
        let coreEntries = entries.filter { $0.type == .core }
        let napEntries = entries.filter { $0.type == .powerNap }
        
        let coreHours = coreEntries.reduce(0.0) { $0 + ($1.duration / 3600.0) }
        let napHours = napEntries.reduce(0.0) { $0 + ($1.duration / 3600.0) }
        
        let totalHours = coreHours + napHours
        
        // Ana uyku verisi
        var coreData = SleepBreakdownData(
            type: NSLocalizedString("analytics.sleepBreakdown.core", tableName: "Analytics", comment: "Core sleep type"),
            hours: coreHours,
            percentage: totalHours > 0 ? (coreHours / totalHours) * 100 : 0,
            color: Color("AccentColor")
        )
        
        // Şekerleme verisi
        var napData = SleepBreakdownData(
            type: NSLocalizedString("analytics.sleepBreakdown.nap", tableName: "Analytics", comment: "Nap sleep type"),
            hours: napHours,
            percentage: totalHours > 0 ? (napHours / totalHours) * 100 : 0,
            color: Color("PrimaryColor")
        )
        
        // Günlük ortalama hesapla
        coreData.averagePerDay = timeRangeDays > 0 ? coreHours / Double(timeRangeDays) : 0
        napData.averagePerDay = timeRangeDays > 0 ? napHours / Double(timeRangeDays) : 0
        
        // Veri olan gün sayısı
        let uniqueCoreDays = Set(coreEntries.map { Calendar.current.startOfDay(for: $0.startTime) }).count
        let uniqueNapDays = Set(napEntries.map { Calendar.current.startOfDay(for: $0.startTime) }).count
        
        coreData.daysWithThisType = uniqueCoreDays
        napData.daysWithThisType = uniqueNapDays
        
        sleepBreakdownData = [coreData, napData]
    }
}

// MARK: - Extensions

extension LocalizedStringKey {
    func toString() -> String {
        return "\(self)"
    }
}
