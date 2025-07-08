import Foundation
import SwiftUI
import WatchKit
import PolyNapShared
import Combine

// MARK: - SharedSleepEntry Extension
extension SharedSleepEntry {
    var dictionary: [String: Any] {
        return [
            "id": id.uuidString,
            "date": date.timeIntervalSince1970,
            "startTime": startTime.timeIntervalSince1970,
            "endTime": endTime.timeIntervalSince1970,
            "durationMinutes": durationMinutes,
            "isCore": isCore,
            "blockId": blockId ?? "",
            "rating": rating
        ]
    }
}

@MainActor
class WatchMainViewModel: ObservableObject {
    
    // MARK: - Published Properties for Milestone 2.1
    
    // Schedule-related properties
    @Published var currentSchedule: SharedUserSchedule?
    @Published var nextSleepTime: String?
    @Published var currentStatusMessage: String = "Program yükleniyor..."
    @Published var isLoading: Bool = false
    
    // Legacy properties (keeping for compatibility)
    @Published var currentSleepBlock: SharedSleepBlock?
    @Published var nextSleepBlock: SharedSleepBlock?
    @Published var isSleeping: Bool = false
    @Published var canRateLastSleep: Bool = false
    @Published var selectedRating: Int = 0
    
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
            timer?.invalidate()
            timer = nil
        }
    }
    
    // MARK: - Public Methods for Milestone 2.1
    
    func requestDataSync() {
        print("🔄 Requesting data sync for schedule...")
        isLoading = true
        currentStatusMessage = "Veri senkronize ediliyor..."
        
        // WatchConnectivity ile iPhone'dan veri iste
        watchConnectivity.requestSync()
        
        // Mock data ile schedule yükle (gerçek implementasyonda Repository'den gelecek)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.loadMockScheduleData()
            self?.updateCurrentStatus()
            self?.isLoading = false
        }
    }
    
    func startTracking() {
        print("🎯 Watch tracking started")
        startPeriodicUpdates()
        requestDataSync()
    }
    
    func stopTracking() {
        print("🛑 Watch tracking stopped")
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Schedule Management
    
    private func loadMockScheduleData() {
        // Mock SharedUserSchedule oluştur
        let mockSchedule = SharedUserSchedule(
            name: "Everyman 4-2",
            scheduleDescription: "Core sleep + 2 naps",
            totalSleepHours: 4.5,
            adaptationPhase: 2,
            isActive: true
        )
        
        // Mock sleep blocks oluştur
        let coreBlock = SharedSleepBlock(
            schedule: mockSchedule,
            startTime: "23:00",
            endTime: "02:30",
            durationMinutes: 210,
            isCore: true
        )
        
        let napBlock1 = SharedSleepBlock(
            schedule: mockSchedule,
            startTime: "08:00", 
            endTime: "08:20",
            durationMinutes: 20,
            isCore: false
        )
        
        let napBlock2 = SharedSleepBlock(
            schedule: mockSchedule,
            startTime: "14:00",
            endTime: "14:20", 
            durationMinutes: 20,
            isCore: false
        )
        
        mockSchedule.sleepBlocks = [coreBlock, napBlock1, napBlock2]
        
        self.currentSchedule = mockSchedule
        self.updateNextSleepTime()
        
        print("✅ Mock schedule data loaded: \(mockSchedule.name)")
    }
    
    private func updateNextSleepTime() {
        guard let schedule = currentSchedule,
              let sleepBlocks = schedule.sleepBlocks else {
            nextSleepTime = nil
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotalMinutes = currentHour * 60 + currentMinute
        
        // Bir sonraki uyku bloğunu bul
        var nextBlock: SharedSleepBlock?
        var minDifference = Int.max
        
        for block in sleepBlocks {
            if let startTime = timeComponents(from: block.startTime) {
                let blockTotalMinutes = startTime.hour * 60 + startTime.minute
                var difference = blockTotalMinutes - currentTotalMinutes
                
                // Eğer negatifse, yarın için hesapla
                if difference < 0 {
                    difference += 24 * 60
                }
                
                if difference < minDifference {
                    minDifference = difference
                    nextBlock = block
                }
            }
        }
        
        if let next = nextBlock {
            nextSleepTime = next.startTime
        } else {
            nextSleepTime = nil
        }
    }
    
    private func updateCurrentStatus() {
        guard let schedule = currentSchedule else {
            currentStatusMessage = "Program bulunamadı"
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        
        // Basit durum kontrolü
        if let sleepBlocks = schedule.sleepBlocks {
            let isInSleepTime = sleepBlocks.contains { block in
                if let startTime = timeComponents(from: block.startTime),
                   let endTime = timeComponents(from: block.endTime) {
                    
                    if startTime.hour <= endTime.hour {
                        // Aynı gün içinde
                        return currentHour >= startTime.hour && currentHour < endTime.hour
                    } else {
                        // Gece yarısını geçen
                        return currentHour >= startTime.hour || currentHour < endTime.hour
                    }
                }
                return false
            }
            
            if isInSleepTime {
                currentStatusMessage = "Şu anda uyku zamanı 😴"
            } else {
                currentStatusMessage = "Aktif dönem - uyanık kalın ☀️"
            }
        } else {
            currentStatusMessage = "Program verisi eksik"
        }
    }
    
    // MARK: - Helper Functions
    
    private func timeComponents(from timeString: String) -> (hour: Int, minute: Int)? {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return nil
        }
        return (hour, minute)
    }
    
    // MARK: - Legacy Methods (keeping for compatibility)
    
    func startSleep() {
        guard !isSleeping, let currentBlock = currentSleepBlock else {
            print("❌ Cannot start sleep: already sleeping or no current block")
            return
        }
        
        let sleepEntry = SharedSleepEntry(
            date: Date(),
            startTime: Date(),
            endTime: Date(),
            durationMinutes: 0,
            isCore: currentBlock.isCore,
            blockId: currentBlock.id.uuidString
        )
        
        currentSleepEntry = sleepEntry
        isSleeping = true
        
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
        
        currentEntry.endTime = endTime
        currentEntry.durationMinutes = Int(duration / 60)
        
        currentSleepEntry = nil
        lastSleepEntry = currentEntry
        isSleeping = false
        canRateLastSleep = true
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.stop)
        
        print("😊 Sleep ended. Duration: \(Int(duration / 60)) minutes")
        
        updateDailyStatistics()
    }
    
    func rateSleep(rating: Int) {
        guard let lastEntry = lastSleepEntry else {
            print("❌ No sleep entry to rate")
            return
        }
        
        lastEntry.rating = rating
        selectedRating = rating
        canRateLastSleep = false
        
        print("⭐ Sleep rated: \(rating) stars")
        
        updateDailyStatistics()
    }
    
    // MARK: - Private Methods
    
    private func setupWatchConnectivityObservers() {
        watchConnectivity.$isReachable
            .sink { [weak self] isReachable in
                if isReachable {
                    self?.requestDataSync()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.updateSleepBlocks()
            self?.updateDailyStatistics()
            self?.updateWeeklyStatistics()
            self?.isLoading = false
        }
    }
    
    private func startPeriodicUpdates() {
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateNextSleepTime()
                self?.updateCurrentStatus()
                self?.updateSleepBlocks()
                self?.updateDailyStatistics()
            }
        }
    }
    
    private func updateSleepBlocks() {
        // Legacy method - keeping for compatibility with old views
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
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
    }
    
    private func updateDailyStatistics() {
        todayTotalSleep = 7.5 * 3600
        todaySleepCount = 4
        todayAverageQuality = 4.2
    }
    
    private func updateWeeklyStatistics() {
        weekTotalSleep = 52.5 * 3600
        weekGoalCompletion = 0.85
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
