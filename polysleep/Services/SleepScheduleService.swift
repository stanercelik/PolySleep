import Foundation

/// SleepSchedule JSON dosyasını okuyan ve yöneten service
final class SleepScheduleService {
    static let shared = SleepScheduleService()
    
    private var allSchedules: [SleepScheduleModel] = []
    
    private init() {
        loadSchedulesFromJSON()
    }
    
    /// JSON dosyasından uyku düzenlerini yükler
    private func loadSchedulesFromJSON() {
        guard let url = Bundle.main.url(forResource: "SleepSchedules", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("❌ SleepSchedules.json dosyası bulunamadı")
            return
        }
        
        do {
            let container = try JSONDecoder().decode(SleepSchedulesContainer.self, from: data)
            allSchedules = container.sleepSchedules
            print("✅ \(allSchedules.count) uyku düzeni yüklendi")
        } catch {
            print("❌ JSON parse hatası: \(error)")
        }
    }
    
    /// Kullanıcının premium durumuna göre uyku düzenlerini filtreler
    func getAvailableSchedules(isPremium: Bool) -> [SleepScheduleModel] {
        if isPremium {
            return allSchedules // Premium kullanıcılar tüm düzenleri görebilir
        } else {
            return allSchedules.filter { !$0.isPremium } // Free kullanıcılar sadece ücretsiz düzenleri görebilir
        }
    }
    
    /// ID'ye göre uyku düzeni getirir
    func getScheduleById(_ id: String) -> SleepScheduleModel? {
        return allSchedules.first { $0.id == id }
    }
    
    /// Tüm uyku düzenlerini getirir (admin/debug amaçlı)
    func getAllSchedules() -> [SleepScheduleModel] {
        return allSchedules
    }
} 