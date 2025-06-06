import Foundation
import AVFoundation
import UIKit

/// Medium makalesine göre alarm ses dosyalarını yönetir ve optimize eder
class AlarmSoundManager {
    static let shared = AlarmSoundManager()
    
    // Medium makalesine göre desteklenen formatlar
    private let supportedInputFormats = ["mp3", "wav", "aiff", "m4a", "mp4"]
    private let targetFormat = "caf" // Apple'ın önerdiği format
    private let maxDuration: TimeInterval = 30.0 // Apple'ın 30 saniye kuralı
    
    // Alarm ses profilleri
    struct AlarmSoundProfile {
        let name: String
        let fileName: String
        let duration: TimeInterval
        let volume: Float
        let isOptimized: Bool
        let format: String
        
        var displayName: String {
            return name.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    private var availableSounds: [AlarmSoundProfile] = []
    
    private init() {
        scanAvailableSounds()
    }
    
    // MARK: - Sound Discovery & Validation
    
    /// Bundle içindeki alarm seslerini tarar ve değerlendirir
    private func scanAvailableSounds() {
        guard let resourcePath = Bundle.main.resourcePath else {
            print("PolyNap Debug: Resource path bulunamadı")
            return
        }
        
        let alarmSoundPath = "\(resourcePath)/AlarmSound"
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: alarmSoundPath)
            
            for file in files {
                let fileURL = URL(fileURLWithPath: "\(alarmSoundPath)/\(file)")
                if let profile = createSoundProfile(from: fileURL) {
                    availableSounds.append(profile)
                    print("PolyNap Debug: Alarm sesi bulundu: \(profile.name) (\(profile.format), \(profile.duration)s)")
                }
            }
            
        } catch {
            print("PolyNap Debug: Alarm ses dosyaları taranamadı: \(error)")
        }
        
        // Varsayılan sesler yoksa oluştur
        if availableSounds.isEmpty {
            createDefaultSounds()
        }
    }
    
    /// Medium makalesine göre ses dosyası profili oluşturur
    private func createSoundProfile(from url: URL) -> AlarmSoundProfile? {
        let fileName = url.lastPathComponent
        let fileExtension = url.pathExtension.lowercased()
        let baseName = url.deletingPathExtension().lastPathComponent
        
        // Format kontrolü
        let allSupportedFormats = supportedInputFormats + [targetFormat]
        guard allSupportedFormats.contains(fileExtension) else {
            print("PolyNap Debug: Desteklenmeyen format: \(fileName)")
            return nil
        }
        
        // Süre kontrolü
        guard let duration = getAudioDuration(from: url) else {
            print("PolyNap Debug: Ses dosyası süresi okunamadı: \(fileName)")
            return nil
        }
        
        // 30 saniye kuralı kontrolü
        let isOptimized = duration <= maxDuration && fileExtension == targetFormat
        
        if duration > maxDuration {
            print("PolyNap Debug: Uyarı - \(fileName) dosyası \(duration)s uzunluğunda (Apple limiti: \(maxDuration)s)")
        }
        
        return AlarmSoundProfile(
            name: baseName,
            fileName: fileName,
            duration: duration,
            volume: 1.0,
            isOptimized: isOptimized,
            format: fileExtension
        )
    }
    
