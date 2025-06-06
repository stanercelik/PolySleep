import SwiftUI
import SwiftData
import UserNotifications

struct AlarmTestView: View {
    @StateObject private var alarmService = AlarmNotificationService.shared
    @StateObject private var alarmAudioManager = AlarmAudioManager.shared
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var languageManager: LanguageManager
    
    // Alarm testi durumları
    @State private var testResults: [String] = []
    @State private var isTestingInProgress = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showSuccessAlert = false
    @State private var selectedTestType = 0
    
    // Medium makalesine göre ses test ayarları
    @State private var testSoundName = "alarm.caf"
    @State private var testVolume: Double = 1.0
    @State private var testDuration: Double = 5.0
    
    private let testTypes = ["Hızlı Test", "Detaylı Test", "Ses Validasyonu", "Sistem Durumu"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Üst durum kartları
                    statusCardsSection
                    
                    // Test türü seçimi
                    testTypeSelection
                    
                    // Medium makalesine göre ses test bölümü
                    soundTestSection
                    
                    // Test butonları
                    testButtonsSection
                    
                    // Test sonuçları
                    testResultsSection
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("🔔 Alarm Test Merkezi")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await alarmService.checkAuthorizationStatus()
                    addTestResult("📱 Alarm Test Merkezi açıldı")
                    
                    // Medium makalesine göre sistem durumu kontrolü
                    await checkSystemStatus()
                }
            }
            .alert("Test Sonucu", isPresented: $showSuccessAlert) {
                Button("Tamam") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - UI Bileşenleri
    
    private var statusCardsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            TestStatusCard(
                icon: "bell.badge",
                title: "Bildirim İzni",
                value: alarmService.isAuthorized ? "✅ Aktif" : "❌ Pasif",
                color: alarmService.isAuthorized ? .green : .red
            )
            
            TestStatusCard(
                icon: "alarm",
                title: "Planlanmış Alarm",
                value: "\(alarmService.pendingNotificationsCount)",
                color: .blue
            )
            
            TestStatusCard(
                icon: "speaker.wave.3",
                title: "Audio Durumu",
                value: alarmAudioManager.isPlaying ? "🔊 Çalıyor" : "🔇 Sessiz",
                color: alarmAudioManager.isPlaying ? .orange : .gray
            )
            
            TestStatusCard(
                icon: "waveform",
                title: "Ses Validasyonu",
                value: "✅ OK",
                color: .green
            )
        }
    }
    
    private var testTypeSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Türü Seçin")
                .font(.headline)
                .fontWeight(.semibold)
            
            Picker("Test Türü", selection: $selectedTestType) {
                ForEach(0..<testTypes.count, id: \.self) { index in
                    Text(testTypes[index]).tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.horizontal)
    }
    
    // Medium makalesine göre ses test bölümü
    private var soundTestSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎵 Ses Test Ayarları (Medium Standartları)")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Ses Dosyası:")
                    Spacer()
                    Picker("Ses", selection: $testSoundName) {
                        Text("alarm.caf (Varsayılan)").tag("alarm.caf")
                        Text("Sistem Alarmı").tag("system_alarm")
                        Text("Kritik Alarm").tag("critical_alarm")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Volume: \(String(format: "%.0f", testVolume * 100))%")
                        Spacer()
                    }
                    Slider(value: $testVolume, in: 0.0...1.0)
                        .accentColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Test Süresi: \(String(format: "%.0f", testDuration))s")
                        Spacer()
                        Text("(Max: 30s)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $testDuration, in: 1.0...30.0)
                        .accentColor(.orange)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private var testButtonsSection: some View {
        VStack(spacing: 16) {
            
            // Ana test butonları
            HStack(spacing: 16) {
                Button(action: {
                    Task {
                        await runSelectedTest()
                    }
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Test Çalıştır")
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(isTestingInProgress)
                
                Button(action: clearTestResults) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Temizle")
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.red)
                    .cornerRadius(12)
                }
            }
            
            // Medium makalesine göre özel test butonları
            VStack(spacing: 12) {
                Button(action: {
                    Task {
                        await testSoundValidation()
                    }
                }) {
                    Label("Ses Dosyası Validasyonu", systemImage: "checkmark.seal")
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    Task {
                        await testAudioPlayer()
                    }
                }) {
                    Label("Audio Player Testi", systemImage: "speaker.wave.3")
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    generateSoundReport()
                }) {
                    Label("Ses Raporu Oluştur", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(8)
                }
            }
            
            // Yardımcı butonlar
            HStack(spacing: 16) {
                Button(action: requestNotificationPermission) {
                    Text("🔔 İzin İste")
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.yellow.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
                
                Button(action: clearAllNotifications) {
                    Text("🗑️ Bildirimleri Temizle")
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var testResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📊 Test Sonuçları")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if isTestingInProgress {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(testResults.reversed(), id: \.self) { result in
                        HStack(alignment: .top) {
                            Text("•")
                                .foregroundColor(.blue)
                                .font(.system(size: 12, weight: .bold))
                            
                            Text(result)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding()
            }
            .frame(height: 200)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Test Fonksiyonları
    
    private func runSelectedTest() async {
        isTestingInProgress = true
        
        switch selectedTestType {
        case 0:
            await runQuickTest()
        case 1:
            await runDetailedTest()
        case 2:
            await testSoundValidation()
        case 3:
            await checkSystemStatus()
        default:
            await runQuickTest()
        }
        
        isTestingInProgress = false
    }
    
    private func runQuickTest() async {
        addTestResult("🚀 Hızlı test başlatıldı...")
        
        // İzin kontrolü
        await alarmService.checkAuthorizationStatus()
        addTestResult("✅ İzin durumu: \(alarmService.isAuthorized ? "Aktif" : "Pasif")")
        
        if alarmService.isAuthorized {
            // 3 saniye sonra test alarmı
            await scheduleTestNotification(delay: 3)
            addTestResult("⏰ Test alarmı 3 saniye sonra çalacak")
        } else {
            addTestResult("❌ Bildirim izni gerekli")
        }
    }
    
    private func runDetailedTest() async {
        addTestResult("🔍 Detaylı test başlatıldı...")
        
        // Sistem bilgileri
        await checkSystemStatus()
        
        // Ses dosyası validasyonu
        await testSoundValidation()
        
        // Audio player testi
        await testAudioPlayer()
        
        // Test bildirimi
        if alarmService.isAuthorized {
            await scheduleTestNotification(delay: 5)
            addTestResult("⏰ Detaylı test alarmı 5 saniye sonra çalacak")
        }
        
        addTestResult("✅ Detaylı test tamamlandı")
    }
    
    // Medium makalesine göre ses validasyon testi
    private func testSoundValidation() async {
        addTestResult("🎵 Ses dosyası validasyonu başlatıldı...")
        
        let soundManager = AlarmSoundManager.shared
        let availableSounds = soundManager.getAvailableSounds()
        
        addTestResult("📁 Bulunan ses dosyaları: \(availableSounds.count)")
        
        for sound in availableSounds {
            let status = sound.isOptimized ? "✅" : "⚠️"
            let durationStatus = sound.duration <= 30.0 ? "✅" : "❌ (\(String(format: "%.1f", sound.duration))s > 30s)"
            addTestResult("\(status) \(sound.displayName): \(sound.format.uppercased()) - \(durationStatus)")
        }
        
        if let bestSound = soundManager.getBestAlarmSound() {
            addTestResult("🏆 En uygun ses: \(bestSound.displayName)")
        } else {
            addTestResult("❌ Uygun ses dosyası bulunamadı")
        }
    }
    
    // Audio player test fonksiyonu
    private func testAudioPlayer() async {
        addTestResult("🔊 Audio player testi başlatıldı...")
        
        // Ses çalmayı başlat
        await AlarmAudioManager.shared.startAlarmAudio(
            soundName: testSoundName,
            volume: Float(testVolume)
        )
        
        addTestResult("▶️ Test sesi çalıyor... (\(String(format: "%.0f", testDuration))s)")
        
        // Belirtilen süre kadar bekle
        try? await Task.sleep(nanoseconds: UInt64(testDuration * 1_000_000_000))
        
        // Sesi durdur
        await AlarmAudioManager.shared.stopAlarmAudio()
        
        addTestResult("⏹️ Test sesi durduruldu")
    }
    
    // Sistem durumu kontrolü
    private func checkSystemStatus() async {
        addTestResult("📱 Sistem durumu kontrol ediliyor...")
        
        // Bildirim ayarları
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        addTestResult("🔔 Bildirim durumu: \(settings.authorizationStatus.rawValue)")
        addTestResult("🔊 Ses izni: \(settings.soundSetting.rawValue)")
        addTestResult("📢 Alert izni: \(settings.alertSetting.rawValue)")
        
        // Bekleyen bildirimler
        let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        addTestResult("⏰ Bekleyen bildirimler: \(pendingRequests.count)")
        
        // Audio session durumu
        if let audioInfo = AlarmAudioManager.shared.getAudioInfo() {
            addTestResult("🎵 Audio session aktif: \(audioInfo["isPlaying"] as? Bool ?? false)")
        }
        
        addTestResult("✅ Sistem durumu kontrolü tamamlandı")
    }
    
    private func scheduleTestNotification(delay: TimeInterval) async {
        let content = UNMutableNotificationContent()
        content.title = "🧪 Test Alarmı"
        content.body = "Bu bir test bildirimidir. Sistem düzgün çalışıyor!"
        content.categoryIdentifier = "SLEEP_ALARM"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: testSoundName))
        
        // Test için time-sensitive seviyesi
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
            content.relevanceScore = 1.0
        }
        
        content.userInfo = [
            "blockId": UUID().uuidString,
            "scheduleId": UUID().uuidString,
            "userId": UUID().uuidString,
            "type": "sleep_alarm",
            "isTest": true
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test_alarm_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            addTestResult("✅ Test bildirimi planlandı")
        } catch {
            addTestResult("❌ Test bildirimi planlanamadı: \(error)")
        }
    }
    
    private func generateSoundReport() {
        let soundManager = AlarmSoundManager.shared
        let report = soundManager.generateSoundReport()
        
        addTestResult("📄 SES RAPORU OLUŞTURULDU:")
        let reportLines = report.components(separatedBy: "\n")
        for line in reportLines {
            if !line.isEmpty {
                addTestResult(line)
            }
        }
    }
    
    private func addTestResult(_ message: String) {
        let timestamp = DateFormatter()
        timestamp.dateFormat = "HH:mm:ss"
        let timestampedMessage = "[\(timestamp.string(from: Date()))] \(message)"
        
        DispatchQueue.main.async {
            testResults.append(timestampedMessage)
        }
    }
    
    private func clearTestResults() {
        testResults.removeAll()
        addTestResult("🧹 Test sonuçları temizlendi")
    }
    
    private func requestNotificationPermission() {
        Task {
            let granted = await alarmService.requestAuthorization()
            await MainActor.run {
                alertMessage = granted ? "Bildirim izni verildi!" : "Bildirim izni reddedildi!"
                showSuccessAlert = true
            }
        }
    }
    
    private func clearAllNotifications() {
        Task {
            await alarmService.cancelAllAlarms()
            await MainActor.run {
                alertMessage = "Tüm bildirimler temizlendi!"
                showSuccessAlert = true
            }
        }
    }
}

// MARK: - Test Status Card Component
struct TestStatusCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    AlarmTestView()
        .environmentObject(LanguageManager.shared)
        .modelContainer(for: [AlarmSettings.self, AlarmNotification.self])
} 
