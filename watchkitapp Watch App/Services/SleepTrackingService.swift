import Foundation
import SwiftUI
import WatchKit
import PolyNapShared
import Combine

// MARK: - Notification Names
extension Notification.Name {
    public static let sleepDidStart = Notification.Name("sleepDidStart")
    public static let sleepDidEnd = Notification.Name("sleepDidEnd")
}

// MARK: - Sleep Tracking State
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

// MARK: - Sleep Tracking Service
@MainActor
class SleepTrackingService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var sleepTrackingState: SleepTrackingState = .idle
    @Published var currentSleepSession: SharedSleepEntry?
    @Published var lastCompletedSleep: SharedSleepEntry?
    @Published var pendingRatingEntry: SharedSleepEntry?
    @Published var sleepSessionDuration: TimeInterval = 0
    @Published var sleepSessionTimer: String = "00:00"
    @Published var estimatedWakeTime: Date?
    @Published var isProcessing: Bool = false
    
    // MARK: - Private Properties
    private var sessionTimer: Timer?
    private let watchConnectivity = WatchConnectivityManager.shared
    private let qualityEmojis = ["😩", "😪", "😐", "😊", "🤩"]
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Sync Service Integration
    private weak var syncService: SyncService?
    
    // MARK: - Initialization
    init(syncService: SyncService? = nil) {
        self.syncService = syncService
        setupObservers()
    }
    
    /// SyncService'i inject eder
    func setSyncService(_ syncService: SyncService) {
        self.syncService = syncService
    }
    
    deinit {
        Task { @MainActor in
            await MainActor.run {
                sessionTimer?.invalidate()
                sessionTimer = nil
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Uyku durumunu toggle eder
    func toggleSleepState() {
        switch sleepTrackingState {
        case .idle:
            startSleepSession()
        case .sleeping:
            endSleepSession()
        case .waitingForRating:
            // Rating mode için UI'ya bilgi ver
            break
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
            blockId: nil, // Will be set by context
            rating: 0
        )
        
        currentSleepSession = sleepEntry
        sleepTrackingState = .sleeping(startTime: startTime)
        
        // Start session timer
        startSessionTimer()
        
        // Estimate wake time
        estimateWakeTime()
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.start)
        
        // Send sleep started message
        sendSleepStartedMessage(sleepEntry)
        
        print("😴 Sleep session started at \(startTime.formatted(date: .omitted, time: .shortened))")
        
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
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.stop)
        
        print("🌅 Sleep session ended. Duration: \(Int(duration/60)) minutes")
        
        isProcessing = false
    }
    
    /// Rating'i confirm eder ve kaydeder
    func confirmSleepRating(rating: Int, emoji: String) {
        guard let entry = pendingRatingEntry else { return }
        
        isProcessing = true
        
        // Update entry with rating
        entry.rating = rating
        entry.emoji = emoji
        
        // Save entry via sync service
        saveSleepEntry(entry)
        
        // Complete the sleep tracking cycle
        sleepTrackingState = .completed(entry: entry)
        lastCompletedSleep = entry
        pendingRatingEntry = nil
        
        // Reset to idle after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.sleepTrackingState = .idle
        }
        
        print("⭐ Sleep rating confirmed: \(rating) stars")
        
        isProcessing = false
    }
    
    /// Mevcut uyku durumu mesajını döndürür
    func getCurrentStatusMessage() -> String {
        switch sleepTrackingState {
        case .idle:
            return "Sonraki uyku için hazır"
        case .preparing:
            return "Uyku hazırlanıyor..."
        case .sleeping(let startTime):
            let duration = Date().timeIntervalSince(startTime)
            let minutes = Int(duration / 60)
            return "Uyku devam ediyor (\(minutes) dakika)"
        case .awakening:
            return "Uyanma süreci..."
        case .waitingForRating:
            return "Uyku kalitesini değerlendirin"
        case .completed:
            return "Uyku tamamlandı"
        }
    }
    
    /// Rating için emoji döndürür
    func getEmojiForRating(_ rating: Int) -> String {
        let index = max(0, min(rating - 1, qualityEmojis.count - 1))
        return qualityEmojis[index]
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // WatchConnectivity observer'larını setup et
        watchConnectivity.$isReachable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isReachable in
                if isReachable {
                    self?.syncPendingData()
                }
            }
            .store(in: &cancellables)
        
        // Sleep tracking message'lerini dinle
        NotificationCenter.default.addObserver(
            forName: .sleepDidStart,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleSleepStartedNotification(notification)
        }
        
        NotificationCenter.default.addObserver(
            forName: .sleepDidEnd,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleSleepEndedNotification(notification)
        }
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
    
    // MARK: - Sync Integration
    
    private func saveSleepEntry(_ entry: SharedSleepEntry) {
        // Önce SyncService'e offline entry olarak ekle
        syncService?.addOfflineEntry(entry)
        
        // Sonra WatchConnectivity ile iPhone'a gönder
        let message = WatchMessage(
            type: .sleepEnded,
            data: entry.dictionary
        )
        watchConnectivity.sendMessage(message)
        
        print("💾 Sleep entry saved: \(entry.rating) stars, \(entry.durationMinutes) minutes")
    }
    
    private func sendSleepStartedMessage(_ entry: SharedSleepEntry) {
        let message = WatchMessage(
            type: .sleepStarted,
            data: entry.dictionary
        )
        watchConnectivity.sendMessage(message)
        
        print("📤 Sleep started message sent")
    }
    
    private func syncPendingData() {
        // Bağlantı kurulduğunda pending data'yı sync et
        if let syncService = syncService, syncService.hasPendingSync {
            syncService.syncOfflineEntries()
        }
    }
    
    // MARK: - Notification Handlers
    
    private func handleSleepStartedNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        print("📩 Sleep started notification received: \(userInfo)")
        
        // Remote sleep start notification handling
        // Bu durumda başka bir device'dan gelen sleep start'ı handle edebiliriz
    }
    
    private func handleSleepEndedNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        print("📩 Sleep ended notification received: \(userInfo)")
        
        // Remote sleep end notification handling
        // Bu durumda başka bir device'dan gelen sleep end'i handle edebiliriz
    }
}

// MARK: - Extensions
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
            "rating": rating,
            "emoji": emoji ?? ""
        ]
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
