import Foundation
import SwiftUI
import PolyNapShared
import Combine

// MARK: - Sleep Statistics Service
@MainActor
class SleepStatisticsService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var todayTotalSleep: TimeInterval = 0
    @Published var todaySleepCount: Int = 0
    @Published var todayAverageQuality: Double = 0.0
    @Published var weekTotalSleep: TimeInterval = 0
    @Published var weekGoalCompletion: Double = 0.0
    @Published var sleepEfficiency: Double = 0.0
    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0
    
    // MARK: - Private Properties
    private let sharedRepository = SharedRepository.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupObservers()
        calculateStatistics()
    }
    
    // MARK: - Public Methods
    
    /// İstatistikleri yeniden hesaplar
    func calculateStatistics() {
        calculateTodayStatistics()
        calculateWeekStatistics()
        calculateSleepEfficiency()
        calculateStreaks()
    }
    
    /// Bugünkü toplam uyku süresini döndürür (formatlanmış)
    func getTodayTotalSleepFormatted() -> String {
        return formatDuration(todayTotalSleep)
    }
    
    /// Haftalık toplam uyku süresini döndürür (formatlanmış)
    func getWeekTotalSleepFormatted() -> String {
        return formatDuration(weekTotalSleep)
    }
    
    /// Uyku efficiency'sini yüzde olarak döndürür
    func getSleepEfficiencyFormatted() -> String {
        return String(format: "%.1f%%", sleepEfficiency * 100)
    }
    
    /// Ortalama uyku kalitesini döndürür
    func getAverageQualityFormatted() -> String {
        return String(format: "%.1f/5", todayAverageQuality)
    }
    
    /// Yeni sleep entry eklendiğinde çağrılır
    func addSleepEntry(_ entry: SharedSleepEntry) {
        // İstatistikleri yeniden hesapla
        calculateStatistics()
        
        print("📊 Statistics updated with new entry: \(entry.durationMinutes) minutes")
    }
    
    /// Belirli bir tarih için sleep entries'i getir
    func getSleepEntriesForDate(_ date: Date) -> [SharedSleepEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let _ = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        // SharedRepository'den entries'i al
        // Şimdilik mock data döndür
        return getMockSleepEntriesForDate(date)
    }
    
    /// Haftalık goal progress'ini hesaplar
    func calculateWeekGoalProgress(targetHours: Double) -> Double {
        let weekTotalHours = weekTotalSleep / 3600
        let weekTargetHours = targetHours * 7
        return min(weekTotalHours / weekTargetHours, 1.0)
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Schedule değişikliklerini observe et
        // Gerçek implementasyonda SharedRepository observers olacak
    }
    
    private func calculateTodayStatistics() {
        let today = Date()
        let todayEntries = getSleepEntriesForDate(today)
        
        // Toplam uyku süresi
        todayTotalSleep = todayEntries.reduce(0) { total, entry in
            total + TimeInterval(entry.durationMinutes * 60)
        }
        
        // Uyku sayısı
        todaySleepCount = todayEntries.count
        
        // Ortalama kalite
        if !todayEntries.isEmpty {
            let totalQuality = todayEntries.reduce(0) { total, entry in
                total + entry.rating
            }
            todayAverageQuality = Double(totalQuality) / Double(todayEntries.count)
        } else {
            todayAverageQuality = 0.0
        }
        
        print("📊 Today: \(formatDuration(todayTotalSleep)), \(todaySleepCount) sleeps, \(todayAverageQuality) avg quality")
    }
    
    private func calculateWeekStatistics() {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        var weekTotal: TimeInterval = 0
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: weekStart) {
                let dayEntries = getSleepEntriesForDate(date)
                weekTotal += dayEntries.reduce(0) { total, entry in
                    total + TimeInterval(entry.durationMinutes * 60)
                }
            }
        }
        
        weekTotalSleep = weekTotal
        
        print("📊 Week total: \(formatDuration(weekTotalSleep))")
    }
    
    private func calculateSleepEfficiency() {
        let today = Date()
        let todayEntries = getSleepEntriesForDate(today)
        
        guard !todayEntries.isEmpty else {
            sleepEfficiency = 0.0
            return
        }
        
        // Basit efficiency hesaplaması: gerçek uyku süresi / planlanan uyku süresi
        let totalActualSleep = todayEntries.reduce(0) { total, entry in
            total + TimeInterval(entry.durationMinutes * 60)
        }
        
        // Ideal olarak 4.5 saat (16200 saniye) hedefliyoruz
        let idealSleep: TimeInterval = 4.5 * 3600
        sleepEfficiency = min(totalActualSleep / idealSleep, 1.0)
        
        print("📊 Sleep efficiency: \(getSleepEfficiencyFormatted())")
    }
    
    private func calculateStreaks() {
        // Streak hesaplaması için son 30 günün verilerini kontrol et
        let calendar = Calendar.current
        let today = Date()
        
        var currentStreakCount = 0
        var bestStreakCount = 0
        var tempStreakCount = 0
        
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let dayEntries = getSleepEntriesForDate(date)
                let dayTotalSleep = dayEntries.reduce(0) { total, entry in
                    total + TimeInterval(entry.durationMinutes * 60)
                }
                
                // Günde en az 3 saat uyku varsa streak devam ediyor
                if dayTotalSleep >= 3 * 3600 {
                    if i == 0 {
                        currentStreakCount += 1
                    }
                    tempStreakCount += 1
                } else {
                    if tempStreakCount > bestStreakCount {
                        bestStreakCount = tempStreakCount
                    }
                    tempStreakCount = 0
                    
                    if i == 0 {
                        currentStreakCount = 0
                    }
                }
            }
        }
        
        currentStreak = currentStreakCount
        bestStreak = max(bestStreakCount, tempStreakCount)
        
        print("📊 Current streak: \(currentStreak) days, Best: \(bestStreak) days")
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return String(format: "%ds %02ddak", hours, minutes)
        } else {
            return String(format: "%ddak", minutes)
        }
    }
    
    private func getMockSleepEntriesForDate(_ date: Date) -> [SharedSleepEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: date)
        
        // Sadece bugün için mock data döndür
        guard targetDate == today else {
            return []
        }
        
        // Mock sleep entries
        return [
            SharedSleepEntry(
                date: date,
                startTime: calendar.date(byAdding: .hour, value: -6, to: date) ?? date,
                endTime: calendar.date(byAdding: .hour, value: -2, to: date) ?? date,
                durationMinutes: 240,
                isCore: true,
                blockId: "core-sleep",
                rating: 4
            ),
            SharedSleepEntry(
                date: date,
                startTime: calendar.date(byAdding: .hour, value: -10, to: date) ?? date,
                endTime: calendar.date(byAdding: .hour, value: -9, to: date) ?? date,
                durationMinutes: 30,
                isCore: false,
                blockId: "nap-1",
                rating: 3
            )
        ]
    }
}

// MARK: - Extensions
extension SleepStatisticsService {
    
    /// Günlük goal için progress döndürür
    var todayGoalProgress: Double {
        let targetHours: Double = 4.5
        let actualHours = todayTotalSleep / 3600
        return min(actualHours / targetHours, 1.0)
    }
    
    /// Haftalık goal için progress döndürür
    var weekGoalProgress: Double {
        let targetHours: Double = 4.5 * 7
        let actualHours = weekTotalSleep / 3600
        return min(actualHours / targetHours, 1.0)
    }
    
    /// Bugünkü performans summary'si
    var todayPerformanceSummary: String {
        let sleepText = todaySleepCount == 1 ? "uyku" : "uyku"
        return "\(todaySleepCount) \(sleepText), \(getTodayTotalSleepFormatted())"
    }
    
    /// Haftalık performans summary'si
    var weekPerformanceSummary: String {
        let progress = weekGoalProgress * 100
        return "\(getWeekTotalSleepFormatted()) (%.0f%% hedef)".replacingOccurrences(of: "%.0f", with: String(format: "%.0f", progress))
    }
} 