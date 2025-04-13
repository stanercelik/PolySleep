import SwiftUI
// OneSignal ana framework'ünü import et
import OneSignalFramework
import UserNotifications // Apple'ın bildirim framework'ünü import et

class OneSignalNotificationService {
    static let shared = OneSignalNotificationService()
    
    // App ID'yi SupabaseConfig'ten oku
    private let oneSignalAppId = SupabaseConfig.oneSignalAppId
    
    private let notificationCenter = UNUserNotificationCenter.current() // Apple'ın bildirim merkezi
    
    private init() {}
    
    /// OneSignal servisini başlatır ve konfigüre eder
    func initialize() {
        // App ID'nin var olduğundan ve boş olmadığından emin ol
        guard !oneSignalAppId.isEmpty else {
            print("HATA: OneSignal App ID SupabaseConfig'te bulunamadı veya boş. Lütfen SupabaseConfig.swift dosyasını veya Environment Variable'ları kontrol edin.")
            return
        }
        
        // SDK'yı başlat
        print("OneSignal SDK başlatılıyor, App ID: \(oneSignalAppId.prefix(5))...") // ID'nin tamamını loglamamak daha güvenli
        OneSignal.initialize(oneSignalAppId, withLaunchOptions: nil)
        
        // Kullanıcı izinlerini OneSignal üzerinden iste (arka planda UNUserNotificationCenter'ı kullanır)
        OneSignal.Notifications.requestPermission({ accepted in
            print("PolySleep: OneSignal - Kullanıcı bildirimleri \(accepted ? "kabul etti" : "reddetti")")
        }, fallbackToSettings: true)
    }
    
    /// Kullanıcıyı benzersiz ID ile tanımlar
    func setExternalUserId(_ userId: String) {
        OneSignal.login(userId)
    }
    
    /// Bildirim etiketleri ekler
    func addTags(_ tags: [String: String]) {
        OneSignal.User.addTags(tags)
    }
    
    /// Belirli bir zamanda Apple UNUserNotificationCenter kullanarak yerel bildirim planlar
    func scheduleLocalNotification(identifier: String, title: String, message: String, triggerDate: Date, additionalData: [String: Any]? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default // Varsayılan bildirim sesi
        
        if let data = additionalData {
            content.userInfo = data
        }
        
        // Bildirimi tetikleyecek zamanı hesapla
        let triggerDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
        
        // Bildirim isteğini oluştur
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Bildirimi sisteme ekle
        notificationCenter.add(request) { error in
            if let error = error {
                print("Yerel bildirim planlama hatası: \(identifier) - \(error.localizedDescription)")
            } else {
                print("Yerel bildirim başarıyla planlandı: \(identifier)")
            }
        }
    }
    
    /// Ana uyku öncesi bildirim planla
    func scheduleCoreNotification(sleepBlock: SleepBlock, minutesBefore: Int) {
        guard minutesBefore > 0 else { return }
        
        guard let timeComponents = TimeFormatter.time(from: sleepBlock.startTime) else { return }
        
        let now = Date()
        let calendar = Calendar.current
        
        guard let sleepTime = calendar.date(bySettingHour: timeComponents.hour, minute: timeComponents.minute, second: 0, of: now) else { return }
        
        guard let notificationTime = calendar.date(byAdding: .minute, value: -minutesBefore, to: sleepTime) else { return }
        
        var finalNotificationTime = notificationTime
        if finalNotificationTime < now {
            finalNotificationTime = calendar.date(byAdding: .day, value: 1, to: notificationTime) ?? notificationTime
        }
        
        let title = "Ana Uyku Zamanı Yaklaşıyor"
        let message = "\(formatTime(minutes: minutesBefore)) sonra ana uyku zamanınız başlayacak."
        
        // Benzersiz bir bildirim ID'si oluştur
        let identifier = "core_sleep_reminder_\(sleepBlock.id.uuidString)"
        
        scheduleLocalNotification(
            identifier: identifier,
            title: title,
            message: message,
            triggerDate: finalNotificationTime,
            additionalData: ["blockType": "core", "startTime": sleepBlock.startTime, "blockId": sleepBlock.id.uuidString]
        )
    }
    
