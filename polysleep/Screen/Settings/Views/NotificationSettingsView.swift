import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userPreferences: [UserPreferences]
    @State private var reminderTime: Double = 15
    @State private var hasScheduleChanged = false
    @State private var showTestAlert = false
    @State private var testNotificationScheduled = false
    
    var currentPreferences: UserPreferences? {
        userPreferences.first
    }
    
    var body: some View {
        List {
            // Bildirim Zamanı Ayarı
            Section(header: Text("Hatırlatma Zamanı")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Uyku zamanından ne kadar önce hatırlatılmak istiyorsun?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if reminderTime > 0 {
                        Text("\(formatTime(minutes: Int(reminderTime)))")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    } else {
                        Text("Bildirimler Kapalı")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: $reminderTime,
                        in: 0...120,
                        step: 1
                    )
                    .onChange(of: reminderTime) { oldValue, newValue in
                        saveReminderTime(minutes: Int(newValue))
                        hasScheduleChanged = true
                    }
                    
                    HStack {
                        Text("Kapalı")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("2 Saat")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Test Bölümü
            Section(header: Text("Test")) {
                VStack(spacing: 12) {
                    Button(action: {
                        testNotificationImmediately()
                    }) {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.accentColor)
                            Text("Test Bildirimi Gönder")
                            Spacer()
                            Image(systemName: "arrow.right.circle")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        test5SecondNotification()
                    }) {
                        HStack {
                            Image(systemName: "clock.badge")
                                .foregroundColor(.blue)
                            Text("5 Saniye Sonra Test")
                            Spacer()
                            Image(systemName: "arrow.right.circle")
                                .foregroundColor(.blue)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if testNotificationScheduled {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Test bildirimi planlandı!")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Bildirim Durumu
            Section(header: Text("Durum")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.accentColor)
                        Text("Bildirim İzni")
                        Spacer()
                        Text("Verildi")
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Image(systemName: "moon")
                            .foregroundColor(.accentColor)
                        Text("Aktif Program")
                        Spacer()
                        if let activeSchedule = ScheduleManager.shared.activeSchedule {
                            Text(activeSchedule.name)
                                .foregroundColor(.green)
                        } else {
                            Text("Yok")
                                .foregroundColor(.orange)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.accentColor)
                        Text("Hatırlatma Süresi")
                        Spacer()
                        Text("\(Int(reminderTime)) dk")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Bildirim Ayarları")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentSettings()
        }
        .onChange(of: hasScheduleChanged) { oldValue, newValue in
            if newValue {
                updateNotificationsForActiveSchedule()
                hasScheduleChanged = false
            }
        }
        .alert("Test Bildirimi", isPresented: $showTestAlert) {
            Button("Tamam") { }
        } message: {
            Text("Test bildirimi gönderildi! Bildirimler kapalıysa ayarlardan açmayı unutma.")
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
        let testTitle = "🧪 PolySleep Test"
        let testBody = "Bu bir test bildirimi! Bildirimler düzgün çalışıyor ✅"
        
        LocalNotificationService.shared.scheduleTestNotification(
            title: testTitle,
            body: testBody,
            delay: 1 // 1 saniye sonra
        )
        
        showTestAlert = true
    }
    
    private func test5SecondNotification() {
        let testTitle = "⏰ 5 Saniye Test"
        let testBody = "Bu bildirim 5 saniye önce planlandı!"
        
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
            return "\(minutes) \(minutes == 1 ? "dakika" : "dakika")"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            
            if remainingMinutes == 0 {
                return "\(hours) \(hours == 1 ? "saat" : "saat")"
            } else {
                return "\(hours) \(hours == 1 ? "saat" : "saat") \(remainingMinutes) \(remainingMinutes == 1 ? "dakika" : "dakika")"
            }
        }
    }
    
    /// Aktif uyku programı için bildirimleri planlar
    private func updateNotificationsForActiveSchedule() {
        ScheduleManager.shared.updateNotificationsForActiveSchedule()
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
