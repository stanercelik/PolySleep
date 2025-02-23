import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class MainScreenViewModel: ObservableObject {
    @Published var model: MainScreenModel
    @Published var isEditing: Bool = false {
        didSet {
            if !isEditing {
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
    
    private var modelContext: ModelContext?
    private var timer: Timer?
    private var timerCancellable: AnyCancellable?
    
    var totalSleepTimeFormatted: String {
        let totalMinutes = model.schedule.schedule.reduce(0) { $0 + $1.duration }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%dh %02dm", hours, minutes)
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
    
    var dailyTip: String {
        "Düzenli uyku saatleri bağışıklık sisteminizi güçlendirir."
    }
    
    var dailyProgress: Double {
        // Dummy Value
        0.65
    }
    
    var currentStreak: Int {
        // Dummy Value
        return 5
    }
    
    init(model: MainScreenModel = MainScreenModel(schedule: UserScheduleModel.defaultSchedule), modelContext: ModelContext? = nil) {
        self.model = model
        self.modelContext = modelContext
        startTimer()

        if let context = modelContext {
            do {
                if let savedSchedule = try context.fetch(FetchDescriptor<SleepScheduleStore>()).first {
                    self.model.schedule = UserScheduleModel(
                        id: savedSchedule.scheduleId,
                        name: savedSchedule.name,
                        description: savedSchedule.scheduleDescription,
                        totalSleepHours: savedSchedule.totalSleepHours,
                        schedule: savedSchedule.schedule
                    )
                }
            } catch {
                print("Error fetching saved schedule: \(error)")
            }
        }
    }
    
    deinit {
        timerCancellable?.cancel()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        
        do {
            if let savedSchedule = try context.fetch(FetchDescriptor<SleepScheduleStore>()).first {
                self.model.schedule = UserScheduleModel(
                    id: savedSchedule.scheduleId,
                    name: savedSchedule.name,
                    description: savedSchedule.scheduleDescription,
                    totalSleepHours: savedSchedule.totalSleepHours,
                    schedule: savedSchedule.schedule
                )
            }
        } catch {
            print("Error fetching saved schedule: \(error)")
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
                    schedule: latestSchedule.schedule
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
            blockErrorMessage = String(localized: "sleepBlock.error.invalidTime")
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
                blockErrorMessage = String(localized: "sleepBlock.error.overlap")
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
        
        // Eğer schedule adı değiştirilmemişse ve blok eklendiyse
        if !model.schedule.name.contains(String(localized: "schedule.customized")) {
            model.schedule.name += " " + String(localized: "schedule.customized")
        }
        
        Task {
            await saveSchedule()
        }
    }
    
    func removeSleepBlock(at offsets: IndexSet) {
        var updatedSchedule = model.schedule
        updatedSchedule.schedule.remove(atOffsets: offsets)
        model.schedule = updatedSchedule
        
        if !model.schedule.name.contains(String(localized: "schedule.customized")) {
            model.schedule.name += " " + String(localized: "schedule.customized")
        }
        
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
            blockErrorMessage = String(localized: "sleepBlock.error.invalidTime")
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
                blockErrorMessage = String(localized: "sleepBlock.error.overlap")
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
            
            if !model.schedule.name.contains(String(localized: "schedule.customized")) {
                model.schedule.name += " " + String(localized: "schedule.customized")
            }
            
            Task {
                await saveSchedule()
            }
        }
    }
    
    func deleteBlock(_ block: SleepBlock) {
        model.schedule.schedule.removeAll { $0.id == block.id }
        
        if !model.schedule.name.contains(String(localized: "schedule.customized")) {
            model.schedule.name += " " + String(localized: "schedule.customized")
        }
        
        Task {
            await saveSchedule()
        }
    }
    
    func startTitleEditing() {
        editingTitle = model.schedule.name
        isEditingTitle = true
    }
    
    func saveTitleChanges() {
        if !editingTitle.isEmpty {
            // Eğer isim zaten özelleştirilmiş ibaresini içeriyorsa, direkt olarak yeni ismi kullan
            if model.schedule.name.contains(String(localized: "schedule.customized")) {
                model.schedule.name = editingTitle
            } else {
                // İlk kez değiştiriliyorsa özelleştirilmiş ibaresini ekle
                model.schedule.name = editingTitle + " " + String(localized: "schedule.customized")
            }
            isEditingTitle = false
            Task {
                await saveSchedule()
            }
        }
    }
    
    func cancelTitleEditing() {
        editingTitle = model.schedule.name
        isEditingTitle = false
    }
    
    private func saveSchedule() async {
        guard let context = modelContext else { return }
        
        do {
            // Mevcut schedule'ı bul veya yeni oluştur
            let descriptor = FetchDescriptor<SleepScheduleStore>()
            let existingSchedules = try context.fetch(descriptor)
            let scheduleStore = existingSchedules.first ?? SleepScheduleStore(
                scheduleId: model.schedule.id,
                name: model.schedule.name,
                scheduleDescription: model.schedule.description,
                totalSleepHours: model.schedule.totalSleepHours,
                schedule: model.schedule.schedule
            )
            
            // Değerleri güncelle
            scheduleStore.scheduleId = model.schedule.id
            scheduleStore.name = model.schedule.name
            scheduleStore.scheduleDescription = model.schedule.description
            scheduleStore.totalSleepHours = model.schedule.totalSleepHours
            scheduleStore.schedule = model.schedule.schedule
            
            if existingSchedules.isEmpty {
                context.insert(scheduleStore)
            }
            
            try context.save()
        } catch {
            print("Schedule kaydetme hatası: \(error)")
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
}
