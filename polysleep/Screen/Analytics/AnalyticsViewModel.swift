import Foundation
import SwiftUI
import SwiftData
import Charts

enum TimeRange: String, CaseIterable, Identifiable {
    case Week = "week"
    case Month = "month"
    case Quarter = "quarter"
    case Custom = "custom"
    
    var id: String { self.rawValue }
}

class AnalyticsViewModel: ObservableObject {
    @Published var selectedTimeRange: TimeRange = .Week
    @Published var isLoading: Bool = false
    @Published var hasEnoughData: Bool = false
    
    // Analiz verileri
    @Published var totalSleepHours: Double = 0.0
    @Published var averageDailyHours: Double = 0.0
    @Published var averageSleepScore: Double = 0.0
    @Published var timeGained: Double = 0.0
    
    // Grafik verileri
    @Published var sleepTrendData: [SleepTrendData] = []
    @Published var sleepBreakdownData: [SleepBreakdownData] = []
    
    private var modelContext: ModelContext?
    private let minimumRequiredDays = 3
    
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
        
        // SwiftData'dan verileri çek
        do {
            let descriptor = FetchDescriptor<HistoryModel>(sortBy: [SortDescriptor(\.date, order: .forward)])
            let historyModels = try modelContext.fetch(descriptor)
            
            // Tarih aralığını belirle
            let endDate = Date()
            let startDate: Date
            
            switch selectedTimeRange {
            case .Week:
                startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
            case .Month:
                startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)!
            case .Quarter:
                startDate = Calendar.current.date(byAdding: .month, value: -3, to: endDate)!
            case .Custom:
                startDate = Calendar.current.date(byAdding: .month, value: -6, to: endDate)!
            }
            
            // Tarih aralığındaki verileri filtrele
            let filteredHistoryModels = historyModels.filter { historyModel in
                return historyModel.date >= startDate && historyModel.date <= endDate
            }
            
            // Yeterli veri var mı kontrol et
            let uniqueDays = Set(filteredHistoryModels.map { Calendar.current.startOfDay(for: $0.date) })
            
            hasEnoughData = uniqueDays.count >= minimumRequiredDays
            
            if hasEnoughData {
                // Yeterli veri varsa analiz et
                analyzeData(historyModels: filteredHistoryModels, startDate: startDate, endDate: endDate)
            }
            
