import Foundation
import UserNotifications

class LocalNotificationService: ObservableObject {
    static let shared = LocalNotificationService()
    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission Handling

    /// Kullanıcıdan bildirim izni ister.
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("PolySleep Debug: Bildirim izni verildi.")
            } else if let error = error {
                print("PolySleep Debug: Bildirim izni istenirken hata oluştu: \(error.localizedDescription)")
            } else {
                print("PolySleep Debug: Bildirim izni reddedildi.")
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
                print("PolySleep Debug: Bildirim planlanırken hata oluştu (\(identifier)): \(error.localizedDescription)")
            } else {
                if let hour = dateComponents.hour, let minute = dateComponents.minute {
                    print("PolySleep Debug: Bildirim başarıyla planlandı: \(identifier) - \(String(format: "%02d:%02d", hour, minute))")
                } else {
                    print("PolySleep Debug: Bildirim başarıyla planlandı: \(identifier) (saat/dakika bilgisi eksik)")
                }
            }
        }
    }
    
    /// Aktif uyku programındaki tüm bloklar için bildirimleri planlar.
    /// Bu fonksiyon, ScheduleManager tarafından çağrılacak.
    /// Detaylı implementasyon daha sonra eklenecek.
    func scheduleNotificationsForActiveSchedule(schedule: UserScheduleModel, leadTimeMinutes: Int) {
        print("PolySleep Debug: \(schedule.name) için bildirimler \(leadTimeMinutes) dakika önce planlanacak...")
        
        cancelAllNotifications()
        
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"

        for block in schedule.schedule {
            guard let startTimeDate = dateFormatter.date(from: block.startTime) else {
                print("PolySleep Debug: Geçersiz başlangıç saati formatı: \(block.startTime) blok ID: \(block.id)")
                continue
            }
            
            guard let notificationTime = calendar.date(byAdding: .minute, value: -leadTimeMinutes, to: startTimeDate) else {
                print("PolySleep Debug: Bildirim zamanı hesaplanamadı, blok ID: \(block.id)")
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
        print("PolySleep Debug: Bildirim iptal edildi: \(identifier)")
    }

    /// Planlanmış tüm bildirimleri iptal eder.
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("PolySleep Debug: Tüm planlanmış bildirimler iptal edildi.")
    }

    /// Teslim edilmiş belirli bir bildirimi kaldırır.
    func removeDeliveredNotification(identifier: String) {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
        print("PolySleep Debug: Teslim edilmiş bildirim kaldırıldı: \(identifier)")
    }

    /// Teslim edilmiş tüm bildirimleri kaldırır.
    func removeAllDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        print("PolySleep Debug: Teslim edilmiş tüm bildirimler kaldırıldı.")
    }
} 