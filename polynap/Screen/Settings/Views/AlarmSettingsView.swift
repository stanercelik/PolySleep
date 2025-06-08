import SwiftUI
import SwiftData
import UserNotifications
import AVFoundation

struct AlarmSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var languageManager: LanguageManager
    
    @Query private var alarmSettings: [AlarmSettings]
    
    @State private var currentSettings: AlarmSettings?
    @State private var showingPermissionAlert = false
    @State private var showingTestAlarm = false
    
    // State for UI reflecting AlarmService status
    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined
    @State private var pendingAlarmsCount: Int = 0
    
    // State variables
    @State private var isEnabled = true { didSet { saveSettingsIfNeeded() } }
    @State private var selectedSound = "alarm.caf" { didSet { saveSettingsIfNeeded() } }
    @State private var volume: Double = 0.8 { didSet { saveSettingsIfNeeded() } }
    @State private var vibrationEnabled = true { didSet { saveSettingsIfNeeded() } }
    @State private var snoozeEnabled = true { didSet { saveSettingsIfNeeded() } }
    @State private var snoozeDuration = 5 { didSet { saveSettingsIfNeeded() } }
    @State private var maxSnoozeCount = 3 { didSet { saveSettingsIfNeeded() } }
    
    private var isAuthorized: Bool {
        notificationAuthStatus == .authorized || notificationAuthStatus == .provisional
    }
    
    private var availableSounds: [(String, String)] {
        return [("alarm.caf", "Alarm")]
    }
    
    private let snoozeDurations = [1, 3, 5, 10, 15]
    private let maxSnoozeCounts = [1, 2, 3, 5, 10]
    
    var body: some View {
        ZStack {
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
                    VStack(spacing: PSSpacing.lg) {
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
                    
                    ModernSettingsSection(
                        title: L("alarmSettings.status.title", table: "Settings"),
                        icon: "alarm",
                        iconColor: isEnabled ? .appPrimary : .appTextSecondary,
                        isMinimal: true
                    ) {
                        VStack(spacing: PSSpacing.lg) {
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
                        ModernSettingsSection(
                            title: L("alarmSettings.permission.title", table: "Settings"),
                            icon: isAuthorized ? "checkmark.shield.fill" : "exclamationmark.triangle.fill",
                            iconColor: isAuthorized ? .green : .orange,
                            isMinimal: true
                        ) {
                            VStack(spacing: PSSpacing.lg) {
                                HStack {
                                    VStack(alignment: .leading, spacing: PSSpacing.xs) {
                                        Text(L("alarmSettings.permission.notificationPermission", table: "Settings"))
                                            .font(PSTypography.headline)
                                            .foregroundColor(.appText)
                                        
                                        Text(isAuthorized ? L("alarmSettings.permission.granted", table: "Settings") : L("alarmSettings.permission.required", table: "Settings"))
                                            .font(PSTypography.caption)
                                            .foregroundColor(isAuthorized ? .green : .orange)
                                    }
                                    
                                    Spacer()
                                    
                                    if !isAuthorized {
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
                                
                                if !isAuthorized {
                                    ModernInfoCard(
                                        icon: "exclamationmark.triangle.fill",
                                        title: L("alarmSettings.permission.requiredTitle", table: "Settings"),
                                        message: L("alarmSettings.permission.requiredMessage", table: "Settings"),
                                        color: .orange
                                    )
                                }
                            }
                        }
                        
                        ModernSettingsSection(
                            title: L("alarmSettings.sound.title", table: "Settings"),
                            icon: "speaker.wave.2.fill",
                            iconColor: .blue,
                            isMinimal: true
                        ) {
                            VStack(spacing: PSSpacing.lg) {
                                VStack(alignment: .leading, spacing: PSSpacing.md) {
                                    Text(L("alarmSettings.sound.alarmSound", table: "Settings"))
                                        .font(PSTypography.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.appText)
                                    
                                    Menu {
                                        ForEach(availableSounds, id: \.0) { sound, name in
                                            Button(action: {
                                                selectedSound = sound
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
                        
                        ModernSettingsSection(
                            title: L("alarmSettings.snooze.title", table: "Settings"),
                            icon: "clock.arrow.2.circlepath",
                            iconColor: .purple,
                            isMinimal: true
                        ) {
                            VStack(spacing: PSSpacing.lg) {
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
                        
                        ModernSettingsSection(
                            title: L("alarmSettings.test.title", table: "Settings"),
                            icon: "testtube.2",
                            iconColor: .green,
                            isMinimal: true
                        ) {
                            VStack(spacing: PSSpacing.lg) {
                                ModernTestButton(
                                    icon: "speaker.wave.2.fill",
                                    title: L("alarmSettings.test.playTestAlarm", table: "Settings"),
                                    subtitle: L("alarmSettings.test.testDescription", table: "Settings"),
                                    color: .green
                                ) {
                                    testAlarm()
                                }
                                
                                ModernDivider()
                                
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
                                    
                                    Text("\(pendingAlarmsCount)")
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
                                
                                PSSecondaryButton("Tüm Alarmları İptal Et", icon: "trash.fill") {
                                    Task {
                                        let alarmService = AlarmService.shared
                                        await alarmService.cancelAllNotifications()
                                        await updateStatus()
                                    }
                                }
                            }
                        }
                    }
                    
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
            Text("Test alarmı 5 saniye sonra çalacak. Uygulamayı kapatabilir, arka plana alabilir veya açık bırakabilirsiniz.")
        }
        .onAppear {
            loadCurrentSettings()
            Task {
                await updateStatus()
            }
        }
        .environment(\.locale, Locale(identifier: languageManager.currentLanguage))
    }
    
    // MARK: - Functions
    
    private func updateStatus() async {
        let alarmService = AlarmService.shared
        notificationAuthStatus = await alarmService.getAuthorizationStatus()
        pendingAlarmsCount = await alarmService.getPendingNotificationsCount()
    }
    
    private func loadCurrentSettings() {
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
            createDefaultSettings()
        }
    }
    
    private func createDefaultSettings() {
        let defaultSettings = AlarmSettings(userId: UUID())
        modelContext.insert(defaultSettings)
        do {
            try modelContext.save()
            currentSettings = defaultSettings
        } catch {
            print("PolyNap Debug: Varsayılan alarm ayarları oluşturulamadı: \(error)")
        }
    }
    
    private func saveSettingsIfNeeded() {
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
            
            Task {
                let alarmService = AlarmService.shared
                await alarmService.rescheduleNotificationsForActiveSchedule(modelContext: modelContext)
            }
            
        } catch {
            print("PolyNap Debug: Alarm ayarları otomatik kaydedilemedi: \(error)")
        }
    }

    private func requestNotificationPermission() async {
        let alarmService = AlarmService.shared
        await alarmService.requestAuthorization()
        await updateStatus()
    }
    
    private func testAlarm() {
        Task {
            let alarmService = AlarmService.shared
            await alarmService.scheduleTestNotification(soundName: selectedSound, volume: Float(volume))
            showingTestAlarm = true
            await updateStatus()
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func previewSound(_ soundFileName: String) {
        let resourceName = soundFileName.replacingOccurrences(of: ".caf", with: "")
        guard let soundURL = Bundle.main.url(forResource: resourceName, withExtension: "caf") else {
            print("PolyNap Debug: Önizleme için ses dosyası bulunamadı: \(soundFileName)")
            return
        }
        
        Task {
            do {
                let player = try AVAudioPlayer(contentsOf: soundURL)
                player.volume = Float(volume)
                player.play()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    player.stop()
                }
            } catch {
                print("PolyNap Debug: Ses önizlemesi oynatılamadı: \(error)")
            }
        }
    }
}

// MARK: - Modern Components

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
