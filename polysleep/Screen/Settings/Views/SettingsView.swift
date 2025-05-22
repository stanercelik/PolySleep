import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("userSelectedTheme") private var userSelectedTheme: Bool?
    @AppStorage("appLanguage") private var appLanguage = "tr"
    @AppStorage("coreNotificationTime") private var coreNotificationTime: Double = 30 // Dakika
    @AppStorage("napNotificationTime") private var napNotificationTime: Double = 15 // Dakika
    @AppStorage("showRatingNotification") private var showRatingNotification = true
    @State private var showLanguagePicker = false
    @State private var showThemePicker = false
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header Card
                    VStack(spacing: 16) {
                        Image(systemName: "gearshape.2.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.appPrimary)
                            .padding(.top, 8)
                        
                        Text("Ayarlar")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.appText)
                        
                        Text("Uygulama deneyiminizi kişiselleştirin")
                            .font(.subheadline)
                            .foregroundColor(.appSecondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.appCardBackground)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    
                    // Profile & Account Section
                    SettingsSection(
                        title: "Hesap & Profil",
                        icon: "person.2.fill",
                        iconColor: .appAccent
                    ) {
                        VStack(spacing: 12) {
                            SettingsNavigationRow(
                                icon: "person.circle.fill",
                                title: "Kişisel Bilgiler",
                                subtitle: "Profil bilgilerinizi düzenleyin",
                                destination: PersonalInfoView()
                            )
                        }
                    }
                    
                    // Notifications Section
                    SettingsSection(
                        title: "Bildirimler",
                        icon: "bell.fill",
                        iconColor: .appSecondary
                    ) {
                        VStack(spacing: 12) {
                            SettingsNavigationRow(
                                icon: "bell.badge.fill",
                                title: "Bildirim Ayarları",
                                subtitle: "Hatırlatma zamanlarını özelleştirin",
                                destination: NotificationSettingsView()
                            )
                        }
                    }
                    
                    // General Settings Section
                    SettingsSection(
                        title: "Genel Ayarlar",
                        icon: "slider.horizontal.3",
                        iconColor: .appPrimary
                    ) {
                        VStack(spacing: 12) {
                            // Theme Setting
                            SettingsActionRow(
                                icon: "moon.circle.fill",
                                title: "Tema",
                                subtitle: "Görünümü değiştir",
                                value: getThemeDisplayText(),
                                action: { showThemePicker = true }
                            )
                            
                            Divider()
                                .background(Color.appSecondaryText.opacity(0.2))
                            
                            // Language Setting
                            SettingsActionRow(
                                icon: "globe.americas.fill",
                                title: "Dil",
                                subtitle: "Uygulama dilini seçin",
                                value: appLanguage == "tr" ? "Türkçe" : "English",
                                action: { showLanguagePicker = true }
                            )
                        }
                    }
                    
                    // Support & More Section
                    SettingsSection(
                        title: "Destek & Daha Fazlası",
                        icon: "heart.fill",
                        iconColor: .red
                    ) {
                        VStack(spacing: 12) {
                            SettingsExternalRow(
                                icon: "star.circle.fill",
                                title: "Uygulamayı Değerlendir",
                                subtitle: "App Store'da değerlendirin",
                                action: {
                                    if let url = URL(string: "https://apps.apple.com/app/id0000000000") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                            
                            Divider()
                                .background(Color.appSecondaryText.opacity(0.2))
                            
                            SettingsNavigationRow(
                                icon: "exclamationmark.shield.fill",
                                title: "Sorumluluk Reddi",
                                subtitle: "Yasal bilgiler",
                                destination: DisclaimerView()
                            )
                            
                            Divider()
                                .background(Color.appSecondaryText.opacity(0.2))
                            
                            SettingsExternalRow(
                                icon: "envelope.circle.fill",
                                title: "Geri Bildirim",
                                subtitle: "Öneri ve şikayetleriniz için",
                                action: {
                                    if let url = URL(string: "mailto:feedback@polysleep.app") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                        }
                    }
                    
                    // Version Info
                    VStack(spacing: 8) {
                        Text("PolySleep")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.appSecondaryText)
                        
                        Text("v1.0.0")
                            .font(.caption2)
                            .foregroundColor(.appSecondaryText.opacity(0.7))
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
                .padding()
            }
        }
        .navigationTitle("Ayarlar")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Tema Seçin", isPresented: $showThemePicker, titleVisibility: .visible) {
            Button("Sistem Varsayılanı") {
                userSelectedTheme = nil
            }
            Button("Açık Tema") {
                userSelectedTheme = false
            }
            Button("Koyu Tema") {
                userSelectedTheme = true
            }
            Button("İptal", role: .cancel) { }
        }
        .confirmationDialog("Dil Seçin", isPresented: $showLanguagePicker, titleVisibility: .visible) {
            Button("Türkçe") {
                appLanguage = "tr"
            }
            Button("English") {
                appLanguage = "en"
            }
            Button("İptal", role: .cancel) { }
        }
        .environment(\.locale, Locale(identifier: appLanguage))
    }
    
    /// Seçili temanın görüntülenen metnini döndürür
    private func getThemeDisplayText() -> String {
        if let userChoice = userSelectedTheme {
            return userChoice ? "Koyu Tema" : "Açık Tema"
        } else {
            return "Sistem Varsayılanı"
        }
    }
}

// MARK: - Custom Components

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
            }
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct SettingsNavigationRow<Destination: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.appPrimary)
                    .frame(width: 28)
                
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
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.appSecondaryText.opacity(0.6))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.appPrimary)
                    .frame(width: 28)
                
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
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.appSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.appSecondary.opacity(0.15))
                    )
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsExternalRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.appPrimary)
                    .frame(width: 28)
                
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
                
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(.appSecondaryText.opacity(0.6))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
        }
    }
}
