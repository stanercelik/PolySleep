import Foundation
import AVFoundation
import SwiftUI
import SwiftData

@MainActor
final class AlarmManager: ObservableObject {
    @Published var isAlarmFiring = false
    
    private var audioPlayer: AVAudioPlayer?
    private var modelContext: ModelContext?
    private var firingNotification: UNNotification?
    
    init() {
        setupNotificationObservers()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
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
    
    @objc private func handleStartAlarm(notification: Notification) {
        print("🎶 AlarmManager: Alarm başlatma bildirimi alındı.")
        print("📋 AlarmManager: Bildirim detayları - name: \(notification.name), userInfo: \(notification.userInfo ?? [:])")
        print("🔄 AlarmManager: Mevcut isAlarmFiring durumu: \(isAlarmFiring)")
        
        // Store the original notification object if it's passed
        if let originalNotification = notification.object as? UNNotification {
            self.firingNotification = originalNotification
            print("💾 AlarmManager: Orijinal UNNotification kaydedildi")
        }
        
        // Alarm zaten çalıyorsa ve bu yeni bir çağrı ise sesi güncelle
        let userInfo = notification.userInfo
        let soundName = userInfo?["soundName"] as? String ?? "alarm.caf"
        print("🎵 AlarmManager: Kullanılacak ses: \(soundName)")
        
        if isAlarmFiring {
            print("🔄 AlarmManager: Alarm zaten çalıyor, ses güncelleniyor.")
            // Mevcut sesi durdur ve yeni ses başlat
            audioPlayer?.stop()
            startAlarmSound(soundName: soundName)
        } else {
            print("🎵 AlarmManager: Yeni alarm başlatılıyor. isAlarmFiring = true yapılıyor...")
            self.isAlarmFiring = true
            print("✅ AlarmManager: isAlarmFiring başarıyla true yapıldı. Şu anki durum: \(isAlarmFiring)")
            startAlarmSound(soundName: soundName)
        }
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
            // Sesin sessiz modda bile çalması için ses oturumunu yapılandır
            try AVAudioSession.sharedInstance().setCategory(
                .playback, 
                mode: .default, 
                options: [.mixWithOthers, .duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1 // Süresiz döngü
            audioPlayer?.volume = Float(volume)
            audioPlayer?.prepareToPlay() // Ses dosyasını hazırla
            
            let playResult = audioPlayer?.play()
            print("✅ AlarmManager: '\(soundName)' alarm sesi başlatıldı. Sonuç: \(playResult ?? false)")
            print("📊 AlarmManager: Audio session category: \(AVAudioSession.sharedInstance().category)")
            
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
        audioPlayer?.stop()
        audioPlayer = nil
        isAlarmFiring = false
        firingNotification = nil
        
        // Ses oturumunu devre dışı bırak
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    func snoozeAlarm() async {
        print("💤 AlarmManager: Alarm erteleniyor (ses durduruluyor).")
        
        guard let notificationToSnooze = firingNotification else {
            print("🚨 AlarmManager: Ertelemek için orijinal bildirim bulunamadı.")
            stopAlarm()
            return
        }
        
        await AlarmService.shared.snoozeAlarm(from: notificationToSnooze)
        
        stopAlarm()
    }
}