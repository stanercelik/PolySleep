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
    @Published private var sleepQualityRatingCompleted = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var modelContext: ModelContext?
    private var timer: Timer?
    private var timerCancellable: AnyCancellable?
    private var languageManager: LanguageManager
    
    private let authManager = AuthManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(model: MainScreenModel = MainScreenModel(schedule: UserScheduleModel.defaultSchedule), languageManager: LanguageManager = LanguageManager.shared) {
        self.model = model
        self.languageManager = languageManager
        
        // Timer'ı başlat
        startTimer()
        
        // Auth durumunu dinle
        setupAuthStateListener()
        
        // Dil değişikliklerini dinle
        setupLanguageChangeListener()
    }
    
    var totalSleepTimeFormatted: String {
        let totalMinutes = model.schedule.schedule.reduce(0) { $0 + $1.duration }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%dh %02dm", hours, minutes)
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
        
        let locale = Locale.current.language.languageCode?.identifier ?? "en"
        if locale == "tr" {
            if hours > 0 {
                return "\(hours)s \(minutes)dk"
            } else {
                return "\(minutes)dk"
            }
        } else {
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
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
            
            if hours > 0 {
                return String(format: L("mainScreen.sleepTimeRemaining", table: "MainScreen"), "\(hours)", "\(minutes)")
            } else {
                return String(format: L("mainScreen.sleepTimeRemainingMinutes", table: "MainScreen"), "\(minutes)")
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
        
        // --- Bildirimleri Güncelle ---
        print("deleteBlock: Bildirimler güncelleniyor...")
        ScheduleManager.shared.activateSchedule(updatedSchedule)
        // --- Bitti ---
        
        // Değişiklikleri kaydet
        Task {
            await saveSchedule()
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
        // Eğer uyku kalitesi değerlendirmesi zaten tamamlandıysa, tekrar gösterme
        guard !showSleepQualityRating, !hasDeferredSleepQualityRating, !sleepQualityRatingCompleted else { return }
        
        let now = Date()
        // Son 30 dakika içinde biten bir uyku bloğu var mı kontrol et
        if let lastBlock = model.schedule.schedule.first(where: { block in
            let endTime = TimeFormatter.time(from: block.endTime)!
            let endDate = Calendar.current.date(
                bySettingHour: endTime.hour,
                minute: endTime.minute,
                second: 0,
                of: now
            ) ?? now
            return endDate <= now && now.timeIntervalSince(endDate) <= 1800 // 30 dakika
        }) {
            lastSleepBlock = lastBlock
            showSleepQualityRating = true
        }
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
    
    /// Uyku kalitesi değerlendirmesinin tamamlandığını işaretler
    /// Bu metot, SleepQualityRatingView'dan çağrılır
    func markSleepQualityRatingAsCompleted() {
        sleepQualityRatingCompleted = true
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
        print("PolySleep Debug: Varsayılan program yükleniyor")
        
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
            print("PolySleep Debug: Yerel veritabanından program yükleme hatası: \(error)")
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
            print("PolySleep Debug: Yerel veritabanına program kaydetme hatası: \(error)")
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
}
