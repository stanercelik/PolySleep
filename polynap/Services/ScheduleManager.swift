import Foundation
import SwiftUI
import SwiftData

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
}
