import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class ProfileScreenViewModel: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var selectedCoreEmoji: String = "🌙"
    @Published var selectedNapEmoji: String = "⚡"
    @Published var activeScheduleName: String = ""
    @Published var adaptationPhase: Int = 0
    @Published var totalSleepHours: Double = 0.0
    @Published var activeSchedule: UserSchedule? = nil
    @Published var adaptationDuration: Int = 21 // Varsayılan 21 gün
    
    // Yeni eklenen hesaplanmış özellik
    var adaptationPhaseDescription: String {
        switch adaptationPhase {
        case 0:
            return NSLocalizedString("adaptation.phase.0", tableName: "Common", comment: "Adaptation Phase 0: Initial")
        case 1:
            return NSLocalizedString("adaptation.phase.1", tableName: "Common", comment: "Adaptation Phase 1: Adjustment")
        case 2:
            return NSLocalizedString("adaptation.phase.2", tableName: "Common", comment: "Adaptation Phase 2: Adaptation")
        case 3:
            return NSLocalizedString("adaptation.phase.3", tableName: "Common", comment: "Adaptation Phase 3: Advanced Adaptation")
        case 4:
            return NSLocalizedString("adaptation.phase.4", tableName: "Common", comment: "Adaptation Phase 4: Full Adaptation")
        case 5...:
            return NSLocalizedString("adaptation.phase.5", tableName: "Common", comment: "Adaptation Phase 5: Complete Adaptation")
        default:
            return NSLocalizedString("adaptation.phase.unknown", tableName: "Common", comment: "Adaptation Phase Unknown")
        }
    }

    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext? = nil) {
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
    
    private func loadData() {
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
                    
                    // Eğer hesaplanan faz, veritabanındaki fazdan farklıysa ve bu bir tutarsızlık değil de
                    // 'günlük kontrol' sonucu bir ilerleme ise güncelle.
                    // Bu mantık, fazın yalnızca gün geçtikçe artmasını sağlar.
                    // Eğer faz manuel olarak sıfırlanmışsa (updatedAt güncellenir), calculateAdaptationPhase doğru sonucu verir.
                    if calculatedPhase != scheduleData.adaptationPhase {
                        // Sadece Repository üzerinden merkezi bir güncelleme fonksiyonu varsa onu kullanmak daha iyi olabilir.
                        // Şimdilik ViewModel'in context'i üzerinden güncelliyoruz.
                        // Bu güncelleme, fazın doğal ilerlemesini yansıtmalı.
                        // scheduleData.updatedAt'in bu noktada değişmemesi gerekebilir, çünkü adaptasyonun başlangıç zamanını temsil ediyor.
                        // Ancak, eğer fazı 'düzeltiyorsak', updatedAt'i de şimdiye ayarlamak mantıklı olabilir.
                        // Bu, ürün kararına bağlıdır. Şimdilik updatedAt'i güncelleyelim.
                        
                        // scheduleData'nın context'e bağlı bir nesne olduğundan emin olun.
                        // ProfileScreenViewModel.modelContext'i kullanıyoruz.
                        
                        // Repository'e bir `updateUserScheduleAdaptationPhase` metodu zaten var, onu kullanalım!
                        // Bu daha temiz bir yaklaşım olacaktır.
                        Task {
                            do {
                                try Repository.shared.updateUserScheduleAdaptationPhase(
                                    scheduleId: scheduleData.id, // UserSchedule ID'si
                                    newPhase: calculatedPhase,
                                    context: context // ProfileScreenViewModel'in modelContext'i
                                )
                                print("Adaptasyon aşaması Repository üzerinden güncellendi.")
                                // UI'ı yeniden yüklemeye gerek yok çünkü zaten self.adaptationPhase ayarlandı.
                                // scheduleData.adaptationPhase ViewModel'de güncellenmeyebilir, ancak self.adaptationPhase günceldir.
                            } catch {
                                print("Adaptasyon aşaması Repository üzerinden güncellenirken hata: \(error)")
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
        let updatedAt = schedule.updatedAt
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: updatedAt, to: currentDate)
        let daysSinceUpdate = (components.day ?? 0) + 1  // 1'den başlatmak için +1 ekliyoruz
        
        let totalDuration = self.adaptationDuration
        let phase: Int
        
        if totalDuration == 28 {
            if daysSinceUpdate <= 1 { phase = 0 }
            else if daysSinceUpdate <= 7 { phase = 1 }
            else if daysSinceUpdate <= 14 { phase = 2 }
            else if daysSinceUpdate <= 20 { phase = 3 }
            else if daysSinceUpdate <= 27 { phase = 4 }
            else { phase = 5 }
        } else {
            if daysSinceUpdate <= 1 { phase = 0 }
            else if daysSinceUpdate <= 7 { phase = 1 }
            else if daysSinceUpdate <= 14 { phase = 2 }
            else if daysSinceUpdate <= 20 { phase = 3 }
            else { phase = 4 }
        }
        return phase
    }

    private func calculateStreak(from history: [HistoryModel]) {
        guard !history.isEmpty else {
            currentStreak = 0
            longestStreak = 0
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
                print("ProfileScreenViewModel: Güncellenecek program SwiftData\'da bulunamadı.")
                throw ProfileError.scheduleUpdateFailed
            }

            scheduleToUpdate.adaptationPhase = 1  // 1. günden başlat
            scheduleToUpdate.updatedAt = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()  // 1 gün öncesi
            
            try context.save()
            
            // UI'ı güncelle
            await MainActor.run {
                self.adaptationPhase = 1  // UI'da da 1. günden başlat
                self.activeSchedule = scheduleToUpdate // Güncellenmiş schedule'ı ata
            }
            
            print("Adaptasyon fazı başarıyla sıfırlandı (SwiftData).")
            
        } catch {
            print("Adaptasyon fazı sıfırlanırken SwiftData hatası: \\(error.localizedDescription)")
            throw ProfileError.saveFailed(error.localizedDescription)
        }
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
