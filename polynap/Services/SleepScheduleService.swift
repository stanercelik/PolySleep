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
        print("🔍 SleepScheduleService: JSON loading başlatılıyor...")
        guard let url = Bundle.main.url(forResource: "SleepSchedules", withExtension: "json") else {
            print("❌ SleepSchedules.json dosyası bundle'da bulunamadı")
            return
        }
        
        guard let data = try? Data(contentsOf: url) else {
            print("❌ SleepSchedules.json dosyası okunamadı")
            return
        }
        
        print("🔍 JSON dosya boyutu: \(data.count) bytes")
        
        do {
            let container = try JSONDecoder().decode(SleepSchedulesContainer.self, from: data)
            allSchedules = container.sleepSchedules
            print("✅ \(allSchedules.count) uyku düzeni yüklendi")
            
            // İlk birkaç schedule'ın description'larını kontrol et
            for (index, schedule) in allSchedules.prefix(3).enumerated() {
                print("🔍 Schedule \(index): \(schedule.id)")
                print("   - EN: '\(schedule.description.en.prefix(50))...'")
                print("   - TR: '\(schedule.description.tr.prefix(50))...'")
                print("   - DE: '\(schedule.description.de.prefix(50))...'")
                print("   - JA: '\(schedule.description.ja.prefix(50))...'")
                print("   - MS: '\(schedule.description.ms.prefix(50))...'")
                print("   - TH: '\(schedule.description.th.prefix(50))...'")
            }
        } catch {
            print("❌ JSON parse hatası: \(error)")
            print("❌ Hata detayı: \(error.localizedDescription)")
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
    
    /// Debug için schedule description'larını test et
    func debugScheduleDescriptions() {
        print("🔍 DEBUG: Testing schedule descriptions...")
        let testLanguages = ["en", "tr", "ja", "de", "ms", "th"]
        
        for schedule in allSchedules.prefix(5) {
            print("🔍 Schedule: \(schedule.id)")
            for lang in testLanguages {
                let desc = schedule.description.localized(for: lang)
                print("   \(lang): '\(desc.prefix(80))...'")
            }
        }
    }
} 