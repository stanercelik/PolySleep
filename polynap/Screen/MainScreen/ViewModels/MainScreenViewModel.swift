import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class MainScreenViewModel: ObservableObject {
    @Published var model: MainScreenModel
    @Published var isEditing: Bool = false {
        didSet {
            if !isEditing && oldValue != isEditing {
                updateAlarms()
            }
        }
    }
    @Published private(set) var nextSleepBlock: SleepBlock?
    @Published private(set) var timeUntilNextBlock: TimeInterval = 0
    @Published private(set) var selectedSchedule: UserScheduleModel?
    @Published var showAddBlockSheet: Bool = false
    @Published var showEditNameSheet: Bool = false
    @Published var editingTitle: String = "" {
        didSet {
            DispatchQueue.main.async {
                if self.editingTitle.count > 30 {
                    self.editingTitle = String(self.editingTitle.prefix(30))
                }
            }
        }
    }
    @Published var newBlockStartTime: Date = Date()
    @Published var newBlockEndTime: Date = Date().addingTimeInterval(3600)
    @Published var newBlockIsCore: Bool = false
    @Published var showBlockError: Bool = false
    @Published var blockErrorMessage: String = ""
    @Published var editingBlockId: UUID?
    @Published var editingBlockStartTime: Date = Date()
    @Published var editingBlockEndTime: Date = Date().addingTimeInterval(3600)
    @Published var editingBlockIsCore: Bool = false
    @Published var isEditingTitle: Bool = false
    @Published var showSleepQualityRating = false
    @Published var hasDeferredSleepQualityRating = false
    @Published var lastSleepBlock: SleepBlock?
    @Published var showScheduleSelection = false
    @Published var availableSchedules: [SleepScheduleModel] = []
    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var modelContext: ModelContext?
    private var timerCancellable: AnyCancellable?
    private var languageManager: LanguageManager
    
    /// Son kontrol edilen tamamlanmış blok
    private var lastCheckedCompletedBlock: String?
    
    private let authManager = AuthManager.shared
    private var cancellables = Set<AnyCancellable>()
    private let revenueCatManager = RevenueCatManager.shared
    
    private let ratedSleepBlocksKey = "ratedSleepBlocks"
    private let deferredSleepBlocksKey = "deferredSleepBlocks"
    
    // MARK: - Computed Properties
    
    /// Share için schedule bilgisini formatlar
    var shareScheduleInfo: String {
        let schedule = model.schedule
        let totalHours = schedule.displayTotalSleepHours // Hesaplanan değeri kullan
        let blocksInfo = schedule.schedule.map { block in
            "\(block.startTime) - \(block.endTime) (\(block.isCore ? "Core" : "Nap"))"
        }.joined(separator: "\n")
        
        return """
        📋 Polifazik Uyku Programım: \(schedule.name)
        
        ⏰ Toplam Uyku: \(String(format: "%.1f", totalHours)) saat
        
        🛏️ Uyku Blokları:
        \(blocksInfo)
        
        📱 PolyNap ile kendi uyku programınızı oluşturun!
        """
    }
    
    /// Toplam uyku süresini formatlar
    var totalSleepTimeFormatted: String {
        let totalHours = model.schedule.displayTotalSleepHours // Hesaplanan değeri kullan
        let hours = Int(totalHours)
        let minutes = Int((totalHours - Double(hours)) * 60)
        
        if minutes == 0 {
            return "\(hours)h"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
    
    /// Günlük ilerleme yüzdesini hesaplar
    var dailyProgress: Double {
        let now = Date()
        let calendar = Calendar.current
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = (currentTime.hour ?? 0) * 60 + (currentTime.minute ?? 0)
        
        // Günün yüzde kaçının geçtiğini hesapla
        let totalMinutesInDay = 24 * 60
        return Double(currentMinutes) / Double(totalMinutesInDay)
    }
    
    /// Bir sonraki uyku bloğunun formatlanmış zamanını döndürür
    var nextSleepBlockFormatted: String {
        guard nextSleepBlock != nil else {
            return L("mainScreen.noUpcomingBlock", table: "MainScreen")
        }
        
        let hours = Int(timeUntilNextBlock) / 3600
        let minutes = (Int(timeUntilNextBlock) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return L("mainScreen.imminent", table: "MainScreen")
        }
    }
    
    /// Günlük ipucunu döndürür
    var dailyTip: LocalizedStringKey {
        return DailyTipManager.getDailyTip()
    }
    
    /// Program açıklamasını mevcut dilde döndürür
    var scheduleDescription: String {
        let description = model.schedule.description
        return languageManager.currentLanguage == "tr" ? description.tr : description.en
    }
    
    /// Kullanıcının şu anda uyku zamanında olup olmadığını kontrol eder
    var isInSleepTime: Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = (currentTime.hour ?? 0) * 60 + (currentTime.minute ?? 0)
        
        for block in model.schedule.schedule {
            let startMinutes = convertTimeStringToMinutes(block.startTime)
            let endMinutes = convertTimeStringToMinutes(block.endTime)
            
            // Gece yarısını geçen bloklar için özel kontrol
            if startMinutes > endMinutes {
                // Örn: 23:00 - 07:00
                if currentMinutes >= startMinutes || currentMinutes <= endMinutes {
                    return true
                }
            } else {
                // Normal bloklar
                if currentMinutes >= startMinutes && currentMinutes <= endMinutes {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Uyku durumu mesajını döndürür
    var sleepStatusMessage: String {
        if isInSleepTime {
            return L("mainScreen.sleepTime", table: "MainScreen")
        } else {
            return L("mainScreen.awakeTime", table: "MainScreen")
        }
    }
    
    init(model: MainScreenModel = MainScreenModel(schedule: UserScheduleModel.defaultSchedule), languageManager: LanguageManager = LanguageManager.shared) {
        self.model = model
        self.languageManager = languageManager
        
        loadPremiumStatus()
        loadAvailableSchedules()
        setupTimerForUI()
        setupAuthStateListener()
        setupLanguageChangeListener()
        setupRevenueCatListener()
    }
    
    deinit {
        timerCancellable?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    /// **YENİ:** Sadece UI'daki geri sayım için kullanılan bir zamanlayıcı. Alarm tetiklemez.
    private func setupTimerForUI() {
        updateNextSleepBlockForUI()
        
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateNextSleepBlockForUI()
            }
    }
    
    /// UI için bir sonraki uyku bloğunu günceller
    private func updateNextSleepBlockForUI() {
        let now = Date()
        let calendar = Calendar.current
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = (currentTime.hour ?? 0) * 60 + (currentTime.minute ?? 0)
        
        // Tüm blokları zamanlarına göre sırala
        let sortedBlocks = model.schedule.schedule.sorted { 
            convertTimeStringToMinutes($0.startTime) < convertTimeStringToMinutes($1.startTime) 
        }
        
        // Bir sonraki bloğu bul
        var nextBlock: SleepBlock?
        var timeUntilNext: TimeInterval = 0
        
        for block in sortedBlocks {
            let blockStartMinutes = convertTimeStringToMinutes(block.startTime)
            
            if blockStartMinutes > currentMinutes {
                // Bugün içinde bir sonraki blok
                nextBlock = block
                timeUntilNext = TimeInterval((blockStartMinutes - currentMinutes) * 60)
                break
            }
        }
        
        // Eğer bugün için blok bulunamadıysa, yarının ilk bloğunu al
        if nextBlock == nil, let firstBlock = sortedBlocks.first {
            nextBlock = firstBlock
            let firstBlockMinutes = convertTimeStringToMinutes(firstBlock.startTime)
            let minutesUntilMidnight = (24 * 60) - currentMinutes
            let minutesFromMidnight = firstBlockMinutes
            timeUntilNext = TimeInterval((minutesUntilMidnight + minutesFromMidnight) * 60)
        }
        
        self.nextSleepBlock = nextBlock
        self.timeUntilNextBlock = timeUntilNext
        
        // Tamamlanan blokları kontrol et
        checkAndShowSleepQualityRating()
    }
    
    /// Zaman string'ini dakikaya çevirir (örn: "14:30" -> 870)
    private func convertTimeStringToMinutes(_ timeString: String) -> Int {
        let components = timeString.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return 0 }
        return components[0] * 60 + components[1]
    }

    /// **YENİ:** Alarm yeniden planlamasını tetikleyen tek ve yetkili fonksiyon.
    private func updateAlarms() {
        guard let context = modelContext else {
            print("🚨 MainScreenViewModel: Alarmları güncellemek için ModelContext mevcut değil.")
            return
        }
        Task {
            await AlarmService.shared.rescheduleNotificationsForActiveSchedule(modelContext: context)
        }
    }
    
    /// ModelContext'i ayarlar ve ilk veri yüklemesini + alarm planlamasını tetikler.
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        print("🗂️ MainScreenViewModel: ModelContext ayarlandı.")
        Task {
            await loadScheduleFromRepository()
        }
    }
    
    // MARK: - ViewModel Fonksiyonları

    func addNewBlock() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_GB") // 24 saatlik format için zorla
        let startTime = formatter.string(from: newBlockStartTime)
        
        // Süre hesaplama - gece yarısını geçen bloklar için düzeltme
        var duration = Calendar.current.dateComponents([.minute], from: newBlockStartTime, to: newBlockEndTime).minute ?? 1
        if duration <= 0 {
            // Bitiş zamanı ertesi güne geçiyorsa (23:00 - 02:00 gibi)
            duration = (24 * 60) + duration
        }
        duration = max(1, duration)
        let isCore = newBlockIsCore  // Kullanıcının seçimini koru
        
        let newBlock = SleepBlock(startTime: startTime, duration: duration, type: isCore ? "core" : "nap", isCore: isCore)
        
        var updatedSchedule = model.schedule
        updatedSchedule.schedule.append(newBlock)
        updatedSchedule.schedule.sort { convertTimeStringToMinutes($0.startTime) < convertTimeStringToMinutes($1.startTime) }
        
        // Toplam uyku saatini güncelle
        updatedSchedule.totalSleepHours = updatedSchedule.calculatedTotalSleepHours
        
        self.model.schedule = updatedSchedule
        
        showAddBlockSheet = false
        resetNewBlockValues()
        updateAlarms()
        
        // Değişiklikleri kalıcı olarak kaydet
        Task {
            await saveSchedule()
        }
    }
    
    func updateBlock() {
        guard let blockId = editingBlockId else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_GB") // 24 saatlik format için zorla
        let startTime = formatter.string(from: editingBlockStartTime)
        
        // Süre hesaplama - gece yarısını geçen bloklar için düzeltme
        var duration = Calendar.current.dateComponents([.minute], from: editingBlockStartTime, to: editingBlockEndTime).minute ?? 1
        if duration <= 0 {
            // Bitiş zamanı ertesi güne geçiyorsa (23:00 - 02:00 gibi)
            duration = (24 * 60) + duration
        }
        duration = max(1, duration)
        let isCore = editingBlockIsCore  // Kullanıcının seçimini koru
        
        if let index = model.schedule.schedule.firstIndex(where: { $0.id == blockId }) {
            var updatedBlock = SleepBlock(startTime: startTime, duration: duration, type: isCore ? "core" : "nap", isCore: isCore)
            // Eski bloğun ID'sini koru
            updatedBlock.id = blockId
            
            var updatedSchedule = model.schedule
            updatedSchedule.schedule[index] = updatedBlock
            updatedSchedule.schedule.sort { convertTimeStringToMinutes($0.startTime) < convertTimeStringToMinutes($1.startTime) }
            
            // Toplam uyku saatini güncelle
            updatedSchedule.totalSleepHours = updatedSchedule.calculatedTotalSleepHours
            
            self.model.schedule = updatedSchedule
            
            editingBlockId = nil
            updateAlarms()
            
            // Değişiklikleri kalıcı olarak kaydet
            Task {
                await saveSchedule()
            }
        }
    }
    
    func deleteBlock(_ block: SleepBlock) {
        var updatedSchedule = model.schedule
        updatedSchedule.schedule.removeAll { $0.id == block.id }
        
        // Toplam uyku saatini güncelle
        updatedSchedule.totalSleepHours = updatedSchedule.calculatedTotalSleepHours
        
        self.model.schedule = updatedSchedule
        
        Task {
            await deleteSleepEntriesForBlock(blockId: block.id.uuidString)
        }
        updateAlarms()
        
        // Değişiklikleri kalıcı olarak kaydet
        Task {
            await saveSchedule()
        }
    }


    
    // MARK: - Sleep Entry Management
    /// Belirli bir bloğa ait olan SleepEntry'leri siler
    private func deleteSleepEntriesForBlock(blockId: String) async {
        guard let modelContext = modelContext else { return }
        
        await MainActor.run {
            do {
                // Bu bloğa ait olan tüm SleepEntry'leri bul
                let predicate = #Predicate<SleepEntry> { entry in
                    entry.blockId == blockId
                }
                let descriptor = FetchDescriptor(predicate: predicate)
                let entriesToDelete = try modelContext.fetch(descriptor)
                
                // Bulunan entry'leri sil
                for entry in entriesToDelete {
                    modelContext.delete(entry)
                }
                
                // Değişiklikleri kaydet
                try modelContext.save()
                
                print("✅ Silinen bloğa ait \(entriesToDelete.count) SleepEntry başarıyla silindi")
            } catch {
                print("❌ SleepEntry'ler silinirken hata: \(error)")
            }
        }
    }
    
    private func saveSchedule() async {
        guard selectedSchedule != nil else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Veritabanına kaydet
            _ = try await Repository.shared.saveSchedule(model.schedule)
                        
            // Bildirimleri güncelle
            await ScheduleManager.shared.activateSchedule(model.schedule)
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            print("✅ Program başarıyla kaydedildi")
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Program kaydedilirken hata oluştu: \(error.localizedDescription)"
                self.isLoading = false
            }
            
        }
    }
    
    private func saveContext() {
        guard let context = modelContext else { return }
        do {
            try context.save()
        } catch {
            print("Error saving changes: \(error)")
        }
    }
    
    /// Uyku bloğu tamamlandığında uyku kalitesi değerlendirmesini göster
    private func checkAndShowSleepQualityRating() {
        // Eğer uyku kalitesi değerlendirmesi zaten gösteriliyorsa, tekrar kontrol etme
        guard !showSleepQualityRating else { return }
        
        // Yeni biten blokları kontrol et
        checkForNewCompletedBlocks()
    }
    

    
    private func saveSleepQuality(rating: Int, startTime: Date, endTime: Date) {
        // Repository kullanarak uyku girdisini kaydet
        Task {
            do {
                // lastSleepBlock?.id UUID tipinde, bunu String'e dönüştürüyoruz
                let blockIdString: String
                if let sleepBlock = lastSleepBlock {
                    blockIdString = sleepBlock.id.uuidString // UUID'yi String'e dönüştür
                } else {
                    blockIdString = UUID().uuidString // Yeni bir UUID oluştur ve String'e dönüştür
                }
                
                let emoji = rating >= 4 ? "😄" : (rating >= 3 ? "😊" : (rating >= 2 ? "😐" : (rating >= 1 ? "😪" : "😩")))
                
                _ = try await Repository.shared.addSleepEntry(
                    blockId: blockIdString, // String olarak gönderiyoruz
                    emoji: emoji,
                    rating: rating,
                    date: startTime
                )
                print("✅ Uyku girdisi bildirimden başarıyla kaydedildi, rating: \(rating)")
            } catch {
                print("❌ Uyku girdisi bildirimden kaydedilirken hata: \(error.localizedDescription)")
            }
        }
        
        SleepQualityNotificationManager.shared.removePendingRating(startTime: startTime, endTime: endTime)
    }
    
    /// Uyku kalitesi değerlendirmesinin tamamlandığını işaretler (puanlandığında)
    /// Bu metot, SleepQualityRatingView'dan "Kaydet" butonuna basıldığında çağrılır
    func markSleepQualityRatingAsCompleted() {
        guard let lastBlock = lastSleepBlock else { return }
        
        // Bu bloğu puanlanmış bloklar listesine ekle (start-end time ile)
        addBlockToRatedList(startTime: lastBlock.startTime, endTime: lastBlock.endTime)
        
        // Eğer ertelenmiş listede varsa, oradan kaldır
        removeBlockFromDeferredList(startTime: lastBlock.startTime, endTime: lastBlock.endTime)
        
        showSleepQualityRating = false
        print("📝 Uyku bloğu \(lastBlock.startTime)-\(lastBlock.endTime) puanlandı ve tamamlandı olarak işaretlendi.")
    }
    
    /// Uyku kalitesi değerlendirmesini erteler ("Daha Sonra" butonuna basıldığında)
    func deferSleepQualityRating() {
        guard let lastBlock = lastSleepBlock else { return }
        
        // Bu bloğu ertelenmiş bloklar listesine ekle
        addBlockToDeferredList(startTime: lastBlock.startTime, endTime: lastBlock.endTime)
        
        showSleepQualityRating = false
        print("⏸️ Uyku bloğu \(lastBlock.startTime)-\(lastBlock.endTime) değerlendirmesi ertelendi.")
    }
    
    // MARK: - UserDefaults Helper Functions
    
    /// Block için unique key oluşturur (start-end time ile)
    private func blockKey(startTime: String, endTime: String) -> String {
        return "\(startTime)-\(endTime)"
    }
    
    /// Bloğu puanlanmış bloklar listesine ekler
    private func addBlockToRatedList(startTime: String, endTime: String) {
        var ratedBlocks = UserDefaults.standard.stringArray(forKey: ratedSleepBlocksKey) ?? []
        let blockKey = blockKey(startTime: startTime, endTime: endTime)
        if !ratedBlocks.contains(blockKey) {
            ratedBlocks.append(blockKey)
            UserDefaults.standard.set(ratedBlocks, forKey: ratedSleepBlocksKey)
            print("✅ Block rated olarak işaretlendi: \(blockKey)")
        }
    }
    
    /// Bloğu ertelenmiş bloklar listesine ekler
    private func addBlockToDeferredList(startTime: String, endTime: String) {
        var deferredBlocks = UserDefaults.standard.stringArray(forKey: deferredSleepBlocksKey) ?? []
        let blockKey = blockKey(startTime: startTime, endTime: endTime)
        if !deferredBlocks.contains(blockKey) {
            deferredBlocks.append(blockKey)
            UserDefaults.standard.set(deferredBlocks, forKey: deferredSleepBlocksKey)
            print("⏸️ Block deferred olarak işaretlendi: \(blockKey)")
        }
    }
    
    /// Bloğu ertelenmiş bloklar listesinden kaldırır
    private func removeBlockFromDeferredList(startTime: String, endTime: String) {
        var deferredBlocks = UserDefaults.standard.stringArray(forKey: deferredSleepBlocksKey) ?? []
        let blockKey = blockKey(startTime: startTime, endTime: endTime)
        deferredBlocks.removeAll { $0 == blockKey }
        UserDefaults.standard.set(deferredBlocks, forKey: deferredSleepBlocksKey)
        print("🗑️ Block deferred listesinden kaldırıldı: \(blockKey)")
    }
    
    /// Bloğun puanlanıp puanlanmadığını kontrol eder
    private func isBlockRated(startTime: String, endTime: String) -> Bool {
        let ratedBlocks = UserDefaults.standard.stringArray(forKey: ratedSleepBlocksKey) ?? []
        let blockKey = blockKey(startTime: startTime, endTime: endTime)
        return ratedBlocks.contains(blockKey)
    }
    
    /// Bloğun ertelenip ertelenmediğini kontrol eder
    private func isBlockDeferred(startTime: String, endTime: String) -> Bool {
        let deferredBlocks = UserDefaults.standard.stringArray(forKey: deferredSleepBlocksKey) ?? []
        let blockKey = blockKey(startTime: startTime, endTime: endTime)
        return deferredBlocks.contains(blockKey)
    }
    
    /// Uygulama başlangıcında bekleyen değerlendirmeleri kontrol eder
    private func checkForPendingSleepQualityRatings() {
        let now = Date()
        let calendar = Calendar.current
        
        // Son 24 saat içinde biten uyku bloklarını kontrol et
        for block in model.schedule.schedule {
            let endTime = TimeFormatter.time(from: block.endTime)!
            let endDate = calendar.date(
                bySettingHour: endTime.hour,
                minute: endTime.minute,
                second: 0,
                of: now
            ) ?? now
            
            // Eğer blok son 24 saat içinde bittiyse
            if endDate <= now && now.timeIntervalSince(endDate) <= 86400 { // 24 saat
                // Eğer bu blok puanlanmamışsa ve ertelenmişse, değerlendirme ekranını göster
                if !isBlockRated(startTime: block.startTime, endTime: block.endTime) && 
                   isBlockDeferred(startTime: block.startTime, endTime: block.endTime) {
                    lastSleepBlock = block
                    showSleepQualityRating = true
                    print("🔄 Ertelenmiş uyku bloğu değerlendirmesi gösteriliyor: \(block.startTime)-\(block.endTime)")
                    break // Bir tane göster, diğerleri sonra
                }
            }
        }
    }
    
    /// Timer'da çağrılan, yeni biten blokları kontrol eden fonksiyon
    private func checkForNewCompletedBlocks() {
        let now = Date()
        let calendar = Calendar.current
        _ = calendar.dateComponents([.hour, .minute], from: now)
        
        // Son 5 dakika içinde biten blokları kontrol et
        for block in model.schedule.schedule {
            let endTime = TimeFormatter.time(from: block.endTime)!
            let endDate = calendar.date(
                bySettingHour: endTime.hour,
                minute: endTime.minute,
                second: 0,
                of: now
            ) ?? now
            
            let blockKey = blockKey(startTime: block.startTime, endTime: block.endTime)
            _ = now.timeIntervalSince(endDate)
            
            // Eğer blok az önce bittiyse (son 1 dakika içinde)
            if endDate <= now && now.timeIntervalSince(endDate) <= 60 { // 1 dakika

                
                // Eğer bu bloğu daha önce kontrol etmediyseysek
                if lastCheckedCompletedBlock != blockKey {
                    
                    // 🚨 UYKU BLOĞU BİTİMİ ALARM SİSTEMİ: Sadece foreground'da alarm tetikle
                    Task {
                        let applicationState = await UIApplication.shared.applicationState
                        
                        if applicationState == .active {
                            // Sadece uygulama ön plandayken instant alarm tetikle
                            if let context = modelContext, let alarmSettings = getAlarmSettings(context: context) {
                                if alarmSettings.isEnabled {
                                    print("🚨 UYKU BLOĞU BİTİMİ ALARMI (FOREGROUND): Tetikleniyor... Block: \(block.startTime)-\(block.endTime)")
                                    await AlarmService.shared.triggerAlarmForEndedBlock(block: block, settings: alarmSettings)
                                } else {
                                    print("🔇 UYKU BLOĞU BİTİMİ: Alarm kapalı, tetiklenmedi.")
                                }
                            } else {
                                print("⚠️ UYKU BLOĞU BİTİMİ: Alarm ayarları bulunamadı, tetiklenemedi.")
                            }
                        } else {
                            print("🔍 UYKU BLOĞU BİTİMİ (BACKGROUND): Scheduled alarm'a güveniyoruz, instant oluşturulmadı.")
                        }
                    }
                    
                    // Eğer bu blok hiç puanlanmamışsa ve ertelenmemişse, değerlendirme ekranını göster
                    if !isBlockRated(startTime: block.startTime, endTime: block.endTime) && 
                       !isBlockDeferred(startTime: block.startTime, endTime: block.endTime) {
                        lastSleepBlock = block
                        lastCheckedCompletedBlock = blockKey
                        showSleepQualityRating = true
                        print("🆕 Yeni biten uyku bloğu değerlendirmesi gösteriliyor: \(block.startTime)-\(block.endTime)")
                        break // Bir tane göster, diğerleri sonra
                    } else {
                        // Block rated/deferred ise, checked olarak işaretle
                        lastCheckedCompletedBlock = blockKey

                    }
                } else {

                }
            }
        }
    }
    
    // MARK: - SwiftData Helper
    
    private func getAlarmSettings(context: ModelContext) -> AlarmSettings? {
        do {
            let descriptor = FetchDescriptor<AlarmSettings>()
            return try context.fetch(descriptor).first
        } catch {
            print("🚨 Alarm ayarları alınırken hata: \(error)")
            return nil
        }
    }
    
    // MARK: - Repository & Offline-First Yaklaşımı
    
    /// Repository'den aktif uyku programını yükler
    func loadScheduleFromRepository() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let activeSchedule = try await Repository.shared.getActiveSchedule() {
                await MainActor.run {
                    // Total sleep hours'ı güncelle
                    var updatedSchedule = activeSchedule
                    updatedSchedule.totalSleepHours = updatedSchedule.calculatedTotalSleepHours
                    
                    self.selectedSchedule = updatedSchedule
                    self.model = MainScreenModel(schedule: updatedSchedule)
                    self.isLoading = false
                    self.updateAlarms()
                }
            } else {
                // Aktif program bulunamadı, varsayılan programı yükle (sadece UI için, kaydetme)
                await MainActor.run {
                    print("⚠️ Aktif program bulunamadı, varsayılan program UI'ya yükleniyor...")
                    let defaultSchedule = UserScheduleModel.defaultSchedule
                    self.selectedSchedule = defaultSchedule
                    self.model = MainScreenModel(schedule: defaultSchedule)
                    self.isLoading = false
                    self.errorMessage = nil
                    self.updateAlarms()
                }
                
                // NOT: Varsayılan programı otomatik olarak kaydetmiyoruz çünkü sonsuz döngü oluşuyor
                // Kullanıcı onboarding yapmadıysa onboarding'e yönlendirilecek
                // Eğer onboarding yapıldıysa kullanıcı manuel olarak bir program seçebilir
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Program yüklenirken hata: \(error.localizedDescription)"
                self.isLoading = false
                
                // Hata durumunda da varsayılan programı UI'ya yükle
                let defaultSchedule = UserScheduleModel.defaultSchedule
                self.selectedSchedule = defaultSchedule
                self.model = MainScreenModel(schedule: defaultSchedule)
                self.updateAlarms()
            }
        }
    }
    
    /// Varsayılan uyku programını yükler
    @MainActor
    func loadDefaultSchedule() {
        // UserScheduleModel.defaultSchedule özelliğini kullan
        let defaultSchedule = UserScheduleModel.defaultSchedule
        
        // Model'i güncelle
        self.model.schedule = defaultSchedule
        
        // Yerel veritabanına kaydet
        saveScheduleToLocalDatabase(defaultSchedule)
    }
    
    /// Yerel veritabanından programı yükler
    private func loadScheduleFromLocalDatabase() {
        guard let modelContext = modelContext else { return }
        
        do {
            if let savedSchedule = try modelContext.fetch(FetchDescriptor<SleepScheduleStore>()).first {
                self.model.schedule = UserScheduleModel(
                    id: savedSchedule.scheduleId,
                    name: savedSchedule.name,
                    description: savedSchedule.scheduleDescription,
                    totalSleepHours: savedSchedule.totalSleepHours,
                    schedule: savedSchedule.schedule,
                    isPremium: savedSchedule.isPremium
                )
            } else {
                // Yerel veritabanında program yoksa varsayılan programı yükle
                loadDefaultSchedule()
            }
        } catch {
            loadDefaultSchedule()
        }
    }
    
    /// Programı yerel veritabanına kaydeder
    private func saveScheduleToLocalDatabase(_ schedule: UserScheduleModel) {
        guard let modelContext = modelContext else { return }
        
        do {
            // Mevcut kayıtları temizle
            let existingSchedules = try modelContext.fetch(FetchDescriptor<SleepScheduleStore>())
            for existingSchedule in existingSchedules {
                modelContext.delete(existingSchedule)
            }
            
            // Yeni programı kaydet
            let scheduleStore = SleepScheduleStore(
                scheduleId: schedule.id,
                name: schedule.name,
                scheduleDescription: schedule.description,
                totalSleepHours: schedule.totalSleepHours,
                schedule: schedule.schedule,
                isPremium: schedule.isPremium
            )
            
            modelContext.insert(scheduleStore)
            try modelContext.save()
        } catch {
            print("PolyNap Debug: Yerel veritabanına program kaydetme hatası: \(error)")
        }
    }
    
    /// Kullanıcı giriş durumunu takip eder ve çevrimiçi olduğunda veriyi yükler
    private func setupAuthStateListener() {
        authManager.$isAuthenticated
            .receive(on: RunLoop.main)
            .sink { [weak self] isAuthenticated in
                Task {
                    await self?.loadScheduleFromRepository()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Dil değişikliklerini dinler ve UI'yi günceller
    private func setupLanguageChangeListener() {
        languageManager.$currentLanguage
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }
    
    private func resetNewBlockValues() {
        newBlockStartTime = Date()
        newBlockEndTime = Date().addingTimeInterval(3600)
        newBlockIsCore = false
    }
    
    // MARK: - Schedule Management
    
    /// Premium durumunu yükler (RevenueCat'den gerçek premium durumu)
    private func loadPremiumStatus() {
        isPremium = RevenueCatManager.shared.userState == .premium
        print("🔄 MainScreenViewModel: RevenueCat premium durumu: \(isPremium)")
    }
    
    /// Kullanıcının görebileceği schedule'ları yükler
    private func loadAvailableSchedules() {
        availableSchedules = SleepScheduleService.shared.getAvailableSchedules(isPremium: isPremium)
    }


    
    /// Schedule seçim sheet'ini gösterir
    func showScheduleSelectionSheet() {
        loadAvailableSchedules()
        showScheduleSelection = true
    }
    
    /// Yeni schedule seçildiğinde çağrılır
    func selectSchedule(_ schedule: SleepScheduleModel) {
        // Repository için UUID formatında ID oluştur (karşılaştırma için)
        let scheduleUUID = generateDeterministicUUID(from: schedule.id)
        let repositoryCompatibleId = scheduleUUID.uuidString
        
        // Schedule zaten seçili ise işlem yapma (UUID formatında karşılaştır)
        guard model.schedule.id != repositoryCompatibleId else {
            print("🔄 Aynı schedule zaten seçili: \(schedule.name) (UUID: \(repositoryCompatibleId))")
            return
        }
        
        // Loading state'i set et
        isLoading = true
        errorMessage = nil
        
        // LocalizedDescription'ı UserScheduleModel için uygun formata dönüştür
        let description = LocalizedDescription(
            en: schedule.description.en,
            tr: schedule.description.tr
        )
        
        // Schedule blocks'ları kontrollü şekilde kopyala ve validate et
        let scheduleBlocks = schedule.schedule.map { block in
            SleepBlock(
                startTime: block.startTime,
                duration: block.duration,
                type: block.type,
                isCore: block.isCore
            )
        }
        
        // Data validation
        print("🔍 Schedule validation başlıyor...")
        print("   - Original ID: \(schedule.id)")
        print("   - UUID ID: \(repositoryCompatibleId)")
        print("   - Name: \(schedule.name)")
        print("   - Description EN: \(description.en)")
        print("   - Description TR: \(description.tr)")
        print("   - Total Hours: \(schedule.totalSleepHours)")
        print("   - Block Count: \(scheduleBlocks.count)")
        print("   - Is Premium: \(schedule.isPremium)")
        
        // Her block için validation
        for (index, block) in scheduleBlocks.enumerated() {
            print("   - Block \(index): \(block.startTime)-\(block.endTime), \(block.duration)min, \(block.type), core:\(block.isCore)")
        }
        
        let userScheduleModel = UserScheduleModel(
            id: repositoryCompatibleId, // UUID formatında ID kullan
            name: schedule.name,
            description: description,
            totalSleepHours: schedule.totalSleepHours,
            schedule: scheduleBlocks,
            isPremium: schedule.isPremium
        )
        
        // Model'i hemen güncelle (UI feedback için)
        model.schedule = userScheduleModel
        selectedSchedule = userScheduleModel
        
        print("🔄 Schedule dönüştürme tamamlandı: \(userScheduleModel.name), \(userScheduleModel.schedule.count) blok")
        
        // Asenkron kaydetme işlemi
        Task {
            do {
                print("💾 Repository'ye kaydetme başlıyor...")
                
                // Veritabanına kaydet
                let savedSchedule = try await Repository.shared.saveSchedule(userScheduleModel)
                
                print("✅ Repository kaydetme başarılı!")
                
                // Bildirimleri güncelle
                await ScheduleManager.shared.activateSchedule(userScheduleModel)
                
                await MainActor.run {
                    isLoading = false
                    print("✅ Yeni schedule başarıyla seçildi ve kaydedildi: \(schedule.name)")
                    print("📊 Kaydedilen schedule: \(savedSchedule.name), \(userScheduleModel.schedule.count) blok")
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Program kaydedilirken hata oluştu. Tekrar deneyin."
                    print("❌ Schedule kaydetme hatası: \(error)")
                    print("📋 Hatalı schedule detayları: ID=\(userScheduleModel.id), Name=\(userScheduleModel.name)")
                    
                    // Hata detayını logla
                    if let repositoryError = error as? RepositoryError {
                        print("🔍 Repository Error Details: \(repositoryError)")
                    }
                    
                    // Error description'ı da logla
                    print("🔍 Error Description: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// String ID'den deterministik UUID oluşturur
    private func generateDeterministicUUID(from stringId: String) -> UUID {
        let namespace = UUID(uuidString: "6BA7B810-9DAD-11D1-80B4-00C04FD430C8")!
        let data = stringId.data(using: .utf8)!
        // Simplified hash for example
        var digest = [UInt8](repeating: 0, count: 16)
        let namespaceBytes = withUnsafeBytes(of: namespace.uuid) { Array($0) }
        for (index, byte) in (namespaceBytes + Array(data)).enumerated() {
            digest[index % 16] ^= byte
        }
        digest[6] = (digest[6] & 0x0F) | 0x50; digest[8] = (digest[8] & 0x3F) | 0x80
        return NSUUID(uuidBytes: digest) as UUID
    }
    
    // MARK: - Premium Status Listener
    

    
    /// RevenueCat durum değişikliklerini dinler
    private func setupRevenueCatListener() {
        revenueCatManager.$userState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userState in
                self?.isPremium = userState == .premium
                self?.loadAvailableSchedules()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation Methods
    
    /// Yeni uyku bloğunu validate eder
    func validateNewBlock() -> Bool {
        // Başlangıç ve bitiş zamanlarını kontrol et
        let startTime = newBlockStartTime
        let endTime = newBlockEndTime
        
        // Süre hesaplama - gece yarısını geçen bloklar için düzeltme
        var duration = Calendar.current.dateComponents([.minute], from: startTime, to: endTime).minute ?? 0
        if duration <= 0 {
            // Bitiş zamanı ertesi güne geçiyorsa (23:00 - 02:00 gibi)
            duration = (24 * 60) + duration
        }
        
        // Minimum süre kontrolü (5 dakika)
        if duration < 5 {
            blockErrorMessage = L("sleepBlock.validation.minimumDuration", table: "MainScreen")
            showBlockError = true
            return false
        }
        
        // Çakışma kontrolü
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_GB") // 24 saatlik format için zorla
        let newStartTimeString = formatter.string(from: startTime)
        let newEndTimeString = formatter.string(from: endTime)
        
        if hasTimeConflict(startTime: newStartTimeString, endTime: newEndTimeString, excludeBlockId: nil) {
            blockErrorMessage = L("sleepBlock.validation.timeConflict", table: "MainScreen")
            showBlockError = true
            return false
        }
        
        return true
    }
    
    /// Düzenlenen uyku bloğunu validate eder
    func validateEditingBlock() -> Bool {
        guard let blockId = editingBlockId else { return false }
        
        // Başlangıç ve bitiş zamanlarını kontrol et
        let startTime = editingBlockStartTime
        let endTime = editingBlockEndTime
        
        // Süre hesaplama - gece yarısını geçen bloklar için düzeltme
        var duration = Calendar.current.dateComponents([.minute], from: startTime, to: endTime).minute ?? 0
        if duration <= 0 {
            // Bitiş zamanı ertesi güne geçiyorsa (23:00 - 02:00 gibi)
            duration = (24 * 60) + duration
        }
        
        // Minimum süre kontrolü (5 dakika)
        if duration < 5 {
            blockErrorMessage = L("sleepBlock.validation.minimumDuration", table: "MainScreen")
            showBlockError = true
            return false
        }
        
        // Çakışma kontrolü (düzenlenen bloğu hariç tut)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_GB") // 24 saatlik format için zorla
        let newStartTimeString = formatter.string(from: startTime)
        let newEndTimeString = formatter.string(from: endTime)
        
        if hasTimeConflict(startTime: newStartTimeString, endTime: newEndTimeString, excludeBlockId: blockId) {
            blockErrorMessage = L("sleepBlock.validation.timeConflict", table: "MainScreen")
            showBlockError = true
            return false
        }
        
        return true
    }
    
    /// Zaman çakışması olup olmadığını kontrol eder
    private func hasTimeConflict(startTime: String, endTime: String, excludeBlockId: UUID?) -> Bool {
        let newStartMinutes = convertTimeStringToMinutes(startTime)
        let newEndMinutes = convertTimeStringToMinutes(endTime)
        
        for block in model.schedule.schedule {
            // Eğer bu düzenlenen blok ise atla
            if let excludeId = excludeBlockId, block.id == excludeId {
                continue
            }
            
            let blockStartMinutes = convertTimeStringToMinutes(block.startTime)
            let blockEndMinutes = convertTimeStringToMinutes(block.endTime)
            
            // Çakışma kontrolü için normalize edilmiş time ranges kullan
            if hasOverlap(
                newStart: newStartMinutes, newEnd: newEndMinutes,
                existingStart: blockStartMinutes, existingEnd: blockEndMinutes
            ) {
                return true
            }
        }
        
        return false
    }
    
    /// İki zaman aralığının çakışıp çakışmadığını kontrol eder (gece yarısını geçen blokları da destekler)
    private func hasOverlap(newStart: Int, newEnd: Int, existingStart: Int, existingEnd: Int) -> Bool {
        // Gece yarısını geçen blokları tespit et
        let newCrossesMiddnight = newEnd <= newStart
        let existingCrossesMiddnight = existingEnd <= existingStart
        
        if !newCrossesMiddnight && !existingCrossesMiddnight {
            // İki blok da normal (gece yarısını geçmiyor)
            return newStart < existingEnd && newEnd > existingStart
        }
        
        if newCrossesMiddnight && !existingCrossesMiddnight {
            // Yeni blok gece yarısını geçiyor, mevcut blok geçmiyor
            // Yeni blok: [newStart, 1440) ∪ [0, newEnd]
            // Mevcut blok: [existingStart, existingEnd]
            let overlapPart1 = newStart < existingEnd && 1440 > existingStart  // [newStart, 1440) ile [existingStart, existingEnd]
            let overlapPart2 = 0 < existingEnd && newEnd > existingStart       // [0, newEnd] ile [existingStart, existingEnd]
            return overlapPart1 || overlapPart2
        }
        
        if !newCrossesMiddnight && existingCrossesMiddnight {
            // Yeni blok gece yarısını geçmiyor, mevcut blok geçiyor
            // Yeni blok: [newStart, newEnd]
            // Mevcut blok: [existingStart, 1440) ∪ [0, existingEnd]
            let overlapPart1 = newStart < 1440 && newEnd > existingStart       // [newStart, newEnd] ile [existingStart, 1440)
            let overlapPart2 = newStart < existingEnd && newEnd > 0            // [newStart, newEnd] ile [0, existingEnd]
            return overlapPart1 || overlapPart2
        }
        
        // Her iki blok da gece yarısını geçiyor
        // Yeni blok: [newStart, 1440) ∪ [0, newEnd]
        // Mevcut blok: [existingStart, 1440) ∪ [0, existingEnd]
        let overlapPart1 = newStart < 1440 && 1440 > existingStart           // [newStart, 1440) ile [existingStart, 1440)
        let overlapPart2 = 0 < existingEnd && newEnd > 0                     // [0, newEnd] ile [0, existingEnd]
        let overlapPart3 = newStart < existingEnd && 1440 > 0                // [newStart, 1440) ile [0, existingEnd]
        let overlapPart4 = 0 < 1440 && newEnd > existingStart               // [0, newEnd] ile [existingStart, 1440)
        return overlapPart1 || overlapPart2 || overlapPart3 || overlapPart4
    }
    
    /// Düzenleme için bloğu hazırlar
    func prepareForEditing(_ block: SleepBlock) {
        editingBlockId = block.id
        
        // Mevcut zamanları Date formatına dönüştür
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_GB") // 24 saatlik format için zorla
        
        let calendar = Calendar.current
        let now = Date()
        
        if let startTime = formatter.date(from: block.startTime) {
            let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
            editingBlockStartTime = calendar.date(bySettingHour: startComponents.hour ?? 0, minute: startComponents.minute ?? 0, second: 0, of: now) ?? now
        }
        
        if let endTime = formatter.date(from: block.endTime) {
            let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
            var endDate = calendar.date(bySettingHour: endComponents.hour ?? 0, minute: endComponents.minute ?? 0, second: 0, of: now) ?? now
            
            // Eğer bitiş zamanı başlangıç zamanından önce ise (gece yarısını geçen blok), ertesi güne kaydır
            if endDate <= editingBlockStartTime {
                endDate = calendar.date(byAdding: .day, value: 1, to: endDate) ?? endDate
            }
            
            editingBlockEndTime = endDate
        }
        
        editingBlockIsCore = block.isCore
    }
}

