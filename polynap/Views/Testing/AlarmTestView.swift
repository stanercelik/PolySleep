import SwiftUI
import SwiftData
import UserNotifications
import AVFoundation

struct AlarmTestView: View {
    // Merkezi servisimize referans veriyoruz. Artık @StateObject'e gerek yok.
    private let alarmService = AlarmService.shared
    
    // In-app alarm UI durumunu yöneten AlarmManager'ı environment'dan alıyoruz.
    @EnvironmentObject private var alarmManager: AlarmManager
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var languageManager: LanguageManager
    
    // Test durumu için state'ler
    @State private var testResults: [String] = []
    @State private var isTestingInProgress = false
    @State private var showSuccessAlert = false
    @State private var alertMessage = ""
    @State private var selectedTestType = 0
    
    // UI'da anlık olarak gösterilecek izin durumu ve bildirim sayısı
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var pendingNotificationCount: Int = 0
    
    // Ses testi için ayarlar
    @State private var testSoundName = "Alarm 1.caf"
    @State private var testVolume: Double = 1.0
    @State private var testDuration: Double = 5.0
    
    // Geçici ses çalar (sadece bu view için)
    @State private var previewAudioPlayer: AVAudioPlayer?

    private let testTypes = ["Hızlı Test", "Detaylı Test", "Ses Validasyonu", "Sistem Durumu"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    statusCardsSection
                    testTypeSelection
                    soundTestSection
                    testButtonsSection
                    testResultsSection
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("🔔 Alarm Test Merkezi")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    addTestResult("📱 Alarm Test Merkezi açıldı")
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
                icon: "bell.badge.fill",
                title: "Bildirim İzni",
                value: permissionStatus == .authorized ? "✅ Aktif" : "❌ Pasif",
                color: permissionStatus == .authorized ? .green : .red
            )
            
            TestStatusCard(
                icon: "alarm.fill",
                title: "Planlanmış Bildirim",
                value: "\(pendingNotificationCount)",
                color: .blue
            )
            
            TestStatusCard(
                icon: "speaker.wave.3.fill",
                title: "Uygulama İçi Alarm",
                value: alarmManager.isAlarmFiring ? "🔊 Çalıyor" : "🔇 Sessiz",
                color: alarmManager.isAlarmFiring ? .orange : .gray
            )
            
            TestStatusCard(
                icon: "waveform.path.ecg",
                title: "Ses Validasyonu",
                value: "Raporla Kontrol",
                color: .purple
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
    
    private var soundTestSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎵 Ses Test Ayarları")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Diğer ayarlar...
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
                    }
                    Slider(value: $testDuration, in: 1.0...10.0) // Süreyi daha makul bir aralığa çektim
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
            HStack(spacing: 16) {
                Button(action: { Task { await runSelectedTest() } }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Testi Çalıştır")
                    }
                }
                .buttonStyle(PrimaryTestButtonStyle(color: .blue))
                .disabled(isTestingInProgress)
                
