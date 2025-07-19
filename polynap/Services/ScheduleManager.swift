import Foundation
import SwiftUI
import SwiftData
import HealthKit

/// Aktif uyku programını yöneten ve bildirimlerin planlanmasını tetikleyen sınıf.
@MainActor
class ScheduleManager: ObservableObject {
    static let shared = ScheduleManager()
    
    @Published var activeSchedule: UserScheduleModel?
    
    // Optimizasyon için son güncelleme bilgilerini tutar
    private var lastNotificationUpdateTime: Date?
    private var lastUpdatedScheduleID: String?
    
    private init() {
        Task {
            do {
                // Silinmiş olarak işaretlenmiş eski varlıkları temizle (isteğe bağlı)
                // try await Repository.shared.cleanupDeletedBlocks()
                
                // Uygulama başlatıldığında depodan aktif programı yükle
                await loadActiveScheduleFromRepository()
            } catch {
                print("🚨 ScheduleManager: Başlatma sırasında hata: \(error)")
            }
        }
    }
    
    /// Repository'den aktif programı yükler ve UI'ı günceller.
    func loadActiveScheduleFromRepository() async {
        print("🔄 ScheduleManager: Depodan aktif program yükleniyor...")
        do {
            if let schedule = try await Repository.shared.getActiveSchedule() {
                self.activeSchedule = schedule
                print("✅ ScheduleManager: Aktif program yüklendi: \(schedule.name)")
                // Program yüklendikten sonra bildirimleri yeniden planla
                await self.updateNotificationsForActiveSchedule()
            } else {
                self.activeSchedule = nil
                print("ℹ️ ScheduleManager: Aktif program bulunamadı.")
                // Aktif program olmadığında tüm bildirimleri iptal et
                await AlarmService.shared.cancelAllNotifications()
            }
        } catch {
            print("🚨 ScheduleManager: Aktif program yüklenirken hata: \(error.localizedDescription)")
            self.activeSchedule = nil
        }
    }
    
    /// **DEĞİŞTİRİLDİ:** Uyku programı veya ayarlar değiştiğinde bildirimleri günceller.
    /// Artık doğrudan yeni `AlarmService`'i çağırır.
    func updateNotificationsForActiveSchedule() async {
        // **DEĞİŞİKLİK:** Artık Repository'den context'i alıyoruz.
        guard let context = Repository.shared.getModelContext() else {
            print("🚨 ScheduleManager: Bildirimler planlanamadı. ModelContext Repository'de bulunamadı.")
            return
        }
        
        guard let schedule = activeSchedule else {
            print("ℹ️ ScheduleManager: Bildirimler güncellenemedi, aktif program yok. Tüm bildirimler iptal ediliyor.")
            await AlarmService.shared.cancelAllNotifications()
            return
        }
        
        // Optimizasyon: Aynı program için kısa süre içinde tekrar tekrar güncelleme yapmayı engelle
        let now = Date()
        if let lastUpdate = lastNotificationUpdateTime,
           let lastID = lastUpdatedScheduleID,
           lastID == schedule.id,
           now.timeIntervalSince(lastUpdate) < 10.0 { // 10 saniyeden kısa süre önce güncellendiyse atla
            print("⏭️ ScheduleManager: Bildirim güncellemesi atlandı (çok sık istek).")
            return
        }
        
        print("🔄 ScheduleManager: Bildirimler '\(schedule.name)' programı için yeniden planlanıyor...")
        
        // Merkezi alarm servisini çağır
        await AlarmService.shared.rescheduleNotificationsForActiveSchedule(modelContext: context)
        
        // Son güncelleme bilgilerini kaydet
        self.lastNotificationUpdateTime = now
        self.lastUpdatedScheduleID = schedule.id
    }
    
    /// Belirtilen bir programı aktif hale getirir.
    func activateSchedule(_ schedule: UserScheduleModel) async {
        print("▶️ ScheduleManager: Program aktifleştiriliyor: \(schedule.name)")
        
        do {
            // Önce mevcut aktif programları deaktive et
            try await Repository.shared.deactivateAllSchedules()
            
            // Sonra yeni programı aktif olarak işaretle
            try await Repository.shared.setScheduleActive(id: schedule.id, isActive: true)
            
            // Yerel state'i güncelle ve bildirimleri yeniden planla
            self.activeSchedule = schedule
            await self.updateNotificationsForActiveSchedule()
            
            // Watch'a senkronizasyon için tam bir sync gerçekleştir
            await WatchSyncBridge.shared.performFullSync()
            
            // Schedule değişikliği notification'ı gönder
            NotificationCenter.default.post(name: .scheduleDidChange, object: nil, userInfo: ["schedule": schedule])
            
            print("✅ ScheduleManager: Program başarıyla aktifleştirildi: \(schedule.name)")
        } catch {
            print("🚨 ScheduleManager: Program aktifleştirilemedi: \(error)")
        }
    }
    
