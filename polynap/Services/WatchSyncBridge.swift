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
    private let sharedRepository = SharedRepository.shared
    private let watchConnectivity = WatchConnectivityManager.shared
    private let logger = Logger(subsystem: "com.tanercelik.polynap", category: "WatchSyncBridge")
    
    // MARK: - Published Properties
    @Published public var isSyncEnabled: Bool = true
    @Published public var lastSyncDate: Date?
    @Published public var syncStatus: SyncStatus = .idle
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var isInitialized = false
    
    public enum SyncStatus {
        case idle
        case syncing
        case success
        case failed(Error)
        case offline
    }
    
    // MARK: - Initialization
    private init() {
        logger.debug("🌉 WatchSyncBridge başlatılıyor")
        setupNotificationObservers()
    }
    
    // MARK: - Public Interface
    
    /// Sync bridge'i aktif eder
    public func enableSync() {
        isSyncEnabled = true
        logger.debug("✅ Watch sync etkinleştirildi")
        
        // İlk sync'i tetikle
        Task {
            await performFullSync()
        }
    }
    
    /// Sync bridge'i deaktif eder
    public func disableSync() {
        isSyncEnabled = false
        logger.debug("❌ Watch sync devre dışı bırakıldı")
    }
    
    /// Manuel tam senkronizasyon
    public func performFullSync() async {
        guard isSyncEnabled else {
            logger.debug("⚠️ Sync devre dışı - atlanıyor")
            return
        }
        
        await MainActor.run {
            syncStatus = .syncing
        }
        
        do {
            // 1. Active schedule'ı sync et
            try await syncActiveScheduleToWatch()
            
            // 2. Son sleep entries'i sync et
            try await syncRecentSleepEntriesToWatch()
            
            // 3. User preferences'ı sync et
            try await syncUserPreferencesToWatch()
            
            await MainActor.run {
                syncStatus = .success
                lastSyncDate = Date()
            }
            
            logger.debug("✅ Tam senkronizasyon tamamlandı")
            
            // Ayrıca application context ile de sync et (offline durumda çalışır)
            if let activeSchedule = try await iosRepository.getActiveSchedule() {
                let scheduleData = try await convertScheduleToWatchFormat(activeSchedule)
                watchConnectivity.updateApplicationContext([
                    "type": "scheduleSync",
                    "schedule": scheduleData,
                    "timestamp": Date().timeIntervalSince1970
                ])
                logger.debug("📡 Application context ile de sync edildi")
            }
            
        } catch {
            await MainActor.run {
                syncStatus = .failed(error)
            }
            logger.error("❌ Sync hatası: \(error.localizedDescription)")
        }
    }
    
    /// ModelContext'i her iki repository'de de ayarla
    public func configureModelContext(_ context: ModelContext) {
        // iOS Repository'yi configure et
        iosRepository.setModelContext(context)
        
        // SharedRepository'yi configure et
        sharedRepository.setModelContext(context)
        
        logger.debug("🔧 ModelContext her iki repository'de de ayarlandı")
        
        // İlk sync'i başlat (biraz gecikme ile repository'nin tamamen hazır olması için)
        if !isInitialized {
            isInitialized = true
            Task {
                // Repository'nin tamamen hazır olması için kısa bir delay
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 saniye
                await performFullSync()
            }
        }
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        // Schedule değişikliklerini dinle
        NotificationCenter.default.addObserver(
            forName: .scheduleDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                await self?.handleScheduleChange(notification)
            }
        }
        
        // Sleep entry eklemelerini dinle
        NotificationCenter.default.addObserver(
            forName: .sleepEntryDidAdd,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                await self?.handleSleepEntryAdd(notification)
            }
        }
        
        // User preferences değişikliklerini dinle
        NotificationCenter.default.addObserver(
            forName: .userPreferencesDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                await self?.handleUserPreferencesChange(notification)
            }
        }
        
        // Watch'tan gelen sleep entry'leri dinle
        NotificationCenter.default.addObserver(
            forName: Notification.Name("sleepEntryDidAdd"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                await self?.handleIncomingSleepEntryFromWatch(notification)
            }
        }
        
        // Watch connectivity durumunu dinle
        watchConnectivity.reachabilityPublisher
            .sink { [weak self] isReachable in
                if isReachable {
                    Task { @MainActor in
                        await self?.performFullSync()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Event Handlers
    
    private func handleScheduleChange(_ notification: Notification) async {
        guard isSyncEnabled else { return }
        
        logger.debug("📅 Schedule değişikliği algılandı - Watch'a sync ediliyor")
        
        do {
            try await syncActiveScheduleToWatch()
        } catch {
            logger.error("❌ Schedule sync hatası: \(error.localizedDescription)")
        }
    }
    
    private func handleSleepEntryAdd(_ notification: Notification) async {
        guard isSyncEnabled else { return }
        
        logger.debug("😴 Yeni sleep entry algılandı - Watch'a sync ediliyor")
        
        // iOS'ta eklenen sleep entry'yi Watch'a bildir
        if let userInfo = notification.userInfo as? [String: Any] {
            watchConnectivity.notifySleepEntryAdded(userInfo)
        }
    }
    
    private func handleUserPreferencesChange(_ notification: Notification) async {
        guard isSyncEnabled else { return }
        
        logger.debug("⚙️ User preferences değişikliği algılandı - Watch'a sync ediliyor")
        
        do {
            try await syncUserPreferencesToWatch()
        } catch {
            logger.error("❌ User preferences sync hatası: \(error.localizedDescription)")
        }
    }
    
    /// Watch'tan gelen sleep entry'leri iOS Repository'ye kaydet
    private func handleIncomingSleepEntryFromWatch(_ notification: Notification) async {
        guard isSyncEnabled else { return }
        
        logger.debug("⌚ Watch'tan sleep entry alındı - iOS Repository'ye kaydediliyor")
        
        guard let userInfo = notification.userInfo as? [String: Any] else {
            logger.error("❌ Watch sleep entry format hatası")
            return
        }
        
        do {
            // Parse sleep entry data from Watch
            guard let rating = userInfo["rating"] as? Int,
                  let emoji = userInfo["emoji"] as? String,
                  let dateInterval = userInfo["date"] as? TimeInterval,
                  let startTimeInterval = userInfo["startTime"] as? TimeInterval,
                  let endTimeInterval = userInfo["endTime"] as? TimeInterval,
                  let durationMinutes = userInfo["durationMinutes"] as? Int,
                  let isCore = userInfo["isCore"] as? Bool else {
                logger.error("❌ Watch sleep entry data eksik")
                return
            }
            
            let date = Date(timeIntervalSince1970: dateInterval)
            let startTime = Date(timeIntervalSince1970: startTimeInterval)
            let endTime = Date(timeIntervalSince1970: endTimeInterval)
            let blockId = userInfo["blockId"] as? String ?? ""
            
            // iOS Repository'ye kaydet
            let savedEntry = try await iosRepository.addSleepEntry(
                blockId: blockId,
                emoji: emoji,
                rating: rating,
                date: date
            )
            
            logger.debug("✅ Watch'tan gelen sleep entry iOS'a kaydedildi: \(savedEntry.rating) stars")
            
        } catch {
            logger.error("❌ Watch sleep entry kaydedilirken hata: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Sync Methods
    
    /// Aktif schedule'ı iOS'tan Watch'a sync eder
    private func syncActiveScheduleToWatch() async throws {
        // iOS'tan aktif schedule'ı al
        guard let activeUserSchedule = try await iosRepository.getActiveSchedule() else {
            logger.debug("⚠️ iOS'ta aktif schedule bulunamadı")
            return
        }
        
        // SharedRepository'ye aktif schedule'ı kaydet/güncelle
        let user = try await ensureSharedUser()
        
        // Mevcut shared schedule'ı kontrol et
        let existingSharedSchedule = try sharedRepository.getActiveSchedule()
        
        if let existingSchedule = existingSharedSchedule {
            // Güncelle
            let description = activeUserSchedule.description.localized(for: LanguageManager.shared.currentLanguage)
            try await sharedRepository.updateSchedule(
                existingSchedule,
                name: activeUserSchedule.name,
                description: description,
                totalSleepHours: activeUserSchedule.totalSleepHours,
                adaptationPhase: nil, // Adaptation phase şimdilik yok
                isActive: true
            )
            
            // Sleep blocks'ları sync et
            try await syncSleepBlocksToShared(
                from: activeUserSchedule.schedule,
                to: existingSchedule
            )
            
            logger.debug("📝 Mevcut shared schedule güncellendi: \(activeUserSchedule.name)")
        } else {
            // Yeni oluştur
            let description = activeUserSchedule.description.localized(for: LanguageManager.shared.currentLanguage)
            let newSharedSchedule = try await sharedRepository.createSchedule(
                user: user,
                name: activeUserSchedule.name,
                description: description,
                totalSleepHours: activeUserSchedule.totalSleepHours,
                adaptationPhase: nil, // Adaptation phase şimdilik yok
                isActive: true
            )
            
            // Sleep blocks'ları sync et
            try await syncSleepBlocksToShared(
                from: activeUserSchedule.schedule,
                to: newSharedSchedule
            )
            
            logger.debug("✨ Yeni shared schedule oluşturuldu: \(activeUserSchedule.name)")
        }
        
        // Watch'a real-time notification gönder (eğer bağlantı varsa)
        let scheduleData = try await convertScheduleToWatchFormat(activeUserSchedule)
        
        if watchConnectivity.isReachable {
            watchConnectivity.notifyScheduleActivated(scheduleData)
            logger.debug("📡 Schedule activation Watch'a gönderildi (real-time)")
        } else {
            // Fallback: Application Context ile sync et (offline durumda çalışır)
            watchConnectivity.updateApplicationContext([
                "type": "scheduleSync",
                "schedule": scheduleData,
                "timestamp": Date().timeIntervalSince1970
            ])
            logger.debug("📡 Schedule activation Watch'a gönderildi (application context)")
        }
    }
    
    /// Sleep blocks'ları iOS modelinden SharedRepository'ye sync eder
    private func syncSleepBlocksToShared(
        from iosBlocks: [SleepBlock],
        to sharedSchedule: SharedUserSchedule
    ) async throws {
        // Mevcut shared sleep blocks'ları temizle
        if let existingBlocks = sharedSchedule.sleepBlocks {
            for block in existingBlocks {
                // SharedRepository'de sleep block silme methodu implement edilmeli
                // Şimdilik log bırakıyoruz
                logger.debug("🗑️ Eski sleep block: \(block.startTime)")
            }
        }
        
        // Yeni sleep blocks'ları ekle
        for iosBlock in iosBlocks {
            _ = try await sharedRepository.createSleepBlock(
                schedule: sharedSchedule,
                startTime: iosBlock.startTime,
                endTime: iosBlock.endTime,
                durationMinutes: iosBlock.duration,
                isCore: iosBlock.isCore,
                syncId: iosBlock.id.uuidString
            )
        }
        
        logger.debug("🔄 \(iosBlocks.count) sleep block sync edildi")
    }
    
    /// Son sleep entries'i Watch'a sync eder
    private func syncRecentSleepEntriesToWatch() async throws {
        // Bu method gelecekte implement edilecek
        logger.debug("💤 Sleep entries sync - gelecekte implement edilecek")
    }
    
    /// User preferences'ı Watch'a sync eder
    private func syncUserPreferencesToWatch() async throws {
        // Bu method gelecekte implement edilecek
        logger.debug("⚙️ User preferences sync - gelecekte implement edilecek")
    }
    
    // MARK: - Helper Methods
    
    /// SharedRepository'de user bulunduğundan emin olur
    private func ensureSharedUser() async throws -> SharedUser {
        // iOS'tan kullanıcı bilgisini al
        let iosUser = try await iosRepository.createOrGetUser()
        
        // SharedRepository'de aynı kullanıcıyı oluştur/al
        return try await sharedRepository.createOrGetUser(
            id: iosUser.id,
            email: iosUser.email,
            displayName: iosUser.displayName,
            isAnonymous: iosUser.isAnonymous,
            isPremium: iosUser.isPremium
        )
    }
    
    /// iOS schedule'ını Watch formatına çevirir
    private func convertScheduleToWatchFormat(_ schedule: UserScheduleModel) async throws -> [String: Any] {
        let sleepBlocksData = schedule.schedule.map { block in
            return [
                "id": block.id.uuidString,
                "startTime": block.startTime,
                "endTime": block.endTime,
                "durationMinutes": block.duration,
                "isCore": block.isCore
            ]
        }
        
        let description = schedule.description.localized(for: LanguageManager.shared.currentLanguage)
        return [
            "id": schedule.id,
            "name": schedule.name,
            "description": description,
            "totalSleepHours": schedule.totalSleepHours,
            "adaptationPhase": 1, // Default value for now
            "sleepBlocks": sleepBlocksData,
            "isActive": true,
            "timestamp": Date().timeIntervalSince1970
        ]
    }
}

// MARK: - Notification Names Extension
extension Notification.Name {
    static let scheduleDidChange = Notification.Name("ScheduleDidChange")
    static let sleepEntryDidAdd = Notification.Name("SleepEntryDidAdd")
    static let userPreferencesDidChange = Notification.Name("UserPreferencesDidChange")
}