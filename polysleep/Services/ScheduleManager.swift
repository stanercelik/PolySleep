import Foundation
import SwiftUI
import SwiftData

/// Uyku programlarını yöneten sınıf
class ScheduleManager: ObservableObject {
    static let shared = ScheduleManager()
    
    @Published var activeSchedule: UserScheduleModel?
    private var lastNotificationUpdateTime: Date?
    private var lastLeadTime: Int?
    
    private init() {
        // Silinmiş olarak işaretlenmiş blokları temizle
        Task {
            do {
                try await Repository.shared.cleanupDeletedBlocks()
                
                // Uygulama başlatıldığında yerel veritabanından aktif programı yükle
                await loadActiveScheduleFromLocalDatabase()
            } catch {
                print("ScheduleManager: Silinmiş bloklar temizlenirken hata: \(error)")
            }
        }
    }
    
    /// Yerel veritabanından aktif programı yükler
    @MainActor
    private func loadActiveScheduleFromLocalDatabase() {
        Task {
            do {
                if let localSchedule = try await Repository.shared.getActiveSchedule() {
                    print("ScheduleManager: Yerel veritabanından aktif program yüklendi: \(localSchedule.name)")
                    DispatchQueue.main.async {
                        self.activeSchedule = localSchedule
                        self.updateNotificationsForActiveSchedule()
                    }
                } else {
                    print("ScheduleManager: Yerel veritabanında aktif program bulunamadı.")
                    DispatchQueue.main.async {
                        self.activeSchedule = nil
                    }
                }
            } catch {
                print("ScheduleManager: Yerel veritabanından aktif program yüklenirken hata: \(error)")
                DispatchQueue.main.async {
                    self.activeSchedule = nil
                }
            }
        }
    }
    
    @MainActor
    func loadActiveSchedule() {
        print("ScheduleManager: Aktif program yükleniyor...")
        loadActiveScheduleFromLocalDatabase()
    }
    
    /// Uyku programı değiştiğinde bildirimleri günceller - optimize edilmiş
    @MainActor func updateNotificationsForActiveSchedule() {
        guard let schedule = activeSchedule else { 
            print("Bildirimler güncellenemedi: Aktif program (activeSchedule) nil. Tüm bildirimler iptal ediliyor.")
            LocalNotificationService.shared.cancelAllNotifications()
            lastNotificationUpdateTime = nil
            lastLeadTime = nil
            return 
        }
        
        // Kullanıcının tercih ettiği hatırlatma süresini al
        let leadTime = Repository.shared.getReminderLeadTime()
        let now = Date()
        
        // Eğer son güncelleme 30 saniye içindeyse ve leadTime aynıysa skip et
        if let lastUpdate = lastNotificationUpdateTime,
           let lastLead = lastLeadTime,
           now.timeIntervalSince(lastUpdate) < 30.0,
           leadTime == lastLead {
            print("⏭️ Bildirim güncellemesi atlandı: Son güncelleme çok yakın zamanda yapıldı")
            return
        }
        
        print("Aktif program (\(schedule.name)) için bildirimler \(leadTime) dakika öncesinden güncelleniyor...")
        LocalNotificationService.shared.scheduleNotificationsForActiveSchedule(schedule: schedule, leadTimeMinutes: leadTime)
        
        // Güncelleme zamanını kaydet
        lastNotificationUpdateTime = now
        lastLeadTime = leadTime
    }
    
    @MainActor
    func activateSchedule(_ schedule: UserScheduleModel) {
        print("ScheduleManager: Program aktifleştiriliyor: \(schedule.name)")
        
        Task {
            do {
                // Önce mevcut aktif programları deaktive et
                try await Repository.shared.deactivateAllSchedules()
                
                // Sonra yeni programı aktif olarak işaretle
                try await Repository.shared.setScheduleActive(id: schedule.id, isActive: true)
                
                // Aktif programı güncelle ve bildirimleri planla
                DispatchQueue.main.async {
                    self.activeSchedule = schedule
                    self.updateNotificationsForActiveSchedule()
                    print("ScheduleManager: Program başarıyla aktifleştirildi: \(schedule.name)")
                }
            } catch {
                print("ScheduleManager: Program aktifleştirilemedi: \(error)")
            }
        }
    }
    
    /// Aktif programı sıfırlar
    @MainActor
    func resetActiveSchedule() async throws {
        print("ScheduleManager: Aktif program sıfırlanıyor...")
        
        // Tüm programları deaktive et
        try await Repository.shared.deactivateAllSchedules()
        
        // Yerel programı temizle
        DispatchQueue.main.async {
            self.activeSchedule = nil
            self.lastNotificationUpdateTime = nil
            self.lastLeadTime = nil
            self.updateNotificationsForActiveSchedule() // Bildirimleri güncelle
            print("ScheduleManager: Aktif program başarıyla sıfırlandı")
        }
    }
} 