    /// Aktif programı sıfırlar.
    func resetActiveSchedule() async {
        print("⏹️ ScheduleManager: Aktif program sıfırlanıyor...")
        
        do {
            // Veritabanındaki tüm programları deaktive et
            try await Repository.shared.deactivateAllSchedules()
            
            // Yerel state'i temizle ve bildirimleri iptal et
            self.activeSchedule = nil
            await self.updateNotificationsForActiveSchedule()
            
            print("✅ ScheduleManager: Aktif program başarıyla sıfırlandı.")
        } catch {
            print("🚨 ScheduleManager: Aktif program sıfırlanırken hata: \(error)")
        }
    }
    
    // MARK: - HealthKit Integration
    
    /// Uyku seansı tamamlandığında HealthKit'e veri kaydetme fonksiyonu
    func saveSleepSessionToHealthKit(startDate: Date, endDate: Date, sleepType: SleepType = .core) async {
        print("💤 ScheduleManager: HealthKit'e uyku seansı kaydediliyor...")
        
        // TODO: HealthKit entegrasyonu tamamlandıktan sonra aktif edilecek
        /*
        // HealthKit authorization kontrolü
        let healthKitManager = HealthKitManager.shared
        guard healthKitManager.authorizationStatus == .sharingAuthorized else {
            print("⚠️ ScheduleManager: HealthKit izni yok, kaydetme atlandı")
            return
        }
        
        // SleepType'ı HealthKit SleepAnalysisType'a çevir
        let healthKitSleepType: SleepAnalysisType
        switch sleepType {
        case .core:
            healthKitSleepType = .asleep
        case .nap:
            healthKitSleepType = .asleep
        case .powerNap:
            healthKitSleepType = .asleep
        }
        
        // HealthKit'e kaydet
        let result = await healthKitManager.saveSleepAnalysis(
            startDate: startDate,
            endDate: endDate,
            sleepType: healthKitSleepType
        )
        
        switch result {
        case .success():
            print("✅ ScheduleManager: Uyku seansı HealthKit'e başarıyla kaydedildi")
            
            // Analytics event gönder
            let duration = endDate.timeIntervalSince(startDate)
            AnalyticsManager.shared.logEvent("healthkit_sleep_saved", parameters: [
                "duration_minutes": duration / 60,
                "sleep_type": String(describing: sleepType)
            ])
            
        case .failure(let error):
            print("🚨 ScheduleManager: HealthKit'e kaydetme hatası: \(error.localizedDescription)")
            
            // Analytics event gönder
            AnalyticsManager.shared.logEvent("healthkit_save_error", parameters: [
                "error": error.localizedDescription
            ])
        }
        */
    }
    
    /// Uyku bloğu tamamlandığında çağrılacak fonksiyon
    func completeSleepBlock(blockId: String, actualEndTime: Date) async {
        print("🏁 ScheduleManager: Uyku bloğu tamamlanıyor: \(blockId)")
        
        guard let schedule = activeSchedule else {
            print("⚠️ ScheduleManager: Aktif program bulunamadı")
            return
        }
        
        // Uyku bloğunu bul
        guard let blockUUID = UUID(uuidString: blockId),
              let block = schedule.schedule.first(where: { $0.id == blockUUID }) else {
            print("⚠️ ScheduleManager: Uyku bloğu bulunamadı: \(blockId)")
            return
        }
        
        // Başlangıç zamanını hesapla
        let startTimeComponents = block.startTimeComponents
        let startTime = Calendar.current.date(bySettingHour: startTimeComponents.hour, minute: startTimeComponents.minute, second: 0, of: Date()) ?? Date()
        
        // String'i SleepType'a çevir
        let sleepType: SleepType
        switch block.type.lowercased() {
        case "core":
            sleepType = .core
        case "nap":
            sleepType = .nap
        case "powernap":
            sleepType = .powerNap
        default:
            sleepType = .core // varsayılan
        }
        
        // HealthKit'e kaydet
        await saveSleepSessionToHealthKit(
            startDate: startTime,
            endDate: actualEndTime,
            sleepType: sleepType
        )
        
        // Diğer işlemleri yap (SleepEntry kaydetme vs.)
        // Bu kısım mevcut işlemlerin devamı olacak
    }
}