    /// Ses dosyası süresini döndürür
    private func getAudioDuration(from url: URL) -> TimeInterval? {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            return Double(audioFile.length) / audioFile.fileFormat.sampleRate
        } catch {
            print("PolyNap Debug: Audio dosya bilgisi okunamadı: \(error)")
            return nil
        }
    }
    
    // MARK: - Sound Optimization (Medium Article Methods)
    
    /// Medium makalesine göre ses dosyasını .caf formatına dönüştürür
    func optimizeSoundFile(inputFileName: String, completion: @escaping (Bool, String?) -> Void) {
        guard let inputURL = Bundle.main.url(forResource: inputFileName.replacingOccurrences(of: ".\(inputFileName.split(separator: ".").last ?? "")", with: ""), withExtension: String(inputFileName.split(separator: ".").last ?? "")) else {
            print("PolyNap Debug: Giriş dosyası bulunamadı: \(inputFileName)")
            completion(false, "Dosya bulunamadı")
            return
        }
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let outputFileName = "\(inputURL.deletingPathExtension().lastPathComponent)_optimized.caf"
        let outputURL = URL(fileURLWithPath: "\(documentsPath)/\(outputFileName)")
        
        // AVAudioConverter kullanarak dönüştürme
        Task {
            do {
                let inputFile = try AVAudioFile(forReading: inputURL)
                let outputFile = try AVAudioFile(forWriting: outputURL, settings: getOptimalCAFSettings())
                
                // Format dönüştürme
                let converter = AVAudioConverter(from: inputFile.processingFormat, to: outputFile.processingFormat)
                
                let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFile.processingFormat, frameCapacity: AVAudioFrameCount(inputFile.length))!
                try inputFile.read(into: inputBuffer)
                
                let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFile.processingFormat, frameCapacity: inputBuffer.frameCapacity)!
                
                var error: NSError?
                let status = converter?.convert(to: outputBuffer, error: &error) { _, _ in
                    return inputBuffer
                }
                
                if status == .haveData, error == nil {
                    try outputFile.write(from: outputBuffer)
                    print("PolyNap Debug: Ses dosyası başarıyla optimize edildi: \(outputFileName)")
                    
                    DispatchQueue.main.async {
                        completion(true, outputFileName)
                    }
                } else {
                    print("PolyNap Debug: Dönüştürme hatası: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                    DispatchQueue.main.async {
                        completion(false, error?.localizedDescription)
                    }
                }
                
            } catch {
                print("PolyNap Debug: Ses optimizasyonu hatası: \(error)")
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    /// Medium makalesine göre optimal .caf ayarları
    private func getOptimalCAFSettings() -> [String: Any] {
        return [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
    }
    
    /// Ses dosyasını 30 saniyeye kırpar (Medium önerisi)
    func trimSoundTo30Seconds(inputFileName: String, completion: @escaping (Bool, String?) -> Void) {
        guard let inputURL = Bundle.main.url(forResource: inputFileName.replacingOccurrences(of: ".\(inputFileName.split(separator: ".").last ?? "")", with: ""), withExtension: String(inputFileName.split(separator: ".").last ?? "")) else {
            completion(false, "Dosya bulunamadı")
            return
        }
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let outputFileName = "\(inputURL.deletingPathExtension().lastPathComponent)_trimmed.caf"
        let outputURL = URL(fileURLWithPath: "\(documentsPath)/\(outputFileName)")
        
        Task {
            do {
                let asset = AVAsset(url: inputURL)
                let duration = try await asset.load(.duration)
                
                if CMTimeGetSeconds(duration) <= maxDuration {
                    print("PolyNap Debug: Dosya zaten 30 saniye veya daha kısa")
                    completion(true, inputFileName)
                    return
                }
                
                // Export session oluştur
                guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
                    completion(false, "Export session oluşturulamadı")
                    return
                }
                
                exportSession.outputURL = outputURL
                exportSession.outputFileType = .caf
                exportSession.timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: maxDuration, preferredTimescale: 44100))
                
                await exportSession.export()
                
                if exportSession.status == .completed {
                    print("PolyNap Debug: Ses dosyası 30 saniyeye kırpıldı: \(outputFileName)")
                    DispatchQueue.main.async {
                        completion(true, outputFileName)
                    }
                } else {
                    print("PolyNap Debug: Kırpma hatası: \(exportSession.error?.localizedDescription ?? "Bilinmeyen hata")")
                    DispatchQueue.main.async {
                        completion(false, exportSession.error?.localizedDescription)
                    }
                }
                
            } catch {
                print("PolyNap Debug: Ses kırpma hatası: \(error)")
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Sound Management
    
    /// Mevcut alarm seslerini döndürür
    func getAvailableSounds() -> [AlarmSoundProfile] {
        return availableSounds
    }
    
    /// En uygun alarm sesini döndürür
    func getBestAlarmSound() -> AlarmSoundProfile? {
        // Öncelik: optimize edilmiş .caf dosyaları
        if let optimizedSound = availableSounds.first(where: { $0.isOptimized }) {
            return optimizedSound
        }
        
        // Sonra: 30 saniye altı dosyalar
        if let validSound = availableSounds.first(where: { $0.duration <= maxDuration }) {
            return validSound
        }
        
        // Son çare: herhangi bir dosya
        return availableSounds.first
    }
    
    /// Varsayılan alarm seslerini oluşturur
    private func createDefaultSounds() {
        // Sistem seslerini alarm profili olarak ekle
        let defaultSounds = [
            AlarmSoundProfile(name: "Sistem Alarmı", fileName: "system_alarm", duration: 2.0, volume: 1.0, isOptimized: false, format: "system"),
            AlarmSoundProfile(name: "Kısa Bip", fileName: "system_beep", duration: 1.0, volume: 0.8, isOptimized: false, format: "system"),
            AlarmSoundProfile(name: "Uzun Alarm", fileName: "system_long", duration: 5.0, volume: 1.0, isOptimized: false, format: "system")
        ]
        
        availableSounds.append(contentsOf: defaultSounds)
        print("PolyNap Debug: Varsayılan alarm sesleri eklendi")
    }
    
    /// Ses dosyası validasyon raporu
    func generateSoundReport() -> String {
        var report = "=== ALARM SESLERİ RAPORU (Medium Makale Standartları) ===\n\n"
        
        for sound in availableSounds {
            report += "🔊 \(sound.displayName)\n"
            report += "   📁 Dosya: \(sound.fileName)\n"
            report += "   ⏱️ Süre: \(String(format: "%.1f", sound.duration))s"
            
            if sound.duration > maxDuration {
                report += " ⚠️ (30s limitini aşıyor!)"
            } else {
                report += " ✅"
            }
            
            report += "\n   🎵 Format: \(sound.format.uppercased())"
            
            if sound.format == targetFormat {
                report += " ✅ (Optimal)"
            } else {
                report += " ⚠️ (Dönüştürülmeli)"
            }
            
            report += "\n   🔧 Optimize: \(sound.isOptimized ? "✅" : "❌")\n\n"
        }
        
        let optimizedCount = availableSounds.filter { $0.isOptimized }.count
        let validCount = availableSounds.filter { $0.duration <= maxDuration }.count
        
        report += "📊 ÖZET:\n"
        report += "• Toplam ses: \(availableSounds.count)\n"
        report += "• Optimize edilmiş: \(optimizedCount)\n"
        report += "• Geçerli süre (≤30s): \(validCount)\n"
        report += "• En uygun ses: \(getBestAlarmSound()?.displayName ?? "Yok")\n"
        
        return report
    }
}

// MARK: - Terminal Integration Helper
extension AlarmSoundManager {
    
    /// Terminal komutunu simüle eden ses dönüştürme (Medium makalesindeki afconvert benzeri)
    func convertSoundWithSimulatedCommand(inputFile: String, completion: @escaping (Bool, String) -> Void) {
        print("PolyNap Debug: Terminal benzeri dönüştürme başlatılıyor...")
        print("Simulated command: afconvert \(inputFile) ~/Desktop/\(inputFile.replacingOccurrences(of: ".mp3", with: ".caf")) -d ima4 -f caff -v")
        
        // Gerçek dönüştürme işlemini çağır
        optimizeSoundFile(inputFileName: inputFile) { success, result in
            let message = success ? 
                "✅ Dönüştürme başarılı: \(result ?? "unknown")" : 
                "❌ Dönüştürme hatası: \(result ?? "unknown error")"
            
            completion(success, message)
        }
    }
} 