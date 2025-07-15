import Foundation
import SwiftData
import PolyNapShared
import OSLog
import Combine

/// iOS Repository ve SharedRepository arasında köprü görevi gören servis
/// iOS app'teki değişiklikleri Apple Watch'a otomatik olarak senkronize eder
@MainActor
public class WatchSyncBridge: ObservableObject {
    public static let shared = WatchSyncBridge()
    
    // MARK: - Dependencies
    private let iosRepository = Repository.shared
    private let watchConnectivity = WatchConnectivityManager.shared
    private let logger = Logger(subsystem: "com.tanercelik.polynap", category: "WatchSyncBridge")
    
    // MARK: - Published Properties
    @Published public var isSyncEnabled: Bool = true
    @Published public var lastSyncDate: Date?
    @Published public var syncStatus: SyncStatus = .idle
    
    private var cancellables = Set<AnyCancellable>()
    
    public enum SyncStatus {
        case idle, syncing, success, failed(Error)
    }
    
    // MARK: - Initialization
    private init() {
        logger.debug("🌉 WatchSyncBridge başlatılıyor")
        setupNotificationObservers()
    }
    
    // MARK: - Public Interface
    
    public func configureModelContext(_ context: ModelContext) {
        iosRepository.setModelContext(context)
        logger.debug("🔧 ModelContext, iOS repository'de ayarlandı")
        
        // Initial sync after a short delay
        Task {
            try? await Task.sleep(for: .seconds(1))
            await performFullSync()
        }
    }
    
    public func performFullSync() async {
        guard isSyncEnabled, await updateSyncStatus(.syncing) else { return }
        
        logger.debug("🔄 Tam senkronizasyon başlatılıyor...")
        
        do {
            try await syncActiveScheduleToWatch()
            // Future implementations for other data types can be added here
            
            await updateSyncStatus(.success)
            logger.debug("✅ Tam senkronizasyon tamamlandı")
        } catch {
            await updateSyncStatus(.failed(error))
            logger.error("❌ Tam senkronizasyon hatası: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Notification Observers
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(forName: .scheduleDidChange, object: nil, queue: .main) { [weak self] _ in
            Task { await self?.handleScheduleChange() }
        }
        
        watchConnectivity.reachabilityPublisher.sink { [weak self] isReachable in
            if isReachable { Task { await self?.performFullSync() } }
        }.store(in: &cancellables)
    }
    
    // MARK: - Event Handlers
    private func handleScheduleChange() async {
        guard isSyncEnabled else { return }
        logger.debug("📅 Schedule değişikliği algılandı - Watch'a sync ediliyor")
        await syncActiveScheduleToWatch()
    }
    
    // MARK: - Sync Methods
    private func syncActiveScheduleToWatch() async {
        guard let activeSchedule = try? await iosRepository.getActiveSchedule() else {
            logger.debug("ℹ️ Senkronize edilecek aktif program bulunamadı.")
            return
        }
        
        do {
            let payload = try await createSchedulePayload(from: activeSchedule)
            let syncPayload = WatchSyncPayload(type: .scheduleSync, data: payload)
            let data = try JSONEncoder().encode(syncPayload)
            
            let messageData = ["payload": data]
            
            // Send to watch via real-time message if possible, and always update context as a fallback
            if watchConnectivity.isReachable {
                let watchMessage = WatchMessage(type: .scheduleUpdate, data: messageData)
                watchConnectivity.sendMessage(watchMessage)
                logger.debug("⚡️ Schedule anlık olarak gönderildi: \(payload.name)")
            }
            watchConnectivity.updateApplicationContext(messageData)
            logger.debug("📦 Schedule application context güncellendi: \(payload.name)")
            
        } catch {
            logger.error("❌ Schedule sync hatası: \(error.localizedDescription)")
            await updateSyncStatus(.failed(error))
        }
    }
    
    // MARK: - Helper Methods
    private func createSchedulePayload(from schedule: UserScheduleModel) async throws -> WSSchedulePayload {
        let sleepBlocks = schedule.schedule.map {
            WSSleepBlock(id: $0.id, startTime: $0.startTime, endTime: $0.endTime, durationMinutes: $0.duration, isCore: $0.isCore)
        }
        
        let adaptationData = try? await getAdaptationDataForWatch()
        let description = schedule.description.localized(for: LanguageManager.shared.currentLanguage)
        
        return WSSchedulePayload(
            id: UUID(uuidString: schedule.id) ?? UUID(),
            name: schedule.name,
            description: description,
            totalSleepHours: schedule.totalSleepHours,
            isActive: true,
            adaptationPhase: adaptationData?.adaptationPhase ?? 1,
            sleepBlocks: sleepBlocks,
            adaptationData: adaptationData
        )
    }
    
    private func getAdaptationDataForWatch() async throws -> WSAdaptationData {
        let recentEntries = try await iosRepository.getRecentSleepEntries(limit: 50)
        let last7Days = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let recentEntriesLast7Days = recentEntries.filter { $0.date >= last7Days }
        
        let totalRating = recentEntriesLast7Days.map { $0.rating }.reduce(0, +)
        let averageRating = recentEntriesLast7Days.isEmpty ? 0.0 : Double(totalRating) / Double(recentEntriesLast7Days.count)
        
        let adaptationPercentage = min(100, max(0, (averageRating / 5.0) * 100))
        let adaptationPhase = min(4, max(1, recentEntriesLast7Days.count / 7 + 1))
        
        return WSAdaptationData(
            adaptationPhase: adaptationPhase,
            adaptationPercentage: adaptationPercentage,
            totalEntries: recentEntries.count,
            last7DaysEntries: recentEntriesLast7Days.count,
            averageRating: averageRating
        )
    }
    
    @discardableResult
    private func updateSyncStatus(_ newStatus: SyncStatus) async -> Bool {
        guard isSyncEnabled else {
            logger.debug("⚠️ Sync devre dışı, durum güncellemesi atlanıyor.")
            return false
        }
        
        if case .syncing = syncStatus {
            logger.warning("⚠️ Zaten devam eden bir senkronizasyon var, yenisi başlatılmadı.")
            return false
        }
        
        syncStatus = newStatus
        if case .success = newStatus {
            lastSyncDate = Date()
        }
        return true
    }
}

// MARK: - Notification Names Extension
extension Notification.Name {
    static let scheduleDidChange = Notification.Name("ScheduleDidChange")
    static let sleepEntryDidAdd = Notification.Name("SleepEntryDidAdd")
    static let userPreferencesDidChange = Notification.Name("UserPreferencesDidChange")
}