    /// Şekerleme öncesi bildirim planla
    func scheduleNapNotification(sleepBlock: SleepBlock, minutesBefore: Int) {
        guard minutesBefore > 0 else { return }
        guard !sleepBlock.isCore else { return }
        
        guard let timeComponents = TimeFormatter.time(from: sleepBlock.startTime) else { return }
        
        let now = Date()
        let calendar = Calendar.current
        
        guard let sleepTime = calendar.date(bySettingHour: timeComponents.hour, minute: timeComponents.minute, second: 0, of: now) else { return }
        
        guard let notificationTime = calendar.date(byAdding: .minute, value: -minutesBefore, to: sleepTime) else { return }
        
        var finalNotificationTime = notificationTime
        if finalNotificationTime < now {
            finalNotificationTime = calendar.date(byAdding: .day, value: 1, to: notificationTime) ?? notificationTime
        }
        
        let title = "Şekerleme Zamanı Yaklaşıyor"
        let message = "\(formatTime(minutes: minutesBefore)) sonra şekerlemeniz başlayacak."
        
        // Benzersiz bir bildirim ID'si oluştur
        let identifier = "nap_reminder_\(sleepBlock.id.uuidString)"
        
        scheduleLocalNotification(
            identifier: identifier,
            title: title,
            message: message,
            triggerDate: finalNotificationTime,
            additionalData: ["blockType": "nap", "startTime": sleepBlock.startTime, "blockId": sleepBlock.id.uuidString]
        )
    }
    
    /// Aktif programdaki tüm uyku blokları için bildirimleri planla
    func scheduleAllNotificationsForActiveSchedule(schedule: UserScheduleModel) {
        clearAllScheduledNotifications() // Önce eski hatırlatıcıları temizle
        
        let coreNotificationTime = UserDefaults.standard.double(forKey: "coreNotificationTime")
        let napNotificationTime = UserDefaults.standard.double(forKey: "napNotificationTime")
        
        // --- DEBUG PRINT --- //
        print("--- Bildirim Planlama Başladı ---")
        print("Aktif Program: \(schedule.name)")
        print("Okunan Ayarlar: Core=\(coreNotificationTime)dk, Nap=\(napNotificationTime)dk")
        print("Toplam Blok Sayısı: \(schedule.schedule.count)")
        // --- END DEBUG PRINT --- //
        
        guard coreNotificationTime > 0 || napNotificationTime > 0 else {
            print("Bildirim süreleri sıfır, planlama yapılmayacak.")
            print("--- Bildirim Planlama Bitti (Süreler Sıfır) ---")
            return
        }
        
        for (index, block) in schedule.schedule.enumerated() {
            // --- DEBUG PRINT --- //
            print("Blok \(index + 1)/\(schedule.schedule.count): ID=\(block.id), Başlangıç=\(block.startTime), Süre=\(block.duration), Tip=\(block.isCore ? "Core" : "Nap")")
            // --- END DEBUG PRINT --- //
            
            let coreIdentifier = "core_sleep_reminder_\(block.id.uuidString)"
            let napIdentifier = "nap_reminder_\(block.id.uuidString)"

            notificationCenter.removePendingNotificationRequests(withIdentifiers: [coreIdentifier, napIdentifier])

            if block.isCore && coreNotificationTime > 0 {
                 // --- DEBUG PRINT --- //
                print("-> Ana uyku bildirimi planlanıyor (Süre: \(Int(coreNotificationTime))dk)")
                // --- END DEBUG PRINT --- //
                scheduleCoreNotification(sleepBlock: block, minutesBefore: Int(coreNotificationTime))
            } else if !block.isCore && napNotificationTime > 0 {
                 // --- DEBUG PRINT --- //
                print("-> Şekerleme bildirimi planlanıyor (Süre: \(Int(napNotificationTime))dk)")
                // --- END DEBUG PRINT --- //
                scheduleNapNotification(sleepBlock: block, minutesBefore: Int(napNotificationTime))
            } else {
                // --- DEBUG PRINT --- //
                print("-> Bu blok için bildirim koşulları sağlanmadı (Core Zamanı: \(coreNotificationTime), Nap Zamanı: \(napNotificationTime))")
                // --- END DEBUG PRINT --- //
            }
        }
        // --- DEBUG PRINT --- //
        print("--- Bildirim Planlama Bitti ---")
        // --- END DEBUG PRINT --- //
    }
    
    /// Tüm planlanmış PolySleep hatırlatıcı bildirimlerini temizle
    func clearAllScheduledNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            // Sadece bizim planladığımız (belirli bir prefix ile başlayan) bildirimleri bul
            let polySleepIdentifiers = requests.filter { 
                $0.identifier.starts(with: "core_sleep_reminder_") || $0.identifier.starts(with: "nap_reminder_") 
            }.map { $0.identifier }
            
            if !polySleepIdentifiers.isEmpty {
                print("Temizlenen PolySleep bildirimleri: \(polySleepIdentifiers)")
                self.notificationCenter.removePendingNotificationRequests(withIdentifiers: polySleepIdentifiers)
            } else {
                print("Temizlenecek PolySleep bildirimi bulunamadı.")
            }
        }
    }
    
    /// Dakikaları formatlı metne çevirir
    private func formatTime(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) dakika"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            
            if remainingMinutes == 0 {
                return "\(hours) saat"
            } else {
                return "\(hours) saat \(remainingMinutes) dakika"
            }
        }
    }
} 
