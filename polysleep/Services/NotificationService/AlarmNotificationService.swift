import Foundation
import UserNotifications
import SwiftData
import AVFoundation

@MainActor
class AlarmNotificationService: ObservableObject {
    static let shared = AlarmNotificationService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let maxPendingNotifications = 60 // iOS limiti 64, güvenlik için 60
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var pendingNotificationsCount = 0
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization Management
    
    /// Bildirim izin durumunu kontrol eder
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Bildirim izni ister
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge, .criticalAlert]
            )
            
            await MainActor.run {
                self.isAuthorized = granted
                self.authorizationStatus = granted ? .authorized : .denied
            }
            
            if granted {
                print("PolySleep Debug: Alarm bildirimi izni verildi")
            } else {
                print("PolySleep Debug: Alarm bildirimi izni reddedildi")
            }
            
            return granted
        } catch {
            print("PolySleep Debug: Bildirim izni istenirken hata: \(error)")
            return false
        }
    }
    
    // MARK: - Alarm Scheduling
    
    /// Uyku bloğu bitimi için alarm planlar
    func scheduleAlarmForSleepBlockEnd(
        blockId: UUID,
        scheduleId: UUID,
        userId: UUID,
        endTime: Date,
        alarmSettings: AlarmSettings,
        modelContext: ModelContext
    ) async {
        guard isAuthorized else {
            print("PolySleep Debug: Alarm planlanamadı - izin yok")
            return
        }
        
        // Mevcut alarm varsa iptal et
        await cancelAlarmForBlock(blockId: blockId)
        
        let identifier = "alarm_\(blockId.uuidString)"
        
        // Bildirim içeriği oluştur
        let content = UNMutableNotificationContent()
        content.title = "⏰ Uyku Alarmı"
        content.body = "Uyku bloğunuz sona erdi! Uyanma zamanı!"
        content.categoryIdentifier = "SLEEP_ALARM"
        content.userInfo = [
            "blockId": blockId.uuidString,
            "scheduleId": scheduleId.uuidString,
            "userId": userId.uuidString,
            "type": "sleep_alarm"
        ]
        
        // Alarm sesi ayarla
        if let soundURL = Bundle.main.url(forResource: alarmSettings.soundName.replacingOccurrences(of: ".caf", with: ""), withExtension: "caf") {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: alarmSettings.soundName))
        } else {
            content.sound = UNNotificationSound.defaultCritical
        }
        
        // Kritik alarm (Focus/Sessiz modu bypass)
        content.interruptionLevel = .critical
        content.relevanceScore = 1.0
        
        // Trigger oluştur
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: endTime),
            repeats: false
        )
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            
            // Veritabanına kaydet
            let alarmNotification = AlarmNotification(
                userId: userId,
                scheduleId: scheduleId,
                blockId: blockId,
                notificationIdentifier: identifier,
                scheduledTime: endTime
            )
            
            modelContext.insert(alarmNotification)
            try modelContext.save()
            
            await updatePendingNotificationsCount()
            
            print("PolySleep Debug: Alarm planlandı - \(identifier) - \(endTime)")
            
        } catch {
            print("PolySleep Debug: Alarm planlanırken hata: \(error)")
        }
    }
    
    /// Uyku programı için tüm alarmları planlar (just-in-time stratejisi)
    func scheduleAlarmsForSchedule(
        schedule: ScheduleEntity,
        alarmSettings: AlarmSettings,
        modelContext: ModelContext
    ) async {
        guard isAuthorized else {
            print("PolySleep Debug: Alarmlar planlanamadı - izin yok")
            return
        }
        
        // Mevcut alarmları temizle
        await cancelAllAlarmsForSchedule(scheduleId: schedule.id)
        
        let calendar = Calendar.current
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        // Önümüzdeki 7 gün için alarmları planla
        for dayOffset in 0..<7 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            
            for block in schedule.sleepBlocks {
                guard let startTime = dateFormatter.date(from: block.startTime) else { continue }
                
                // Blok bitiş zamanını hesapla
                guard let endTime = calendar.date(byAdding: .minute, value: block.durationMinutes, to: startTime) else { continue }
                
                // Hedef tarihe taşı
                let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
                let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
                
                guard let finalEndTime = calendar.date(bySettingHour: endComponents.hour ?? 0,
                                                      minute: endComponents.minute ?? 0,
                                                      second: 0,
                                                      of: targetDate) else { continue }
                
                // Geçmiş zamanlar için alarm planlamayı atla
                if finalEndTime <= now { continue }
                
                await scheduleAlarmForSleepBlockEnd(
                    blockId: block.id,
                    scheduleId: schedule.id,
                    userId: schedule.userId,
                    endTime: finalEndTime,
                    alarmSettings: alarmSettings,
                    modelContext: modelContext
                )
            }
        }
    }
    
    // MARK: - Alarm Management
    
    /// Belirli bir blok için alarmı iptal eder
    func cancelAlarmForBlock(blockId: UUID) async {
        let identifier = "alarm_\(blockId.uuidString)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        await updatePendingNotificationsCount()
        print("PolySleep Debug: Alarm iptal edildi - \(identifier)")
    }
    
    /// Belirli bir program için tüm alarmları iptal eder
    func cancelAllAlarmsForSchedule(scheduleId: UUID) async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let identifiersToCancel = pendingRequests.compactMap { request in
            let userInfo = request.content.userInfo
            if let requestScheduleId = userInfo["scheduleId"] as? String,
               requestScheduleId == scheduleId.uuidString {
                return request.identifier
            }
            return nil
        }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        await updatePendingNotificationsCount()
        print("PolySleep Debug: Program alarmları iptal edildi - \(scheduleId)")
    }
    
    /// Tüm alarmları iptal eder
    func cancelAllAlarms() async {
        notificationCenter.removeAllPendingNotificationRequests()
        await updatePendingNotificationsCount()
        print("PolySleep Debug: Tüm alarmlar iptal edildi")
    }
    
    /// Erteleme (snooze) işlemi
    func snoozeAlarm(
        blockId: UUID,
        snoozeDurationMinutes: Int,
        alarmSettings: AlarmSettings,
        modelContext: ModelContext
    ) async {
        let snoozeTime = Date().addingTimeInterval(TimeInterval(snoozeDurationMinutes * 60))
        
        // Yeni erteleme alarmı planla
        await scheduleAlarmForSleepBlockEnd(
            blockId: blockId,
            scheduleId: UUID(), // Geçici
            userId: UUID(), // Geçici
            endTime: snoozeTime,
            alarmSettings: alarmSettings,
            modelContext: modelContext
        )
        
        print("PolySleep Debug: Alarm ertelendi - \(snoozeDurationMinutes) dakika")
    }
    
    // MARK: - Utility Functions
    
    /// Bekleyen bildirim sayısını günceller
    private func updatePendingNotificationsCount() async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let alarmCount = pendingRequests.filter { request in
            let userInfo = request.content.userInfo
            return userInfo["type"] as? String == "sleep_alarm"
        }.count
        
        await MainActor.run {
            self.pendingNotificationsCount = alarmCount
        }
    }
    
    /// Bekleyen alarm bildirimlerini listeler
    func getPendingAlarms() async -> [UNNotificationRequest] {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        return pendingRequests.filter { request in
            let userInfo = request.content.userInfo
            return userInfo["type"] as? String == "sleep_alarm"
        }
    }
    
    /// Alarm limit kontrolü
    func canScheduleMoreAlarms() async -> Bool {
        await updatePendingNotificationsCount()
        return pendingNotificationsCount < maxPendingNotifications
    }
    
    /// Fallback uyarısı göster (izin yoksa veya sessiz modda)
    func showFallbackAlert(for blockId: UUID) {
        // Bu fonksiyon UI tarafında implement edilecek
        // NotificationCenter ile UI'ya mesaj gönderebilir
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowFallbackAlarmAlert"),
            object: nil,
            userInfo: ["blockId": blockId.uuidString]
        )
    }
}

// MARK: - Notification Categories
extension AlarmNotificationService {
    /// Bildirim kategorilerini kaydet
    func registerNotificationCategories() {
        // Ertele butonu - yeşil renk
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "⏰ Ertele (5dk)",
            options: [.foreground]
        )
        
        // Kapat butonu - kırmızı renk, destructive
        let stopAction = UNNotificationAction(
            identifier: "STOP_ACTION",
            title: "⏹️ Kapat",
            options: [.destructive, .authenticationRequired]
        )
        
        // Alarm kategorisi - butonları sıralı şekilde göster
        let alarmCategory = UNNotificationCategory(
            identifier: "SLEEP_ALARM",
            actions: [snoozeAction, stopAction],
            intentIdentifiers: [],
            options: [.customDismissAction, .allowInCarPlay]
        )
        
        notificationCenter.setNotificationCategories([alarmCategory])
        print("PolySleep Debug: Alarm bildirim kategorileri kaydedildi")
    }
} 