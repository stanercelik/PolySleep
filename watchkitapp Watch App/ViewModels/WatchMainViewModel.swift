import Foundation
import SwiftUI
import SwiftData
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

// MARK: - Sleep Tracking State Enum
public enum SleepTrackingState: Equatable {
    case idle
    case preparing
    case sleeping(startTime: Date)
    case awakening
    case completed(entry: SharedSleepEntry)
    case waitingForRating(entry: SharedSleepEntry)
    
    public var isSleeping: Bool {
        if case .sleeping = self {
            return true
        }
        return false
    }
    
    public var canRate: Bool {
        if case .waitingForRating = self {
            return true
        }
        return false
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
    
    // MARK: - Milestone 2.2: Enhanced Sleep Tracking State
    
    // Core sleep tracking state
    @Published var sleepTrackingState: SleepTrackingState = .idle
    @Published var currentSleepSession: SharedSleepEntry?
    @Published var lastCompletedSleep: SharedSleepEntry?
    @Published var pendingRatingEntry: SharedSleepEntry?
    
    // Sleep quality rating system
    @Published var selectedQualityRating: Int = 3
    @Published var selectedEmoji: String = "😴"
    @Published var isRatingMode: Bool = false
    @Published var qualityEmojis: [String] = ["😩", "😪", "😐", "😊", "🤩"]
    @Published var currentRating: Int = 0
    @Published var isProcessing: Bool = false
    
    // Real-time sync state
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncTime: Date?
    @Published var hasPendingSync: Bool = false
    @Published var offlineEntries: [SharedSleepEntry] = []
    
    // Enhanced sleep stats
    @Published var sleepSessionDuration: TimeInterval = 0
    @Published var sleepSessionTimer: String = "00:00"
    @Published var estimatedWakeTime: Date?
    @Published var sleepEfficiency: Double = 0.0
    
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
    private let sharedRepository = SharedRepository.shared
    private var currentSleepEntry: SharedSleepEntry?
    private var lastSleepEntry: SharedSleepEntry?
    private var timer: Timer?
    private var sessionTimer: Timer?
    private var modelContext: ModelContext?
    
    // MARK: - Sync Status Enum
    public enum SyncStatus: Equatable {
        case idle
        case syncing
        case success(Date)
        case failed(String)
        case offline
        
        var color: Color {
            switch self {
            case .idle: return .gray
            case .syncing: return .blue
            case .success: return .green
            case .failed: return .red
            case .offline: return .orange
            }
        }
        
        var message: String {
            switch self {
            case .idle: return "Bekleniyor"
            case .syncing: return "Senkronize ediliyor"
            case .success(let date): return "Senkronize edildi \(date.formatted(date: .omitted, time: .shortened))"
            case .failed(let error): return "Hata: \(error)"
            case .offline: return "Çevrimdışı"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupWatchConnectivityObservers()
        loadInitialData()
        setupSleepTrackingObservers()
    }
    
    deinit {
        let currentTimer = timer
        let currentSessionTimer = sessionTimer
        
        Task { @MainActor in
            currentTimer?.invalidate()
            currentSessionTimer?.invalidate()
        }
        
        timer = nil
        sessionTimer = nil
    }
    
    // MARK: - Configuration Methods
    
    func configureSharedRepository(with modelContext: ModelContext) {
        self.modelContext = modelContext
        print("✅ WatchMainViewModel: SharedRepository configured")
    }
    
    func loadMockData() {
        // Fallback mock data
        let mockSchedule = SharedUserSchedule(
            id: UUID(),
            user: nil,
            name: "Biphasic Schedule",
            scheduleDescription: "2 saatlik uyku blokları",
            totalSleepHours: 6.0,
            adaptationPhase: 2,
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true
        )
        
        currentSchedule = mockSchedule
        nextSleepTime = "22:00"
        currentStatusMessage = "Mock data yüklendi"
        
        print("📱 Mock data loaded for Watch")
    }
    
    // MARK: - Milestone 2.2: Enhanced Sleep Tracking Methods
    
    /// Uyku durumunu toggle eder
    func toggleSleepState() {
        switch sleepTrackingState {
        case .idle:
            startSleepSession()
        case .sleeping:
            endSleepSession()
        case .waitingForRating:
            // Rating mode'a geç
            isRatingMode = true
        default:
            break
        }
    }
    
    /// Uyku oturumunu başlatır
    func startSleepSession() {
        guard sleepTrackingState == .idle else {
            print("❌ Cannot start sleep: already in tracking state")
            return
        }
        
        isProcessing = true
        let startTime = Date()
        
        // Determine if this is a core sleep or nap
        let isCore = determineIfCoreSleep(at: startTime)
        
        // Create new sleep entry
        let sleepEntry = SharedSleepEntry(
            date: startTime,
            startTime: startTime,
            endTime: startTime, // Will be updated when ended
            durationMinutes: 0,
            isCore: isCore,
            blockId: currentSleepBlock?.id.uuidString,
            rating: 0
        )
        
        currentSleepSession = sleepEntry
        sleepTrackingState = .sleeping(startTime: startTime)
        
        // Update legacy compatibility
        isSleeping = true
        
        // Start session timer
        startSessionTimer()
        
        // Estimate wake time
        estimateWakeTime()
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.start)
        
        print("😴 Sleep session started at \(startTime.formatted(date: .omitted, time: .shortened))")
        
        // Update current status
        updateCurrentStatus()
        
        isProcessing = false
    }
    
    /// Uyku oturumunu sonlandırır
    func endSleepSession() {
        guard case .sleeping(let startTime) = sleepTrackingState,
              let session = currentSleepSession else {
            print("❌ Cannot end sleep: not in sleeping state")
            return
        }
        
        isProcessing = true
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Update sleep entry
        session.endTime = endTime
        session.durationMinutes = Int(duration / 60)
        
        // Stop session timer
        stopSessionTimer()
        
        // Transition to rating mode
        sleepTrackingState = .waitingForRating(entry: session)
        pendingRatingEntry = session
        isRatingMode = true
        
        // Update legacy compatibility
        isSleeping = false
        canRateLastSleep = true
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.stop)
        
        print("🌅 Sleep session ended. Duration: \(Int(duration/60)) minutes")
        
        // Update current status
        updateCurrentStatus()
        
        isProcessing = false
    }
    
    /// Uyku kalitesi rating'ini ayarlar
    func setSleepRating(_ rating: Int) {
        currentRating = rating
        
        let emojis = ["😩", "😪", "😐", "😊", "🤩"]
        let index = max(0, min(rating - 1, emojis.count - 1))
        selectedEmoji = emojis[index]
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.click)
    }
    
