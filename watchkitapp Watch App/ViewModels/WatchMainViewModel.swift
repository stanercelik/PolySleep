import Foundation
import SwiftUI
import SwiftData
import WatchKit
import PolyNapShared
import Combine

// MARK: - Refactored WatchMainViewModel
@MainActor
class WatchMainViewModel: ObservableObject {
    
    // MARK: - Published Properties for UI
    @Published var currentSchedule: SharedUserSchedule?
    @Published var nextSleepBlock: SharedSleepBlock?
    @Published var currentStatusMessage: String = L("schedule_loading", tableName: "ViewModels")
    @Published var isLoading: Bool = true
    @Published var currentTime: Date = Date()
    @Published var timeUntilNextSleep: String = ""
    
    // MARK: - Computed Properties for UI
    
    /// Schedule name for UI display
    var scheduleName: String {
        currentSchedule?.name ?? ""
    }
    
    /// Formatted total sleep hours for UI display
    var totalSleepHours: String {
        guard let schedule = currentSchedule else { return "" }
        return String(format: "%.1f sa", schedule.totalSleepHours ?? 0.0)
    }
    
    // MARK: - Service Dependencies
    public let sleepTrackingService = SleepTrackingService()
    public let syncService = SyncService()
    public let statisticsService = SleepStatisticsService()
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var sharedRepository: SharedRepository?
    
    // MARK: - Initialization
    init() {
        setupServiceObservers()
        setupWatchConnectivityListeners()
        
        // Start a timer for real-time UI updates (like the clock hand)
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.currentTime = Date()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Requests data synchronization from iOS app
    public func requestDataSync() {
        syncService.requestDataSync()
    }
    
    // MARK: - Configuration
    func configureSharedRepository(with modelContext: ModelContext) {
        self.sharedRepository = SharedRepository.shared
        if self.sharedRepository?.getModelContext() == nil {
            self.sharedRepository?.setModelContext(modelContext)
            print("✅ WatchMainViewModel: ModelContext configured")
        }
        
        Task {
            await loadActiveSchedule()
        }
    }
    
    // MARK: - Data Loading
    private func loadActiveSchedule() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let repository = sharedRepository, repository.getModelContext() != nil else {
            print("⚠️ SharedRepository not ready. Waiting for sync.")
            currentStatusMessage = L("waiting_for_connection", tableName: "ViewModels")
            syncService.requestDataSync()
            return
        }
        
        do {
            if let activeSchedule = try repository.getActiveSchedule() {
                self.currentSchedule = activeSchedule
                print("✅ Watch: Active schedule loaded: \(activeSchedule.name)")
                updateUI(with: activeSchedule)
            } else {
                print("⚠️ No active schedule found. Requesting full sync from iOS.")
                currentStatusMessage = L("synchronizing", tableName: "ViewModels")
                WatchConnectivityManager.shared.requestFullDataSync()
            }
        } catch {
            print("❌ Watch: Error loading schedule: \(error.localizedDescription)")
            currentStatusMessage = L("loading_error", tableName: "ViewModels")
        }
    }
    
    // MARK: - Watch Connectivity Handlers
    private func setupWatchConnectivityListeners() {
        print("🔗 Watch: Setting up connectivity listeners...")
        let center = NotificationCenter.default
        
        center.addObserver(forName: .scheduleDidUpdate, object: nil, queue: .main) { [weak self] notification in
            Task { await self?.handleSyncPayload(from: notification.userInfo) }
        }
        
        center.addObserver(forName: .scheduleDataBatchReceived, object: nil, queue: .main) { [weak self] notification in
            Task { await self?.handleSyncPayload(from: notification.userInfo) }
        }
        
        center.addObserver(forName: .watchContextDidUpdate, object: nil, queue: .main) { [weak self] notification in
            Task { await self?.handleSyncPayload(from: notification.userInfo) }
        }
        
        print("✅ Watch: All connectivity listeners set up.")
    }
    
