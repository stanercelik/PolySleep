import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.colorScheme) private var colorScheme
    @Query private var userPreferences: [UserPreferences]
    @State private var reminderTime: Double = 15
    @State private var hasScheduleChanged = false
    @State private var showTestAlert = false
    @State private var testNotificationScheduled = false
    @State private var notificationPermissionStatus = L("notifications.permission.unknown", table: "Profile")
    
    var currentPreferences: UserPreferences? {
        userPreferences.first
    }
    
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
                LazyVStack(spacing: 20) {
                    // Hero Header Section
                    VStack(spacing: 16) {
                        // Icon with gradient background
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.appAccent.opacity(0.8),
                                            Color.appSecondary.opacity(0.6)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                                .shadow(
                                    color: Color.appAccent.opacity(0.3),
                                    radius: 12,
                                    x: 0,
                                    y: 6
                                )
                            
                            Image(systemName: "bell.badge.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text(L("notifications.management.title", table: "Profile"))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.appText)
                            
                            Text(L("notifications.management.subtitle", table: "Profile"))
                                .font(.subheadline)
                                .foregroundColor(.appTextSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 24)
                    
                    // Reminder Time Card
                    ModernNotificationCard {
                        VStack(spacing: 20) {
                            // Card Header
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.appPrimary.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "clock.arrow.2.circlepath")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.appPrimary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(L("notifications.reminderTime.title", table: "Profile"))
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.appText)
                                    
                                    Text(L("notifications.reminderTime.subtitle", table: "Profile"))
                                        .font(.caption)
                                        .foregroundColor(.appTextSecondary)
                                }
                                
                                Spacer()
                            }
                            
                            // Time Display
                            VStack(spacing: 16) {
                                HStack {
                                    if reminderTime > 0 {
                                        Text("\(formatTime(minutes: Int(reminderTime)))")
                                            .font(.system(size: 28, weight: .bold, design: .rounded))
                                            .foregroundColor(.appAccent)
                                    } else {
                                        Text(L("notifications.off", table: "Profile"))
                                            .font(.system(size: 28, weight: .bold, design: .rounded))
                                            .foregroundColor(.appTextSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Quick Actions
                                    HStack(spacing: 8) {
                                        ModernQuickTimeButton(time: 5, currentTime: $reminderTime)
                                        ModernQuickTimeButton(time: 15, currentTime: $reminderTime)
                                        ModernQuickTimeButton(time: 30, currentTime: $reminderTime)
                                    }
                                }
                                
                                ModernSlider(
                                    value: $reminderTime,
                                    range: 0...120,
                                    step: 1,
                                    trackColor: Color.appTextSecondary.opacity(0.2),
                                    thumbColor: Color.appAccent
                                )
                                .onChange(of: reminderTime) { oldValue, newValue in
                                    saveReminderTime(minutes: Int(newValue))
                                    hasScheduleChanged = true
                                }
                                
                                HStack {
                                    Text(L("notifications.off", table: "Profile"))
                                        .font(.caption2)
                                        .foregroundColor(.appTextSecondary)
                                    Spacer()
                                    Text(L("notifications.twoHours", table: "Profile"))
                                        .font(.caption2)
                                        .foregroundColor(.appTextSecondary)
                                }
                            }
                        }
                    }
                    
                    // Test Section Card
                    ModernNotificationCard {
                        VStack(spacing: 20) {
                            // Card Header
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.appSecondary.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "testtube.2")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.appSecondary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(L("notifications.test.title", table: "Profile"))
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.appText)
                                    
                                    Text(L("notifications.test.subtitle", table: "Profile"))
                                        .font(.caption)
                                        .foregroundColor(.appTextSecondary)
                                }
                                
                                Spacer()
                            }
                            
                            VStack(spacing: 12) {
                                ModernNotificationTestButton(
                                    icon: "bell.badge.fill",
                                    title: L("notifications.test.immediate.title", table: "Profile"),
                                    subtitle: L("notifications.test.immediate.subtitle", table: "Profile"),
                                    color: .appAccent
                                ) {
                                    testNotificationImmediately()
                                }
                                
                                ModernNotificationTestButton(
                                    icon: "timer",
                                    title: L("notifications.test.delayed.title", table: "Profile"),
                                    subtitle: L("notifications.test.delayed.subtitle", table: "Profile"),
                                    color: .appSecondary
                                ) {
                                    test5SecondNotification()
                                }
                                
                                if testNotificationScheduled {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text(L("notifications.test.scheduled", table: "Profile"))
                                            .font(.caption)
                                            .foregroundColor(.green)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.green.opacity(0.1))
                                    )
                                    .transition(.opacity.combined(with: .scale))
                                }
                            }
                        }
                    }
                    
                    // Status Card
                    ModernNotificationCard {
                        VStack(spacing: 20) {
                            // Card Header
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(L("notifications.status.title", table: "Profile"))
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.appText)
                                    
                                    Text(L("notifications.status.subtitle", table: "Profile"))
                                        .font(.caption)
                                        .foregroundColor(.appTextSecondary)
                                }
                                
                                Spacer()
                            }
                            
                            VStack(spacing: 12) {
                                ModernStatusRow(
                                    icon: "bell.circle.fill",
                                    title: L("notifications.permission.title", table: "Profile"),
                                    value: notificationPermissionStatus,
                                    valueColor: notificationPermissionStatus == L("notifications.permission.granted", table: "Profile") ? .green : .orange
                                )
                                
                                ModernStatusDivider()
                                
                                ModernStatusRow(
                                    icon: "moon.circle.fill",
                                    title: L("notifications.status.activeProgram", table: "Profile"),
                                    value: ScheduleManager.shared.activeSchedule?.name ?? L("notifications.status.noProgram", table: "Profile"),
                                    valueColor: ScheduleManager.shared.activeSchedule != nil ? .green : .orange
                                )
                                
                                ModernStatusDivider()
                                
                                ModernStatusRow(
                                    icon: "timer.circle.fill",
                                    title: L("notifications.status.reminderTime", table: "Profile"),
                                    value: "\(Int(reminderTime)) " + L("notifications.minutes", table: "Profile"),
                                    valueColor: .appPrimary
                                )
                            }
                        }
                    }
                    
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle(L("notifications.settings.title", table: "Profile"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentSettings()
            checkNotificationPermission()
        }
        .onChange(of: hasScheduleChanged) { oldValue, newValue in
            if newValue {
                updateNotificationsForActiveSchedule()
                hasScheduleChanged = false
            }
        }
        .alert(L("notifications.test.alert.title", table: "Profile"), isPresented: $showTestAlert) {
            Button(L("general.ok", table: "Profile")) { }
        } message: {
            Text(L("notifications.test.alert.message", table: "Profile"))
        }
    }
    
    private func loadCurrentSettings() {
        if let preferences = currentPreferences {
            reminderTime = Double(preferences.reminderLeadTimeInMinutes)
        } else {
            // İlk kez açılıyorsa UserPreferences oluştur
            createInitialPreferences()
        }
    }
    
    private func createInitialPreferences() {
        let newPreferences = UserPreferences(reminderLeadTimeInMinutes: 15)
        modelContext.insert(newPreferences)
        
        do {
            try modelContext.save()
            reminderTime = 15
        } catch {
            print("UserPreferences oluşturulurken hata: \(error)")
        }
    }
    
    private func saveReminderTime(minutes: Int) {
        guard let preferences = currentPreferences else {
            createInitialPreferences()
            return
        }
        
        preferences.reminderLeadTimeInMinutes = minutes
        
        do {
            try modelContext.save()
            print("✅ Hatırlatma süresi güncellendi: \(minutes) dakika")
        } catch {
            print("❌ Hatırlatma süresi kaydedilemedi: \(error)")
        }
    }
    
    private func testNotificationImmediately() {
        let testTitle = L("notifications.test.immediate.content.title", table: "Profile")
        let testBody = L("notifications.test.immediate.content.body", table: "Profile")
        
        LocalNotificationService.shared.scheduleTestNotification(
            title: testTitle,
            body: testBody,
            delay: 1 // 1 saniye sonra
        )
        
        showTestAlert = true
    }
    
    private func test5SecondNotification() {
        let testTitle = L("notifications.test.delayed.content.title", table: "Profile")
        let testBody = L("notifications.test.delayed.content.body", table: "Profile")
        
        LocalNotificationService.shared.scheduleTestNotification(
            title: testTitle,
            body: testBody,
            delay: 5 // 5 saniye sonra
        )
        
        testNotificationScheduled = true
        
        // 6 saniye sonra test durumunu sıfırla
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            testNotificationScheduled = false
        }
    }
    
    private func formatTime(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) " + (minutes == 1 ? L("notifications.minute", table: "Profile") : L("notifications.minutes", table: "Profile"))
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            
            if remainingMinutes == 0 {
                return "\(hours) " + (hours == 1 ? L("notifications.hour", table: "Profile") : L("notifications.hours", table: "Profile"))
            } else {
                return "\(hours) " + (hours == 1 ? L("notifications.hour", table: "Profile") : L("notifications.hours", table: "Profile")) + " \(remainingMinutes) " + (remainingMinutes == 1 ? L("notifications.minute", table: "Profile") : L("notifications.minutes", table: "Profile"))
            }
        }
    }
    
    /// Aktif uyku programı için bildirimleri planlar
    private func updateNotificationsForActiveSchedule() {
        ScheduleManager.shared.updateNotificationsForActiveSchedule()
    }
    
    private func checkNotificationPermission() {
        LocalNotificationService.shared.getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    notificationPermissionStatus = L("notifications.permission.granted", table: "Profile")
                case .denied:
                    notificationPermissionStatus = L("notifications.permission.denied", table: "Profile")
                case .notDetermined:
                    notificationPermissionStatus = L("notifications.permission.notDetermined", table: "Profile")
                case .provisional:
                    notificationPermissionStatus = L("notifications.permission.provisional", table: "Profile")
                case .ephemeral:
                    notificationPermissionStatus = L("notifications.permission.ephemeral", table: "Profile")
                @unknown default:
                    notificationPermissionStatus = L("notifications.permission.unknown", table: "Profile")
                }
            }
        }
    }
}