    /// Rating'i confirm eder ve kaydet
    func confirmSleepRating() {
        guard let entry = pendingRatingEntry else { return }
        
        isProcessing = true
        
        // Update entry with rating
        entry.rating = currentRating
        entry.emoji = selectedEmoji
        
        // Save entry
        saveSleepEntry(entry)
        
        // Complete the sleep tracking cycle
        sleepTrackingState = .completed(entry: entry)
        lastCompletedSleep = entry
        isRatingMode = false
        currentRating = 0
        pendingRatingEntry = nil
        
        // Update legacy compatibility
        canRateLastSleep = false
        
        // Reset to idle after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.sleepTrackingState = .idle
            self?.updateCurrentStatus()
        }
        
        print("⭐ Sleep rating confirmed: \(currentRating) stars")
        
        isProcessing = false
    }
    
    // MARK: - Data Sync Methods
    
    func requestDataSync() {
        syncStatus = .syncing
        
        // Request data from iPhone
        watchConnectivity.requestSync()
        
        // Simulate sync delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.syncStatus = .success(Date())
            self?.lastSyncTime = Date()
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func setupWatchConnectivityObservers() {
        watchConnectivity.$isReachable
            .sink { [weak self] isReachable in
                if isReachable {
                    self?.requestDataSync()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupSleepTrackingObservers() {
        // Observer for sleep tracking state changes
        $sleepTrackingState
            .sink { [weak self] state in
                self?.updateCurrentStatus()
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        // Load initial data from repository or mock
        loadMockData()
    }
    
    private func determineIfCoreSleep(at date: Date) -> Bool {
        // Simple heuristic: if it's between 21:00 and 06:00, it's likely core sleep
        let hour = Calendar.current.component(.hour, from: date)
        return hour >= 21 || hour <= 6
    }
    
    private func startSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateSleepSessionTimer()
            }
        }
    }
    
    private func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }
    
    private func updateSleepSessionTimer() {
        guard case .sleeping(let startTime) = sleepTrackingState else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        sleepSessionDuration = duration
        
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            sleepSessionTimer = String(format: "%d:%02d", hours, minutes)
        } else {
            sleepSessionTimer = String(format: "%02d:%02d", minutes, Int(duration) % 60)
        }
    }
    
    private func estimateWakeTime() {
        // Estimate wake time based on current sleep block or default duration
        let defaultDuration: TimeInterval = 90 * 60 // 90 minutes
        estimatedWakeTime = Date().addingTimeInterval(defaultDuration)
    }
    
    private func updateCurrentStatus() {
        switch sleepTrackingState {
        case .idle:
            currentStatusMessage = "Sonraki uyku için hazır"
        case .preparing:
            currentStatusMessage = "Uyku hazırlanıyor..."
        case .sleeping(let startTime):
            let duration = Date().timeIntervalSince(startTime)
            let minutes = Int(duration / 60)
            currentStatusMessage = "Uyku devam ediyor (\(minutes) dakika)"
        case .awakening:
            currentStatusMessage = "Uyanma süreci..."
        case .waitingForRating:
            currentStatusMessage = "Uyku kalitesini değerlendirin"
        case .completed:
            currentStatusMessage = "Uyku tamamlandı"
        }
    }
    
    private func saveSleepEntry(_ entry: SharedSleepEntry) {
        // Save to repository
        // For now, just send to iPhone
        let message = WatchMessage(
            type: .sleepEnded,
            data: entry.dictionary
        )
        watchConnectivity.sendMessage(message)
        
        print("💾 Sleep entry saved: \(entry.rating) stars, \(entry.durationMinutes) minutes")
    }
}

// MARK: - WatchMessage Helper

struct WatchMessage {
    let type: WatchMessageType
    let data: [String: Any]
}

enum WatchMessageType: String, CaseIterable {
    case sleepStarted = "sleepStarted"
    case sleepEnded = "sleepEnded"
    case qualityRated = "qualityRated"
    case syncRequest = "syncRequest"
    case scheduleUpdate = "scheduleUpdate"
} 