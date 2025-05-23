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
        case .Week: return L("analytics.timeRange.week", table: "Analytics")
        case .Month: return L("analytics.timeRange.month", table: "Analytics")
        case .Quarter: return L("analytics.timeRange.quarter", table: "Analytics")
        case .Year: return L("analytics.timeRange.year", table: "Analytics")
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
    
    var localizedName: String {
        switch self {
        case .excellent: return L("analytics.sleepQuality.excellent", table: "Analytics")
        case .good: return L("analytics.sleepQuality.good", table: "Analytics")
        case .average: return L("analytics.sleepQuality.average", table: "Analytics")
        case .poor: return L("analytics.sleepQuality.poor", table: "Analytics")
        case .bad: return L("analytics.sleepQuality.bad", table: "Analytics")
        }
    }
    
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
                let descriptor = FetchDescriptor<HistoryModel>(sortBy: [SortDescriptor(\HistoryModel.date, order: .forward)])
                let allHistoryModels = try await modelContext.fetch(descriptor)

                let endDate = Date()
                let startDate = calculateStartDate(from: endDate)
                
                let filteredHistoryModels = allHistoryModels.filter { $0.date >= startDate && $0.date <= endDate }
                let previousPeriodModels = allHistoryModels.filter {
                    let prevStartDate = calculatePreviousPeriodStartDate(from: startDate, endDate: endDate)
                    return $0.date >= prevStartDate && $0.date < startDate
                }
                
                let uniqueDaysCount = Set(filteredHistoryModels.map { Calendar.current.startOfDay(for: $0.date) }).count

                await MainActor.run {
                    hasEnoughData = uniqueDaysCount >= minimumRequiredDays
                    if hasEnoughData {
                        analyzeData(historyModels: filteredHistoryModels, startDate: startDate, endDate: endDate)
                        compareToPreviousPeriod(currentModels: filteredHistoryModels, previousModels: previousPeriodModels)
                    } else if !filteredHistoryModels.isEmpty {
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
        let allSleepEntries = historyModels.flatMap { $0.sleepEntries ?? [] }
        var stats = SleepStatistics()
        stats.totalSleepHours = allSleepEntries.reduce(0.0) { $0 + ($1.duration / 3600.0) }

        let calendar = Calendar.current
        let daysWithData = Set(historyModels.map { calendar.startOfDay(for: $0.date) }).sorted()
        let daysWithDataCount = daysWithData.count
        stats.averageDailyHours = daysWithDataCount > 0 ? stats.totalSleepHours / Double(daysWithDataCount) : 0
        
        let totalScoreSum = allSleepEntries.reduce(0) { $0 + $1.rating }
        stats.averageSleepScore = allSleepEntries.isEmpty ? 0 : Double(totalScoreSum) / Double(allSleepEntries.count)
        
        let traditionalSleepHours = 8.0 * Double(daysWithDataCount)
        stats.timeGained = max(0, traditionalSleepHours - stats.totalSleepHours)
        stats.efficiencyPercentage = traditionalSleepHours > 0 ? ((traditionalSleepHours - stats.totalSleepHours) / traditionalSleepHours) * 100 : 0
            
        var bestDay: (date: Date, hours: Double, score: Double)?
        var worstDay: (date: Date, hours: Double, score: Double)?
        
        for dayDate in daysWithData {
            let dayEntries = allSleepEntries.filter { calendar.isDate($0.date, inSameDayAs: dayDate) }
            if dayEntries.isEmpty { continue }
            
            let dayTotalHours = dayEntries.reduce(0.0) { $0 + $1.duration / 3600.0 }
            let dayTotalScore = dayEntries.reduce(0) { $0 + $1.rating }
            let dayAverageScore = Double(dayTotalScore) / Double(dayEntries.count)
            
            if bestDay == nil || dayAverageScore > bestDay!.score {
                bestDay = (dayDate, dayTotalHours, dayAverageScore)
            }
            if worstDay == nil || dayAverageScore < worstDay!.score {
                worstDay = (dayDate, dayTotalHours, dayAverageScore)
            }
        }
        
        stats.bestDay = bestDay?.date
        stats.bestDayScore = bestDay?.score ?? 0
        stats.worstDay = worstDay?.date
        stats.worstDayScore = worstDay?.score ?? 5.0 // Default to 5 for comparison

        if daysWithDataCount > 1 {
            var sleepTimesInMinutes: [Double] = []
            for entry in allSleepEntries { // Iterate over allSleepEntries directly
                let components = calendar.dateComponents([.hour, .minute], from: entry.startTime)
                if let hour = components.hour, let minute = components.minute {
                    sleepTimesInMinutes.append(Double(hour * 60 + minute))
                }
            }
            
            if sleepTimesInMinutes.count > 1 {
                let mean = sleepTimesInMinutes.reduce(0, +) / Double(sleepTimesInMinutes.count)
                let variance = sleepTimesInMinutes.reduce(0) { $0 + pow($1 - mean, 2) } / Double(sleepTimesInMinutes.count - 1)
                let standardDeviation = sqrt(variance)
                stats.consistencyScore = max(0, 100 - min(100, standardDeviation / 60)) // SD in minutes / 60 min
                stats.variabilityScore = min(100, standardDeviation / 60)
            }
        }

        if daysWithDataCount > 2 {
            let sortedHistoryByDate = historyModels.sorted(by: { $0.date < $1.date })
            let firstHalfModels = sortedHistoryByDate.prefix(sortedHistoryByDate.count / 2)
            let secondHalfModels = sortedHistoryByDate.suffix(sortedHistoryByDate.count - sortedHistoryByDate.count / 2)
            
            let firstHalfEntries = firstHalfModels.flatMap { $0.sleepEntries ?? [] }
            let secondHalfEntries = secondHalfModels.flatMap { $0.sleepEntries ?? [] }

            let firstHalfScoreSum = firstHalfEntries.reduce(0) { $0 + $1.rating }
            let secondHalfScoreSum = secondHalfEntries.reduce(0) { $0 + $1.rating }
            
            let firstHalfAvg = !firstHalfEntries.isEmpty ? Double(firstHalfScoreSum) / Double(firstHalfEntries.count) : 0
            let secondHalfAvg = !secondHalfEntries.isEmpty ? Double(secondHalfScoreSum) / Double(secondHalfEntries.count) : 0
            
            stats.trendDirection = secondHalfAvg - firstHalfAvg
            stats.improvementRate = firstHalfAvg > 0 ? (secondHalfAvg - firstHalfAvg) / firstHalfAvg * 100 : 0
        }
        
        var qualityStats = SleepQualityStats()
        for dayDate in daysWithData {
            let dayEntries = allSleepEntries.filter { calendar.isDate($0.date, inSameDayAs: dayDate) }
            if dayEntries.isEmpty { continue }
            let dayTotalScore = dayEntries.reduce(0) { $0 + $1.rating }
            let dayAvgScore = Double(dayTotalScore) / Double(dayEntries.count)
            let category = SleepQualityCategory.fromRating(dayAvgScore)
            
            switch category {
            case .excellent: qualityStats.excellentDays += 1
            case .good: qualityStats.goodDays += 1
            case .average: qualityStats.averageDays += 1
            case .poor: qualityStats.poorDays += 1
            case .bad: qualityStats.badDays += 1
            }
        }
        
        self.totalSleepHours = stats.totalSleepHours
        self.averageDailyHours = stats.averageDailyHours
        self.averageSleepScore = stats.averageSleepScore
        self.timeGained = stats.timeGained
        self.sleepStatistics = stats
        self.sleepQualityStats = qualityStats
        self.bestSleepDay = bestDay
        self.worstSleepDay = worstDay
        
        createTrendData(fromSleepEntries: allSleepEntries, startDate: startDate, endDate: endDate)
        createBreakdownData(from: allSleepEntries, timeRangeDays: selectedTimeRange.days)
    }
    
    private func compareToPreviousPeriod(currentModels: [HistoryModel], previousModels: [HistoryModel]) {
        let currentSleepEntries = currentModels.flatMap { $0.sleepEntries ?? [] }
        let prevSleepEntries = previousModels.flatMap { $0.sleepEntries ?? [] }
        
        let currentTotalHours = currentSleepEntries.reduce(0.0) { $0 + ($1.duration / 3600.0) }
        let prevTotalHours = prevSleepEntries.reduce(0.0) { $0 + ($1.duration / 3600.0) }
        
        let currentTotalScoreSum = currentSleepEntries.reduce(0) { $0 + $1.rating }
        let prevTotalScoreSum = prevSleepEntries.reduce(0) { $0 + $1.rating }
        
        let currentAvgScore = !currentSleepEntries.isEmpty ? Double(currentTotalScoreSum) / Double(currentSleepEntries.count) : 0
        let prevAvgScore = !prevSleepEntries.isEmpty ? Double(prevTotalScoreSum) / Double(prevSleepEntries.count) : 0
        
        let hoursDiff = currentTotalHours - prevTotalHours
        let scoreDiff = currentAvgScore - prevAvgScore
        
        previousPeriodComparison = (hoursDiff, scoreDiff)
    }
    
    private func createTrendData(fromSleepEntries entries: [SleepEntry], startDate: Date, endDate: Date) {
        sleepTrendData = []
        let calendar = Calendar.current
        let maxDataPoints = selectedTimeRange.days
        
        guard let actualStartDate = calendar.date(byAdding: .day, value: -(maxDataPoints - 1), to: calendar.startOfDay(for: endDate)) else { return }

        for dayOffset in 0..<maxDataPoints {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: actualStartDate) else { continue }
            
            // Filter entries for the specific day
            let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
            
            let coreEntries = dayEntries.filter { $0.isCore }
            let napEntries = dayEntries.filter { !$0.isCore }
            
            let totalHours = dayEntries.reduce(0.0) { $0 + $1.duration / 3600.0 }
            let coreHours = coreEntries.reduce(0.0) { $0 + $1.duration / 3600.0 }
            let napHours = napEntries.reduce(0.0) { $0 + $1.duration / 3600.0 }

            let totalScoreSum = dayEntries.reduce(0) { $0 + $1.rating }
            let score = dayEntries.isEmpty ? 0.0 : Double(totalScoreSum) / Double(dayEntries.count)
            
            var sleepData = SleepTrendData(
                date: date,
                totalHours: totalHours,
                coreHours: coreHours,
                napHours: napHours,
                score: score
            )

            let sortedNaps = napEntries.sorted { $0.startTime < $1.startTime }
            sleepData.nap1Hours = (sortedNaps.first?.duration ?? 0.0) / 3600.0
            sleepData.nap2Hours = (sortedNaps.dropFirst().first?.duration ?? 0.0) / 3600.0
            
            sleepTrendData.append(sleepData)
        }
        // Ensure the trend data is sorted by date if the generation order wasn't strictly chronological
        sleepTrendData.sort(by: { $0.date < $1.date })
    }
    
    private func createBreakdownData(from entries: [SleepEntry], timeRangeDays: Int) {
        sleepBreakdownData = []
        guard timeRangeDays > 0 else { return } // Avoid division by zero
        
        let coreEntries = entries.filter { $0.isCore } // isCore direkt kullanılır
        let napEntries = entries.filter { !$0.isCore }  // isCore direkt kullanılır
        
        let coreHours = coreEntries.reduce(0.0) { $0 + ($1.duration / 3600.0) }
        let napHours = napEntries.reduce(0.0) { $0 + ($1.duration / 3600.0) }
        
        let totalHours = coreHours + napHours
        
        var coreData = SleepBreakdownData(
            type: L("analytics.sleepBreakdown.core", table: "Analytics"),
            hours: coreHours,
            percentage: totalHours > 0 ? (coreHours / totalHours) * 100 : 0,
            color: Color("AccentColor") // Design system rengi
        )
        
        var napData = SleepBreakdownData(
            type: L("analytics.sleepBreakdown.nap", table: "Analytics"),
            hours: napHours,
            percentage: totalHours > 0 ? (napHours / totalHours) * 100 : 0,
            color: Color("PrimaryColor") // Design system rengi
        )
        
        coreData.averagePerDay = coreHours / Double(timeRangeDays)
        napData.averagePerDay = napHours / Double(timeRangeDays)
        
        let uniqueCoreDays = Set(coreEntries.map { Calendar.current.startOfDay(for: $0.date) }).count // date kullanılır
        let uniqueNapDays = Set(napEntries.map { Calendar.current.startOfDay(for: $0.date) }).count // date kullanılır
        
        coreData.daysWithThisType = uniqueCoreDays
        napData.daysWithThisType = uniqueNapDays
        
        sleepBreakdownData = [coreData, napData].filter { $0.hours > 0 } // Sadece saati olanları göster
    }
}

// MARK: - Extensions

extension LocalizedStringKey {
    func toString() -> String {
        return "\(self)"
    }
}