// MARK: - Modern Components

// Modern notification card component with enhanced styling
struct ModernNotificationCard<Content: View>: View {
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCardBackground)
                    .overlay(
                        // Subtle border for light mode
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(colorScheme == .light ? 0.15 : 0),
                                        Color.gray.opacity(colorScheme == .light ? 0.05 : 0)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: colorScheme == .light ? 
                        Color.black.opacity(0.08) : 
                        Color.black.opacity(0.3),
                        radius: colorScheme == .light ? 12 : 16,
                        x: 0,
                        y: colorScheme == .light ? 6 : 8
                    )
            )
    }
}

// Modern quick time button with enhanced styling
struct ModernQuickTimeButton: View {
    let time: Int
    @Binding var currentTime: Double
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentTime = Double(time)
            }
        }) {
            Text("\(time)dk")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(currentTime == Double(time) ? .white : .appAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(currentTime == Double(time) ? Color.appAccent : Color.appAccent.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(currentTime == Double(time) ? Color.clear : Color.appAccent.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(ModernQuickButtonStyle())
    }
}

// Modern slider with enhanced styling
struct ModernSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let trackColor: Color
    let thumbColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Slider(value: $value, in: range, step: step)
                .accentColor(thumbColor)
                .background(
                    // Custom track
                    RoundedRectangle(cornerRadius: 8)
                        .frame(height: 6)
                        .foregroundColor(trackColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .frame(height: 6)
                                .foregroundColor(thumbColor)
                                .scaleEffect(x: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)), y: 1, anchor: .leading)
                        )
                        .allowsHitTesting(false)
                )
        }
    }
}

// Modern test button with enhanced styling
struct ModernNotificationTestButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.appText)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(color.opacity(0.7))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
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
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ModernTestButtonStyle())
    }
}

// Modern status row with enhanced styling
struct ModernStatusRow: View {
    let icon: String
    let title: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appPrimary)
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.appText)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(valueColor.opacity(0.1))
                )
        }
    }
}

// Modern status divider
struct ModernStatusDivider: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.appTextSecondary.opacity(colorScheme == .light ? 0.15 : 0.08),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.horizontal, 8)
    }
}

// MARK: - Button Styles

struct ModernQuickButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct ModernTestButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NotificationSettingsView()
                .modelContainer(for: [UserPreferences.self])
        }
    }
}
