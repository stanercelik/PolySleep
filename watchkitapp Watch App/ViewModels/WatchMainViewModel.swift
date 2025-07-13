import Foundation
import SwiftUI
import SwiftData
import WatchKit
import PolyNapShared
import Combine

// MARK: - Clean Architecture ile refactor edilmiş WatchMainViewModel
@MainActor
class WatchMainViewModel: ObservableObject {
    
    // MARK: - Published Properties for UI
    
    // Schedule-related properties
    @Published var currentSchedule: SharedUserSchedule?
    @Published var currentSleepBlock: SharedSleepBlock?
    @Published var nextSleepBlock: SharedSleepBlock?
    @Published var nextSleepTime: String?
    @Published var currentStatusMessage: String = L("schedule_loading", table: "ViewModels")
    @Published var isLoading: Bool = false
    
    // Legacy compatibility properties
    @Published var isSleeping: Bool = false
    @Published var canRateLastSleep: Bool = false
    @Published var selectedRating: Int = 0
    @Published var selectedQualityRating: Int = 3
    @Published var selectedEmoji: String = "😴"
    @Published var isRatingMode: Bool = false
    @Published var currentRating: Int = 0
    @Published var qualityEmojis: [String] = ["😩", "😪", "😐", "😊", "🤩"]
    
    // MARK: - Service Dependencies (Lazy Initialized)
    private lazy var sleepTrackingService: SleepTrackingService = SleepTrackingService()
    private lazy var syncService: SyncService = SyncService()
    private lazy var statisticsService: SleepStatisticsService = SleepStatisticsService()
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var modelContext: ModelContext?
    private var timer: Timer?
    private var sharedRepository: SharedRepository?
    
    // MARK: - Initialization
    
    init() {
        setupServiceObservers()
        loadInitialData()
        
        // Watch Connectivity için notification listener'lar ekle
        setupWatchConnectivityListeners()
    }
    
    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Configuration Methods
    
    func configureSharedRepository(with modelContext: ModelContext) {
        self.modelContext = modelContext
        self.sharedRepository = SharedRepository.shared
        
        // ModelContext'in zaten ayarlanıp ayarlanmadığını kontrol et
        if self.sharedRepository?.getModelContext() == nil {
            self.sharedRepository?.setModelContext(modelContext)
            print("✅ WatchMainViewModel: ModelContext ayarlandı")
        } else {
            print("🔍 WatchMainViewModel: ModelContext zaten mevcut")
        }
        
        print("✅ WatchMainViewModel: SharedRepository configured")
        
        // Repository configure olduktan sonra gerçek data'yı yükle
        Task {
            await loadActiveSchedule()
        }
    }
    
    // MARK: - Watch Connectivity Setup
    
