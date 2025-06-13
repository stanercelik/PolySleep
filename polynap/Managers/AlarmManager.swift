import Foundation
import AVFoundation
import SwiftUI
import SwiftData

// DEĞİŞİKLİK: AlarmManager artık Singleton pattern ile yapılandırıldı
@MainActor
final class AlarmManager: ObservableObject {
    
    // YENİ: Singleton instance - Single Source of Truth
    static let shared = AlarmManager()
    
    // YENİ: Alarm bilgi modeli
    struct AlarmInfo {
        let title: String
        let body: String
        let soundName: String
        let userInfo: [AnyHashable: Any]
        let originalNotification: UNNotification?
    }
    
    @Published var isAlarmFiring = false
    // YENİ: Mevcut alarm bilgileri
    @Published var currentAlarmInfo: AlarmInfo?
    
    private var audioPlayer: AVAudioPlayer?
    private var modelContext: ModelContext?
    
    // DEĞİŞİKLİK: Private init for singleton
    private init() {
        setupNotificationObservers()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // DEĞİŞİKLİK: NotificationCenter observers sadece ön plan alarmları için kullanılacak
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStartAlarm),
            name: .startAlarm,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStopAlarm),
            name: .stopAlarm,
            object: nil
        )
    }
    
    // YENİ: Ana alarm tetikleme metodu - AppDelegate'den doğrudan çağrılacak
    func triggerAlarm(
        title: String = "Polyphasic Sleep Alarm",
        body: String = "Uyku zamanınız!",
        soundName: String = "Alarm 1.caf",
        userInfo: [AnyHashable: Any] = [:],
        originalNotification: UNNotification? = nil
    ) {
        print("🚨 AlarmManager.shared: triggerAlarm çağrıldı - title: \(title)")
        print("📊 AlarmManager.shared: Mevcut isAlarmFiring durumu: \(isAlarmFiring)")
        print("🧵 AlarmManager.shared: Thread kontrolü - Main: \(Thread.isMainThread)")
        
        // CRITICAL FIX: State validation ve defensive programming
        print("🔍 DIAGNOSTIC: Current state - isAlarmFiring: \(isAlarmFiring), currentAlarmInfo: \(currentAlarmInfo?.title ?? "nil")")
        
        // State temizliği kontrolü - eğer inconsistent state varsa temizle
        if isAlarmFiring && currentAlarmInfo == nil {
            print("⚠️ INCONSISTENT STATE DETECTED: isAlarmFiring=true ama currentAlarmInfo=nil")
            print("🔧 STATE RECOVERY: isAlarmFiring false'a çekiliyor")
            isAlarmFiring = false
            audioPlayer?.stop()
            audioPlayer = nil
        }
        
        // Alarm bilgilerini sakla
        self.currentAlarmInfo = AlarmInfo(
            title: title,
            body: body,
            soundName: soundName,
            userInfo: userInfo,
            originalNotification: originalNotification
        )
        
        print("📋 AlarmManager.shared: AlarmInfo kaydedildi - title: \(title), body: \(body)")
        
        // CRITICAL FIX: Explicit state management
        let shouldStartNewAlarm = !isAlarmFiring
        
        // Alarm zaten çalıyorsa sesi güncelle
        if isAlarmFiring {
            print("🔄 AlarmManager.shared: Alarm zaten çalıyor, ses güncelleniyor")
            audioPlayer?.stop()
            startAlarmSound(soundName: soundName)
        } else {
            print("🎵 AlarmManager.shared: Yeni alarm başlatılıyor - isAlarmFiring = true")
            
            // CRITICAL FIX: Guaranteed main thread state update with validation
            let updateStateOnMainThread = {
                // Double-check state before updating
                if !self.isAlarmFiring {
                    self.isAlarmFiring = true
                    print("✅ AlarmManager.shared: isAlarmFiring = true SUCCESSFULLY set!")
                    print("🔍 AlarmManager.shared: UI Update confirmation - isAlarmFiring: \(self.isAlarmFiring)")
                } else {
                    print("⚠️ AlarmManager.shared: isAlarmFiring was already true - skipping update")
                }
            }
            
            if Thread.isMainThread {
                updateStateOnMainThread()
            } else {
                DispatchQueue.main.sync {
                    updateStateOnMainThread()
                }
            }
            
            startAlarmSound(soundName: soundName)
        }
        
        print("📊 AlarmManager.shared: triggerAlarm tamamlandı - Final isAlarmFiring: \(isAlarmFiring)")
        print("📋 AlarmManager.shared: Final currentAlarmInfo title: \(currentAlarmInfo?.title ?? "nil")")
        
        // CRITICAL FIX: Robust validation with retry mechanism
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("🔍 AlarmManager.shared: Final kontrol - isAlarmFiring: \(self.isAlarmFiring)")
            print("🔍 AlarmManager.shared: Final kontrol - currentAlarmInfo: \(self.currentAlarmInfo?.title ?? "nil")")
            
            // CRITICAL FIX: Validation ve recovery mechanism
            if shouldStartNewAlarm && !self.isAlarmFiring {
                print("🚨 CRITICAL: Alarm state inconsistency detected! Fixing...")
                self.isAlarmFiring = true
                print("🔧 RECOVERY: isAlarmFiring force set to true")
            }
            
            if self.currentAlarmInfo == nil {
                print("🚨 CRITICAL: AlarmInfo lost! Recreating...")
                self.currentAlarmInfo = AlarmInfo(
                    title: title,
                    body: body,
                    soundName: soundName,
                    userInfo: userInfo,
                    originalNotification: originalNotification
                )
                print("🔧 RECOVERY: AlarmInfo recreated")
            }
        }
    }
    
    // DEĞİŞİKLİK: Eski NotificationCenter handler'ları ön plan senaryoları için korunuyor
    @objc private func handleStartAlarm(notification: Notification) {
        print("🎶 AlarmManager: Ön plan alarm bildirimi alındı")
        
        let userInfo = notification.userInfo ?? [:]
        let soundName = userInfo["soundName"] as? String ?? "Alarm 1.caf"
        let title = userInfo["title"] as? String ?? "Polyphasic Sleep Alarm"
        let body = userInfo["body"] as? String ?? "Uyku zamanınız!"
        
        triggerAlarm(
            title: title,
            body: body,
            soundName: soundName,
            userInfo: userInfo,
            originalNotification: notification.object as? UNNotification
        )
    }
    
    @objc private func handleStopAlarm() {
        stopAlarm()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func startAlarmSound(soundName: String) {
        guard let context = modelContext else {
            print("🚨 AlarmManager: ModelContext ayarlanmadı. Alarm ayarları alınamıyor.")
            return
        }
        
        // Ses seviyesi için en son alarm ayarlarını al
        let request = FetchDescriptor<AlarmSettings>()
        let volume = (try? context.fetch(request).first?.volume) ?? 0.8
        
        // Ses dosyasının URL'sini al
        let resourceName = soundName.replacingOccurrences(of: ".caf", with: "")
        guard let soundURL = Bundle.main.url(forResource: resourceName, withExtension: "caf") else {
            print("🚨 AlarmManager: '\(soundName)' ses dosyası bundle içinde bulunamadı.")
            print("📁 AlarmManager: Bundle içindeki ses dosyaları:")
            if let bundlePath = Bundle.main.resourcePath {
                let files = try? FileManager.default.contentsOfDirectory(atPath: bundlePath)
                let audioFiles = files?.filter { $0.contains(".caf") || $0.contains(".wav") || $0.contains(".mp3") }
                audioFiles?.forEach { print("   - \($0)") }
            }
            return
        }
        
        print("🎵 AlarmManager: Ses dosyası bulundu: \(soundURL.path)")
        print("📊 AlarmManager: Volume: \(volume), Resource: \(resourceName).caf")
        
        do {
            // DEĞİŞİKLİK: Critical Alert desteği için ses session yapılandırması
            try AVAudioSession.sharedInstance().setCategory(
                .playback, 
                mode: .default, 
                options: [.mixWithOthers, .duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1 // Süresiz döngü
            audioPlayer?.volume = Float(volume)
            audioPlayer?.prepareToPlay()
            
            let playResult = audioPlayer?.play()
            print("✅ AlarmManager: '\(soundName)' alarm sesi başlatıldı. Sonuç: \(playResult ?? false)")
            
        } catch {
            print("🚨 AlarmManager: Ses çalınamadı: \(error.localizedDescription)")
            
            // Alternatif ses çalma yöntemi
            do {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .defaultToSpeaker)
                try AVAudioSession.sharedInstance().setActive(true)
                
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.numberOfLoops = -1
                audioPlayer?.volume = Float(volume)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                
                print("✅ AlarmManager: Alternatif metod ile ses başlatıldı.")
            } catch {
                print("🚨 AlarmManager: Alternatif ses metodu da başarısız: \(error.localizedDescription)")
            }
        }
    }
    
    func stopAlarm() {
        print("🛑 AlarmManager: Alarm durduruluyor.")
        print("🔍 DIAGNOSTIC: Pre-stop state - isAlarmFiring: \(isAlarmFiring), currentAlarmInfo: \(currentAlarmInfo?.title ?? "nil")")
        
        // CRITICAL FIX: Ses tamamen durdur
        audioPlayer?.stop()
        audioPlayer = nil
        
        // CRITICAL FIX: State'i main thread'de güvenli şekilde temizle
        let clearStateOnMainThread = {
            self.isAlarmFiring = false
            self.currentAlarmInfo = nil
            print("✅ AlarmManager: State successfully cleared - isAlarmFiring: false, currentAlarmInfo: nil")
        }
        
        if Thread.isMainThread {
            clearStateOnMainThread()
        } else {
            DispatchQueue.main.sync {
                clearStateOnMainThread()
            }
        }
        
        // Ses oturumunu devre dışı bırak
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("✅ AlarmManager: Audio session deactivated successfully")
        } catch {
            print("⚠️ AlarmManager: Audio session deactivation failed: \(error)")
        }
        
        // CRITICAL FIX: Final state validation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("🔍 FINAL CHECK: Post-stop state - isAlarmFiring: \(self.isAlarmFiring), currentAlarmInfo: \(self.currentAlarmInfo?.title ?? "nil")")
            
            // Eğer state hala temizlenmemişse force clear
            if self.isAlarmFiring {
                print("🚨 CRITICAL: isAlarmFiring still true after stop! Force clearing...")
                self.isAlarmFiring = false
            }
            
            if self.currentAlarmInfo != nil {
                print("🚨 CRITICAL: currentAlarmInfo still exists after stop! Force clearing...")
                self.currentAlarmInfo = nil
            }
        }
    }
    
    func snoozeAlarm() async {
        print("💤 AlarmManager: Alarm erteleniyor (ses durduruluyor).")
        
        guard let alarmInfo = currentAlarmInfo,
              let notificationToSnooze = alarmInfo.originalNotification else {
            print("🚨 AlarmManager: Ertelemek için orijinal bildirim bulunamadı.")
            stopAlarm()
            return
        }
        
        await AlarmService.shared.snoozeAlarm(from: notificationToSnooze)
        stopAlarm()
    }
    
    // YENİ: Critical Alert desteği için gelecekte kullanılacak
    func setCriticalAlertMode(_ enabled: Bool) {
        // Critical Alert entitlement onaylandığında burada implementasyon yapılacak
        print("🔥 AlarmManager: Critical Alert modu: \(enabled ? "Aktif" : "Pasif")")
    }
}