    private func handleSyncPayload(from userInfo: [AnyHashable: Any]?) async {
        print("📦 Watch: Received sync payload")
        guard let payloadData = userInfo?["payload"] as? Data else {
            print("❌ Watch: Sync payload data is missing or not Data")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let payload = try decoder.decode(WatchSyncPayload<WSSchedulePayload>.self, from: payloadData)
            
            if let schedulePayload = payload.data, payload.type == .scheduleSync || payload.type == .scheduleActivated {
                print("📅 Watch: Decoding and saving schedule: \(schedulePayload.name)")
                await saveSchedule(from: schedulePayload)
            }
        } catch {
            print("❌ Watch: Failed to decode sync payload: \(error)")
        }
    }
    
    private func saveSchedule(from payload: WSSchedulePayload) async {
        guard let repository = sharedRepository, repository.getModelContext() != nil else {
            print("❌ Watch: Cannot save schedule, repository not configured.")
            return
        }
        
        isLoading = true
        
        do {
            // Deactivate previous schedule
            if let activeSchedule = try repository.getActiveSchedule(), activeSchedule.id != payload.id {
                try await repository.deactivateSchedule(id: activeSchedule.id)
                print("🔄 Deactivated old schedule: \(activeSchedule.name)")
            }
            
            // Create or update the schedule
            let savedSchedule = try await repository.createOrUpdateSchedule(from: payload)
            
            // Update the UI
            self.currentSchedule = savedSchedule
            updateUI(with: savedSchedule)
            
            print("✅ Watch: Successfully saved schedule '\(payload.name)' to repository.")
            
        } catch {
            print("❌ Watch: Error saving schedule to repository: \(error.localizedDescription)")
            currentStatusMessage = L("update_error", tableName: "ViewModels")
        }
        
        isLoading = false
    }
    
    // MARK: - UI Update Logic
    private func updateUI(with schedule: SharedUserSchedule) {
        currentStatusMessage = schedule.name
        calculateNextSleepTime()
    }
    
    func calculateNextSleepTime() {
        guard let schedule = currentSchedule, let sleepBlocks = schedule.sleepBlocks, !sleepBlocks.isEmpty else {
            nextSleepBlock = nil
            timeUntilNextSleep = L("no_active_schedule", tableName: "ViewModels")
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        let upcomingSleeps = sleepBlocks.compactMap { block -> (date: Date, block: SharedSleepBlock)? in
            guard let blockTime = timeStringToDate(block.startTime) else { return nil }
            
            let todayTime = calendar.date(bySettingHour: calendar.component(.hour, from: blockTime),
                                          minute: calendar.component(.minute, from: blockTime),
                                          second: 0,
                                          of: calendar.startOfDay(for: now))!
            
            let tomorrowTime = calendar.date(byAdding: .day, value: 1, to: todayTime)!
            
            return (todayTime > now) ? (todayTime, block) : (tomorrowTime, block)
        }.sorted { $0.date < $1.date }
        
        if let nextSleep = upcomingSleeps.first {
            self.nextSleepBlock = nextSleep.block
            let interval = nextSleep.date.timeIntervalSince(now)
            timeUntilNextSleep = formatTimeInterval(interval)
        } else {
            self.nextSleepBlock = nil
            timeUntilNextSleep = L("no_upcoming_sleeps", tableName: "ViewModels")
        }
    }
    
    // MARK: - Service Observers
    private func setupServiceObservers() {
        syncService.$syncStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if case .success = status {
                    Task { await self?.loadActiveSchedule() }
                }
            }
            .store(in: &cancellables)
        
        syncService.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                if isConnected {
                    print("🔗 Connected to iOS, requesting sync.")
                    self?.syncService.requestDataSync()
                } else {
                    print("🔌 Disconnected from iOS.")
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    private func timeStringToDate(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString)
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return L("now", tableName: "ViewModels")
        }
    }
}

// MARK: - Convenience Properties & Service Access
extension WatchMainViewModel {
    var sleepSessionTimer: String { sleepTrackingService.sleepSessionTimer }
    var isProcessing: Bool { sleepTrackingService.isProcessing || syncService.isSyncing }
    var syncStatusMessage: String { syncService.syncStatusMessage }
    var syncStatusColor: Color { syncService.syncStatusColor }
}

// MARK: - Localization Helper
private func L(_ key: String, tableName: String) -> String {
    return NSLocalizedString(key, tableName: tableName, comment: "")
} 