    private func setupWatchConnectivityListeners() {
        print("🔗 Watch: Connectivity listeners kuruluyor...")
        
        // Schedule güncellemelerini dinle
        NotificationCenter.default.addObserver(
            forName: Notification.Name("scheduleDidUpdate"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("📅 Watch: scheduleDidUpdate notification alındı")
            Task { @MainActor in
                await self?.handleScheduleUpdate(notification.userInfo)
            }
        }
        
        // Schedule data batch güncellemelerini dinle
        NotificationCenter.default.addObserver(
            forName: Notification.Name("scheduleDataBatchReceived"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("📦 Watch: scheduleDataBatchReceived notification alındı")
            Task { @MainActor in
                await self?.handleScheduleDataBatch(notification.userInfo)
            }
        }
        
        // Watch connectivity status değişikliklerini dinle
        NotificationCenter.default.addObserver(
            forName: Notification.Name("watchConnectivityStatusChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("📶 Watch: watchConnectivityStatusChanged notification alındı")
            self?.handleConnectivityStatusChange(notification.userInfo)
        }
        
        // Schedule activated notification'ı da dinle (iOS'tan gelen direkt aktivasyon)
        NotificationCenter.default.addObserver(
            forName: Notification.Name("scheduleActivated"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("🎯 Watch: scheduleActivated notification alındı")
            Task { @MainActor in
                await self?.handleScheduleUpdate(notification.userInfo)
            }
        }
        
        print("✅ Watch: Tüm connectivity listeners kuruldu")
    }
    
    // MARK: - Data Loading Methods
    
    /// Aktif schedule'ı repository'den yükler
    private func loadActiveSchedule() async {
        // Repository kontrolü
        guard let repository = sharedRepository else {
            print("⚠️ SharedRepository henüz configure edilmedi, Watch connectivity ile sync bekleniyor")
            await MainActor.run {
                currentStatusMessage = L("waiting_for_connection", table: "ViewModels")
                requestDataSync() // iOS'tan data sync isteiği gönder
            }
            return
        }
        
        // ModelContext kontrolü
        guard repository.getModelContext() != nil else {
            print("⚠️ SharedRepository'de ModelContext bulunamadı, Watch connectivity ile sync bekleniyor")
            await MainActor.run {
                currentStatusMessage = L("waiting_for_connection", table: "ViewModels")
                requestDataSync() // iOS'tan data sync isteiği gönder
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Aktif schedule'ı al
            if let activeSchedule = try repository.getActiveSchedule() {
                await MainActor.run {
                    currentSchedule = activeSchedule
                    print("✅ Watch: Aktif schedule yüklendi: \(activeSchedule.name)")
                    currentStatusMessage = "📱 \(activeSchedule.name)"
                    calculateNextSleepTime()
                }
            } else {
                // Aktif schedule yoksa tüm schedule'ları kontrol et
                let allSchedules = try repository.getAllSchedules()
                if let firstSchedule = allSchedules.first {
                    // İlk schedule'ı aktif yap
                    try await repository.setActiveSchedule(firstSchedule.id)
                    await MainActor.run {
                        currentSchedule = firstSchedule
                        print("✅ Watch: İlk schedule aktif yapıldı: \(firstSchedule.name)")
                        currentStatusMessage = "📱 \(firstSchedule.name)"
                        calculateNextSleepTime()
                    }
                } else {
                    print("⚠️ Watch: Hiç schedule bulunamadı, iOS'tan sync bekleniyor")
                    await MainActor.run {
                        currentStatusMessage = L("synchronizing", table: "ViewModels")
                        // iOS'tan full data sync isteyî gönder
                        WatchConnectivityManager.shared.requestFullDataSync()
                        
                        // 5 saniye sonra tekrar dene
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                            Task {
                                await self.retryScheduleLoad()
                            }
                        }
                    }
                }
            }
        } catch {
            print("❌ Watch: Schedule yüklenirken hata: \(error.localizedDescription)")
            await MainActor.run {
                currentStatusMessage = L("loading_error", table: "ViewModels")
                // Hata durumunda iOS'tan sync iste
                requestDataSync()
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Watch Connectivity Handlers
    
    private func handleScheduleUpdate(_ userInfo: [AnyHashable: Any]?) async {
        print("📅 Watch: Schedule güncelleme bildirimi alındı")
        print("📅 Watch: UserInfo: \(String(describing: userInfo))")
        
        // Eğer schedule data geliyorsa, bunu parse et ve SharedRepository'ye kaydet
        if let scheduleData = userInfo as? [String: Any] {
            await parseAndSaveScheduleFromiOS(scheduleData)
        }
        
        // Repository'den yeniden yükle
        await loadActiveSchedule()
        
        // WatchConnectivityManager'a sync başarısını bildir
        let response: [String: Any] = ["status": "received", "type": "scheduleUpdate", "timestamp": Date().timeIntervalSince1970]
        WatchConnectivityManager.shared.notifyScheduleUpdate(response)
    }
    
    /// iOS'tan gelen schedule data'sını parse eder ve SharedRepository'ye kaydeder
    private func parseAndSaveScheduleFromiOS(_ scheduleData: [String: Any]) async {
        print("🔄 Watch: iOS schedule data parse ediliyor...")
        
        guard let repository = sharedRepository,
              repository.getModelContext() != nil else {
            print("❌ Watch: SharedRepository kullanılamıyor")
            return
        }
        
        do {
            // Schedule bilgilerini parse et
            guard let scheduleName = scheduleData["name"] as? String,
                  let scheduleDescription = scheduleData["description"] as? String,
                  let totalSleepHours = scheduleData["totalSleepHours"] as? Double,
                  let sleepBlocksData = scheduleData["sleepBlocks"] as? [[String: Any]] else {
                print("❌ Watch: Schedule data format hatası")
                return
            }
            
            print("📅 Watch: Schedule parse ediliyor: \(scheduleName)")
            
            // User'ı oluştur/al
            let user = try await repository.createOrGetUser(
                id: UUID(),
                email: nil,
                displayName: "Watch User",
                isAnonymous: true,
                isPremium: false
            )
            
            // Mevcut aktif schedule'ı deaktive et
            if let activeSchedule = try repository.getActiveSchedule() {
                try await repository.updateSchedule(
                    activeSchedule,
                    name: activeSchedule.name,
                    description: activeSchedule.scheduleDescription,
                    totalSleepHours: activeSchedule.totalSleepHours,
                    adaptationPhase: activeSchedule.adaptationPhase,
                    isActive: false
                )
            }
            
            // Yeni schedule oluştur
            let newSchedule = try await repository.createSchedule(
                user: user,
                name: scheduleName,
                description: scheduleDescription,
                totalSleepHours: totalSleepHours,
                adaptationPhase: 1,
                isActive: true
            )
            
            // Sleep blocks'ları ekle
            for blockData in sleepBlocksData {
                guard let startTime = blockData["startTime"] as? String,
                      let endTime = blockData["endTime"] as? String,
                      let durationMinutes = blockData["durationMinutes"] as? Int,
                      let isCore = blockData["isCore"] as? Bool else {
                    continue
                }
                
                let syncId = blockData["id"] as? String ?? UUID().uuidString
                
                _ = try await repository.createSleepBlock(
                    schedule: newSchedule,
                    startTime: startTime,
                    endTime: endTime,
                    durationMinutes: durationMinutes,
                    isCore: isCore,
                    syncId: syncId
                )
            }
            
            print("✅ Watch: Schedule başarıyla kaydedildi: \(scheduleName)")
            
        } catch {
            print("❌ Watch: Schedule kayıt hatası: \(error.localizedDescription)")
        }
    }
    
    private func handleScheduleDataBatch(_ userInfo: [AnyHashable: Any]?) async {
        guard let schedules = userInfo?["schedules"] as? [[String: Any]] else {
            print("❌ Schedule data batch format hatası")
            return
        }
        
        print("📦 Schedule data batch alındı: \(schedules.count) schedule")
        
        // Repository'ye batch import işlemi
        // Bu işlem SharedRepository tarafından handle edilecek
        await loadActiveSchedule()
    }
    
    private func handleConnectivityStatusChange(_ userInfo: [AnyHashable: Any]?) {
        guard let isReachable = userInfo?["isReachable"] as? Bool else { return }
        
        if isReachable {
            print("📱 iOS app'e bağlantı kuruldu, sync başlatılıyor")
            requestDataSync()
        } else {
            print("📱 iOS app bağlantısı kesildi")
        }
    }
    
    // MARK: - Public Methods - Sleep Tracking
    
    /// Uyku durumunu toggle eder
    func toggleSleepState() {
        sleepTrackingService.toggleSleepState()
    }
    
    /// Uyku kalitesi rating'ini ayarlar
    func setSleepRating(_ rating: Int) {
        currentRating = rating
        selectedQualityRating = rating
        
        let index = max(0, min(rating - 1, qualityEmojis.count - 1))
        selectedEmoji = qualityEmojis[index]
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.click)
    }
    
    /// Rating'i confirm eder ve kaydeder
    func confirmSleepRating() {
        sleepTrackingService.confirmSleepRating(rating: currentRating, emoji: selectedEmoji)
        
        // Reset UI state
        currentRating = 0
        selectedRating = 0
        isRatingMode = false
        
        // Update statistics
        if let entry = sleepTrackingService.lastCompletedSleep {
            statisticsService.addSleepEntry(entry)
        }
    }
    
    // MARK: - Public Methods - Data Sync
    
    /// Data senkronizasyonu başlatır
    func requestDataSync() {
        syncService.requestDataSync()
        
        // WatchConnectivityManager üzerinden de sync request gönder
        WatchConnectivityManager.shared.requestSync()
        
        // Sync sonrası schedule'ı yeniden yükle
        Task {
            await loadActiveSchedule()
        }
    }
    
    /// Sync durumunu sıfırlar
    func resetSyncStatus() {
        syncService.resetSyncStatus()
    }
    
    // MARK: - Public Methods - Schedule Management
    
    /// Bir sonraki uyku bloğunun zamanını hesaplar
    func calculateNextSleepTime() {
        guard let schedule = currentSchedule else {
            nextSleepTime = nil
            currentStatusMessage = L("schedule_not_found", table: "ViewModels")
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        
        guard let sleepBlocks = schedule.sleepBlocks, !sleepBlocks.isEmpty else {
            nextSleepTime = nil
            currentStatusMessage = L("sleep_blocks_not_found", table: "ViewModels")
            return
        }
        
        // Tüm uyku bloklarını zamanla birlikte sırala
        var upcomingSleepBlocks: [(time: Date, block: SharedSleepBlock)] = []
        
        for block in sleepBlocks {
            guard let startTime = timeStringToDate(block.startTime) else {
                continue
            }
            
            // Bugün için zamanı hesapla
            let todayTime = calendar.date(bySettingHour: calendar.component(.hour, from: startTime),
                                        minute: calendar.component(.minute, from: startTime),
                                        second: 0,
                                        of: today) ?? today
            
            // Yarın için zamanı hesapla
            let tomorrowTime = calendar.date(byAdding: .day, value: 1, to: todayTime) ?? todayTime
            
            // Eğer bugünün zamanı geçmişse, yarının zamanını kullan
            if todayTime > now {
                upcomingSleepBlocks.append((time: todayTime, block: block))
            } else {
                upcomingSleepBlocks.append((time: tomorrowTime, block: block))
            }
        }
        
        // En yakın uyku bloğunu bul
        let sortedBlocks = upcomingSleepBlocks.sorted { $0.time < $1.time }
        
        if let nextBlock = sortedBlocks.first {
            nextSleepBlock = nextBlock.block
            currentSleepBlock = nextBlock.block
            
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            nextSleepTime = formatter.string(from: nextBlock.time)
            
            let timeUntilNext = nextBlock.time.timeIntervalSince(now)
            let hours = Int(timeUntilNext) / 3600
            let minutes = Int(timeUntilNext) % 3600 / 60
            
            if hours > 0 {
                currentStatusMessage = String(format: L("next_sleep_hours_minutes", table: "ViewModels"), hours, minutes)
            } else if minutes > 0 {
                currentStatusMessage = String(format: L("next_sleep_minutes", table: "ViewModels"), minutes)
            } else {
                currentStatusMessage = L("sleep_time_now", table: "ViewModels")
            }
        } else {
            nextSleepTime = nil
            currentStatusMessage = L("next_sleep_not_found", table: "ViewModels")
        }
    }
    
    /// Schedule'ı yeniden yükle
    func refreshSchedule() {
        Task {
            await loadActiveSchedule()
        }
    }
    
    /// Schedule yüklemeyi yeniden dene (retry mechanism)
    private func retryScheduleLoad() async {
        print("🔄 Watch: Schedule yükleme retry deneniyor...")
        
        // Önce SharedRepository'den tekrar kontrol et
        guard let repository = sharedRepository else {
            print("⚠️ Watch: SharedRepository hala kullanılamıyor")
            return
        }
        
        do {
            let allSchedules = try repository.getAllSchedules()
            if let firstSchedule = allSchedules.first {
                await MainActor.run {
                    currentSchedule = firstSchedule
                    print("✅ Watch: Retry ile schedule bulundu: \(firstSchedule.name)")
                    currentStatusMessage = "📱 \(firstSchedule.name)"
                    calculateNextSleepTime()
                }
            } else {
                print("⚠️ Watch: Retry'de hala schedule bulunamadı")
                await MainActor.run {
                    currentStatusMessage = L("waiting_for_ios", table: "ViewModels")
                }
            }
        } catch {
            print("❌ Watch: Retry sırasında hata: \(error.localizedDescription)")
        }
    }
    
    /// Mock data yükler (son çare fallback için - sadece geliştirme aşamasında)
    private func loadMockDataIfNeeded() {
        // Mock data yüklemeyi tamamen devre dışı bırak
        print("❌ Watch: Mock data yüklemesi devre dışı bırakıldı")
        currentStatusMessage = L("waiting_for_ios_data", table: "ViewModels")
        
        // Sync request gönder
        requestDataSync()
    }
    
    // MARK: - Private Methods
    
    private func setupServiceObservers() {
        // Sleep tracking service observers
        sleepTrackingService.$sleepTrackingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateLegacyProperties(from: state)
                self?.currentStatusMessage = self?.sleepTrackingService.getCurrentStatusMessage() ?? ""
            }
            .store(in: &cancellables)
        
        sleepTrackingService.$pendingRatingEntry
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entry in
                self?.isRatingMode = entry != nil
                self?.canRateLastSleep = entry != nil
            }
            .store(in: &cancellables)
        
        // Sync service observers
        syncService.$syncStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateSyncStatus(status)
            }
            .store(in: &cancellables)
        
        syncService.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.requestDataSync()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateLegacyProperties(from state: SleepTrackingState) {
        // Legacy compatibility için state'i legacy properties'e map et
        isSleeping = state.isSleeping
        canRateLastSleep = state.canRate
        
        // Reset rating when not in rating mode
        if !state.canRate {
            selectedRating = 0
            currentRating = 0
        }
    }
    
    private func updateSyncStatus(_ status: SyncStatus) {
        switch status {
        case .success:
            // Sync başarılı olduğunda schedule'ı güncelle
            Task {
                await loadActiveSchedule()
            }
        case .failed:
            // Sync başarısız olduğunda current schedule yoksa mock data kullan
            if currentSchedule == nil {
                print("⚠️ Sync başarısız, mock data kullanılıyor")
                loadMockDataIfNeeded()
            }
        default:
            break
        }
    }
    
    private func loadInitialData() {
        // İlk yükleme: repository'den gerçek veri yüklemeyi dene
        Task {
            await loadActiveSchedule()
            
            // Eğer hala schedule yok ise ve debug modda isek, mock data yükle
            if currentSchedule == nil {
                await MainActor.run {
                    loadMockDataIfNeeded()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func timeStringToDate(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        // Bugünün tarihini al ve time string'den sadece saat/dakika bilgisini al
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Time string'i parse et
        guard let time = formatter.date(from: timeString) else {
            return nil
        }
        
        // Saat ve dakika bilgilerini al
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        
        // Bugünün tarihi ile birleştir
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today)
    }
}

// MARK: - Extensions - Service Access
extension WatchMainViewModel {
    
    /// Sleep tracking service'e erişim
    var sleepTracking: SleepTrackingService {
        return sleepTrackingService
    }
    
    /// Sync service'e erişim
    var sync: SyncService {
        return syncService
    }
    
    /// Statistics service'e erişim
    var statistics: SleepStatisticsService {
        return statisticsService
    }
}

// MARK: - Extensions - Convenience Properties
extension WatchMainViewModel {
    
    /// Mevcut uyku durumu
    var currentSleepState: SleepTrackingState {
        return sleepTrackingService.sleepTrackingState
    }
    
    /// Uyku session timer'ı
    var sleepSessionTimer: String {
        return sleepTrackingService.sleepSessionTimer
    }
    
    /// Processing durumu
    var isProcessing: Bool {
        return sleepTrackingService.isProcessing || syncService.isSyncing
    }
    
    /// Sync durumu
    var syncStatusMessage: String {
        return syncService.syncStatusMessage
    }
    
    /// Sync durumu rengi
    var syncStatusColor: Color {
        return syncService.syncStatusColor
    }
    
    /// Bugünkü uyku summary'si
    var todayPerformanceSummary: String {
        return statisticsService.todayPerformanceSummary
    }
    
    /// Bugünkü uyku efficiency'si
    var todaySleepEfficiency: String {
        return statisticsService.getSleepEfficiencyFormatted()
    }
} 