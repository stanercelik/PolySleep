import Foundation
import SwiftUI
import SwiftData

/// Uyku programlarını yöneten sınıf
class ScheduleManager: ObservableObject {
    static let shared = ScheduleManager()
    
    @Published var activeSchedule: UserScheduleModel?
    
    private init() {
    }
    
    @MainActor
    func loadActiveSchedule() {
        print("ScheduleManager: Aktif program yükleniyor...")
        Task {
            do {
                guard AuthManager.shared.isAuthenticated else {
                    print("ScheduleManager: Kullanıcı doğrulanmadı, program yüklenemiyor.")
                    DispatchQueue.main.async {
                        self.activeSchedule = nil
                    }
                    return
                }
                
                print("ScheduleManager: Kullanıcı doğrulandı, Supabase'den program çekiliyor.")
                let schedules = try await SupabaseService.shared.schedule.getUserSchedules()
                if let activeDbSchedule = schedules.first(where: { $0.isActive }) {
                    print("ScheduleManager: Aktif DB programı bulundu: \(activeDbSchedule.name)")
                    let blocks = try await SupabaseService.shared.schedule.getSleepBlocksForSchedule(scheduleId: activeDbSchedule.id)
                    let activeModelSchedule = activeDbSchedule.toUserScheduleModel(with: blocks)
                    print("ScheduleManager: Program UserScheduleModel'e dönüştürüldü.")
                    DispatchQueue.main.async {
                        print("ScheduleManager: activeSchedule ayarlanıyor ve bildirimler güncelleniyor.")
                        self.activeSchedule = activeModelSchedule
                        self.updateNotificationsForActiveSchedule() // Program yüklendikten sonra bildirimleri planla
                    }
                } else {
                    print("ScheduleManager: Aktif veritabanı programı bulunamadı.")
                    DispatchQueue.main.async {
                        self.activeSchedule = nil // Aktif program yoksa nil yap
                    }
                }
            } catch {
                print("ScheduleManager: Aktif program yüklenemedi HATA: \(error)")
                DispatchQueue.main.async {
                    self.activeSchedule = nil // Hata durumunda nil yap
                }
            }
        }
    }
    
    /// Uyku programı değiştiğinde bildirimleri günceller
    func updateNotificationsForActiveSchedule() {
        guard let schedule = activeSchedule else { 
            print("Bildirimler güncellenemedi: Aktif program (activeSchedule) nil.")
            OneSignalNotificationService.shared.clearAllScheduledNotifications()
            return 
        }
        print("Aktif program (\(schedule.name)) için bildirimler güncelleniyor...")
        OneSignalNotificationService.shared.scheduleAllNotificationsForActiveSchedule(schedule: schedule)
    }
    
    func activateSchedule(_ schedule: UserScheduleModel) {
        // TODO: Supabase tarafında da bu programı aktif olarak işaretle
        print("ScheduleManager: Program manuel olarak aktifleştiriliyor: \(schedule.name)")
        DispatchQueue.main.async {
             self.activeSchedule = schedule
             self.updateNotificationsForActiveSchedule()
        }
    }
} 