                Button(action: clearTestResults) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Temizle")
                    }
                }
                .buttonStyle(PrimaryTestButtonStyle(color: .red))
            }
            
            VStack(spacing: 12) {
                Button(action: { Task { await testAudioPlayer() } }) {
                    Label("Sadece Sesi Test Et", systemImage: "speaker.wave.3.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryTestButtonStyle(color: .orange))
                
                Button(action: generateSoundReport) {
                    Label("Ses Dosyası Raporu Oluştur", systemImage: "doc.text.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryTestButtonStyle(color: .purple))
            }
            
            HStack(spacing: 16) {
                Button(action: { Task { await requestNotificationPermission() } }) {
                    Text("🔔 İzin İste")
                }
                .buttonStyle(SecondaryTestButtonStyle(color: .yellow, foreground: .black))
                
                Button(action: { Task { await clearAllNotifications() } }) {
                    Text("🗑️ Bildirimleri Temizle")
                }
                .buttonStyle(SecondaryTestButtonStyle(color: .gray))
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
                if isTestingInProgress {
                    ProgressView().scaleEffect(0.8)
                }
            }
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(testResults.reversed(), id: \.self) { result in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•").font(.system(size: 14, weight: .bold))
                            Text(result).font(.system(size: 13, design: .monospaced))
                            Spacer()
                        }
                    }
                }
                .padding()
            }
            .frame(height: 250)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Test Functions
    
    private func runSelectedTest() async {
        isTestingInProgress = true
        addTestResult("🚀 \(testTypes[selectedTestType]) başlatıldı...")
        
        switch selectedTestType {
        case 0: await runQuickTest()
        case 1: await runDetailedTest()
        case 2: await testSoundValidation()
        case 3: await checkSystemStatus()
        default: break
        }
        
        isTestingInProgress = false
        addTestResult("✅ Test tamamlandı.")
    }
    
    private func runQuickTest() async {
        await checkPermissionStatus()
        if permissionStatus == .authorized {
            addTestResult("⏰ Test alarmı 5 saniye sonra çalması için planlandı.")
            await alarmService.scheduleTestNotification(soundName: "Alarm 1.caf", volume: 1.0)
        } else {
            addTestResult("❌ Bildirim izni gerekli. Lütfen izin isteyin.")
        }
    }
    
    private func runDetailedTest() async {
        await checkSystemStatus()
        await testSoundValidation()
        await runQuickTest()
    }
    
    private func testSoundValidation() async {
        addTestResult("🎵 Ses dosyası validasyonu başlatıldı...")
        let soundManager = AlarmSoundManager.shared
        let report = soundManager.generateSoundReport()
        report.components(separatedBy: "\n").forEach { addTestResult($0) }
    }
    
    private func testAudioPlayer() async {
        addTestResult("🔊 Sadece ses testi başlatıldı...")
        addTestResult("▶️ Test sesi çalınıyor... (\(String(format: "%.0f", testDuration))s)")
        
        // Bu view'e özel geçici bir ses çalar oluştur
        guard let url = Bundle.main.url(forResource: "alarm", withExtension: "caf") else {
            addTestResult("❌ Alarm 1.caf dosyası bulunamadı.")
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            previewAudioPlayer = try AVAudioPlayer(contentsOf: url)
            previewAudioPlayer?.volume = Float(testVolume)
            previewAudioPlayer?.play()
            
            try? await Task.sleep(nanoseconds: UInt64(testDuration * 1_000_000_000))
            
            previewAudioPlayer?.stop()
            previewAudioPlayer = nil
            try? AVAudioSession.sharedInstance().setActive(false)
            
            addTestResult("⏹️ Test sesi durduruldu.")
        } catch {
            addTestResult("❌ Ses çalınırken hata: \(error.localizedDescription)")
        }
    }
    
    private func checkSystemStatus() async {
        addTestResult("--- Sistem Durumu Kontrolü ---")
        await checkPermissionStatus()
        await checkPendingNotifications()
        addTestResult("📱 Uygulama İçi Alarm: \(alarmManager.isAlarmFiring ? "Aktif" : "Pasif")")
        addTestResult("-----------------------------")
    }

    private func generateSoundReport() {
        addTestResult("--- Ses Dosyası Raporu ---")
        let report = AlarmSoundManager.shared.generateSoundReport()
        report.components(separatedBy: "\n").forEach { addTestResult($0) }
        addTestResult("--------------------------")
    }
    
    // MARK: - Helper Functions
    
    private func addTestResult(_ message: String) {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let timestamp = DateFormatter()
        timestamp.dateFormat = "HH:mm:ss"
        let timestampedMessage = "[\(timestamp.string(from: Date()))] \(message)"
        
        DispatchQueue.main.async {
            testResults.append(timestampedMessage)
        }
    }
    
    private func clearTestResults() {
        testResults.removeAll()
        addTestResult("🧹 Test sonuçları temizlendi.")
    }
    
    private func requestNotificationPermission() async {
        await alarmService.requestAuthorization()
        await checkPermissionStatus()
        alertMessage = (permissionStatus == .authorized) ? "Bildirim izni verildi!" : "Bildirim izni reddedildi!"
        showSuccessAlert = true
    }
    
    private func clearAllNotifications() async {
        await alarmService.cancelAllNotifications()
        await checkPendingNotifications()
        alertMessage = "Tüm planlanmış bildirimler temizlendi!"
        showSuccessAlert = true
    }

    private func checkPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            self.permissionStatus = settings.authorizationStatus
            addTestResult("🔔 Bildirim İzin Durumu: \(permissionStatus.description)")
        }
    }

    private func checkPendingNotifications() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        await MainActor.run {
            self.pendingNotificationCount = requests.count
            addTestResult("⏰ Planlanmış Bildirim Sayısı: \(pendingNotificationCount)")
        }
    }
}

// MARK: - Supporting Components & Styles

extension UNAuthorizationStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notDetermined: return "Belirlenmedi"
        case .denied: return "Reddedildi"
        case .authorized: return "İzin Verildi"
        case .provisional: return "Geçici İzin"
        case .ephemeral: return "Kısa Süreli"
        @unknown default: return "Bilinmeyen Durum"
        }
    }
}

private struct PrimaryTestButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(color)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

private struct SecondaryTestButtonStyle: ButtonStyle {
    let color: Color
    var foreground: Color = .primary
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(color.opacity(0.2))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

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
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#if DEBUG
struct AlarmTestView_Previews: PreviewProvider {
    static var previews: some View {
        AlarmTestView()
            .environmentObject(LanguageManager.shared)
            .environmentObject(AlarmManager())
            .modelContainer(for: [AlarmSettings.self, AlarmNotification.self])
    }
}
#endif
