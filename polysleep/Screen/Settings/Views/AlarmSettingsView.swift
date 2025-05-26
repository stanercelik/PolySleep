import SwiftUI
import SwiftData
import UserNotifications

struct AlarmSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var alarmService = AlarmNotificationService.shared
    @Query private var alarmSettings: [AlarmSettings]
    
    @State private var currentSettings: AlarmSettings?
    @State private var showingPermissionAlert = false
    @State private var showingTestAlarm = false
    
    // Geçici ayarlar (UI binding için)
    @State private var isEnabled = true
    @State private var selectedSound = "alarm.caf"
    @State private var volume: Double = 0.8
    @State private var vibrationEnabled = true
    @State private var snoozeEnabled = true
    @State private var snoozeDuration = 5
    @State private var maxSnoozeCount = 3
    
    private let availableSounds = [
        ("alarm.caf", "Varsayılan Alarm"),
        ("default", "Sistem Varsayılanı"),
        ("critical", "Kritik Alarm")
    ]
    
    private let snoozeDurations = [1, 3, 5, 10, 15]
    private let maxSnoozeCounts = [1, 2, 3, 5, 10]
    
    var body: some View {
        NavigationView {
            Form {
                // Alarm Durumu
                Section {
                    HStack {
                        Image(systemName: isEnabled ? "alarm.fill" : "alarm")
                            .foregroundColor(isEnabled ? .accentColor : .secondary)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Uyku Alarmları")
                                .font(.headline)
                            Text(isEnabled ? "Aktif" : "Devre Dışı")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $isEnabled)
                            .labelsHidden()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Alarm Durumu")
                } footer: {
                    Text("Uyku bloklarınız bittiğinde alarm çalmasını istiyorsanız etkinleştirin.")
                }
                
                if isEnabled {
                    // İzin Durumu
                    Section {
                        HStack {
                            Image(systemName: alarmService.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(alarmService.isAuthorized ? .green : .orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Bildirim İzni")
                                    .font(.subheadline)
                                Text(alarmService.isAuthorized ? "İzin verildi" : "İzin gerekli")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if !alarmService.isAuthorized {
                                Button("İzin Ver") {
                                    Task {
                                        await requestNotificationPermission()
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .padding(.vertical, 2)
                    } footer: {
                        if !alarmService.isAuthorized {
                            Text("Alarmların çalışması için bildirim izni gereklidir.")
                        }
                    }
                    
                    // Ses Ayarları
                    Section("Ses Ayarları") {
                        // Alarm Sesi
                        Picker("Alarm Sesi", selection: $selectedSound) {
                            ForEach(availableSounds, id: \.0) { sound, name in
                                Text(name).tag(sound)
                            }
                        }
                        
                        // Ses Seviyesi
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Ses Seviyesi")
                                Spacer()
                                Text("\(Int(volume * 100))%")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            
                            Slider(value: $volume, in: 0.1...1.0, step: 0.1) {
                                Text("Ses Seviyesi")
                            } minimumValueLabel: {
                                Image(systemName: "speaker.fill")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            } maximumValueLabel: {
                                Image(systemName: "speaker.wave.3.fill")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        // Titreşim
                        Toggle("Titreşim", isOn: $vibrationEnabled)
                    }
                    
                    // Erteleme Ayarları
                    Section("Erteleme Ayarları") {
                        Toggle("Erteleme İzin Ver", isOn: $snoozeEnabled)
                        
                        if snoozeEnabled {
                            Picker("Erteleme Süresi", selection: $snoozeDuration) {
                                ForEach(snoozeDurations, id: \.self) { duration in
                                    Text("\(duration) dakika").tag(duration)
                                }
                            }
                            
                            Picker("Maksimum Erteleme", selection: $maxSnoozeCount) {
                                ForEach(maxSnoozeCounts, id: \.self) { count in
                                    Text("\(count) kez").tag(count)
                                }
                            }
                        }
                    }
                    
                    // Test ve Bilgi
                    Section {
                        // Test Alarmı
                        Button(action: {
                            testAlarm()
                        }) {
                            HStack {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundColor(.accentColor)
                                Text("Test Alarmı Çal")
                                Spacer()
                            }
                        }
                        
                        // Bekleyen Alarmlar
                        HStack {
                            Image(systemName: "clock.badge")
                                .foregroundColor(.secondary)
                            Text("Bekleyen Alarmlar")
                            Spacer()
                            Text("\(alarmService.pendingNotificationsCount)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    } footer: {
                        Text("Test alarmı 5 saniye sonra çalacaktır. Bekleyen alarm sayısı otomatik olarak güncellenir.")
                    }
                }
            }
            .navigationTitle("Alarm Ayarları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        saveSettings()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Bildirim İzni", isPresented: $showingPermissionAlert) {
                Button("Ayarlara Git") {
                    openAppSettings()
                }
                Button("İptal", role: .cancel) { }
            } message: {
                Text("Alarm özelliğini kullanmak için Ayarlar'dan bildirim izni vermeniz gerekiyor.")
            }
            .alert("Test Alarmı", isPresented: $showingTestAlarm) {
                Button("Tamam") { }
            } message: {
                Text("Test alarmı 5 saniye sonra çalacak.")
            }
        }
        .onAppear {
            loadCurrentSettings()
            Task {
                await alarmService.checkAuthorizationStatus()
            }
        }
    }
    
    // MARK: - Functions
    
    private func loadCurrentSettings() {
        // Mevcut kullanıcının ayarlarını yükle
        if let settings = alarmSettings.first {
            currentSettings = settings
            isEnabled = settings.isEnabled
            selectedSound = settings.soundName
            volume = settings.volume
            vibrationEnabled = settings.vibrationEnabled
            snoozeEnabled = settings.snoozeEnabled
            snoozeDuration = settings.snoozeDurationMinutes
            maxSnoozeCount = settings.maxSnoozeCount
        } else {
            // Varsayılan ayarları oluştur
            createDefaultSettings()
        }
    }
    
    private func createDefaultSettings() {
        let defaultSettings = AlarmSettings(userId: UUID()) // Gerçek userId buraya gelecek
        modelContext.insert(defaultSettings)
        
        do {
            try modelContext.save()
            currentSettings = defaultSettings
        } catch {
            print("PolySleep Debug: Varsayılan alarm ayarları oluşturulamadı: \(error)")
        }
    }
    
    private func saveSettings() {
        guard let settings = currentSettings else {
            createDefaultSettings()
            return
        }
        
        settings.isEnabled = isEnabled
        settings.soundName = selectedSound
        settings.volume = volume
        settings.vibrationEnabled = vibrationEnabled
        settings.snoozeEnabled = snoozeEnabled
        settings.snoozeDurationMinutes = snoozeDuration
        settings.maxSnoozeCount = maxSnoozeCount
        settings.updatedAt = Date()
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("PolySleep Debug: Alarm ayarları kaydedilemedi: \(error)")
        }
    }
    
    private func requestNotificationPermission() async {
        let granted = await alarmService.requestAuthorization()
        
        if !granted {
            await MainActor.run {
                showingPermissionAlert = true
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func testAlarm() {
        Task {
            // 5 saniye sonra test alarmı
            let testContent = UNMutableNotificationContent()
            testContent.title = "🔔 Test Alarmı"
            testContent.body = "Bu bir test alarmıdır. Ertele ve Kapat butonlarını test edebilirsiniz!"
            testContent.categoryIdentifier = "SLEEP_ALARM" // Butonları göstermek için
            testContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: selectedSound))
            testContent.interruptionLevel = .critical
            testContent.userInfo = [
                "blockId": UUID().uuidString,
                "scheduleId": UUID().uuidString,
                "userId": UUID().uuidString,
                "type": "sleep_alarm"
            ]
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(
                identifier: "test_alarm_\(UUID().uuidString)",
                content: testContent,
                trigger: trigger
            )
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                await MainActor.run {
                    showingTestAlarm = true
                }
            } catch {
                print("PolySleep Debug: Test alarmı planlanamadı: \(error)")
            }
        }
    }
}

#Preview {
    AlarmSettingsView()
        .modelContainer(for: [AlarmSettings.self])
} 