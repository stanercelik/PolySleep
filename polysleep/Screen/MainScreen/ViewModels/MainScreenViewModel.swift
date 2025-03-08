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
    @Published var lastSleepBlock: (start: Date, end: Date)?
    @Published private var sleepQualityRatingCompleted = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var modelContext: ModelContext?
    private var timer: Timer?
    private var timerCancellable: AnyCancellable?
    
    // Supabase servisi referansı
    private var scheduleService: SupabaseScheduleService {
        return SupabaseService.shared.schedule
    }
    
    @StateObject private var authManager = AuthManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(model: MainScreenModel = MainScreenModel(schedule: UserScheduleModel.defaultSchedule)) {
        self.model = model
        
        // Timer'ı başlat
        startTimer()
        
        // Auth durumunu dinle
        setupAuthStateListener()
        
        // Supabase'den veri yükle
        Task {
            // Önce auth durumunun hazır olmasını bekle
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 saniye bekle
            
            // Eğer varsayılan program kullanılıyorsa, Supabase'den veri yüklemeyi dene
            if model.schedule.id == "default" {
                await loadScheduleFromSupabase()
            }
        }
    }
    
    var totalSleepTimeFormatted: String {
        let totalMinutes = model.schedule.schedule.reduce(0) { $0 + $1.duration }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%dh %02dm", hours, minutes)
    }
    
    var scheduleDescription: String {
        let locale = Locale.current.language.languageCode?.identifier ?? "en"
        if locale == "tr" {
            return model.schedule.description.tr
        } else {
            return model.schedule.description.en
        }
    }
    
    var nextSleepBlockFormatted: String {
        guard let _ = model.schedule.nextBlock else {
            return "-"
        }
        
        let remainingTime = model.schedule.remainingTimeToNextBlock
        let hours = remainingTime / 60
        let minutes = remainingTime % 60
        
        if hours > 0 {
            return "\(hours)s \(minutes)dk"
        } else {
            return "\(minutes)dk"
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
            return "Gün içindeki şekerlemeleri kaçırmamak için alarmlarınızı kontrol edin."
        } else if hour < 18 {
            return "Akşam yemeğini uyku bloğundan en az 2 saat önce yemeyi unutmayın."
        } else {
            return "Ana uyku bloğundan önce ekran kullanımını azaltın ve rahatlatıcı bir rutin oluşturun."
        }
    }
    
    var currentStreak: Int {
        // Dummy Value
        return 5
    }
    
    var isInSleepTime: Bool {
        model.schedule.currentBlock != nil
    }
    
    var sleepStatusMessage: String {
        if isInSleepTime {
            return "İyi Uykular! 💤💤"
        } else if model.schedule.nextBlock != nil {
            let remainingTime = model.schedule.remainingTimeToNextBlock
            let hours = remainingTime / 60
            let minutes = remainingTime % 60
            
            if hours > 0 {
                return "Uyku saatine \(hours)s \(minutes)dk kaldı"
            } else {
                return "Uyku saatine \(minutes)dk kaldı"
            }
        } else {
            return "Bugün için uyku planı yok"
        }
    }
    
    func shareScheduleInfo() -> String {
        var shareText = """
        🌙 PolySleep Uyku Programım
        
        📋 Program: \(model.schedule.name)
        ⏰ Toplam Uyku: \(totalSleepTimeFormatted)
        🔄 Mevcut Seri: \(currentStreak) gün
        📊 Günlük İlerleme: %\(Int(dailyProgress * 100))
        
        🛏️ Uyku Blokları:
        """
        
        for block in model.schedule.schedule {
            shareText += "\n• \(block.startTime)-\(block.endTime) (\(block.isCore ? "Ana Uyku" : "Şekerleme"))"
        }
        
        shareText += "\n\n#PolySleep #UykuDüzeni"
        
        return shareText
    }
    
    deinit {
        timerCancellable?.cancel()
    }
    
    /// ModelContext'i ayarlar
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        
        // Supabase'den verileri yükle
        Task {
            await loadScheduleFromSupabase()
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
            blockErrorMessage = "sleepBlock.error.invalidTime"
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
                blockErrorMessage = "sleepBlock.error.overlap"
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
        let isCore = duration >= 180 // 3 saat ve üzeri ana uyku olarak kabul edilir
        
        let newBlock = SleepBlock(
            startTime: startTime,
            duration: duration,
            type: isCore ? "core" : "nap",
            isCore: isCore
        )
        
        model.schedule.schedule.append(newBlock)
        model.schedule.schedule.sort { convertTimeStringToMinutes($0.startTime) < convertTimeStringToMinutes($1.startTime) }
        
        Task {
            await saveSchedule()
        }
    }
    
    func removeSleepBlock(at offsets: IndexSet) {
        var updatedSchedule = model.schedule
        updatedSchedule.schedule.remove(atOffsets: offsets)
        model.schedule = updatedSchedule
        
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
            blockErrorMessage = "sleepBlock.error.invalidTime"
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
                blockErrorMessage = "sleepBlock.error.overlap"
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
        
        if let index = model.schedule.schedule.firstIndex(where: { $0.id == blockId }) {
            let updatedBlock = SleepBlock(
                startTime: startTime,
                duration: duration,
                type: editingBlockIsCore ? "core" : "nap",
                isCore: editingBlockIsCore
            )
            
            model.schedule.schedule[index] = updatedBlock
            model.schedule.schedule.sort { convertTimeStringToMinutes($0.startTime) < convertTimeStringToMinutes($1.startTime) }
            
            Task {
                await saveSchedule()
            }
        }
    }
    
    func deleteBlock(_ block: SleepBlock) {
        model.schedule.schedule.removeAll { $0.id == block.id }
        
        
        Task {
            await saveSchedule()
        }
    }
    
    private func saveSchedule() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Programı Supabase'e kaydet
            let success = try await scheduleService.saveRecommendedSchedule(
                schedule: model.schedule.toSleepScheduleModel,
                adaptationPeriod: model.currentDay
            )
            
            if !success {
                print("PolySleep Debug: Program Supabase'e kaydedilemedi, yerel veritabanına kaydediliyor")
                
                // Yerel veritabanına kaydet
                saveScheduleToLocalDatabase(model.schedule)
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
        } catch {
            print("PolySleep Debug: Supabase'e program kaydedilemedi: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = NSLocalizedString("supabase.error.sync", comment: "")
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
            let startTime = TimeFormatter.time(from: lastBlock.startTime)!
            let endTime = TimeFormatter.time(from: lastBlock.endTime)!
            
            let startDate = Calendar.current.date(
                bySettingHour: startTime.hour,
                minute: startTime.minute,
                second: 0,
                of: now
            ) ?? now
            
            let endDate = Calendar.current.date(
                bySettingHour: endTime.hour,
                minute: endTime.minute,
                second: 0,
                of: now
            ) ?? now
            
            lastSleepBlock = (start: startDate, end: endDate)
            showSleepQualityRating = true
        }
    }
    
    private func saveSleepQuality(rating: Int, startTime: Date, endTime: Date) {
        // TODO: Implement actual save functionality
        print("Sleep quality saved from notification: \(rating)")
        SleepQualityNotificationManager.shared.removePendingRating(startTime: startTime, endTime: endTime)
    }
    
    /// Uyku kalitesi değerlendirmesinin tamamlandığını işaretler
    /// Bu metot, SleepQualityRatingView'dan çağrılır
    func markSleepQualityRatingAsCompleted() {
        sleepQualityRatingCompleted = true
    }
    
    /// Supabase'den aktif uyku programını ve bloklarını yükler
    @MainActor
    func loadScheduleFromSupabase() async {
        isLoading = true
        errorMessage = nil
        
        // Kullanıcının oturum açıp açmadığını kontrol et
        if !authManager.isAuthenticated {
            print("PolySleep Debug: Kullanıcı oturumu kapalı, varsayılan program kullanılıyor")
            loadDefaultSchedule()
            isLoading = false
            return
        }
        
        do {
            print("PolySleep Debug: Supabase'den aktif program yükleniyor...")
            
            // Aktif programı getir
            let activeSchedule = try await scheduleService.getActiveSchedule()
            
            if let schedule = activeSchedule {
                print("PolySleep Debug: Aktif program bulundu, bloklar yükleniyor...")
                
                // Program bloklarını getir
                let blocks = try await scheduleService.getSleepBlocksForSchedule(scheduleId: schedule.id)
                
                if !blocks.isEmpty {
                    print("PolySleep Debug: \(blocks.count) adet program bloğu yüklendi")
                    
                    // UserScheduleModel'e dönüştür
                    let userScheduleModel = schedule.toUserScheduleModel(with: blocks)
                    
                    // Model'i güncelle
                    self.model.schedule = userScheduleModel
                    
                    // Yerel veritabanına kaydet
                    saveScheduleToLocalDatabase(userScheduleModel)
                    isLoading = false
                    return
                } else {
                    print("PolySleep Debug: Program blokları bulunamadı, varsayılan program kullanılacak")
                }
            } else {
                print("PolySleep Debug: Aktif program bulunamadı, yerel veritabanı kontrol ediliyor")
                
                // Yerel veritabanından programı yüklemeyi dene
                loadScheduleFromLocalDatabase()
                
                // Yerel veritabanında program yoksa ve model varsayılan programı kullanıyorsa
                if model.schedule.id == "default" {
                    print("PolySleep Debug: Yerel veritabanında program bulunamadı, varsayılan program Supabase'e kaydedilecek")
                    
                    // Varsayılan programı Supabase'e kaydet
                    let success = try await scheduleService.saveRecommendedSchedule(
                        schedule: UserScheduleModel.defaultSchedule.toSleepScheduleModel,
                        adaptationPeriod: model.currentDay
                    )
                    
                    if success {
                        print("PolySleep Debug: Varsayılan program Supabase'e kaydedildi")
                    } else {
                        print("PolySleep Debug: Varsayılan program Supabase'e kaydedilemedi")
                    }
                }
            }
            
            isLoading = false
        } catch {
            print("PolySleep Debug: Supabase'den program yüklenirken hata oluştu: \(error)")
            
            // Hata durumunda yerel veritabanından yüklemeyi dene
            loadScheduleFromLocalDatabase()
            
            DispatchQueue.main.async {
                self.errorMessage = NSLocalizedString("supabase.error.sync", comment: "")
                self.isLoading = false
            }
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
    
    /// Uyku programını Supabase'e kaydeder
    func saveScheduleToSupabase() async {
        do {
            // Programı Supabase'e kaydet
            _ = try await scheduleService.saveRecommendedSchedule(
                schedule: model.schedule.toSleepScheduleModel,
                adaptationPeriod: model.currentDay
            )
            
            // Başarılı kayıt sonrası yerel veritabanına da kaydet
            saveScheduleToLocalDatabase(model.schedule)
        } catch {
            print("PolySleep Debug: Supabase'e kayıt hatası: \(error)")
            errorMessage = "supabase.error.sync"
        }
    }
    
    private func setupAuthStateListener() {
        authManager.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    print("PolySleep Debug: Kullanıcı oturumu açıldı, veriler yükleniyor...")
                    // Kullanıcı giriş yaptığında veriyi yükle
                    Task {
                        await self?.loadScheduleFromSupabase()
                    }
                } else {
                    print("PolySleep Debug: Kullanıcı oturumu kapalı, varsayılan program kullanılıyor")
                }
            }
            .store(in: &cancellables)
    }
}
