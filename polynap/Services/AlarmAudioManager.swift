import Foundation
import AVFoundation
import UIKit
import AudioToolbox

/// Medium makalesine göre geliştirilmiş uzun süreli alarm audio yönetimi
@MainActor
class AlarmAudioManager: NSObject, ObservableObject {
    static let shared = AlarmAudioManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    @Published var isPlaying = false
    
    // Medium makalesine göre .caf formatı tercih edilir
    private let supportedFormats = ["caf", "wav", "aiff", "mp3"]
    private let maxAlarmDuration: TimeInterval = 30.0 // Apple'ın 30 saniye kuralı
    
    private override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Audio Session Setup (Enhanced)
    
    /// Medium makalesine göre audio session'ı alarm için optimal ayarlarla yapılandırır
    private func setupAudioSession() {
        do {
            // Alarm için optimum kategori ve seçenekler
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [
                    .defaultToSpeaker,        // Hoparlörden çalsın
                    .allowBluetooth,          // Bluetooth desteği
                    .allowBluetoothA2DP,      // A2DP desteği
                    .allowAirPlay,            // AirPlay desteği
                    .duckOthers               // Diğer sesleri azaltsın
                ]
            )
            
            // Audio session'ı aktifleştir
            try audioSession.setActive(true)
            
            print("PolyNap Debug: Audio session alarm için optimal ayarlarla yapılandırıldı")
            
        } catch {
            print("PolyNap Debug: Audio session yapılandırma hatası: \(error)")
        }
    }
    
    // MARK: - Sound File Validation (Medium Article Guidelines)
    
    /// Medium makalesine göre ses dosyası geçerliliğini kontrol eder
    private func validateSoundFile(_ url: URL) -> Bool {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate
            
            // Apple'ın 30 saniye kuralını kontrol et
            if duration > maxAlarmDuration {
                print("PolyNap Debug: Uyarı - Ses dosyası \(duration)s uzunluğunda, Apple'ın 30s limitini aşıyor")
                return false
            }
            
            // Format kontrolü (.caf formatı tercih edilir)
            let fileExtension = url.pathExtension.lowercased()
            if !supportedFormats.contains(fileExtension) {
                print("PolyNap Debug: Uyarı - Desteklenmeyen ses formatı: \(fileExtension)")
                return false
            }
            
            print("PolyNap Debug: Ses dosyası geçerli - \(duration)s (\(fileExtension))")
            return true
            
        } catch {
            print("PolyNap Debug: Ses dosyası validasyon hatası: \(error)")
            return false
        }
    }
    
    /// Medium makalesine göre en uygun ses dosyasını bulur
    private func findBestSoundFile(soundName: String) -> URL? {
        let soundFileName = soundName.replacingOccurrences(of: ".caf", with: "")
        
        // Öncelik sırası: .caf (tercih edilen) -> .wav -> .aiff -> .mp3
        let priorityFormats = ["caf", "wav", "aiff", "mp3"]
        
        for format in priorityFormats {
            if let url = Bundle.main.url(forResource: soundFileName, withExtension: format) {
                if validateSoundFile(url) {
                    print("PolyNap Debug: En uygun ses dosyası bulundu: \(soundFileName).\(format)")
                    return url
                }
            }
        }
        
        // Fallback: varsayılan alarm sesi
        for format in priorityFormats {
            if let url = Bundle.main.url(forResource: "alarm", withExtension: format) {
                if validateSoundFile(url) {
                    print("PolyNap Debug: Fallback alarm sesi kullanılıyor: alarm.\(format)")
                    return url
                }
            }
        }
        
        print("PolyNap Debug: Uygun ses dosyası bulunamadı")
        return nil
    }
    
    // MARK: - Enhanced Alarm Audio Control
    
    /// Medium makalesine göre uzun süreli alarm sesini başlatır
    func startAlarmAudio(soundName: String = "alarm", volume: Float = 1.0) async {
        guard !isPlaying else {
            print("PolyNap Debug: Alarm sesi zaten çalıyor")
            return
        }
        
        print("PolyNap Debug: Medium yöntemiyle alarm sesi başlatılıyor...")
        
        // Background task başlat
        startBackgroundTask()
        
        // En uygun ses dosyasını bul
        guard let soundURL = findBestSoundFile(soundName: soundName) else {
            print("PolyNap Debug: Geçerli ses dosyası bulunamadı, sistem alarmı kullanılacak")
            await useSystemAlarmSound()
            return
        }
        
        do {
            // Audio session'ı yeniden yapılandır
            setupAudioSession()
            
            // Audio player oluştur - Medium önerilerine göre
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.delegate = self
            audioPlayer?.volume = min(max(volume, 0.0), 1.0) // 0.0-1.0 arası sınırla
            audioPlayer?.numberOfLoops = -1 // Sonsuz döngü (30 saniye timer ile sınırlanacak)
            
            // Audio player'ı hazırla
            audioPlayer?.prepareToPlay()
            
            // Çalmaya başla
            let success = audioPlayer?.play() ?? false
            if success {
                isPlaying = true
                print("PolyNap Debug: Güçlü alarm sesi başlatıldı - \(soundName) (volume: \(volume))")
                
                // Apple'ın önerisi: 30 saniye sonra otomatik durdur
                DispatchQueue.main.asyncAfter(deadline: .now() + maxAlarmDuration) { [weak self] in
                    Task {
                        await self?.stopAlarmAudio()
                    }
                }
            } else {
                print("PolyNap Debug: Alarm sesi başlatılamadı")
                stopBackgroundTask()
                await useSystemAlarmSound()
            }
            
        } catch {
            print("PolyNap Debug: Audio player oluşturma hatası: \(error)")
            stopBackgroundTask()
            await useSystemAlarmSound()
        }
    }
    
    /// Alarm sesini durdurur
    func stopAlarmAudio() async {
        guard isPlaying else { return }
        
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        
        // Audio session'ı diğer uygulamalara bırak
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("PolyNap Debug: Audio session kapatma hatası: \(error)")
        }
        
        // Background task'i sonlandır
        stopBackgroundTask()
        
        print("PolyNap Debug: Alarm sesi durduruldu")
    }
    
    /// Medium makalesine göre sistem alarm sesi kullan (fallback)
    private func useSystemAlarmSound() async {
        print("PolyNap Debug: Sistem alarm sesi çalınıyor (fallback)")
        
        // Birden fazla sistem sesi çal (daha etkili)
        let systemSounds: [SystemSoundID] = [
            1005, // Alarm
            1013, // SMS tone 1  
            1016, // SMS tone 4
            1020, // Anticipate
            1026  // Chord
        ]
        
        // 30 saniye boyunca sistem seslerini döngüde çal
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < maxAlarmDuration {
            for soundID in systemSounds {
                AudioServicesPlaySystemSound(soundID)
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 saniye bekle
                
                if Date().timeIntervalSince(startTime) >= maxAlarmDuration {
                    break
                }
            }
        }
        
        stopBackgroundTask()
        print("PolyNap Debug: Sistem alarm sesi döngüsü tamamlandı")
    }
    
    // MARK: - Volume Control & Audio Quality
    
    /// Alarm volume'ünü dinamik olarak ayarlar
    func adjustVolume(_ newVolume: Float) {
        guard isPlaying, let player = audioPlayer else { return }
        
        let clampedVolume = min(max(newVolume, 0.0), 1.0)
        player.volume = clampedVolume
        
        print("PolyNap Debug: Alarm volume ayarlandı: \(clampedVolume)")
    }
    
    /// Audio kalitesi bilgilerini döndürür
    func getAudioInfo() -> [String: Any]? {
        guard let player = audioPlayer else { return nil }
        
        return [
            "isPlaying": player.isPlaying,
            "volume": player.volume,
            "duration": player.duration,
            "currentTime": player.currentTime,
            "numberOfChannels": player.numberOfChannels,
            "format": player.url?.pathExtension ?? "unknown"
        ]
    }
    
    // MARK: - Background Task Management
    
    /// Background task başlatır (ses devam etsin)
    private func startBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "AlarmAudio") { [weak self] in
            self?.stopBackgroundTask()
        }
        print("PolyNap Debug: Background task başlatıldı")
    }
    
    /// Background task'i sonlandırır
    private func stopBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
            print("PolyNap Debug: Background task sonlandırıldı")
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension AlarmAudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            print("PolyNap Debug: Alarm sesi bitti")
        } else {
            print("PolyNap Debug: Alarm sesi hata ile sonlandı")
        }
        isPlaying = false
        stopBackgroundTask()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("PolyNap Debug: Audio decode hatası: \(error?.localizedDescription ?? "Bilinmeyen hata")")
        isPlaying = false
        stopBackgroundTask()
    }
} 
