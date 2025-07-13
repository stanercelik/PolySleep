import Foundation
import UserNotifications
import SwiftData
import UIKit

@MainActor
final class AlarmService: ObservableObject {
    static let shared = AlarmService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let calendar = Calendar.current
    
    // iOS'in izin verdiği maksimum bildirim sayısı 64'tür, güvenli bir sınır olarak 60 kullanıyoruz.
    private let notificationLimit = 60
    
    // Bildirim kategori tanımlayıcıları
    static let alarmCategoryIdentifier = "ALARM_CATEGORY"
    static let reminderCategoryIdentifier = "REMINDER_CATEGORY"

    // Bu sadece bir kez çağrılır.
    private init() {
        Task {
            await requestAuthorization()
            await registerNotificationCategories()
        }
    }

    // MARK: - Yetkilendirme ve Kurulum

    /// Kullanıcıdan bildirim izni ister.
    func requestAuthorization() async {
        do {
            // Alarmların zamanında teslim edilmesi için .timeSensitive önemlidir.
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge, .timeSensitive])
            if granted {
                print("✅ AlarmService: Bildirim izni verildi.")
            } else {
                print("⚠️ AlarmService: Bildirim izni reddedildi.")
            }
        } catch {
            print("🚨 AlarmService: Bildirim izni istenirken hata: \(error.localizedDescription)")
        }
    }
    
    /// "Ertele" ve "Kapat" gibi eylemlerle bildirim kategorilerini kaydeder.
    private func registerNotificationCategories() async {
        // ALARM Kategorisi (Eylemli)
        let snoozeAction = UNNotificationAction(identifier: "SNOOZE_ACTION", title: L("alarm.action.snooze", table: "Alarms"), options: [])
        let stopAction = UNNotificationAction(identifier: "STOP_ACTION", title: L("alarm.action.stop", table: "Alarms"), options: [.destructive])
        let alarmCategory = UNNotificationCategory(
            identifier: Self.alarmCategoryIdentifier,
            actions: [snoozeAction, stopAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // HATIRLATICI Kategorisi (Eylemsiz)
        let reminderCategory = UNNotificationCategory(
            identifier: Self.reminderCategoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([alarmCategory, reminderCategory])
        print("✅ AlarmService: Bildirim kategorileri (Alarm ve Hatırlatıcı) kaydedildi.")
    }

    // MARK: - Ana Planlama Mantığı

    /// Aktif uyku programı için tüm alarmları ve hatırlatıcıları planlayan ana fonksiyondur.
    /// Kullanıcının programı veya alarm ayarları değiştiğinde çağrılmalıdır.
    func rescheduleNotificationsForActiveSchedule(modelContext: ModelContext) async {
        // 1. Gerekli ayarları ve programı SwiftData'dan al
        guard let activeSchedule = try? getActiveSchedule(context: modelContext) else {
            print("ℹ️ AlarmService: Aktif program bulunamadı. Tüm bildirimler iptal ediliyor.")
            await cancelAllNotifications()
            return
        }
        
        guard let alarmSettings = try? getAlarmSettings(context: modelContext) else {
            print("ℹ️ AlarmService: Alarm ayarları bulunamadı. Sadece hatırlatıcılar planlanacak.")
            return // Ayarlar yoksa devam etme
        }
        
        guard let userPreferences = try? getUserPreferences(context: modelContext) else {
            print("ℹ️ AlarmService: Kullanıcı tercihleri bulunamadı.")
            return
        }
        
        print("🔄 AlarmService: '\(activeSchedule.name)' programı için bildirimler yeniden planlanıyor...")
        
        // 2. Kopya bildirimleri önlemek için önceden planlanmış tüm bildirimleri iptal et
        await cancelAllNotifications()
        
        var scheduledCount = 0
        
        // 3. Gelecek 7 gün için uyku bloklarını işle
        let futureBlocks = calculateFutureBlocks(for: activeSchedule, daysInAdvance: 7)
        
        for blockInstance in futureBlocks {
            // Limiti kontrol et
            if scheduledCount >= notificationLimit {
                print("⚠️ AlarmService: Bildirim limitine (\(notificationLimit)) ulaşıldı. Planlama durduruldu.")
                break
            }
            
            // 4. UYKU ALARMINI PLANLA (eğer alarmlar aktifse)
            if alarmSettings.isEnabled {
                await scheduleAlarm(at: blockInstance.endDate, with: alarmSettings, for: activeSchedule)
                scheduledCount += 1
            }
            
            // 5. HATIRLATICI BİLDİRİMİNİ PLANLA (eğer hatırlatma süresi 0'dan büyükse)
            let leadTime = userPreferences.reminderLeadTimeInMinutes
            if leadTime > 0 {
                let reminderDate = blockInstance.startDate.addingTimeInterval(-Double(leadTime * 60))
                // Sadece gelecekteki hatırlatıcıları planla
                if reminderDate > Date() {
                    await scheduleReminder(at: reminderDate, for: blockInstance)
                    scheduledCount += 1
                }
            }
        }
        
        print("✅ AlarmService: Başarıyla \(scheduledCount) bildirim (alarm ve hatırlatıcı) planlandı.")
        await printPendingNotifications() // Hata ayıklama için
    }

    // MARK: - Anlık Alarm Tetikleme

    /// Bir uyku bloğu bittiğinde senaryolara göre anında alarmı tetikler.
    /// - `MainScreenViewModel`'den çağrılır.
    func triggerAlarmForEndedBlock(block: SleepBlock, settings: AlarmSettings) async {
        let applicationState = await UIApplication.shared.applicationState
        
        // Duplicate alarm check - aynı block için zaten scheduled alarm var mı?
        let blockEndTime = Date() // Şu an bitiş zamanı
        let tolerance: TimeInterval = 120 // 2 dakika tolerans (daha geniş)
        
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let hasScheduledAlarm = pendingRequests.contains { request in
            guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
                  let triggerDate = trigger.nextTriggerDate() else { return false }
            
            let timeDiff = abs(triggerDate.timeIntervalSince(blockEndTime))
            let isAlarmCategory = request.content.categoryIdentifier == Self.alarmCategoryIdentifier
            let isScheduledAlarm = request.content.userInfo["isScheduledAlarm"] as? Bool == true
            
            return timeDiff < tolerance && isAlarmCategory && isScheduledAlarm
        }
        
        // Eğer scheduled alarm varsa ve background'daysa, duplicate alarm oluşturma
        if hasScheduledAlarm && applicationState != .active {
            print("⚠️ AlarmService: Bu blok için zaten scheduled alarm var ve uygulama background'da, duplicate oluşturulmuyor.")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = L("alarm.wake.title", table: "Alarms")
        content.body = L("alarm.wake.body", table: "Alarms")
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: settings.soundName))
        content.categoryIdentifier = Self.alarmCategoryIdentifier
        content.interruptionLevel = .timeSensitive // Bu, "Rahatsız Etme" modunu bile atlamasını sağlar
        content.badge = 1
        content.userInfo = [
            "soundName": settings.soundName,
            "blockId": block.id.uuidString,
            "isInstantAlarm": true  // Bu instant alarm olduğunu belirtir
        ]

        if applicationState == .active {
            // Senaryo 3: Uygulama ön planda
            // Hemen UI'ı güncellemek için bir bildirim gönder.
            print("▶️ AlarmService: Uygulama ön planda. Alarm görünümünü tetiklemek için bildirim gönderiliyor.")
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .startAlarm,
                    object: nil,
                    userInfo: content.userInfo
                )
            }
        } else {
            // Senaryo 1 & 2: Uygulama arka planda veya kapalı
            // Background'da zaten scheduled alarm var, duplicate oluşturma
            print("🔍 AlarmService: Uygulama background/closed - scheduled alarm'a güveniyoruz, duplicate oluşturulmuyor.")
            
            // Background'dan foreground'a geçişte alarm'ı tetiklemek için state kaydı
            await MainActor.run {
                UserDefaults.standard.set(true, forKey: "pendingBackgroundAlarm")
                UserDefaults.standard.set(content.userInfo, forKey: "pendingAlarmInfo")
                print("📝 AlarmService: Background alarm state kaydedildi.")
            }
        }
    }

    // MARK: - Yardımcı Planlama Fonksiyonları

    private func scheduleAlarm(at date: Date, with settings: AlarmSettings, for schedule: UserSchedule) async {
        let content = UNMutableNotificationContent()
        content.title = L("alarm.wake.scheduled.title", table: "Alarms")
        content.body = L("alarm.wake.scheduled.body", table: "Alarms")
        content.categoryIdentifier = Self.alarmCategoryIdentifier
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: settings.soundName))
        content.interruptionLevel = .timeSensitive
        content.badge = 1
        content.userInfo = [
            "scheduleId": schedule.id.uuidString, 
            "soundName": settings.soundName,
            "isScheduledAlarm": true
        ]
        
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "alarm-\(date.timeIntervalSince1970)", content: content, trigger: trigger)
        
        do { try await notificationCenter.add(request) }
        catch { print("🚨 AlarmService: Alarm planlanamadı: \(error.localizedDescription)") }
    }
    
    private func scheduleReminder(at date: Date, for block: BlockInstance) async {
        let content = UNMutableNotificationContent()
        content.title = L("alarm.sleep.title", table: "Alarms")
        
        // 24 saatlik format için DateFormatter kullan
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.locale = Locale(identifier: "en_GB")
        let startTimeFormatted = timeFormatter.string(from: block.startDate)
        
        content.body = String(format: L("alarm.sleep.reminder.body", table: "Alarms"), block.scheduleName, startTimeFormatted)
        content.categoryIdentifier = Self.reminderCategoryIdentifier
        content.sound = .default
        
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "reminder-\(date.timeIntervalSince1970)", content: content, trigger: trigger)

        do { try await notificationCenter.add(request) }
        catch { print("🚨 AlarmService: Hatırlatıcı planlanamadı: \(error.localizedDescription)") }
    }

    // MARK: - Veri Çekme ve Hesaplama

    private func getActiveSchedule(context: ModelContext) throws -> UserSchedule? {
        let descriptor = FetchDescriptor<UserSchedule>(predicate: #Predicate { $0.isActive == true })
        return try context.fetch(descriptor).first
    }

    private func getAlarmSettings(context: ModelContext) throws -> AlarmSettings? {
        let descriptor = FetchDescriptor<AlarmSettings>()
        return try context.fetch(descriptor).first
    }
    
    private func getUserPreferences(context: ModelContext) throws -> UserPreferences? {
        let descriptor = FetchDescriptor<UserPreferences>()
        return try context.fetch(descriptor).first
    }

    private struct BlockInstance {
        let startDate: Date
        let endDate: Date
        let scheduleName: String
    }

    private func calculateFutureBlocks(for schedule: UserSchedule, daysInAdvance: Int) -> [BlockInstance] {
        var instances: [BlockInstance] = []
        let today = calendar.startOfDay(for: Date())
        
        guard let blocks = schedule.sleepBlocks else { return [] }

        for dayOffset in 0..<daysInAdvance {
            guard let targetDay = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            for block in blocks {
                let startComponents = calendar.dateComponents([.hour, .minute], from: block.startTime)
                guard var blockStartDate = calendar.date(bySettingHour: startComponents.hour!, minute: startComponents.minute!, second: 0, of: targetDay) else { continue }
                
                var blockEndDate = blockStartDate.addingTimeInterval(TimeInterval(block.durationMinutes * 60))
                
                // Bitiş saati başlangıçtan küçükse (gece yarısını aşıyorsa), hem başlangıç hem de bitiş tarihini bir gün ileri al
                let endComponents = calendar.dateComponents([.hour, .minute], from: block.endTime)
                if endComponents.hour! < startComponents.hour! {
                     blockEndDate = calendar.date(byAdding: .day, value: 1, to: blockEndDate)!
                     if blockStartDate > blockEndDate { // Örn: 23:00'da başlayan blok için, hedef gün 1 ise başlangıç 1. gün 23:00 olmalı.
                         blockStartDate = calendar.date(byAdding: .day, value: -1, to: blockStartDate)!
                     }
                }
                
                if blockEndDate > Date() {
                    instances.append(BlockInstance(startDate: blockStartDate, endDate: blockEndDate, scheduleName: schedule.name))
                }
            }
        }
        return instances.sorted { $0.startDate < $1.startDate }
    }
    
    // MARK: - Alarm Yönetimi

    /// Erteleme için tek seferlik bir alarm planlar.
    func snoozeAlarm(from notification: UNNotification) async {
        // Erteleme süresini ayarlardan al (veya varsayılan kullan).
        // Basitlik için burada 5 dakika kullanıyoruz.
        let snoozeMinutes = 5
        let snoozeDate = Date().addingTimeInterval(TimeInterval(snoozeMinutes * 60))
        
        let content = notification.request.content.mutableCopy() as! UNMutableNotificationContent
        content.title = L("alarm.snoozed.title", table: "Alarms")
        content.body = L("alarm.snoozed.body", table: "Alarms")
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: snoozeDate.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(identifier: "snooze-\(UUID().uuidString)", content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("✅ AlarmService: Alarm \(snoozeMinutes) dakika ertelendi.")
        } catch {
            print("🚨 AlarmService: Erteleme alarmı planlanamadı: \(error.localizedDescription)")
        }
    }
    
    /// Planlanmış tüm alarm bildirimlerini iptal eder.
    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        await MainActor.run {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        print("🗑️ AlarmService: Tüm bekleyen bildirimler iptal edildi.")
    }

    /// Hızlı, tek seferlik bir test bildirimi planlar.
    public func scheduleTestNotification(soundName: String, volume: Float) async {
        let content = UNMutableNotificationContent()
        content.title = L("alarm.test.title", table: "Alarms")
        content.body = L("alarm.test.body", table: "Alarms")
        content.categoryIdentifier = Self.alarmCategoryIdentifier // Eylemleri göstermek için
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName))
        content.interruptionLevel = .timeSensitive
        content.userInfo = [
            "soundName": soundName,
            "isTestAlarm": true // Test alarmı olduğunu belirtelim
        ]

        let identifier = "test-alarm-\(UUID().uuidString)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false) // 5 saniye içinde
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            print("✅ AlarmService: 5 saniye içinde çalacak test alarmı planlandı.")
            print("📋 AlarmService: Test alarm ID: \(identifier)")
            print("📋 AlarmService: Test alarm categoryIdentifier: \(content.categoryIdentifier)")
            print("📋 AlarmService: Test alarm userInfo: \(content.userInfo)")
        } catch {
            print("🚨 AlarmService: Test alarmı planlanamadı: \(error.localizedDescription)")
        }
    }

    // MARK: - Durum Kontrolü

    public func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    public func getPendingNotificationsCount() async -> Int {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests.count
    }

    // MARK: - Hata Ayıklama
    
    /// Mevcut bekleyen tüm bildirimleri hata ayıklama için konsola yazdırır.
    func printPendingNotifications() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        if requests.isEmpty {
            print("--- 🔔 Bekleyen Bildirim Yok ---")
        } else {
            print("--- 🔔 \(requests.count) Bekleyen Bildirim ---")
            for request in requests {
                let type = request.content.categoryIdentifier == Self.alarmCategoryIdentifier ? "ALARM" : "REMINDER"
                if let trigger = request.trigger as? UNCalendarNotificationTrigger, let date = trigger.nextTriggerDate() {
                    print("  - [\(type)] ID: \(request.identifier), Tarih: \(date.formatted(date: .abbreviated, time: .complete))")
                } else {
                    print("  - [\(type)] ID: \(request.identifier), Tetikleyici: \(String(describing: request.trigger))")
                }
            }
            print("---------------------------------")
        }
    }
}
