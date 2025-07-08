import Foundation
import SwiftUI
import WatchKit
import PolyNapShared
import Combine

@MainActor
class WatchMainViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentSleepBlock: SharedSleepBlock?
    @Published var nextSleepBlock: SharedSleepBlock?
    @Published var isSleeping: Bool = false
    @Published var canRateLastSleep: Bool = false
    @Published var selectedRating: Int = 0
    @Published var isLoading: Bool = false
    
    // Daily Statistics
    @Published var todayTotalSleep: TimeInterval = 0
    @Published var todaySleepCount: Int = 0
    @Published var todayAverageQuality: Double = 0.0
    
    // Weekly Statistics  
    @Published var weekTotalSleep: TimeInterval = 0
    @Published var weekGoalCompletion: Double = 0.0
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let watchConnectivity = WatchConnectivityManager.shared
    private var currentSleepEntry: SharedSleepEntry?
    private var lastSleepEntry: SharedSleepEntry?
    private var timer: Timer?
    
    // MARK: - Initialization
    
    init() {
        setupWatchConnectivityObservers()
        loadInitialData()
    }
    
    deinit {
        Task { @MainActor in
            stopTracking()
        }
    }
    
    // MARK: - Public Methods
    
    func startTracking() {
        print("🎯 Watch tracking started")
        startPeriodicUpdates()
        requestSyncFromPhone()
    }
    
    func stopTracking() {
        print("🛑 Watch tracking stopped")
        timer?.invalidate()
        timer = nil
    }
    
    func startSleep() {
        guard !isSleeping, let currentBlock = currentSleepBlock else {
            print("❌ Cannot start sleep: already sleeping or no current block")
            return
        }
        
        let sleepEntry = SharedSleepEntry(
            date: Date(),
            startTime: Date(),
            endTime: Date(), // Will be updated when sleep ends
            durationMinutes: 0, // Will be calculated when sleep ends
            isCore: currentBlock.isCore,
            blockId: currentBlock.id.uuidString
        )
        
        currentSleepEntry = sleepEntry
        isSleeping = true
        
        // iPhone'a bildir
        watchConnectivity.notifySleepStarted(sleepEntry: sleepEntry)
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.start)
        
        print("😴 Sleep started for block: \(currentBlock.id)")
    }
    
    func endSleep() {
        guard isSleeping, let currentEntry = currentSleepEntry else {
            print("❌ Cannot end sleep: not sleeping")
            return
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(currentEntry.startTime)
        
        var sleepEntry = currentEntry
        sleepEntry.endTime = endTime
        sleepEntry.durationMinutes = Int(duration / 60)
        
        currentSleepEntry = nil
        lastSleepEntry = sleepEntry
        isSleeping = false
        canRateLastSleep = true
        
        // iPhone'a bildir
        watchConnectivity.notifySleepEnded(sleepEntry: sleepEntry)
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.stop)
        
        print("😊 Sleep ended. Duration: \(Int(duration / 60)) minutes")
        
        // Statistics'i güncelle
        updateDailyStatistics()
    }
    
    func rateSleep(rating: Int) {
        guard let lastEntry = lastSleepEntry else {
            print("❌ No sleep entry to rate")
            return
        }
        
        var sleepEntry = lastEntry
        sleepEntry.rating = rating
        selectedRating = rating
        canRateLastSleep = false
        lastSleepEntry = sleepEntry
        
        // iPhone'a bildir
        let message = WatchMessage(type: .qualityRated, data: [
            "id": sleepEntry.id.uuidString,
            "rating": rating
        ])
        watchConnectivity.sendMessage(message)
        
        print("⭐ Sleep rated: \(rating) stars")
        
        // Statistics'i güncelle
        updateDailyStatistics()
    }
    
    // MARK: - Private Methods
    
    private func setupWatchConnectivityObservers() {
        // WatchConnectivity durumunu izle
        watchConnectivity.$isReachable
            .sink { [weak self] isReachable in
                if isReachable {
                    self?.requestSyncFromPhone()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        isLoading = true
        
        // Simulated data loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.updateSleepBlocks()
            self.updateDailyStatistics()
            self.updateWeeklyStatistics()
            self.isLoading = false
        }
    }
    
    private func startPeriodicUpdates() {
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateSleepBlocks()
                self?.updateDailyStatistics()
            }
        }
    }
    
    private func requestSyncFromPhone() {
        watchConnectivity.requestSync()
    }
    
    private func updateSleepBlocks() {
        // Bu method gerçek implementasyonda SharedRepository'den veri çekecek
        // Şimdilik mock data kullanıyoruz
        
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        // Mock current sleep block
        if hour >= 23 || hour <= 6 {
            currentSleepBlock = SharedSleepBlock(
                startTime: "23:00",
                endTime: "06:00",
                durationMinutes: 420,
                isCore: true
            )
        } else if hour >= 14 && hour <= 15 {
            currentSleepBlock = SharedSleepBlock(
                startTime: "14:00",
                endTime: "14:30",
                durationMinutes: 30,
                isCore: false
            )
        } else {
            currentSleepBlock = nil
        }
        
        // Mock next sleep block
        if hour < 14 {
            nextSleepBlock = SharedSleepBlock(
                startTime: "14:00",
                endTime: "14:30", 
                durationMinutes: 30,
                isCore: false
            )
        } else if hour < 23 {
            nextSleepBlock = SharedSleepBlock(
                startTime: "23:00",
                endTime: "06:00",
                durationMinutes: 420,
                isCore: true
            )
        } else {
            nextSleepBlock = nil
        }
        
        print("🔄 Sleep blocks updated - Current: \(currentSleepBlock?.startTime ?? "none"), Next: \(nextSleepBlock?.startTime ?? "none")")
    }
    
    private func updateDailyStatistics() {
        // Bu method gerçek implementasyonda SharedRepository'den veri çekecek
        // Şimdilik mock data
        
        todayTotalSleep = 7.5 * 3600 // 7.5 hours in seconds
        todaySleepCount = 4
        todayAverageQuality = 4.2
        
        print("📊 Daily statistics updated")
    }
    
    private func updateWeeklyStatistics() {
        // Bu method gerçek implementasyonda SharedRepository'den veri çekecek
        // Şimdilik mock data
        
        weekTotalSleep = 52.5 * 3600 // 52.5 hours in seconds
        weekGoalCompletion = 0.85 // 85%
        
        print("📈 Weekly statistics updated")
    }
}

// MARK: - Mock Data Extensions

extension WatchMainViewModel {
    func loadMockData() {
        currentSleepBlock = SharedSleepBlock(
            startTime: "23:00",
            endTime: "06:00",
            durationMinutes: 420,
            isCore: true
        )
        
        nextSleepBlock = SharedSleepBlock(
            startTime: "14:00",
            endTime: "14:30",
            durationMinutes: 30,
            isCore: false
        )
        
        todayTotalSleep = 7.5 * 3600
        todaySleepCount = 4
        todayAverageQuality = 4.2
        weekTotalSleep = 52.5 * 3600
        weekGoalCompletion = 0.85
    }
} 