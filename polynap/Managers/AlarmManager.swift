import Foundation
import AVFoundation
import SwiftUI
import SwiftData

class AlarmManager: ObservableObject {
    @Published var isAlarmFiring = false
    
    var audioPlayer: AVAudioPlayer?
    private var modelContext: ModelContext?
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
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
    
    @objc private func handleStartAlarm() {
        startAlarmSound()
    }
    
    @objc private func handleStopAlarm() {
        stopAlarm()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func startAlarmSound(soundName: String = "alarm.caf") {
        // Settings'ten ses ayarlarını al
        var finalSoundName = soundName
        var finalVolume: Float = 0.8
        
        if let context = modelContext {
            let request = FetchDescriptor<AlarmSettings>()
            do {
                let alarmSettingsList = try context.fetch(request)
                if let settings = alarmSettingsList.first {
                    finalSoundName = settings.soundName
                    finalVolume = Float(settings.volume)
                }
            } catch {
                print("PolyNap Debug: AlarmSettings alınamadı, varsayılan ses kullanılıyor: \(error)")
            }
        }
        
        // AlarmSound klasöründeki .caf dosyasını kullan
        let resourceName = finalSoundName.replacingOccurrences(of: ".caf", with: "")
        
        guard let soundURL = Bundle.main.url(forResource: resourceName, withExtension: "caf") else {
            print("PolyNap Debug: AlarmSound klasöründe ses dosyası bulunamadı: \(finalSoundName)")
            // Fallback olarak alarm.caf kullan
            if let defaultURL = Bundle.main.url(forResource: "alarm", withExtension: "caf") {
                createAudioPlayer(url: defaultURL, volume: finalVolume)
                print("PolyNap Debug: Varsayılan alarm.caf kullanılıyor")
            } else {
                print("PolyNap Debug: Hiçbir alarm sesi bulunamadı!")
            }
            return
        }
        
        createAudioPlayer(url: soundURL, volume: finalVolume)
    }
    
    private func createAudioPlayer(url: URL, volume: Float) {
        do {
            // Sesin sessiz modda bile çalmasını sağlamak için.
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Sonsuz döngü
            audioPlayer?.volume = volume
            audioPlayer?.play()
            
            print("PolyNap Debug: Alarm sesi başlatıldı - Volume: \(volume)")
            
            // State'i güncelle, UI tetiklensin
            DispatchQueue.main.async {
                self.isAlarmFiring = true
            }
        } catch {
            print("PolyNap Debug: Ses çalınamadı: \(error.localizedDescription)")
        }
    }
    
    func stopAlarm() {
        audioPlayer?.stop()
        audioPlayer = nil
        DispatchQueue.main.async {
            self.isAlarmFiring = false
        }
    }
    
    func snoozeAlarm() {
        stopAlarm()
        
        // Settings'ten erteleme süresini al
        guard let context = modelContext else {
            print("PolyNap Debug: ModelContext bulunamadı, varsayılan 5 dakika erteleme kullanılıyor")
            let snoozeDate = Date().addingTimeInterval(5 * 60)
            AlarmService.shared.scheduleAlarmNotification(date: snoozeDate, repeats: false)
            return
        }
        
        // AlarmSettings'i al
        let request = FetchDescriptor<AlarmSettings>()
        do {
            let alarmSettingsList = try context.fetch(request)
            let snoozeDuration = alarmSettingsList.first?.snoozeDurationMinutes ?? 5
            let snoozeDate = Date().addingTimeInterval(TimeInterval(snoozeDuration * 60))
            AlarmService.shared.scheduleAlarmNotification(date: snoozeDate, repeats: false, modelContext: context)
            print("PolyNap Debug: Alarm \(snoozeDuration) dakika ertelendi")
        } catch {
            print("PolyNap Debug: AlarmSettings alınamadı: \(error), varsayılan 5 dakika kullanılıyor")
            let snoozeDate = Date().addingTimeInterval(5 * 60)
            AlarmService.shared.scheduleAlarmNotification(date: snoozeDate, repeats: false, modelContext: context)
        }
    }
} 