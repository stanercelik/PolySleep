import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage("coreNotificationTime") private var coreNotificationTime: Double = 30 // Dakika
    @AppStorage("napNotificationTime") private var napNotificationTime: Double = 15 // Dakika
    @AppStorage("showRatingNotification") private var showRatingNotification = true
    
    var body: some View {
        List {
            // Ana Uyku Bildirimleri
            Section(header: Text("notifications.core.title", tableName: "Profile")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("notifications.core.description", tableName: "Profile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if coreNotificationTime > 0 {
                        Text("notifications.time.before \(formatTime(minutes: Int(coreNotificationTime)))", tableName: "Profile")
                            .font(.headline)
                    } else {
                        Text("notifications.disabled", tableName: "Profile")
                            .font(.headline)
                    }
                    
                    Slider(
                        value: $coreNotificationTime,
                        in: 0...120,
                        step: 1
                    )
                    
                    HStack {
                        Text("notifications.off", tableName: "Profile")
                            .font(.caption)
                        Spacer()
                        Text("2 \(Text("notifications.hours", tableName: "Profile"))")
                            .font(.caption)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Şekerleme Bildirimleri
            Section(header: Text("notifications.nap.title", tableName: "Profile")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("notifications.nap.description", tableName: "Profile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if napNotificationTime > 0 {
                        Text("notifications.time.before \(formatTime(minutes: Int(napNotificationTime)))", tableName: "Profile")
                            .font(.headline)
                    } else {
                        Text("notifications.disabled", tableName: "Profile")
                            .font(.headline)
                    }
                    
                    Slider(
                        value: $napNotificationTime,
                        in: 0...120,
                        step: 1
                    )
                    
                    HStack {
                        Text("notifications.off", tableName: "Profile")
                            .font(.caption)
                        Spacer()
                        Text("2 \(Text("notifications.hours", tableName: "Profile"))")
                            .font(.caption)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Oylama Bildirimleri
            Section(header: Text("notifications.rating.title", tableName: "Profile")) {
                Toggle(isOn: $showRatingNotification) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("notifications.rating.label", tableName: "Profile")
                        Text("notifications.rating.description", tableName: "Profile")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("settings.notifications.settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatTime(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) \(minutes == 1 ? NSLocalizedString("notifications.minute", tableName: "Profile", comment: "") : NSLocalizedString("notifications.minutes", tableName: "Profile", comment: ""))"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            
            if remainingMinutes == 0 {
                return "\(hours) \(hours == 1 ? NSLocalizedString("notifications.hour", tableName: "Profile", comment: "") : NSLocalizedString("notifications.hours", tableName: "Profile", comment: ""))"
            } else {
                return "\(hours) \(hours == 1 ? NSLocalizedString("notifications.hour", tableName: "Profile", comment: "") : NSLocalizedString("notifications.hours", tableName: "Profile", comment: "")) \(remainingMinutes) \(remainingMinutes == 1 ? NSLocalizedString("notifications.minute", tableName: "Profile", comment: "") : NSLocalizedString("notifications.minutes", tableName: "Profile", comment: ""))"
            }
        }
    }
}

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NotificationSettingsView()
        }
    }
}
