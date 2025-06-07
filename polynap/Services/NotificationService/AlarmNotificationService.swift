import Foundation
import UserNotifications
import SwiftData
import AVFoundation
import UIKit

@MainActor
class AlarmNotificationService: ObservableObject {
    static let shared = AlarmNotificationService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let maxPendingNotifications = 60 // iOS limiti 64, güvenlik için 60
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var pendingNotificationsCount = 0
    @Published var isLongAlarmActive = false
    
    // Uzun süreli alarm için - Medium makalesinden esinlenerek optimize edildi
    private var longAlarmTimer: Timer?
    private var alarmStartTime: Date?
    private let alarmDuration: TimeInterval = 30 // 30 saniye alarm süresi
    private let notificationInterval: TimeInterval = 2 // Her 2 saniyede bir bildirim (daha etkili)
    
    // Mevcut alarm ses dosyaları (Medium makalesine uygun .caf formatında)
    private let availableAlarmSounds: [String: String] = [
        "default": "alarm.caf",
        "classic": "alarm.caf",
        "urgent": "alarm.caf"
    ]
    
    private init() {
        checkAuthorizationStatus()
        registerNotificationCategories()
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
    
    /// Medium makalesine göre bildirim izni ister - critical alert olmadan
    func requestAuthorization() async -> Bool {
        do {
            // Critical alert özellikle hariç bırakıldı (Medium makalesi önerisi)
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            await MainActor.run {
                self.isAuthorized = granted
                self.authorizationStatus = granted ? .authorized : .denied
            }
            
            if granted {
                print("PolyNap Debug: Alarm bildirimi izni verildi (normal mod)")
            } else {
                print("PolyNap Debug: Alarm bildirimi izni reddedildi")
            }
            
            return granted
        } catch {
            print("PolyNap Debug: Bildirim izni istenirken hata: \(error)")
            return false
        }
    }
    
    // MARK: - Enhanced Alarm Sound System (Medium makalesine göre)
    
    /// Medium makalesindeki önerilere göre alarm sesi ayarlar
    private func createAlarmSound(soundName: String) -> UNNotificationSound {
        // .caf formatındaki ses dosyalarını kontrol et
        if let _ = Bundle.main.url(forResource: soundName.replacingOccurrences(of: ".caf", with: ""), withExtension: "caf") {
            return UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName))
        } else {
            print("PolyNap Debug: Özel ses bulunamadı (\(soundName)), varsayılan alarm sesi kullanılacak")
            // Sistem varsayılanından daha güçlü bir ses
            return UNNotificationSound.defaultCritical
        }
    }
    
    /// Alarm sesi geçerlilik kontrolü (≤ 30 saniye)
    private func validateAlarmSoundDuration(soundName: String) -> Bool {
        guard let soundURL = Bundle.main.url(forResource: soundName.replacingOccurrences(of: ".caf", with: ""), withExtension: "caf") else {
            return false
        }
        
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            let duration = audioPlayer.duration
            
            if duration > 30.0 {
                print("PolyNap Debug: Uyarı - Ses dosyası 30 saniyeden uzun (\(duration)s), kesilme riski var")
                return false
            }
            
            print("PolyNap Debug: Ses dosyası geçerli - \(duration) saniye")
            return true
        } catch {
            print("PolyNap Debug: Ses dosyası kontrol edilemedi: \(error)")
            return false
        }
    }
    
    // MARK: - Long Duration Alarm System (Enhanced)
    
    /// Medium makalesine göre 30 saniye boyunca SADECE BİR ALARM çalan güçlü alarm başlatır
    func startLongDurationAlarm(
        blockId: UUID,
        scheduleId: UUID,
        userId: UUID,
        alarmSettings: AlarmSettings
    ) {
        guard isAuthorized && !isLongAlarmActive else {
            print("PolyNap Debug: Uzun alarm başlatılamadı - izin yok veya zaten aktif")
            showFallbackAlert(for: blockId)
            return
        }
        
        // Önce aynı block için mevcut alarmları iptal et
        Task {
            await cancelAlarmForBlock(blockId: blockId)
        }
        
        isLongAlarmActive = true
        alarmStartTime = Date()
        
        print("PolyNap Debug: 30 saniye TEKLI güçlü alarm başlatıldı")
        
        // Ses dosyası geçerliliğini kontrol et
        if !validateAlarmSoundDuration(soundName: alarmSettings.soundName) {
            print("PolyNap Debug: Ses dosyası sorunlu, varsayılan kullanılacak")
        }
        
        // Audio manager ile sürekli ses çalmayı başlat (TEK SES ÇALMAK İÇİN)
        Task {
            await AlarmAudioManager.shared.startAlarmAudio(
                soundName: alarmSettings.soundName,
                volume: Float(alarmSettings.volume)
            )
        }
        
        // SADECE BİR TEK ALARM BİLDİRİMİ GÖNDER (notification spam yapmayacağız)
        scheduleInstantAlarmNotification(
            blockId: blockId,
            scheduleId: scheduleId,
            userId: userId,
            iteration: 0,
            alarmSettings: alarmSettings
        )
        
        // 30 saniye sonra kesinlikle durdur
        DispatchQueue.main.asyncAfter(deadline: .now() + alarmDuration) { [weak self] in
            self?.stopLongDurationAlarm()
        }
    }
    
    /// Medium makalesine göre anlık alarm bildirimi planlar (güçlendirilmiş)
    private func scheduleInstantAlarmNotification(
        blockId: UUID,
        scheduleId: UUID,
        userId: UUID,
        iteration: Int,
        alarmSettings: AlarmSettings
    ) {
        let identifier = "long_alarm_\(blockId.uuidString)_\(iteration)_\(Date().timeIntervalSince1970)"
        
        let content = UNMutableNotificationContent()
        content.title = "⏰ UYANMA ALARMI!"
        content.body = "Uyku bloğunuz sona erdi! Hemen uyanın! (\(iteration + 1)/15)"
        content.categoryIdentifier = "LONG_SLEEP_ALARM"
        content.userInfo = [
            "blockId": blockId.uuidString,
            "scheduleId": scheduleId.uuidString,
            "userId": userId.uuidString,
            "type": "long_sleep_alarm",
            "iteration": iteration
        ]
        
        // Medium makalesine göre ses ayarları - critical alert olmadan
        content.sound = createAlarmSound(soundName: alarmSettings.soundName)
        
        // iOS 15+ için maksimum önem derecesi (critical alert olmadan)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive // Critical değil, time-sensitive
            content.relevanceScore = 1.0
        }
        
        // Badge sayısını artır (kullanıcının dikkatini çekmek için)
        content.badge = NSNumber(value: iteration + 1)
        
        // 0.5 saniye sonra tetikle (daha hızlı)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("PolyNap Debug: Anlık alarm bildirimi eklenirken hata: \(error)")
            } else {
                print("PolyNap Debug: Güçlü alarm bildirimi eklendi - iterasyon \(iteration)")
            }
        }
    }
    
    /// Uzun süreli alarmı durdurur
    func stopLongDurationAlarm() {
        guard isLongAlarmActive else { return }
        
        isLongAlarmActive = false
        longAlarmTimer?.invalidate()
        longAlarmTimer = nil
        alarmStartTime = nil
        
        // Badge'i temizle
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // Audio manager'da sesi durdur
        Task {
            await AlarmAudioManager.shared.stopAlarmAudio()
        }
        
        print("PolyNap Debug: Uzun alarm durduruldu, badge temizlendi")
        
        // İlgili tüm bekleyen bildirimleri temizle
        notificationCenter.getPendingNotificationRequests { requests in
            let longAlarmIdentifiers = requests.compactMap { request in
                if request.identifier.contains("long_alarm_") {
                    return request.identifier
                }
                return nil
            }
            
            if !longAlarmIdentifiers.isEmpty {
                self.notificationCenter.removePendingNotificationRequests(withIdentifiers: longAlarmIdentifiers)
                print("PolyNap Debug: \(longAlarmIdentifiers.count) uzun alarm bildirimi temizlendi")
            }
        }
        
        // UI'ya alarm durduruldu sinyali gönder
        NotificationCenter.default.post(
            name: NSNotification.Name("LongAlarmStopped"),
            object: nil
        )
    }
    
    // MARK: - Alarm Scheduling (Enhanced for non-critical)
    
    /// Medium makalesine göre uyku bloğu bitimi için güçlü alarm planlar
    func scheduleAlarmForSleepBlockEnd(
        blockId: UUID,
        scheduleId: UUID,
        userId: UUID,
        endTime: Date,
        alarmSettings: AlarmSettings,
        modelContext: ModelContext
    ) async {
        guard isAuthorized else {
            print("PolyNap Debug: Alarm planlanamadı - izin yok")
            return
        }
        
        // Mevcut alarm varsa iptal et
        await cancelAlarmForBlock(blockId: blockId)
        
        let identifier = "alarm_\(blockId.uuidString)"
        
        // Medium makalesine göre güçlü alarm içeriği oluştur
        let content = UNMutableNotificationContent()
        content.title = "⏰ UYANMA ALARMI!"
        content.body = "Uyku bloğunuz sona erdi! Dokunarak 30 saniye güçlü alarm başlatın!"
        content.categoryIdentifier = "SLEEP_ALARM"
        content.userInfo = [
            "blockId": blockId.uuidString,
            "scheduleId": scheduleId.uuidString,
            "userId": userId.uuidString,
            "type": "sleep_alarm"
        ]
        
        // Ses dosyası geçerliliğini kontrol et ve ayarla
        if validateAlarmSoundDuration(soundName: alarmSettings.soundName) {
            content.sound = createAlarmSound(soundName: alarmSettings.soundName)
        } else {
            content.sound = UNNotificationSound.defaultCritical
        }
        
        // Critical alert olmadan maksimum etkililik
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
            content.relevanceScore = 1.0
        }
        
        // Badge ile dikkat çekme
        content.badge = 1
        
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
            
            print("PolyNap Debug: Güçlü alarm planlandı - \(identifier) - \(endTime)")
            
        } catch {
            print("PolyNap Debug: Alarm planlanırken hata: \(error)")
        }
    }
    
    /// Uyku programı için tüm alarmları planlar (just-in-time stratejisi)
    func scheduleAlarmsForSchedule(
        schedule: ScheduleEntity,
        alarmSettings: AlarmSettings,
        modelContext: ModelContext
    ) async {
        guard isAuthorized else {
            print("PolyNap Debug: Alarmlar planlanamadı - izin yok")
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
        print("PolyNap Debug: Alarm iptal edildi - \(identifier)")
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
        print("PolyNap Debug: Program alarmları iptal edildi - \(scheduleId)")
    }
    
    /// Tüm alarmları iptal eder
    func cancelAllAlarms() async {
        notificationCenter.removeAllPendingNotificationRequests()
        // Badge'i temizle
        UIApplication.shared.applicationIconBadgeNumber = 0
        await updatePendingNotificationsCount()
        print("PolyNap Debug: Tüm alarmlar iptal edildi, badge temizlendi")
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
        
        print("PolyNap Debug: Alarm ertelendi - \(snoozeDurationMinutes) dakika")
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
        // Uzun Alarm Başlat butonu - mavi renk
        let startLongAlarmAction = UNNotificationAction(
            identifier: "START_LONG_ALARM_ACTION",
            title: "🔔 30sn Uzun Alarm",
            options: [.foreground]
        )
        
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
        
        // Ana alarm kategorisi - uzun alarm başlatma butonlu
        let alarmCategory = UNNotificationCategory(
            identifier: "SLEEP_ALARM",
            actions: [startLongAlarmAction, snoozeAction, stopAction],
            intentIdentifiers: [],
            options: [.customDismissAction, .allowInCarPlay]
        )
        
        // Uzun alarm kategorisi - sadece durdurma butonu
        let stopLongAlarmAction = UNNotificationAction(
            identifier: "STOP_LONG_ALARM_ACTION",
            title: "⏹️ Alarmı Durdur",
            options: [.destructive, .authenticationRequired]
        )
        
        let longAlarmCategory = UNNotificationCategory(
            identifier: "LONG_SLEEP_ALARM",
            actions: [stopLongAlarmAction],
            intentIdentifiers: [],
            options: [.customDismissAction, .allowInCarPlay]
        )
        
        notificationCenter.setNotificationCategories([alarmCategory, longAlarmCategory])
        print("PolyNap Debug: Tüm alarm bildirim kategorileri kaydedildi")
    }
} 