import SwiftUI
import SwiftData
import UserNotifications
import AVFoundation

struct AlarmSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var languageManager: LanguageManager
    
    @StateObject private var alarmService = AlarmNotificationService.shared
    @Query private var alarmSettings: [AlarmSettings]
    
    @State private var currentSettings: AlarmSettings?
    @State private var showingPermissionAlert = false
    @State private var showingTestAlarm = false
    
    // Geçici ayarlar (UI binding için) - otomatik kaydetme ile
    @State private var isEnabled = true {
        didSet { saveSettingsIfNeeded() }
    }
    @State private var selectedSound = "alarm.caf" {
        didSet { saveSettingsIfNeeded() }
    }
    @State private var volume: Double = 0.8 {
        didSet { saveSettingsIfNeeded() }
    }
    @State private var vibrationEnabled = true {
        didSet { saveSettingsIfNeeded() }
    }
    @State private var snoozeEnabled = true {
        didSet { saveSettingsIfNeeded() }
    }
    @State private var snoozeDuration = 5 {
        didSet { saveSettingsIfNeeded() }
    }
    @State private var maxSnoozeCount = 3 {
        didSet { saveSettingsIfNeeded() }
    }
    
    // Simple Alarm State
    @State private var simpleAlarmTime = Date()
    @State private var isSimpleAlarmRepeated = false
    @State private var pendingAlarmsCount: Int = 0
    
    // AlarmSound klasöründeki ses dosyalarını dinamik olarak yükle
    private var availableSounds: [(String, String)] {
        var sounds: [(String, String)] = []
        
        // AlarmSound klasöründeki .caf dosyalarını bul
        if let soundsPath = Bundle.main.path(forResource: "alarm", ofType: "caf") {
            let soundsURL = URL(fileURLWithPath: soundsPath).deletingLastPathComponent()
            
            do {
                let soundFiles = try FileManager.default.contentsOfDirectory(at: soundsURL, includingPropertiesForKeys: nil)
                    .filter { $0.pathExtension == "caf" }
                    .sorted { $0.lastPathComponent < $1.lastPathComponent }
                
                for soundFile in soundFiles {
                    let fileName = soundFile.lastPathComponent
                    let displayName = soundFile.deletingPathExtension().lastPathComponent.capitalized
                    sounds.append((fileName, displayName))
                }
            } catch {
                print("PolyNap Debug: AlarmSound klasörü okunamadı: \(error)")
            }
        }
        
        // Hiç ses bulunamazsa varsayılan ekle
        if sounds.isEmpty {
            sounds.append(("alarm.caf", "Alarm"))
        }
        
        return sounds
    }
    
    private let snoozeDurations = [1, 3, 5, 10, 15]
    private let maxSnoozeCounts = [1, 2, 3, 5, 10]
    
    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.appBackground,
                    Color.appBackground.opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: PSSpacing.xl) {
                    // Hero Header Section
                    VStack(spacing: PSSpacing.lg) {
                        // Icon with gradient background
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.appPrimary.opacity(0.8),
                                            Color.appAccent.opacity(0.6)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: PSIconSize.headerIcon, height: PSIconSize.headerIcon)
                                .shadow(
                                    color: Color.appPrimary.opacity(0.3),
                                    radius: PSSpacing.md,
                                    x: 0,
                                    y: PSSpacing.sm
                                )
                            
                            Image(systemName: "alarm.fill")
                                .font(.system(size: PSIconSize.headerIcon / 1.8))
                                .foregroundColor(.appTextOnPrimary)
                        }
                        
                        VStack(spacing: PSSpacing.sm) {
                            Text(L("alarmSettings.title", table: "Settings"))
                                .font(PSTypography.title1)
                                .foregroundColor(.appText)
                            
                            Text(L("alarmSettings.subtitle", table: "Settings"))
                                .font(PSTypography.body)
                                .foregroundColor(.appTextSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                    .padding(.top, PSSpacing.sm)
                    .padding(.horizontal, PSSpacing.xl)
                    
                    // Alarm Durumu Section
                    ModernSettingsSection(
                        title: L("alarmSettings.status.title", table: "Settings"),
                        icon: "alarm",
                        iconColor: isEnabled ? .appPrimary : .appTextSecondary,
                        isMinimal: true
                    ) {
                        VStack(spacing: PSSpacing.lg) {
                            // Main toggle
                            HStack {
                                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                                    Text(L("alarmSettings.status.sleepAlarms", table: "Settings"))
                                        .font(PSTypography.headline)
                                        .foregroundColor(.appText)
                                    
                                    Text(isEnabled ? L("alarmSettings.status.active", table: "Settings") : L("alarmSettings.status.disabled", table: "Settings"))
                                        .font(PSTypography.caption)
                                        .foregroundColor(.appTextSecondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $isEnabled)
                                    .labelsHidden()
                                    .scaleEffect(1.1)
                            }
                            .padding(.vertical, PSSpacing.xs)
                            
                            if !isEnabled {
                                ModernInfoCard(
                                    icon: "info.circle.fill",
                                    title: L("alarmSettings.status.disabledTitle", table: "Settings"),
                                    message: L("alarmSettings.status.disabledMessage", table: "Settings"),
                                    color: .orange
                                )
                            }
                        }
                    }
                    
                    if isEnabled {
                        // İzin Durumu Section
                        ModernSettingsSection(
                            title: L("alarmSettings.permission.title", table: "Settings"),
                            icon: alarmService.isAuthorized ? "checkmark.shield.fill" : "exclamationmark.triangle.fill",
                            iconColor: alarmService.isAuthorized ? .green : .orange,
                            isMinimal: true
                        ) {
                            VStack(spacing: PSSpacing.lg) {
                                HStack {
                                    VStack(alignment: .leading, spacing: PSSpacing.xs) {
                                        Text(L("alarmSettings.permission.notificationPermission", table: "Settings"))
                                            .font(PSTypography.headline)
                                            .foregroundColor(.appText)
                                        
                                        Text(alarmService.isAuthorized ? L("alarmSettings.permission.granted", table: "Settings") : L("alarmSettings.permission.required", table: "Settings"))
                                            .font(PSTypography.caption)
                                            .foregroundColor(alarmService.isAuthorized ? .green : .orange)
                                    }
                                    
                                    Spacer()
                                    
                                    if !alarmService.isAuthorized {
                                        PSSecondaryButton(L("alarmSettings.permission.grantButton", table: "Settings")) {
                                            Task {
                                                await requestNotificationPermission()
                                            }
                                        }
                                        .frame(width: 100)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.green)
                                    }
                                }
                                
                                if !alarmService.isAuthorized {
                                    ModernInfoCard(
                                        icon: "exclamationmark.triangle.fill",
                                        title: L("alarmSettings.permission.requiredTitle", table: "Settings"),
                                        message: L("alarmSettings.permission.requiredMessage", table: "Settings"),
                                        color: .orange
                                    )
                                }
                            }
                        }
                        
                        // Ses Ayarları Section
                        ModernSettingsSection(
                            title: L("alarmSettings.sound.title", table: "Settings"),
                            icon: "speaker.wave.2.fill",
                            iconColor: .blue,
                            isMinimal: true
                        ) {
                            VStack(spacing: PSSpacing.lg) {
                                // Alarm Sesi
                                VStack(alignment: .leading, spacing: PSSpacing.md) {
                                    Text(L("alarmSettings.sound.alarmSound", table: "Settings"))
                                        .font(PSTypography.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.appText)
                                    
                                    Menu {
                                        ForEach(availableSounds, id: \.0) { sound, name in
                                            Button(action: {
                                                selectedSound = sound
                                                print("PolyNap Debug: Alarm sesi seçildi: \(sound)")
                                                // Ses önizlemesi
                                                previewSound(sound)
                                            }) {
                                                HStack {
                                                    Image(systemName: "speaker.wave.2.fill")
                                                        .foregroundColor(.appPrimary)
                                                        .frame(width: 20)
                                                    Text(name)
                                                    if sound == selectedSound {
                                                        Spacer()
                                                        Image(systemName: "checkmark")
                                                            .foregroundColor(.appPrimary)
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(availableSounds.first(where: { $0.0 == selectedSound })?.1 ?? L("alarmSettings.sounds.default", table: "Settings"))
                                                .font(PSTypography.body)
                                                .foregroundColor(.appText)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.caption)
                                                .foregroundColor(.appTextSecondary)
                                        }
                                        .padding(PSSpacing.md)
                                        .background(
                                            RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                                                .fill(Color.appCardBackground.opacity(0.5))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                                                        .stroke(Color.appTextSecondary.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                    }
                                }
                                
                                ModernDivider()
                                
                                // Ses Seviyesi
                                VStack(alignment: .leading, spacing: PSSpacing.md) {
                                    HStack {
                                        Text(L("alarmSettings.sound.volume", table: "Settings"))
                                            .font(PSTypography.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.appText)
                                        
                                        Spacer()
                                        
                                        Text("\(Int(volume * 100))%")
                                            .font(PSTypography.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.appPrimary)
                                            .padding(.horizontal, PSSpacing.sm)
                                            .padding(.vertical, PSSpacing.xs)
                                            .background(
                                                Capsule()
                                                    .fill(Color.appPrimary.opacity(0.15))
                                            )
                                    }
                                    
                                    HStack {
                                        Image(systemName: "speaker.fill")
                                            .foregroundColor(.appTextSecondary)
                                            .font(.caption)
                                        
                                        Slider(value: $volume, in: 0.1...1.0, step: 0.1)
                                            .accentColor(.appPrimary)
                                        
                                        Image(systemName: "speaker.wave.3.fill")
                                            .foregroundColor(.appTextSecondary)
                                            .font(.caption)
                                    }
                                }
                                
                                ModernDivider()
                                
                                // Titreşim
                                HStack {
                                    VStack(alignment: .leading, spacing: PSSpacing.xs) {
                                        Text(L("alarmSettings.sound.vibration", table: "Settings"))
                                            .font(PSTypography.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.appText)
                                        
                                        Text(L("alarmSettings.sound.vibrationDescription", table: "Settings"))
                                            .font(PSTypography.caption)
                                            .foregroundColor(.appTextSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $vibrationEnabled)
                                        .labelsHidden()
                                        .scaleEffect(1.1)
                                }
                                .padding(.vertical, PSSpacing.xs)
                            }
                        }
                        
                        // Erteleme Ayarları Section
                        ModernSettingsSection(
                            title: L("alarmSettings.snooze.title", table: "Settings"),
                            icon: "clock.arrow.2.circlepath",
                            iconColor: .purple,
                            isMinimal: true
                        ) {
                            VStack(spacing: PSSpacing.lg) {
                                // Erteleme toggle
                                HStack {
                                    VStack(alignment: .leading, spacing: PSSpacing.xs) {
                                        Text(L("alarmSettings.snooze.allowSnooze", table: "Settings"))
                                            .font(PSTypography.headline)
                                            .foregroundColor(.appText)
                                        
                                        Text(L("alarmSettings.snooze.allowSnoozeDescription", table: "Settings"))
                                            .font(PSTypography.caption)
                                            .foregroundColor(.appTextSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $snoozeEnabled)
                                        .labelsHidden()
                                        .scaleEffect(1.1)
                                }
                                .padding(.vertical, PSSpacing.xs)
                                
                                if snoozeEnabled {
                                    ModernDivider()
                                    
                                    // Erteleme Süresi
                                    VStack(alignment: .leading, spacing: PSSpacing.md) {
                                        Text(L("alarmSettings.snooze.duration", table: "Settings"))
                                            .font(PSTypography.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.appText)
                                        
                                        Menu {
                                            ForEach(snoozeDurations, id: \.self) { duration in
                                                Button(L("alarmSettings.snooze.minutesFormat", table: "Settings").replacingOccurrences(of: "{duration}", with: "\(duration)")) {
                                                    snoozeDuration = duration
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Text(L("alarmSettings.snooze.minutesFormat", table: "Settings").replacingOccurrences(of: "{duration}", with: "\(snoozeDuration)"))
                                                    .font(PSTypography.body)
                                                    .foregroundColor(.appText)
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.up.chevron.down")
                                                    .font(.caption)
                                                    .foregroundColor(.appTextSecondary)
                                            }
                                            .padding(PSSpacing.md)
                                            .background(
                                                RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                                                    .fill(Color.appCardBackground.opacity(0.5))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                                                            .stroke(Color.appTextSecondary.opacity(0.3), lineWidth: 1)
                                                    )
                                            )
                                        }
                                    }
                                    
                                    ModernDivider()
                                    
                                    // Maksimum Erteleme
                                    VStack(alignment: .leading, spacing: PSSpacing.md) {
                                        Text(L("alarmSettings.snooze.maxCount", table: "Settings"))
                                            .font(PSTypography.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.appText)
                                        
                                        Menu {
                                            ForEach(maxSnoozeCounts, id: \.self) { count in
                                                Button(L("alarmSettings.snooze.timesFormat", table: "Settings").replacingOccurrences(of: "{count}", with: "\(count)")) {
                                                    maxSnoozeCount = count
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Text(L("alarmSettings.snooze.timesFormat", table: "Settings").replacingOccurrences(of: "{count}", with: "\(maxSnoozeCount)"))
                                                    .font(PSTypography.body)
                                                    .foregroundColor(.appText)
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.up.chevron.down")
                                                    .font(.caption)
                                                    .foregroundColor(.appTextSecondary)
                                            }
                                            .padding(PSSpacing.md)
                                            .background(
                                                RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                                                    .fill(Color.appCardBackground.opacity(0.5))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                                                            .stroke(Color.appTextSecondary.opacity(0.3), lineWidth: 1)
                                                    )
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Yeni Basit Alarm Ayarları Bölümü
                        ModernSettingsSection(
                            title: "Hızlı Alarm Kur",
                            icon: "plus.alarm.fill",
                            iconColor: .cyan,
                            isMinimal: true
                        ) {
                            VStack(spacing: PSSpacing.lg) {
                                Text("Aşağıdan hızlıca tek seferlik veya günlük tekrar eden bir alarm kurabilirsiniz. Bu alarm, uyku programınızdan bağımsızdır.")
                                    .font(PSTypography.caption)
                                    .foregroundColor(.appTextSecondary)
                                
                                DatePicker(
                                    "Alarm Zamanı",
                                    selection: $simpleAlarmTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .font(PSTypography.body)
                                .tint(.appPrimary)
                                
                                Toggle("Her gün tekrarla", isOn: $isSimpleAlarmRepeated)
                                    .font(PSTypography.body)
                                    .tint(.appPrimary)
                                
                                VStack(spacing: PSSpacing.md) {
                                    PSPrimaryButton("Hızlı Alarm Kur", icon: "alarm.fill") {
                                        AlarmService.shared.scheduleAlarmNotification(
                                            date: simpleAlarmTime,
                                            repeats: isSimpleAlarmRepeated,
                                            modelContext: modelContext
                                        )
                                        updatePendingAlarmsCount()
                                    }
                                    
                                    PSPrimaryButton("Test Alarmı (30sn)", icon: "testtube.2", customBackgroundColor: .orange) {
                                        AlarmService.shared.scheduleTestAlarm(modelContext: modelContext)
                                        updatePendingAlarmsCount()
                                        showingTestAlarm = true
                                    }
                                    
                                    PSPrimaryButton("Tüm Alarmları İptal Et", icon: "trash.fill", destructive: true) {
                                        AlarmService.shared.cancelPendingAlarms()
                                        updatePendingAlarmsCount()
                                    }
                                }
                                
                                ModernDivider()
                                
                                HStack {
                                    Text("Bekleyen Hızlı Alarm Sayısı:")
                                        .font(PSTypography.body)
                                    Spacer()
                                    Text("\(pendingAlarmsCount)")
                                        .font(PSTypography.headline)
                                        .foregroundColor(.appPrimary)
                                }
                                
                                PSSecondaryButton("Tüm Hızlı Alarmları İptal Et", icon: "trash.fill") {
                                    AlarmService.shared.cancelPendingAlarms()
                                    updatePendingAlarmsCount()
                                }
                            }
                        }
                        
                        // Test ve Bilgi Section
                        ModernSettingsSection(
                            title: L("alarmSettings.test.title", table: "Settings"),
                            icon: "testtube.2",
                            iconColor: .green,
                            isMinimal: true
                        ) {
                            VStack(spacing: PSSpacing.lg) {
                                // Test Alarmı
                                ModernTestButton(
                                    icon: "speaker.wave.2.fill",
                                    title: L("alarmSettings.test.playTestAlarm", table: "Settings"),
                                    subtitle: L("alarmSettings.test.testDescription", table: "Settings"),
                                    color: .green
                                ) {
                                    testAlarm()
                                }
                                
                                // Kapsamlı Alarm Testi (Sleep Block Bitimi Simülasyonu)
                                ModernTestButton(
                                    icon: "alarm.fill",
                                    title: "Sleep Block Alarm Testi",
                                    subtitle: "Uyku bloğu bitimi alarmını test eder (tüm senaryolar)",
                                    color: .blue
                                ) {
                                    testComprehensiveAlarm()
                                }
                                
                                ModernDivider()
                                
                                // Bekleyen Alarmlar
                                HStack {
                                    VStack(alignment: .leading, spacing: PSSpacing.xs) {
                                        Text(L("alarmSettings.test.pendingAlarms", table: "Settings"))
                                            .font(PSTypography.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.appText)
                                        
                                        Text(L("alarmSettings.test.pendingAlarmsDescription", table: "Settings"))
                                            .font(PSTypography.caption)
                                            .foregroundColor(.appTextSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(alarmService.pendingNotificationsCount)")
                                        .font(PSTypography.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.appPrimary)
                                        .padding(.horizontal, PSSpacing.md)
                                        .padding(.vertical, PSSpacing.sm)
                                        .background(
                                            Circle()
                                                .fill(Color.appPrimary.opacity(0.15))
                                        )
                                }
                            }
                        }
                    }
                    
                    // Bottom spacing
                    Spacer(minLength: PSSpacing.xl)
                }
                .padding(.horizontal, PSSpacing.lg)
                .padding(.bottom, PSSpacing.xl)
            }
        }
        .navigationTitle(L("alarmSettings.title", table: "Settings"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(L("alarmSettings.permission.alertTitle", table: "Settings"), isPresented: $showingPermissionAlert) {
            Button(L("alarmSettings.permission.alertSettings", table: "Settings")) {
                openAppSettings()
            }
            Button(L("general.cancel", table: "Settings"), role: .cancel) { }
        } message: {
            Text(L("alarmSettings.permission.alertMessage", table: "Settings"))
        }
        .alert("Test Alarmı Kuruldu", isPresented: $showingTestAlarm) {
            Button("Tamam") { }
        } message: {
            Text("Test alarmı 5 saniye sonra çalacak ve 30 saniye boyunca sürekli çalacak. Uygulamayı kapatabilir, arka plana alabilir veya açık bırakabilirsiniz.")
        }
        .onAppear {
            loadCurrentSettings()
            Task {
                await alarmService.checkAuthorizationStatus()
            }
            updatePendingAlarmsCount()
        }
        .environment(\.locale, Locale(identifier: languageManager.currentLanguage))
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
            print("PolyNap Debug: Varsayılan alarm ayarları oluşturulamadı: \(error)")
        }
    }
    
    // Otomatik kaydetme fonksiyonu
    private func saveSettingsIfNeeded() {
        guard let settings = currentSettings else {
            createDefaultSettings()
            return
        }
        
        // Değişiklikleri ayarlara yansıt
        settings.isEnabled = isEnabled
        settings.soundName = selectedSound
        settings.volume = volume
        settings.vibrationEnabled = vibrationEnabled
        settings.snoozeEnabled = snoozeEnabled
        settings.snoozeDurationMinutes = snoozeDuration
        settings.maxSnoozeCount = maxSnoozeCount
        settings.updatedAt = Date()
        
        // SwiftData otomatik kaydetme
        do {
            try modelContext.save()
        } catch {
            print("PolyNap Debug: Alarm ayarları otomatik kaydedilemedi: \(error)")
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
    
    /// Ses önizlemesi için kısa oynatma
    private func previewSound(_ soundFileName: String) {
        let resourceName = soundFileName.replacingOccurrences(of: ".caf", with: "")
        guard let soundURL = Bundle.main.url(forResource: resourceName, withExtension: "caf") else {
            print("PolyNap Debug: Önizleme için ses dosyası bulunamadı: \(soundFileName)")
            return
        }
        
        // 3 saniye önizleme oynat
        Task {
            do {
                let player = try AVAudioPlayer(contentsOf: soundURL)
                player.volume = Float(volume)
                player.play()
                
                // 3 saniye sonra durdur
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    player.stop()
                }
            } catch {
                print("PolyNap Debug: Ses önizlemesi oynatılamadı: \(error)")
            }
        }
    }
    
    private func testAlarm() {
        Task {
            // 5 saniye sonra test alarmı
            let testContent = UNMutableNotificationContent()
            testContent.title = "🔔 " + L("alarmSettings.test.notificationTitle", table: "Settings")
            testContent.body = L("alarmSettings.test.notificationBody", table: "Settings")
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
                print("PolyNap Debug: Test alarmı planlanamadı: \(error)")
            }
        }
    }
    
    /// Kapsamlı alarm testi - Sleep block bitimi simülasyonu
    private func testComprehensiveAlarm() {
        // Kapsamlı alarm sistemini test et (tüm senaryolar)
        AlarmService.shared.scheduleTestComprehensiveAlarm(modelContext: modelContext)
        
        showingTestAlarm = true
        print("PolyNap Debug: Kapsamlı alarm test sistemi başlatıldı - 5 saniye sonra tetiklenecek")
    }
    
    private func updatePendingAlarmsCount() {
        AlarmService.shared.notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                self.pendingAlarmsCount = requests.filter { $0.content.categoryIdentifier == "ALARM_CATEGORY" }.count
            }
        }
    }
}

// MARK: - Modern Components

// Modern info card for displaying important information
struct ModernInfoCard: View {
    let icon: String
    let title: String
    let message: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: PSSpacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: PSSpacing.xs) {
                Text(title)
                    .font(PSTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Text(message)
                    .font(PSTypography.caption)
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(PSSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// Modern test button for alarm testing
struct ModernTestButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: PSSpacing.md) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text(title)
                        .font(PSTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.appText)
                    
                    Text(subtitle)
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(color.opacity(0.7))
            }
            .padding(PSSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                color.opacity(0.05),
                                color.opacity(0.02)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { isPressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = isPressing
            }
        } perform: {
            action()
        }
    }
}

#Preview {
    NavigationStack {
        AlarmSettingsView()
            .modelContainer(for: [AlarmSettings.self])
            .environmentObject(LanguageManager.shared)
    }
} 
