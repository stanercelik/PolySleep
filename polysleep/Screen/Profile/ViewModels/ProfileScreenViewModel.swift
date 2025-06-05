import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class ProfileScreenViewModel: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var totalSleepSessions: Int = 0
    @Published var successRate: Double = 0.0
    @Published var adaptationPhase: Int = 0
    @Published var activeScheduleName: String = ""
    @Published var totalSleepHours: Double = 0.0
    @Published var selectedCoreEmoji: String = "🌙"
    @Published var selectedNapEmoji: String = "💤"
    @Published var activeSchedule: UserSchedule? = nil
    @Published var adaptationDuration: Int = 21 // Varsayılan 21 gün
    
    // Debug ve Undo özellikleri
    @Published var showingUndoScheduleChange: Bool = false
    @Published var showingAdaptationDebug: Bool = false
    @Published var debugAdaptationDay: Int = 1
    
    private let languageManager: LanguageManager

    // Yeni eklenen hesaplanmış özellik
    var adaptationPhaseDescription: String {
        switch adaptationPhase {
        case 0:
            return L("profile.adaptation.phase.day1", table: "Profile") // "1. Gün - Başlangıç"
        case 1:
            return L("profile.adaptation.phase.initial", table: "Profile") // "İlk Adaptasyon (2-7. günler)"
        case 2:
            return L("profile.adaptation.phase.middle", table: "Profile") // "Orta Adaptasyon (8-14. günler)"
        case 3:
            return L("profile.adaptation.phase.advanced", table: "Profile") // "İlerlemiş Adaptasyon (15-21. günler)"
        case 4:
            return L("profile.adaptation.phase.final", table: "Profile") // "Son Adaptasyon (22-28. günler)"
        case 5...:
            return L("profile.adaptation.phase.complete", table: "Profile") // "Adaptasyon Tamamlandı"
        default:
            return L("profile.adaptation.phase.unknown", table: "Profile")
        }
    }
    
    // Adaptasyon tamamlandı mı kontrol et
    var isAdaptationCompleted: Bool {
        guard let schedule = activeSchedule else { return false }
        
        let calendar = Calendar.current
        let startDate = schedule.updatedAt
        let currentDate = Date()
        
        let startOfStartDate = calendar.startOfDay(for: startDate)
        let startOfCurrentDate = calendar.startOfDay(for: currentDate)
        
        let components = calendar.dateComponents([.day], from: startOfStartDate, to: startOfCurrentDate)
        let daysPassed = components.day ?? 0
        let currentDay = daysPassed + 1
        
        return currentDay >= adaptationDuration
    }
    
    // Tamamlanan gün sayısı
    var completedAdaptationDays: Int {
        guard let schedule = activeSchedule else { return 0 }
        
        let calendar = Calendar.current
        let startDate = schedule.updatedAt
        let currentDate = Date()
        
        let startOfStartDate = calendar.startOfDay(for: startDate)
        let startOfCurrentDate = calendar.startOfDay(for: currentDate)
        
        let components = calendar.dateComponents([.day], from: startOfStartDate, to: startOfCurrentDate)
        let daysPassed = components.day ?? 0
        
        return daysPassed + 1
    }

    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext? = nil, languageManager: LanguageManager = LanguageManager.shared) {
        self.languageManager = languageManager
        self.modelContext = modelContext
        if modelContext != nil {
            loadData()
        }
        loadEmojiPreferences()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadData()
    }
    
    func loadData() {
        guard let context = modelContext else { 
            print("ProfileScreenViewModel: ModelContext yüklenemedi, loadData iptal edildi.")
            return
        }
        
        do {
            let descriptor = FetchDescriptor<HistoryModel>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            let historyItems = try context.fetch(descriptor)
            calculateStreak(from: historyItems)
        } catch {
            print("Profildeki streak verileri yüklenirken hata: \(error)")
        }
        
        // Undo data durumunu kontrol et
        objectWillChange.send()
        
        Task {
            await loadActiveSchedule()
        }
    }
    
    private func resetScheduleUI() {
        self.activeScheduleName = ""
        self.adaptationPhase = 0
        self.totalSleepHours = 0
        self.activeSchedule = nil
        self.adaptationDuration = 21
    }

    // Aktif uyku programını ve adaptasyon aşamasını yükle
    private func loadActiveSchedule() async {
        guard let context = modelContext else {
            print("ProfileScreenViewModel: ModelContext bulunamadı, aktif program yüklenemiyor.")
            await MainActor.run { resetScheduleUI() }
            return
        }

        guard let currentUserIdString = AuthManager.shared.currentUser?.id,
              let currentUserId = UUID(uuidString: currentUserIdString) else {
            print("ProfileScreenViewModel: Geçerli kullanıcı ID\'si bulunamadı.")
            await MainActor.run { resetScheduleUI() }
            return
        }
            
        print("ProfileScreenViewModel: Aktif program yükleniyor, Kullanıcı ID: \\(currentUserId.uuidString)")

        do {
            // Repository üzerinden aktif programı çek
            let activeScheduleEntity = try Repository.shared.getActiveUserSchedule(userId: currentUserId, context: context)

            await MainActor.run {
                if let scheduleData = activeScheduleEntity {
                    print("ProfileScreenViewModel: Aktif program bulundu ve UI güncelleniyor: \\(scheduleData.name)")
                    self.activeSchedule = scheduleData
                    self.activeScheduleName = scheduleData.name
                    
                    let scheduleNameLowercased = scheduleData.name.lowercased()
                    if scheduleNameLowercased.contains("uberman") || 
                       scheduleNameLowercased.contains("dymaxion") ||
                       (scheduleNameLowercased.contains("everyman") && scheduleNameLowercased.contains("1")) {
                        self.adaptationDuration = 28
                    } else {
                        self.adaptationDuration = 21
                    }
                    
                    let calculatedPhase = self.calculateAdaptationPhase(schedule: scheduleData)
                    self.adaptationPhase = calculatedPhase
                    
                    // Eğer hesaplanan faz, veritabanındaki fazdan farklıysa güncelle
                    // Bu, adaptasyonun doğal ilerlemesini sağlar
                    if calculatedPhase != scheduleData.adaptationPhase {
                        print("ProfileScreenViewModel: Adaptasyon fazı güncelleniyor. Eski: \(scheduleData.adaptationPhase), Yeni: \(calculatedPhase)")
                        
                        Task {
                            do {
                                // Repository üzerinden güncelle
                                try Repository.shared.updateUserScheduleAdaptationPhase(
                                    scheduleId: scheduleData.id,
                                    newPhase: calculatedPhase,
                                    context: context
                                )
                                print("ProfileScreenViewModel: Adaptasyon aşaması Repository üzerinden güncellendi.")
                                
                                // Local schedule objesini de güncelle
                                scheduleData.adaptationPhase = calculatedPhase
                                
                            } catch {
                                print("ProfileScreenViewModel: Adaptasyon aşaması güncellenirken hata: \(error)")
                            }
                        }
                    }
                    self.totalSleepHours = scheduleData.totalSleepHours ?? 0.0
                } else {
                    print("ProfileScreenViewModel: Aktif program bulunamadı.")
                    self.resetScheduleUI()
                }
            }
        } catch {
            print("ProfileScreenViewModel: Aktif program Repository veya SwiftData ile yüklenirken hata: \\(error)")
            await MainActor.run { self.resetScheduleUI() }
        }
    }
    
    private func calculateAdaptationPhase(schedule: UserSchedule) -> Int {
        let currentDate = Date()
        let startDate = schedule.updatedAt
        
        let calendar = Calendar.current
        
        // İki tarih arasındaki tam gün farkını hesapla
        let startOfStartDate = calendar.startOfDay(for: startDate)
        let startOfCurrentDate = calendar.startOfDay(for: currentDate)
        
        let components = calendar.dateComponents([.day], from: startOfStartDate, to: startOfCurrentDate)
        let daysPassed = components.day ?? 0
        
        // 1. gün = adaptasyon başladığı gün (daysPassed = 0)
        // 2. gün = bir sonraki gün (daysPassed = 1)
        // vs.
        let currentDay = daysPassed + 1
        
        print("ProfileScreenViewModel: Adaptasyon hesaplama - Başlangıç: \(startDate), Şu an: \(currentDate), Geçen günler: \(daysPassed), Mevcut gün: \(currentDay)")
        
        let totalDuration = self.adaptationDuration
        let phase: Int
        
        if totalDuration == 28 {
            // 28 günlük programlar için (Uberman, Dymaxion, Everyman 1)
            switch currentDay {
            case 1:
                phase = 0  // İlk gün - Başlangıç
            case 2...7:
                phase = 1  // 2-7. günler - İlk Adaptasyon
            case 8...14:
                phase = 2  // 8-14. günler - Orta Adaptasyon
            case 15...21:
                phase = 3  // 15-21. günler - İlerlemiş Adaptasyon
            case 22...28:
                phase = 4  // 22-28. günler - İleri Adaptasyon
            default:
                phase = 5  // 28+ günler - Tamamlanmış
            }
        } else {
            // 21 günlük programlar için (diğer programlar)
            switch currentDay {
            case 1:
                phase = 0  // İlk gün - Başlangıç
            case 2...7:
                phase = 1  // 2-7. günler - İlk Adaptasyon
            case 8...14:
                phase = 2  // 8-14. günler - Orta Adaptasyon
            case 15...21:
                phase = 3  // 15-21. günler - İlerlemiş Adaptasyon
            default:
                phase = 4  // 21+ günler - Tamamlanmış
            }
        }
        
        print("ProfileScreenViewModel: Hesaplanan faz: \(phase)")
        return phase
    }

    private func calculateStreak(from history: [HistoryModel]) {
        guard !history.isEmpty else {
            currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")
            longestStreak = UserDefaults.standard.integer(forKey: "longestStreak")
            return
        }

        var current = 0
        var longest = 0
        var lastDate: Date? = nil

        for entry in history.sorted(by: { $0.date > $1.date }) {
            guard let last = lastDate else {
                current = 1
                lastDate = entry.date
                continue
            }

            if Calendar.current.isDate(entry.date, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: last)!) {
                current += 1
            } else if !Calendar.current.isDate(entry.date, inSameDayAs: last) {
                current = 1
            }
            lastDate = entry.date
            if current > longest {
                longest = current
            }
        }
        
        // currentStreak'i UserDefaults'a kaydet
        UserDefaults.standard.set(current, forKey: "currentStreak")
        self.currentStreak = current
        
        let storedLongestStreak = UserDefaults.standard.integer(forKey: "longestStreak")
        if longest > storedLongestStreak {
            UserDefaults.standard.set(longest, forKey: "longestStreak")
            self.longestStreak = longest
        } else {
            self.longestStreak = storedLongestStreak
        }
    }
    
    // MARK: - Emoji Tercihleri
    
    // Emoji kaydetme fonksiyonu - ProfileScreenView içinde kullanılıyor
    func saveEmojiPreference(coreEmoji: String? = nil, napEmoji: String? = nil) {
        if let core = coreEmoji {
            self.selectedCoreEmoji = core
        }
        if let nap = napEmoji {
            self.selectedNapEmoji = nap
        }
        
        // Tercihleri UserDefaults'a kaydet
        saveEmojiPreferences()
        
        print("Emoji tercihleri kaydedildi. Core: \(selectedCoreEmoji), Nap: \(selectedNapEmoji)")
    }
    
    // UserDefaults'a emoji tercihlerini kaydet
    private func saveEmojiPreferences() {
        UserDefaults.standard.set(selectedCoreEmoji, forKey: "selectedCoreEmoji")
        UserDefaults.standard.set(selectedNapEmoji, forKey: "selectedNapEmoji")
    }

    private func loadEmojiPreferences() {
        if let coreEmoji = UserDefaults.standard.string(forKey: "selectedCoreEmoji") {
            selectedCoreEmoji = coreEmoji
        }
        if let napEmoji = UserDefaults.standard.string(forKey: "selectedNapEmoji") {
            selectedNapEmoji = napEmoji
        }
    }
    
    // MARK: - Adaptasyon Fazı Yönetimi
    
    // Adaptasyon fazını sıfırlama fonksiyonu - ProfileScreenView içinde kullanılıyor
    func resetAdaptationPhase() async throws {
        guard let context = modelContext, 
              let currentScheduleId = activeSchedule?.id else { // scheduleId'yi aktif programdan al
            throw ProfileError.noActiveSchedule
        }
        
        do {
            // UserSchedule'ı ID ile çek
            let predicate = #Predicate<UserSchedule> { $0.id == currentScheduleId }
            var fetchDescriptor = FetchDescriptor(predicate: predicate)
            fetchDescriptor.fetchLimit = 1
            
            guard let scheduleToUpdate = try context.fetch(fetchDescriptor).first else {
                print("ProfileScreenViewModel: Güncellenecek program SwiftData'da bulunamadı.")
                throw ProfileError.scheduleUpdateFailed
            }

            // Adaptasyonu bugünden başlat (1. gün)
            scheduleToUpdate.adaptationPhase = 0  // İlk faz (1. gün)
            scheduleToUpdate.updatedAt = Date()   // Şu anki zaman - adaptasyon bugün başlıyor
            
            try context.save()
            
            // UI'ı güncelle
            await MainActor.run {
                self.adaptationPhase = 0  // UI'da da ilk fazdan başlat
                self.activeSchedule = scheduleToUpdate // Güncellenmiş schedule'ı ata
            }
            
            print("Adaptasyon fazı başarıyla sıfırlandı - Bugünden (1. gün) başlatıldı.")
            
        } catch {
            print("Adaptasyon fazı sıfırlanırken SwiftData hatası: \(error.localizedDescription)")
            throw ProfileError.saveFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Undo ve Debug Metodları
    
    /// Schedule değişimini geri al
    func undoScheduleChange() async throws {
        do {
            try await Repository.shared.undoScheduleChange()
            await loadActiveSchedule()
            // Streak'i yeniden yükle
            if let context = modelContext {
                let descriptor = FetchDescriptor<HistoryModel>(sortBy: [SortDescriptor(\.date, order: .reverse)])
                let historyItems = try context.fetch(descriptor)
                calculateStreak(from: historyItems)
            }
        } catch {
            throw error
        }
    }
    
    /// Undo verisi mevcut mu kontrol et
    func hasUndoData() -> Bool {
        return Repository.shared.hasUndoData()
    }
    
    /// Adaptasyon debug günü ayarla
    func setAdaptationDebugDay(_ dayNumber: Int) async throws {
        guard let scheduleId = activeSchedule?.id else {
            throw ProfileError.noActiveSchedule
        }
        
        do {
            try await Repository.shared.setAdaptationDebugDay(scheduleId: scheduleId, dayNumber: dayNumber)
            await loadActiveSchedule()
        } catch {
            throw error
        }
    }
    
    /// Debug için maksimum gün sayısını hesapla
    var maxDebugDays: Int {
        return adaptationDuration + 7 // Adaptasyon süresi + 7 gün extra
    }
}

// MARK: - Hata Tipleri
enum ProfileError: Error, LocalizedError {
    case noActiveSchedule
    case saveFailed(String)
    case scheduleUpdateFailed
    
    var errorDescription: String? {
        switch self {
        case .noActiveSchedule:
            return "Sıfırlanacak aktif bir uyku programı bulunamadı."
        case .saveFailed(let reason):
            return "Kaydetme başarısız: \(reason)"
        case .scheduleUpdateFailed:
            return "Program güncellenemedi."
        }
    }
}

// Eğer UserSchedule.scheduleDescription (eski JSONB) kullanılacaksa
// ve bu bir LocalizedDescription struct'ına decode edilecekse,
// bu struct'ın Codable olması gerekir.
// struct LocalizedDescription: Codable {
// var en: String
// var tr: String
// }
