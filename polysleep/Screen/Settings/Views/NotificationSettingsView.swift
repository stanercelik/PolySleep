import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
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
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header Card
                    VStack(spacing: 16) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.appAccent)
                            .padding(.top, 8)
                        
                        Text(L("notifications.management.title", table: "Profile"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.appText)
                        
                        Text(L("notifications.management.subtitle", table: "Profile"))
                            .font(.subheadline)
                            .foregroundColor(.appSecondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.appCardBackground)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    
                    // Reminder Time Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "clock.arrow.2.circlepath")
                                .font(.title2)
                                .foregroundColor(.appPrimary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L("notifications.reminderTime.title", table: "Profile"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.appText)
                                
                                Text(L("notifications.reminderTime.subtitle", table: "Profile"))
                                    .font(.caption)
                                    .foregroundColor(.appSecondaryText)
                            }
                            
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                if reminderTime > 0 {
                                    Text("\(formatTime(minutes: Int(reminderTime)))")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.appAccent)
                                } else {
                                    Text(L("notifications.off", table: "Profile"))
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.appSecondaryText)
                                }
                                
                                Spacer()
                                
                                // Quick Actions
                                HStack(spacing: 8) {
                                    QuickTimeButton(time: 5, currentTime: $reminderTime)
                                    QuickTimeButton(time: 15, currentTime: $reminderTime)
                                    QuickTimeButton(time: 30, currentTime: $reminderTime)
                                }
                            }
                            
                            CustomSlider(
                                value: $reminderTime,
                                range: 0...120,
                                step: 1,
                                trackColor: Color.appSecondaryText.opacity(0.2),
                                thumbColor: Color.appAccent
                            )
                            .onChange(of: reminderTime) { oldValue, newValue in
                                saveReminderTime(minutes: Int(newValue))
                                hasScheduleChanged = true
                            }
                            
                            HStack {
                                Text(L("notifications.off", table: "Profile"))
                                    .font(.caption2)
                                    .foregroundColor(.appSecondaryText)
                                Spacer()
                                Text(L("notifications.twoHours", table: "Profile"))
                                    .font(.caption2)
                                    .foregroundColor(.appSecondaryText)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appCardBackground)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
                    
                    // Test Section Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "testtube.2")
                                .font(.title2)
                                .foregroundColor(.appSecondary)
                            
                            Text(L("notifications.test.title", table: "Profile"))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.appText)
                        }
                        
                        VStack(spacing: 12) {
                            NotificationTestButton(
                                icon: "bell.badge.fill",
                                title: L("notifications.test.immediate.title", table: "Profile"),
                                subtitle: L("notifications.test.immediate.subtitle", table: "Profile"),
                                color: .appAccent
                            ) {
                                testNotificationImmediately()
                            }
                            
                            NotificationTestButton(
                                icon: "timer",
                                title: L("notifications.test.delayed.title", table: "Profile"),
                                subtitle: L("notifications.test.delayed.subtitle", table: "Profile"),
                                color: .appSecondary
                            ) {
                                test5SecondNotification()
                            }
                            
                            if testNotificationScheduled {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(L("notifications.test.scheduled", table: "Profile"))
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .transition(.opacity.combined(with: .scale))
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appCardBackground)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
                    
                    // Status Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.title2)
                                .foregroundColor(.appPrimary)
                            
                            Text(L("notifications.status.title", table: "Profile"))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.appText)
                        }
                        
                        VStack(spacing: 12) {
                            StatusRow(
                                icon: "bell.circle.fill",
                                title: L("notifications.permission.title", table: "Profile"),
                                value: notificationPermissionStatus,
                                valueColor: notificationPermissionStatus == L("notifications.permission.granted", table: "Profile") ? .green : .orange
                            )
                            
                            Divider()
                                .background(Color.appSecondaryText.opacity(0.2))
                            
                            StatusRow(
                                icon: "moon.circle.fill",
                                title: L("notifications.status.activeProgram", table: "Profile"),
                                value: ScheduleManager.shared.activeSchedule?.name ?? L("notifications.status.noProgram", table: "Profile"),
                                valueColor: ScheduleManager.shared.activeSchedule != nil ? .green : .orange
                            )
                            
                            Divider()
                                .background(Color.appSecondaryText.opacity(0.2))
                            
                            StatusRow(
                                icon: "timer.circle.fill",
                                title: L("notifications.status.reminderTime", table: "Profile"),
                                value: "\(Int(reminderTime)) " + L("notifications.minutes", table: "Profile"),
                                valueColor: .appPrimary
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appCardBackground)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
                }
                .padding()
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

// MARK: - Custom Components

struct QuickTimeButton: View {
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
                .foregroundColor(currentTime == Double(time) ? .white : .appSecondaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(currentTime == Double(time) ? Color.appAccent : Color.appSecondaryText.opacity(0.1))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let trackColor: Color
    let thumbColor: Color
    
    var body: some View {
        Slider(value: $value, in: range, step: step)
            .accentColor(thumbColor)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .frame(height: 4)
                    .foregroundColor(trackColor)
                    .allowsHitTesting(false)
            )
    }
}

struct NotificationTestButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.appText)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.appSecondaryText)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(color.opacity(0.7))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
}

struct StatusRow: View {
    let icon: String
    let title: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.appPrimary)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.appText)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
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