            isLoading = false
            
        } catch {
            print("Veri yüklenirken hata oluştu: \(error)")
            isLoading = false
            hasEnoughData = false
        }
    }
    
    private func analyzeData(historyModels: [HistoryModel], startDate: Date, endDate: Date) {
        // Tüm uyku kayıtları
        let allSleepEntries = historyModels.flatMap { $0.sleepEntries }
        
        // Veri olan günler
        let calendar = Calendar.current
        let daysWithData = Set(historyModels.map { calendar.startOfDay(for: $0.date) })
        let daysWithDataCount = daysWithData.count
        
        // Toplam uyku saati
        totalSleepHours = allSleepEntries.reduce(0.0) { result, entry in
            return result + (entry.duration / 3600.0)
        }
        
        // Günlük ortalama uyku saati (sadece veri olan günler için)
        averageDailyHours = daysWithDataCount > 0 ? totalSleepHours / Double(daysWithDataCount) : 0
        
        // Ortalama uyku skoru
        let totalScore = allSleepEntries.reduce(0) { result, entry in
            return result + entry.rating
        }
        averageSleepScore = allSleepEntries.isEmpty ? 0 : Double(totalScore) / Double(allSleepEntries.count)
        
        // Kazanılan zaman (8 saatlik geleneksel uyku düzenine göre, sadece veri olan günler için)
        let traditionalSleepHours = 8.0 * Double(daysWithDataCount)
        timeGained = traditionalSleepHours - totalSleepHours
        timeGained = max(0, timeGained)
        
        createTrendData(from: historyModels, startDate: startDate, endDate: endDate)
        
        createBreakdownData(from: allSleepEntries)
    }
    
    private func createTrendData(from historyModels: [HistoryModel], startDate: Date, endDate: Date) {
        sleepTrendData = []
        let calendar = Calendar.current
        
        // Seçilen zaman aralığına göre gösterilecek veri sayısını belirle
        let maxDataPoints: Int
        let dateComponent: Calendar.Component
        
        switch selectedTimeRange {
        case .Week:
            maxDataPoints = 7
            dateComponent = .day
        case .Month:
            maxDataPoints = 30
            dateComponent = .day
        case .Quarter:
            maxDataPoints = 90
            dateComponent = .day
        case .Custom:
            maxDataPoints = 180
            dateComponent = .day
        }
        
        // Veri noktalarını oluştur
        let dayCount = calendar.dateComponents([dateComponent], from: startDate, to: endDate).value(for: dateComponent) ?? maxDataPoints
        let dataPointCount = min(dayCount, maxDataPoints)
        
        for dayOffset in 0..<dataPointCount {
            if let date = calendar.date(byAdding: dateComponent, value: dayOffset, to: startDate) {
                let dayStart = calendar.startOfDay(for: date)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                
                let dayEntries = historyModels
                    .filter { $0.date >= dayStart && $0.date < dayEnd }
                    .flatMap { $0.sleepEntries }
                
                let coreEntries = dayEntries.filter { $0.type == .core }
                let napEntries = dayEntries.filter { $0.type == .powerNap }
                
                let totalHours = dayEntries.reduce(0.0) { $0 + $1.duration / 3600.0 }
                let coreHours = coreEntries.reduce(0.0) { $0 + $1.duration / 3600.0 }
                
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
                
                let totalScore = dayEntries.reduce(0) { result, entry in
                    return result + entry.rating
                }
                let score = dayEntries.isEmpty ? 0.0 : Double(totalScore) / Double(dayEntries.count)
                
                let sleepData = SleepTrendData(
                    date: date,
                    totalHours: totalHours,
                    coreHours: coreHours,
                    nap1Hours: nap1Hours,
                    nap2Hours: nap2Hours,
                    score: score
                )
                sleepTrendData.append(sleepData)
            }
        }
    }
    
    private func createBreakdownData(from entries: [SleepEntry]) {
        sleepBreakdownData = []
        
        let coreEntries = entries.filter { $0.type == .core }
        let napEntries = entries.filter { $0.type == .powerNap }
        
        let coreHours = coreEntries.reduce(0.0) { $0 + ($1.duration / 3600.0) }
        let napHours = napEntries.reduce(0.0) { $0 + ($1.duration / 3600.0) }
        
        let totalHours = coreHours + napHours
        
        sleepBreakdownData.append(SleepBreakdownData(
            type: NSLocalizedString("analytics.sleepBreakdown.core", tableName: "Analytics", comment: "Core sleep type"),
            hours: coreHours,
            percentage: totalHours > 0 ? (coreHours / totalHours) * 100 : 0,
            color: Color("AccentColor")
        ))
        
        sleepBreakdownData.append(SleepBreakdownData(
            type: NSLocalizedString("analytics.sleepBreakdown.nap", tableName: "Analytics", comment: "Nap sleep type"),
            hours: napHours,
            percentage: totalHours > 0 ? (napHours / totalHours) * 100 : 0,
            color: Color("PrimaryColor")
        ))
    }
}

// MARK: - Data Models

struct SleepTrendData: Identifiable {
    let id = UUID()
    let date: Date
    let totalHours: Double
    let coreHours: Double
    let nap1Hours: Double
    let nap2Hours: Double
    let score: Double
}

struct SleepBreakdownData: Identifiable {
    let id = UUID()
    let type: String
    let hours: Double
    let percentage: Double
    let color: Color
}

// MARK: - Extensions

extension LocalizedStringKey {
    func toString() -> String {
        return "\(self)"
    }
}
