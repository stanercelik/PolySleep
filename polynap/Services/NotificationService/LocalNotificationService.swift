import Foundation
import UserNotifications
import SwiftData

class LocalNotificationService: ObservableObject {
    static let shared = LocalNotificationService()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // Alarm servisi referansı
    private let alarmService = AlarmNotificationService.shared

    private init() {
        // Bildirim kategorilerini kaydet
        registerNotificationCategories()
    }

    // MARK: - Permission Handling

    /// Kullanıcıdan bildirim izni ister.
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
            if granted {
                print("PolyNap Debug: Bildirim izni verildi.")
            } else if let error = error {
                print("PolyNap Debug: Bildirim izni istenirken hata oluştu: \(error.localizedDescription)")
            } else {
                print("PolyNap Debug: Bildirim izni reddedildi.")
            }
            completion(granted, error)
        }
    }

    /// Mevcut bildirim izin durumunu kontrol eder.
    func getNotificationSettings(completion: @escaping (UNNotificationSettings) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            completion(settings)
        }
    }

    // MARK: - Notification Scheduling

    /// Test bildirimi planlar (hemen veya belirli bir süre sonra)
    func scheduleTestNotification(title: String, body: String, delay: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let identifier = "test_notification_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("PolyNap Debug: Test bildirimi planlanırken hata oluştu: \(error.localizedDescription)")
            } else {
                print("PolyNap Debug: Test bildirimi başarıyla planlandı: \(delay) saniye sonra")
            }
        }
    }

    /// Belirli bir uyku bloğu için bildirim planlar.
    /// - Parameters:
    ///   - block: Bildirimi planlanacak uyku bloğu.
    ///   - scheduleName: Uyku programının adı (bildirim içeriğinde kullanılacak).
    ///   - fireDateComponents: Bildirimin tetikleneceği tarih bileşenleri.
    ///   - identifierPrefix: Bildirim için benzersiz bir tanımlayıcı ön eki.
    func scheduleNotification(
        title: String,
        body: String,
        identifier: String,
        dateComponents: DateComponents,
        repeats: Bool = false
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("PolyNap Debug: Bildirim planlanırken hata oluştu (\(identifier)): \(error.localizedDescription)")
            } else {
                if let hour = dateComponents.hour, let minute = dateComponents.minute {
                    print("PolyNap Debug: Bildirim başarıyla planlandı: \(identifier) - \(String(format: "%02d:%02d", hour, minute))")
                } else {
                    print("PolyNap Debug: Bildirim başarıyla planlandı: \(identifier) (saat/dakika bilgisi eksik)")
                }
            }
        }
    }
    
    /// Aktif uyku programındaki tüm bloklar için bildirimleri planlar.
    /// Bu fonksiyon, ScheduleManager tarafından çağrılacak.
    /// Detaylı implementasyon daha sonra eklenecek.
    func scheduleNotificationsForActiveSchedule(schedule: UserScheduleModel, leadTimeMinutes: Int) {
        print("PolyNap Debug: \(schedule.name) için bildirimler \(leadTimeMinutes) dakika önce planlanacak...")
        
        cancelAllNotifications()
        
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"

        for block in schedule.schedule {
            guard let startTimeDate = dateFormatter.date(from: block.startTime) else {
                print("PolyNap Debug: Geçersiz başlangıç saati formatı: \(block.startTime) blok ID: \(block.id)")
                continue
            }
            
            guard let notificationTime = calendar.date(byAdding: .minute, value: -leadTimeMinutes, to: startTimeDate) else {
                print("PolyNap Debug: Bildirim zamanı hesaplanamadı, blok ID: \(block.id)")
                continue
            }
            
            let fireDateComponents = calendar.dateComponents([.hour, .minute], from: notificationTime)
            let notificationIdentifier = "sleepblock_\(block.id.uuidString)"
            
            let endTimeStr = calculateEndTime(startTime: block.startTime, durationMinutes: block.duration)
            
            let title = "😴 Uyku Zamanı!"
            let body = "Sıradaki uykun (\(block.isCore ? "Ana" : "Kestirme")) birazdan başlıyor: \(block.startTime) - \(endTimeStr)"
            
            scheduleNotification(
                title: title,
                body: body,
                identifier: notificationIdentifier,
                dateComponents: fireDateComponents,
                repeats: true
            )
        }
    }

    // MARK: - Helper Functions
    
    private func calculateEndTime(startTime: String, durationMinutes: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        guard let startDate = dateFormatter.date(from: startTime) else {
            return "N/A"
        }
        
        let calendar = Calendar.current
        guard let endDate = calendar.date(byAdding: .minute, value: durationMinutes, to: startDate) else {
            return "N/A"
        }
        
        return dateFormatter.string(from: endDate)
    }

    // MARK: - Notification Management

    /// Planlanmış belirli bir bildirimi iptal eder.
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("PolyNap Debug: Bildirim iptal edildi: \(identifier)")
    }

    /// Planlanmış tüm bildirimleri iptal eder.
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("PolyNap Debug: Tüm planlanmış bildirimler iptal edildi.")
    }

    /// Teslim edilmiş belirli bir bildirimi kaldırır.
    func removeDeliveredNotification(identifier: String) {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
        print("PolyNap Debug: Teslim edilmiş bildirim kaldırıldı: \(identifier)")
    }

    /// Teslim edilmiş tüm bildirimleri kaldırır.
    func removeAllDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        print("PolyNap Debug: Teslim edilmiş tüm bildirimler kaldırıldı.")
    }
    
    // MARK: - Alarm Integration
    
    /// Uyku programı için hem hatırlatıcı hem de alarm bildirimlerini planlar
    func scheduleNotificationsWithAlarms(
        schedule: UserScheduleModel,
        leadTimeMinutes: Int,
        alarmSettings: AlarmSettings?,
        modelContext: ModelContext
    ) async {
        print("PolyNap Debug: \(schedule.name) için bildirimler ve alarmlar planlanıyor...")
        
        // Mevcut bildirimleri temizle
        cancelAllNotifications()
        
        // Alarm servisi ile alarmları temizle
        if let scheduleEntity = convertToScheduleEntity(schedule) {
            await alarmService.cancelAllAlarmsForSchedule(scheduleId: scheduleEntity.id)
        }
        
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"

        for block in schedule.schedule {
            guard let startTimeDate = dateFormatter.date(from: block.startTime) else {
                print("PolyNap Debug: Geçersiz başlangıç saati formatı: \(block.startTime) blok ID: \(block.id)")
                continue
            }
            
            // 1. Uyku başlangıcı için hatırlatıcı bildirim
            guard let notificationTime = calendar.date(byAdding: .minute, value: -leadTimeMinutes, to: startTimeDate) else {
                print("PolyNap Debug: Bildirim zamanı hesaplanamadı, blok ID: \(block.id)")
                continue
            }
            
            let fireDateComponents = calendar.dateComponents([.hour, .minute], from: notificationTime)
            let notificationIdentifier = "sleepblock_\(block.id.uuidString)"
            
            let endTimeStr = calculateEndTime(startTime: block.startTime, durationMinutes: block.duration)
            
            let title = "😴 Uyku Zamanı!"
            let body = "Sıradaki uykun (\(block.isCore ? "Ana" : "Kestirme")) birazdan başlıyor: \(block.startTime) - \(endTimeStr)"
            
            scheduleNotification(
                title: title,
                body: body,
                identifier: notificationIdentifier,
                dateComponents: fireDateComponents,
                repeats: true
            )
            
            // 2. Uyku bitişi için alarm (eğer ayarlar varsa)
            if let alarmSettings = alarmSettings, alarmSettings.isEnabled {
                guard let endTimeDate = calendar.date(byAdding: .minute, value: block.duration, to: startTimeDate) else {
                    continue
                }
                
                // Önümüzdeki 7 gün için alarmları planla
                for dayOffset in 0..<7 {
                    guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }
                    
                    let endComponents = calendar.dateComponents([.hour, .minute], from: endTimeDate)
                    guard let finalEndTime = calendar.date(bySettingHour: endComponents.hour ?? 0,
                                                          minute: endComponents.minute ?? 0,
                                                          second: 0,
                                                          of: targetDate) else { continue }
                    
                    // Geçmiş zamanlar için alarm planlamayı atla
                    if finalEndTime <= Date() { continue }
                    
                    await alarmService.scheduleAlarmForSleepBlockEnd(
                        blockId: block.id,
                        scheduleId: UUID(), // Geçici - gerçek schedule ID'si kullanılacak
                        userId: UUID(), // Geçici - gerçek user ID'si kullanılacak
                        endTime: finalEndTime,
                        alarmSettings: alarmSettings,
                        modelContext: modelContext
                    )
                }
            }
        }
    }
    
    /// UserScheduleModel'i ScheduleEntity'ye dönüştürür (geçici helper)
    private func convertToScheduleEntity(_ schedule: UserScheduleModel) -> ScheduleEntity? {
        // Bu fonksiyon gerçek implementasyonda daha detaylı olacak
        let entity = ScheduleEntity(
            userId: UUID(), // Gerçek user ID
            name: schedule.name,
            totalSleepHours: schedule.totalSleepHours
        )
        return entity
    }
    
    // MARK: - Notification Categories
    
    /// Bildirim kategorilerini kaydet
    private func registerNotificationCategories() {
        // Uyku hatırlatıcısı kategorisi
        let sleepReminderCategory = UNNotificationCategory(
            identifier: "SLEEP_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        // Alarm kategorisi - AlarmNotificationService ile senkronize
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "⏰ Ertele (5dk)",
            options: [.foreground]
        )
        
        let stopAction = UNNotificationAction(
            identifier: "STOP_ACTION",
            title: "⏹️ Kapat",
            options: [.destructive, .authenticationRequired]
        )
        
        let alarmCategory = UNNotificationCategory(
            identifier: "SLEEP_ALARM",
            actions: [snoozeAction, stopAction],
            intentIdentifiers: [],
            options: [.customDismissAction, .allowInCarPlay]
        )
        
        notificationCenter.setNotificationCategories([sleepReminderCategory, alarmCategory])
        print("PolyNap Debug: Tüm bildirim kategorileri kaydedildi")
    }
} 