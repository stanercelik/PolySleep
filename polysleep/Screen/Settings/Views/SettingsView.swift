import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("appLanguage") private var appLanguage = "tr"
    @AppStorage("coreNotificationTime") private var coreNotificationTime: Double = 30 // Dakika
    @AppStorage("napNotificationTime") private var napNotificationTime: Double = 15 // Dakika
    @AppStorage("showRatingNotification") private var showRatingNotification = true
    @State private var showLanguagePicker = false
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            List {
                // MARK: - Hakkımda Bölümü
                Section(header: Text("settings.about.title", tableName: "Profile")) {
                    NavigationLink(destination: PersonalInfoView()) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.appPrimary)
                                .frame(width: 24)
                            Text("settings.about.personalInfo", tableName: "Profile")
                        }
                    }
                }
                
                // MARK: - Hatırlatmalar Bölümü
                Section(header: Text("settings.notifications.title", tableName: "Profile")) {
                    NavigationLink(destination: NotificationSettingsView()) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.appPrimary)
                                .frame(width: 24)
                            Text("settings.notifications.settings", tableName: "Profile")
                        }
                    }
                }
                
                // MARK: - Genel Ayarlar Bölümü
                Section(header: Text("settings.general.title", tableName: "Profile")) {
                    // Koyu Mod Ayarı
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.appPrimary)
                            .frame(width: 24)
                        Text("settings.general.darkMode", tableName: "Profile")
                        Spacer()
                        Toggle("", isOn: $isDarkMode)
                            .labelsHidden()
                    }
                    
                    // Dil Ayarı
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.appPrimary)
                            .frame(width: 24)
                        Text("settings.general.language", tableName: "Profile")
                        Spacer()
                        Button(action: {
                            showLanguagePicker = true
                        }) {
                            Text(appLanguage == "tr" ? "Türkçe" : "English")
                                .foregroundColor(.appSecondary)
                        }
                    }
                    .actionSheet(isPresented: $showLanguagePicker) {
                        ActionSheet(
                            title: Text("settings.general.selectLanguage", tableName: "Profile"),
                            buttons: [
                                .default(Text("Türkçe")) {
                                    appLanguage = "tr"
                                },
                                .default(Text("English")) {
                                    appLanguage = "en"
                                },
                                .cancel()
                            ]
                        )
                    }
                }
                
                // MARK: - Diğer Bölümü
                Section(header: Text("settings.other.title", tableName: "Profile")) {
                    // Bize Oy Ver
                    Button(action: {
                        // App Store'da uygulamaya yönlendir
                        if let url = URL(string: "https://apps.apple.com/app/id0000000000") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.appPrimary)
                                .frame(width: 24)
                            Text("settings.other.rateApp", tableName: "Profile")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    // Sorumluluk Reddi
                    NavigationLink(destination: DisclaimerView()) {
                        HStack {
                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundColor(.appPrimary)
                                .frame(width: 24)
                            Text("settings.other.disclaimer", tableName: "Profile")
                        }
                    }
                    
                    // Geribildirim Ver
                    Button(action: {
                        // Mail gönderme işlemi
                        if let url = URL(string: "mailto:feedback@polysleep.app") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.appPrimary)
                                .frame(width: 24)
                            Text("settings.other.feedback", tableName: "Profile")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .scrollContentBackground(.hidden)
        .navigationTitle("settings.title")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.locale, Locale(identifier: appLanguage))
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
        }
    }
}
