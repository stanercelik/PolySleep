import Foundation
import SwiftUI
import SwiftData
import Combine
import Supabase

@MainActor
class ProfileScreenViewModel: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var selectedCoreEmoji: String = "🌙"
    @Published var selectedNapEmoji: String = "⚡"
    @Published var activeScheduleName: String = ""
    @Published var adaptationPhase: Int = 0
    @Published var totalSleepHours: Double = 0.0
    
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        loadData()
        loadEmojiPreferences()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadData()
    }
    
    // Verileri yükle
    private func loadData() {
        guard let context = modelContext else { return }
        
        do {
            // Geçmiş kayıtları al
            let descriptor = FetchDescriptor<HistoryModel>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            let historyItems = try context.fetch(descriptor)
            
            // Streak hesapla
            calculateStreak(from: historyItems)
            
            // Aktif uyku programını ve adaptasyon aşamasını getir
            Task {
                await loadActiveSchedule()
            }
            
            // Emoji tercihlerini yükle
            loadEmojiPreferences()
        } catch {
            print("Profil verilerini yüklerken hata: \(error)")
        }
    }
    
    // Aktif uyku programını ve adaptasyon aşamasını yükle
    private func loadActiveSchedule() async {
        // Client optional değil, doğrudan kullanabiliriz
        let client = SupabaseService.shared.client
        
        do {
            let response = try await client.database
                .from("user_schedules")
                .select()
                .eq("is_active", value: true)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
            
            // PostgrestResponse'dan doğru şekilde decode etme
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let schedules = try decoder.decode([ActiveSchedule].self, from: response.data)
            
            if let activeSchedule = schedules.first {
                DispatchQueue.main.async {
                    self.activeScheduleName = activeSchedule.name
                    self.adaptationPhase = activeSchedule.adaptationPhase ?? 0
                    self.totalSleepHours = Double(activeSchedule.totalSleepHours ?? 0)
                }
            }
        } catch {
            print("Aktif uyku programını yüklerken hata: \(error)")
        }
    }
    
    // Streak hesaplama
    private func calculateStreak(from historyItems: [HistoryModel]) {
        guard !historyItems.isEmpty else {
            currentStreak = 0
            longestStreak = 0
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var tempStreak = 0
        var maxStreak = 0
        var previousDate = today
        
        // Tarih sırasına göre sırala (en yeni en başta)
        let sortedItems = historyItems.sorted { $0.date > $1.date }
        
        // Bugünden geriye doğru kontrol et
        for item in sortedItems {
            let itemDate = calendar.startOfDay(for: item.date)
            
            // Sadece tamamlanmış günleri say
            if item.completionStatus == .completed {
                // İlk öğe veya bir önceki günse
                if tempStreak == 0 || calendar.isDate(itemDate, inSameDayAs: previousDate) || 
                   calendar.isDate(itemDate, equalTo: calendar.date(byAdding: .day, value: -1, to: previousDate)!, toGranularity: .day) {
                    tempStreak += 1
                    previousDate = itemDate
                } else {
                    // Streak kırıldı
                    break
                }
            } else {
                // Tamamlanmamış gün, streak kırıldı
                break
            }
        }
        
        // En uzun streak'i hesapla
        var currentLongestStreak = 0
        previousDate = Date.distantFuture
        
        for item in historyItems.sorted(by: { $0.date < $1.date }) {
            if item.completionStatus == .completed {
                let itemDate = calendar.startOfDay(for: item.date)
                
                if previousDate == Date.distantFuture || 
                   calendar.isDate(itemDate, equalTo: calendar.date(byAdding: .day, value: 1, to: previousDate)!, toGranularity: .day) {
                    currentLongestStreak += 1
                } else if !calendar.isDate(itemDate, inSameDayAs: previousDate) {
                    // Aynı gün değilse ve ardışık değilse, yeni streak başlat
                    maxStreak = max(maxStreak, currentLongestStreak)
                    currentLongestStreak = 1
                }
                
                previousDate = itemDate
            } else {
                // Tamamlanmamış gün, mevcut streak'i sıfırla
                maxStreak = max(maxStreak, currentLongestStreak)
                currentLongestStreak = 0
                previousDate = Date.distantFuture
            }
        }
        
        maxStreak = max(maxStreak, currentLongestStreak)
        
        currentStreak = tempStreak
        longestStreak = maxStreak
    }
    
    // Emoji tercihlerini yükle
    private func loadEmojiPreferences() {
        // UserDefaults'tan emoji tercihlerini yükle
        let defaults = UserDefaults.standard
        selectedCoreEmoji = defaults.string(forKey: "selectedCoreEmoji") ?? "🌙"
        selectedNapEmoji = defaults.string(forKey: "selectedNapEmoji") ?? "⚡"
    }
    
    // Emoji tercihlerini kaydet
    func saveEmojiPreference(coreEmoji: String? = nil, napEmoji: String? = nil) {
        let defaults = UserDefaults.standard
        
        if let coreEmoji = coreEmoji {
            selectedCoreEmoji = coreEmoji
            defaults.set(coreEmoji, forKey: "selectedCoreEmoji")
            
            // Bildirim gönder (emoji değişti)
            NotificationCenter.default.post(name: Notification.Name("CoreEmojiChanged"), object: coreEmoji)
        }
        
        if let napEmoji = napEmoji {
            selectedNapEmoji = napEmoji
            defaults.set(napEmoji, forKey: "selectedNapEmoji")
            
            // Bildirim gönder (emoji değişti)
            NotificationCenter.default.post(name: Notification.Name("NapEmojiChanged"), object: napEmoji)
        }
    }
}

// Aktif Program modeli
struct ActiveSchedule: Codable {
    let id: UUID
    let userId: UUID?
    let name: String
    let totalSleepHours: Double?
    let adaptationPhase: Int?
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case totalSleepHours = "total_sleep_hours"
        case adaptationPhase = "adaptation_phase"
        case isActive = "is_active"
    }
}
