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
                // Düzenleme modundan çıkıldığında değişiklikleri kaydet
                Task {
                    await saveSchedule()
                }
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
    @Published var lastCheckedCompletedBlock: String? // Son kontrol edilen bloğu tutmak için
    @Published var showScheduleSelection = false // Schedule seçimi sheet'ini kontrol eder
    @Published var availableSchedules: [SleepScheduleModel] = [] // Kullanıcının görebileceği schedule'lar
    @Published var isPremium: Bool = false // Premium durumunu takip eder

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var modelContext: ModelContext?
    private var timer: Timer?
    private var timerCancellable: AnyCancellable?
    private var languageManager: LanguageManager
    
    private let authManager = AuthManager.shared
    private var cancellables = Set<AnyCancellable>()
    private let revenueCatManager = RevenueCatManager.shared
    
    // UserDefaults için anahtarlar
    private let ratedSleepBlocksKey = "ratedSleepBlocks" // Puanlanmış bloklar (start-end time ile)
    private let deferredSleepBlocksKey = "deferredSleepBlocks" // Ertelenmiş bloklar (start-end time ile)
    
    init(model: MainScreenModel = MainScreenModel(schedule: UserScheduleModel.defaultSchedule), languageManager: LanguageManager = LanguageManager.shared) {
        self.model = model
        self.languageManager = languageManager
        
        // Premium durumunu kontrol et
        loadPremiumStatus()
        
        // Mevcut schedule'ları yükle
        loadAvailableSchedules()
        
        // Timer'ı başlat
        startTimer()
        
        // Auth durumunu dinle
        setupAuthStateListener()
        
        // Dil değişikliklerini dinle
        setupLanguageChangeListener()
        
        // Uyku kalitesi değerlendirme durumunu kontrol et
        checkForPendingSleepQualityRatings()
        
        // RevenueCat premium durum değişikliklerini dinle
        setupRevenueCatListener()
    }
    
    var totalSleepTimeFormatted: String {
        let totalMinutes = model.schedule.schedule.reduce(0) { $0 + $1.duration }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 && minutes > 0 {
            return String(format: L("mainScreen.timeFormat.hoursMinutes", table: "MainScreen"), "\(hours)", "\(minutes)")
        } else if hours > 0 {
            return String(format: L("mainScreen.timeFormat.hoursOnly", table: "MainScreen"), "\(hours)")
        } else {
            return String(format: L("mainScreen.timeFormat.minutesOnly", table: "MainScreen"), "\(minutes)")
        }
    }
    
    var scheduleDescription: String {
        let currentLang = languageManager.currentLanguage
        if currentLang == "tr" {
            return model.schedule.description.tr
        } else {
            return model.schedule.description.en
        }
    }
    
    var nextSleepBlockFormatted: String {
        guard let _ = model.schedule.nextBlock else {
            return L("mainScreen.nextSleepBlock.none", table: "MainScreen")
        }
        
        let remainingTime = model.schedule.remainingTimeToNextBlock
        let hours = remainingTime / 60
        let minutes = remainingTime % 60
        
        if hours > 0 && minutes > 0 {
            return String(format: L("mainScreen.timeFormat.hoursMinutes", table: "MainScreen"), "\(hours)", "\(minutes)")
        } else if hours > 0 {
            return String(format: L("mainScreen.timeFormat.hoursOnly", table: "MainScreen"), "\(hours)")
        } else {
            return String(format: L("mainScreen.timeFormat.minutesOnly", table: "MainScreen"), "\(minutes)")
        }
    }
    
    var dailyTip: LocalizedStringKey {
        DailyTipManager.getDailyTip()
    }
    
    // Günlük ilerleme hesaplama fonksiyonu
    var dailyProgress: Double {
        calculateDailyProgress()
    }
    
    // Günlük ilerlemeyi hesaplayan fonksiyon
    func calculateDailyProgress() -> Double {
        let todayBlocks = getTodaySleepBlocks()
        
        if todayBlocks.isEmpty {
            return 0.0
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        var completedMinutes = 0
        var totalMinutes = 0
        
        for block in todayBlocks {
            let blockStartDate = combineDateWithTime(date: startOfDay, timeString: block.startTime)
            let blockEndDate = combineDateWithTime(date: startOfDay, timeString: block.endTime)
            
            // Eğer bitiş zamanı başlangıç zamanından önceyse, ertesi güne geçmiş demektir
            var adjustedEndDate = blockEndDate
            if blockEndDate < blockStartDate {
                adjustedEndDate = calendar.date(byAdding: .day, value: 1, to: blockEndDate)!
            }
            
            let blockDuration = Int(adjustedEndDate.timeIntervalSince(blockStartDate) / 60)
            totalMinutes += blockDuration
            
            // Blok tamamlanmış mı kontrol et
            if now > adjustedEndDate {
                // Blok tamamen tamamlanmış
                completedMinutes += blockDuration
            } else if now > blockStartDate {
                // Blok kısmen tamamlanmış
                let completedDuration = Int(now.timeIntervalSince(blockStartDate) / 60)
                completedMinutes += min(completedDuration, blockDuration)
            }
        }
        
        // İlerleme oranını hesapla
        return totalMinutes > 0 ? Double(completedMinutes) / Double(totalMinutes) : 0.0
    }
    
    private func getTodaySleepBlocks() -> [SleepBlock] {
        return model.schedule.schedule
    }
    
    private func combineDateWithTime(date: Date, timeString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        guard let time = dateFormatter.date(from: timeString) else {
            return date
        }
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        return calendar.date(bySettingHour: timeComponents.hour ?? 0, 
                            minute: timeComponents.minute ?? 0, 
                            second: 0, 
                            of: date) ?? date
    }
    
    var dailyReminder: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        if hour < 12 {
            return L("mainScreen.morningReminder", table: "MainScreen")
        } else if hour < 18 {
            return L("mainScreen.afternoonReminder", table: "MainScreen")
        } else {
            return L("mainScreen.eveningReminder", table: "MainScreen")
        }
    }
    
    var isInSleepTime: Bool {
        model.schedule.currentBlock != nil
    }
    
    var sleepStatusMessage: String {
        if isInSleepTime {
            return L("mainScreen.goodNightMessage", table: "MainScreen")
        } else if model.schedule.nextBlock != nil {
            let remainingTime = model.schedule.remainingTimeToNextBlock
            let hours = remainingTime / 60
            let minutes = remainingTime % 60
            
            if hours > 0 && minutes > 0 {
                return String(format: L("mainScreen.sleepTimeRemaining.hoursMinutes", table: "MainScreen"), "\(hours)", "\(minutes)")
            } else if hours > 0 {
                return String(format: L("mainScreen.sleepTimeRemaining.hoursOnly", table: "MainScreen"), "\(hours)")
            } else {
                return String(format: L("mainScreen.sleepTimeRemaining.minutesOnly", table: "MainScreen"), "\(minutes)")
            }
        } else {
            return L("mainScreen.noSleepPlan", table: "MainScreen")
        }
    }
    
    func shareScheduleInfo() -> String {
        var shareText = L("mainScreen.shareTitle", table: "MainScreen") + "\n\n"
        
        shareText += String(format: L("mainScreen.shareSchedule", table: "MainScreen"), model.schedule.name) + "\n"
        shareText += String(format: L("mainScreen.shareTotalSleep", table: "MainScreen"), totalSleepTimeFormatted) + "\n"
        shareText += String(format: L("mainScreen.shareProgress", table: "MainScreen"), "\(Int(dailyProgress * 100))") + "\n\n"
        
        shareText += L("mainScreen.shareSleepBlocks", table: "MainScreen")
        
        for block in model.schedule.schedule {
            let blockType = block.isCore
                ? L("mainScreen.shareCoreSleep", table: "MainScreen")
                : L("mainScreen.shareNap", table: "MainScreen")
            
            shareText += "\n• \(block.startTime)-\(block.endTime) (\(blockType))"
        }
        
        shareText += "\n\n" + L("mainScreen.shareHashtags", table: "MainScreen")
        
        return shareText
    }
    
    deinit {
        timerCancellable?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    /// ModelContext'i ayarlar
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        print("🗂️ MainScreenViewModel: ModelContext ayarlandı.")
        // ModelContext ayarlandıktan sonra yerel veriyi yükle
        Task {
            await loadScheduleFromRepository()
        }
    }
    
    private func loadSavedSchedule() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<SleepScheduleStore>()
            let savedSchedules = try context.fetch(descriptor)
            
            if let latestSchedule = savedSchedules.first {
                let scheduleModel = UserScheduleModel(
                    id: latestSchedule.scheduleId,
                    name: latestSchedule.name,
                    description: latestSchedule.scheduleDescription,
                    totalSleepHours: latestSchedule.totalSleepHours,
                    schedule: latestSchedule.schedule,
                    isPremium: latestSchedule.isPremium
                )
                
                selectedSchedule = scheduleModel
                model = MainScreenModel(schedule: scheduleModel)
                print("✅ Loaded saved schedule: \(scheduleModel.name)")
            }
        } catch {
            print("❌ Error loading saved schedule: \(error)")
        }
    }
    
    private func startTimer() {
        updateNextSleepBlock()
        
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateNextSleepBlock()
                    self?.checkAndShowSleepQualityRating()
                }
            }
    }
    
    private func updateNextSleepBlock() {
        let now = Date()
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = currentComponents.hour! * 60 + currentComponents.minute!
        
        if let next = findNextBlock(currentMinutes: currentMinutes, blocks: model.schedule.schedule) {
            nextSleepBlock = next.block
            timeUntilNextBlock = next.timeUntil
            return
        }
        
        if let firstBlock = model.schedule.schedule.first {
            let minutesUntilMidnight = 24 * 60 - currentMinutes
            let blockStartMinutes = convertTimeStringToMinutes(firstBlock.startTime)
            timeUntilNextBlock = TimeInterval((minutesUntilMidnight + blockStartMinutes) * 60)
            nextSleepBlock = firstBlock
        }
    }
    
    private func findNextBlock(currentMinutes: Int, blocks: [SleepBlock]) -> (block: SleepBlock, timeUntil: TimeInterval)? {
        var nextBlock: SleepBlock?
        var minFutureTimeDifference = Int.max
        
        for block in blocks {
            let startMinutes = convertTimeStringToMinutes(block.startTime)
            var timeDifference = startMinutes - currentMinutes
            
            if timeDifference < 0 {
                timeDifference += 24 * 60
            }
            
            if timeDifference < minFutureTimeDifference {
                minFutureTimeDifference = timeDifference
                nextBlock = block
            }
        }
        
        if let block = nextBlock {
            return (block, TimeInterval(minFutureTimeDifference * 60))
        }
        return nil
    }
    
    private func convertTimeStringToMinutes(_ timeString: String) -> Int {
        let components = timeString.split(separator: "-")
        let startTime = components[0].trimmingCharacters(in: .whitespaces)
        let parts = startTime.split(separator: ":")
        let hours = Int(parts[0])!
        let minutes = Int(parts[1])!
        return hours * 60 + minutes
    }
    
    private func normalizeMinutes(_ minutes: Int) -> Int {
        return (minutes + 24 * 60) % (24 * 60)
    }
    
    private func isOverlapping(start1: Int, end1: Int, start2: Int, end2: Int) -> Bool {
        let normalizedStart1 = normalizeMinutes(start1)
        let normalizedEnd1 = normalizeMinutes(end1)
        let normalizedStart2 = normalizeMinutes(start2)
        let normalizedEnd2 = normalizeMinutes(end2)
        
        // Eğer bitiş başlangıçtan küçükse, gece yarısını geçiyor demektir
        let range1: Set<Int>
        if normalizedEnd1 < normalizedStart1 {
            range1 = Set(normalizedStart1...(24 * 60 - 1)).union(Set(0...normalizedEnd1))
        } else {
            range1 = Set(normalizedStart1...normalizedEnd1)
        }
        
        let range2: Set<Int>
        if normalizedEnd2 < normalizedStart2 {
            range2 = Set(normalizedStart2...(24 * 60 - 1)).union(Set(0...normalizedEnd2))
        } else {
            range2 = Set(normalizedStart2...normalizedEnd2)
        }
        
        return !range1.intersection(range2).isEmpty
    }
    
    // MARK: - Editing Functions
    
    func validateNewBlock() -> Bool {
        // Başlangıç zamanı bitiş zamanından önce olmalı
        if newBlockStartTime >= newBlockEndTime {
            blockErrorMessage = L("sleepBlock.error.invalidTime", table: "MainScreen")
            showBlockError = true
            return false
        }
        
        // Bloklar çakışmamalı
        let newStartMinutes = Calendar.current.component(.hour, from: newBlockStartTime) * 60 + Calendar.current.component(.minute, from: newBlockStartTime)
        let newEndMinutes = Calendar.current.component(.hour, from: newBlockEndTime) * 60 + Calendar.current.component(.minute, from: newBlockEndTime)
        
        for block in model.schedule.schedule {
            let blockStart = convertTimeStringToMinutes(block.startTime)
            let blockEnd = convertTimeStringToMinutes(block.endTime)
            
            if isOverlapping(start1: newStartMinutes, end1: newEndMinutes, start2: blockStart, end2: blockEnd) {
                blockErrorMessage = L("sleepBlock.error.overlap", table: "MainScreen")
                showBlockError = true
                return false
            }
        }
        
        return true
    }
    
    func addNewBlock() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let startTime = formatter.string(from: newBlockStartTime)
        
        let duration = Calendar.current.dateComponents([.minute], from: newBlockStartTime, to: newBlockEndTime).minute ?? 0
        
        // Süreye göre otomatik olarak ana uyku veya şekerleme belirleme
        let isCore = duration >= 45 // 45 dakika ve üzeri ana uyku olarak kabul edilir
        
        let newBlock = SleepBlock(
            startTime: startTime,
            duration: duration,
            type: isCore ? "core" : "nap",
            isCore: isCore
        )
        
        // Yerel model güncelleniyor
        var updatedSchedule = model.schedule
        updatedSchedule.schedule.append(newBlock)
        updatedSchedule.schedule.sort { convertTimeStringToMinutes($0.startTime) < convertTimeStringToMinutes($1.startTime) }
        self.model.schedule = updatedSchedule
        
        // --- Bildirimleri Güncelle ---
        print("addNewBlock: Bildirimler güncelleniyor...")
        ScheduleManager.shared.activateSchedule(updatedSchedule)
        // --- Bitti ---
        
        showAddBlockSheet = false
        resetNewBlockValues()
        
        // Arka planda kaydet
        Task {
            await saveSchedule()
        }
    }
    
    func removeSleepBlock(at offsets: IndexSet) {
        // Yerel model güncelleniyor
        var updatedSchedule = model.schedule
        updatedSchedule.schedule.remove(atOffsets: offsets)
        model.schedule = updatedSchedule
        
        // --- Bildirimleri Güncelle ---
        print("removeSleepBlock: Bildirimler güncelleniyor...")
        ScheduleManager.shared.activateSchedule(updatedSchedule)
        // --- Bitti ---
        
        // Değişiklikleri kaydet
        Task {
            await saveSchedule()
        }
    }
    
    func prepareForEditing(_ block: SleepBlock) {
        editingBlockId = block.id
        editingBlockIsCore = block.isCore
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let startDate = formatter.date(from: block.startTime) {
            editingBlockStartTime = startDate
        }
        
        if let endDate = formatter.date(from: block.endTime) {
            editingBlockEndTime = endDate
        }
    }
    
    func validateEditingBlock() -> Bool {
        // Başlangıç zamanı bitiş zamanından önce olmalı
        if editingBlockStartTime >= editingBlockEndTime {
            blockErrorMessage = L("sleepBlock.error.invalidTime", table: "MainScreen")
            showBlockError = true
            return false
        }
        
        // Bloklar çakışmamalı
        let newStartMinutes = Calendar.current.component(.hour, from: editingBlockStartTime) * 60 + Calendar.current.component(.minute, from: editingBlockStartTime)
        let newEndMinutes = Calendar.current.component(.hour, from: editingBlockEndTime) * 60 + Calendar.current.component(.minute, from: editingBlockEndTime)
        
        for block in model.schedule.schedule {
            // Düzenlenen bloğu atla
            if block.id == editingBlockId {
                continue
            }
            
            let blockStart = convertTimeStringToMinutes(block.startTime)
            let blockEnd = convertTimeStringToMinutes(block.endTime)
            
            if isOverlapping(start1: newStartMinutes, end1: newEndMinutes, start2: blockStart, end2: blockEnd) {
                blockErrorMessage = L("sleepBlock.error.overlap", table: "MainScreen")
                showBlockError = true
                return false
            }
        }
        
        return true
    }
    
    func updateBlock() {
        guard let blockId = editingBlockId else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let startTime = formatter.string(from: editingBlockStartTime)
        
        let duration = Calendar.current.dateComponents([.minute], from: editingBlockStartTime, to: editingBlockEndTime).minute ?? 0
        
        // Süreye göre otomatik olarak ana uyku veya şekerleme belirleme
        let isCore = duration >= 45 // 45 dakika ve üzeri ana uyku olarak kabul edilir
        
        if let index = model.schedule.schedule.firstIndex(where: { $0.id == blockId }) {
            let updatedBlock = SleepBlock(
                startTime: startTime,
                duration: duration,
                type: isCore ? "core" : "nap",
                isCore: isCore
            )
            
            // Yerel model güncelleniyor
            var updatedSchedule = model.schedule
            updatedSchedule.schedule[index] = updatedBlock
            updatedSchedule.schedule.sort { convertTimeStringToMinutes($0.startTime) < convertTimeStringToMinutes($1.startTime) }
            self.model.schedule = updatedSchedule
            
            // --- Bildirimleri Güncelle ---
            print("updateBlock: Bildirimler güncelleniyor...")
            ScheduleManager.shared.activateSchedule(updatedSchedule)
            // --- Bitti ---
            
            editingBlockId = nil // Düzenleme modunu kapat
            
            // Değişiklikleri kaydet
            Task {
                await saveSchedule()
            }
        }
    }
    
    func deleteBlock(_ block: SleepBlock) {
        // Yerel model güncelleniyor
        var updatedSchedule = model.schedule
        updatedSchedule.schedule.removeAll { $0.id == block.id }
        self.model.schedule = updatedSchedule
        
        // Silinen bloğa ait SleepEntry'leri de sil
        Task {
            await deleteSleepEntriesForBlock(blockId: block.id.uuidString)
        }
        
        // --- Bildirimleri Güncelle ---
        print("deleteBlock: Bildirimler güncelleniyor...")
        ScheduleManager.shared.activateSchedule(updatedSchedule)
        // --- Bitti ---
        
        // Değişiklikleri kaydet
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
            ScheduleManager.shared.activateSchedule(model.schedule)
            
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
        let currentComponents = calendar.dateComponents([.hour, .minute], from: now)
        
        // Debug: Hangi blokların kontrol edildiğini göster
        print("PolyNap Debug: Sleep block tamamlanma kontrolü - Şu anki zaman: \(currentComponents.hour!):\(String(format: "%02d", currentComponents.minute!))")
        
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
            let timeDifference = now.timeIntervalSince(endDate)
            
            // Debug: Her block için durumu göster
            if timeDifference >= -60 && timeDifference <= 120 { // Yakın zamanlı blokları debug için göster
                print("PolyNap Debug: Block \(block.startTime)-\(block.endTime) | Bitiş: \(endTime.hour):\(String(format: "%02d", endTime.minute)) | Fark: \(Int(timeDifference))s")
            }
            
            // Eğer blok az önce bittiyse (son 1 dakika içinde)
            if endDate <= now && now.timeIntervalSince(endDate) <= 60 { // 1 dakika
                print("PolyNap Debug: ✅ Sleep block bitimi tespit edildi! Block: \(block.startTime)-\(block.endTime)")
                
                // Eğer bu bloğu daha önce kontrol etmediyseysek
                if lastCheckedCompletedBlock != blockKey {
                    
                    // 🚨 KAPSAMLI ALARM SİSTEMİ: Uyku bloğu bitiminde tüm senaryolar için alarm
                    AlarmService.shared.scheduleComprehensiveAlarmForSleepBlockEnd(date: now, modelContext: modelContext)
                    print("🚨 KAPSAMLI ALARM AKTİF: Sleep block bitti, alarm sistemi tetiklendi: \(block.startTime)-\(block.endTime)")
                    
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
                        print("PolyNap Debug: Block zaten değerlendirilmiş/ertelenmiş, sadece alarm tetiklendi")
                    }
                } else {
                    print("PolyNap Debug: Bu block zaten kontrol edildi: \(blockKey)")
                }
            }
        }
    }
    
    // MARK: - Repository & Offline-First Yaklaşımı
    
    /// Repository'den aktif uyku programını yükler
    func loadScheduleFromRepository() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let activeSchedule = try await Repository.shared.getActiveSchedule() {
                // activeSchedule zaten UserScheduleModel tipinde olduğu için dönüştürmeye gerek yok
                let scheduleModel = activeSchedule
                
                DispatchQueue.main.async {
                    self.selectedSchedule = scheduleModel
                    self.model = MainScreenModel(schedule: scheduleModel)
                    self.isLoading = false
                    
                    // Bildirimleri güncelle
                    // ScheduleManager zaten Repository'den gelen değişikliği gözlemleyebilir
                    // veya burada manuel tetikleme yapılabilir. Şimdilik yorum satırı:
                    // ScheduleManager.shared.activateSchedule(scheduleModel)
                }
                
                print("✅ Repository'den aktif program yüklendi: \(activeSchedule.name)")
            } else {
                // Aktif program yoksa, varsayılanı yükle veya boş durumu göster.
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = L("error.no_active_schedule_found", table: "MainScreen")
                    // Gerekirse burada varsayılan bir program yüklenebilir veya boş ekran gösterilebilir.
                    // self.loadDefaultSchedule() // Örnek
                }
                 print("ℹ️ Repository'de aktif program bulunamadı.")
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = L("error.schedule_load_failed", table: "MainScreen") + ": \(error.localizedDescription)"
                self.isLoading = false
            }
            
            print("❌ Repository'den program yüklenirken hata: \(error)")
        }
    }
    
    /// Varsayılan uyku programını yükler
    @MainActor
    func loadDefaultSchedule() {
        print("PolyNap Debug: Varsayılan program yükleniyor")
        
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
            print("PolyNap Debug: Yerel veritabanından program yükleme hatası: \(error)")
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
        
        // Kullanıcının oturum durumunu dinle
        authManager.$isAuthenticated
            .receive(on: RunLoop.main)
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    // Kullanıcı giriş yaptığında, yerel veritabanından programı yükle
                    Task {
                        await self?.loadScheduleFromRepository()
                    }
                } else {
                    // Kullanıcı çıkış yaptığında, varsayılan programı göster
                    self?.loadDefaultSchedule()
                }
            }
            .store(in: &cancellables)
        
    }
    
    /// Dil değişikliklerini dinler ve UI'yi günceller
    private func setupLanguageChangeListener() {
        languageManager.$currentLanguage
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                // Schedule description güncellenmesi için objectWillChange tetiklenir
                self?.objectWillChange.send()
            }
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
        // RevenueCat'den gerçek premium durumunu al
        isPremium = RevenueCatManager.shared.userState == .premium
        print("🔄 MainScreenViewModel: RevenueCat premium durumu: \(isPremium)")
    }
    
    /// Kullanıcının görebileceği schedule'ları yükler
    private func loadAvailableSchedules() {
        availableSchedules = SleepScheduleService.shared.getAvailableSchedules(isPremium: isPremium)
    }
    

    
    /// Schedule seçim sheet'ini gösterir
    func showScheduleSelectionSheet() {
        loadAvailableSchedules() // En güncel listeyi yükle
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
                ScheduleManager.shared.activateSchedule(userScheduleModel)
                
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
        // PolySleep namespace UUID'si (sabit bir UUID)
        let namespace = UUID(uuidString: "6BA7B810-9DAD-11D1-80B4-00C04FD430C8") ?? UUID()
        
        // String'i Data'ya dönüştür
        let data = stringId.data(using: .utf8) ?? Data()
        
        // MD5 hash ile deterministik UUID oluştur
        var digest = [UInt8](repeating: 0, count: 16)
        
        // Basit hash algoritması (production'da CryptoKit kullanılabilir)
        let namespaceBytes = withUnsafeBytes(of: namespace.uuid) { Array($0) }
        let stringBytes = Array(data)
        
        for (index, byte) in (namespaceBytes + stringBytes).enumerated() {
            digest[index % 16] ^= byte
        }
        
        // UUID'nin version ve variant bitlerini ayarla (version 5 için)
        digest[6] = (digest[6] & 0x0F) | 0x50  // Version 5
        digest[8] = (digest[8] & 0x3F) | 0x80  // Variant 10
        
        // UUID oluştur
        let uuid = NSUUID(uuidBytes: digest) as UUID
        
        print("🔄 Deterministik UUID oluşturuldu: \(stringId) -> \(uuid.uuidString)")
        return uuid
    }
    
    // MARK: - Premium Status Listener
    

    
    /// RevenueCat durum değişikliklerini dinler
    private func setupRevenueCatListener() {
        revenueCatManager.$userState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userState in
                let isPremium = userState == .premium
                self?.isPremium = isPremium
                self?.loadAvailableSchedules()
                print("🔄 RevenueCat Premium durumu güncellendi: \(isPremium)")
            }
            .store(in: &cancellables)
    }
}

