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
    @Published var dailyProgress: Double = 0.0
    @Published var completedDays: Int = 0
    @Published var totalDays: Int = 0
    @Published var badges: [Badge] = []
    @Published var showBadgeDetail: Bool = false
    @Published var selectedBadge: Badge?
    
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        loadData()
        setupBadges()
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
            
            // İlerleme hesapla
            calculateProgress(from: historyItems)
            
            // Emoji tercihlerini yükle
            loadEmojiPreferences()
        } catch {
            print("Profil verilerini yüklerken hata: \(error)")
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
    
    // İlerleme hesaplama
    private func calculateProgress(from historyItems: [HistoryModel]) {
        guard !historyItems.isEmpty else {
            dailyProgress = 0.0
            completedDays = 0
            totalDays = 0
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Son 30 günü değerlendir
        let startDate = calendar.date(byAdding: .day, value: -30, to: today)!
        
        // Tarih aralığındaki tüm günleri oluştur
        var allDates: [Date] = []
        var currentDate = startDate
        
        while currentDate <= today {
            allDates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        totalDays = allDates.count
        
        // Tamamlanmış günleri say
        let completedHistoryItems = historyItems.filter { item in
            let itemDate = calendar.startOfDay(for: item.date)
            return itemDate >= startDate && itemDate <= today && item.completionStatus == .completed
        }
        
        completedDays = completedHistoryItems.count
        
        // İlerleme yüzdesini hesapla
        dailyProgress = totalDays > 0 ? Double(completedDays) / Double(totalDays) : 0.0
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
        }
        
        if let napEmoji = napEmoji {
            selectedNapEmoji = napEmoji
            defaults.set(napEmoji, forKey: "selectedNapEmoji")
        }
    }
    
    // Rozet sistemi
    private func setupBadges() {
        badges = [
            Badge(id: "beginner", name: "Başlangıç", description: "Polifazik uyku düzenine başladın", icon: "star.fill", isUnlocked: true),
            Badge(id: "week_streak", name: "Haftalık Seri", description: "7 gün üst üste uyku düzenini korudun", icon: "flame.fill", isUnlocked: currentStreak >= 7),
            Badge(id: "month_streak", name: "Aylık Seri", description: "30 gün üst üste uyku düzenini korudun", icon: "crown.fill", isUnlocked: currentStreak >= 30),
            Badge(id: "perfect_week", name: "Mükemmel Hafta", description: "Bir hafta boyunca tüm uyku bloklarını tamamladın", icon: "checkmark.seal.fill", isUnlocked: false),
            Badge(id: "night_owl", name: "Gece Kuşu", description: "Gece yarısından sonra 10 kez başarıyla uyandın", icon: "moon.stars.fill", isUnlocked: false),
            Badge(id: "early_bird", name: "Erken Kuş", description: "Sabah 6'dan önce 10 kez başarıyla uyandın", icon: "sunrise.fill", isUnlocked: false)
        ]
    }
    
    // Rozet detaylarını göster
    func showBadgeDetails(badge: Badge) {
        selectedBadge = badge
        showBadgeDetail = true
    }
}

// Rozet modeli
struct Badge: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    var isUnlocked: Bool
}
