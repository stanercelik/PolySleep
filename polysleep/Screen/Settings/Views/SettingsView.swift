import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("userSelectedTheme") private var userSelectedTheme: Bool?
    @AppStorage("coreNotificationTime") private var coreNotificationTime: Double = 30 // Dakika
    @AppStorage("napNotificationTime") private var napNotificationTime: Double = 15 // Dakika
    @AppStorage("showRatingNotification") private var showRatingNotification = true
    @EnvironmentObject private var languageManager: LanguageManager
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
                        
                        Text(L("settings.title", table: "Profile"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.appText)
                        
                        Text(L("settings.subtitle", table: "Profile"))
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
                        title: L("settings.about.title", table: "Profile"),
                        icon: "person.2.fill",
                        iconColor: .appAccent
                    ) {
                        VStack(spacing: 12) {
                            SettingsNavigationRow(
                                icon: "person.circle.fill",
                                title: L("settings.about.personalInfo", table: "Profile"),
                                subtitle: L("settings.about.personalInfo.subtitle", table: "Profile"),
                                destination: PersonalInfoView()
                            )
                        }
                    }
                    
                    // Notifications Section
                    SettingsSection(
                        title: L("settings.notifications.title", table: "Profile"),
                        icon: "bell.fill",
                        iconColor: .appSecondary
                    ) {
                        VStack(spacing: 12) {
                            SettingsNavigationRow(
                                icon: "bell.badge.fill",
                                title: L("settings.notifications.settings", table: "Profile"),
                                subtitle: L("settings.notifications.subtitle", table: "Profile"),
                                destination: NotificationSettingsView()
                            )
                        }
                    }
                    
                    // General Settings Section
                    SettingsSection(
                        title: L("settings.general.title", table: "Profile"),
                        icon: "gearshape.fill",
                        iconColor: .gray
                    ) {
                        VStack(spacing: 12) {
                            // Theme Setting
                            SettingsActionRow(
                                icon: "moon.circle.fill",
                                title: L("settings.general.theme", table: "Profile"),
                                subtitle: L("settings.general.selectTheme", table: "Profile"),
                                value: getThemeDisplayText(),
                                action: { showThemePicker = true }
                            )
                            
                            Divider()
                                .background(Color.appSecondaryText.opacity(0.2))
                            
                            // Language Setting
                            SettingsActionRow(
                                icon: "globe.americas.fill",
                                title: L("settings.general.language", table: "Profile"),
                                subtitle: L("settings.general.selectLanguage", table: "Profile"),
                                value: getLanguageDisplayText(),
                                action: { showLanguagePicker = true }
                            )
                        }
                    }
                    
                    // Support & More Section
                    SettingsSection(
                        title: L("settings.other.title", table: "Profile"),
                        icon: "heart.fill",
                        iconColor: .red
                    ) {
                        VStack(spacing: 12) {
                            SettingsNavigationRow(
                                icon: "bell.fill",
                                title: L("settings.notifications.settings", table: "Profile"),
                                destination: NotificationSettingsView()
                            )
                            
                            Divider()
                                .background(Color.appSecondaryText.opacity(0.2))
                            
                            SettingsNavigationRow(
                                icon: "info.circle.fill",
                                title: L("settings.other.disclaimer", table: "Profile"),
                                destination: DisclaimerView()
                            )
                            
                            Divider()
                                .background(Color.appSecondaryText.opacity(0.2))
                            
                            SettingsExternalLinkRow(
                                icon: "envelope.fill",
                                title: L("settings.other.feedback", table: "Profile"),
                                url: "mailto:support@polysleep.app"
                            )
                            
                            Divider()
                                .background(Color.appSecondaryText.opacity(0.2))
                            
                            SettingsExternalLinkRow(
                                icon: "star.fill",
                                title: L("settings.other.rateApp", table: "Profile"),
                                url: "https://apps.apple.com/app/polysleep/id123456789"
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
        .navigationTitle(L("settings.title", table: "Profile"))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(L("settings.general.selectTheme", table: "Profile"), isPresented: $showThemePicker, titleVisibility: .visible) {
            Button(L("settings.general.theme.system", table: "Profile")) {
                userSelectedTheme = nil
            }
            Button(L("settings.general.theme.light", table: "Profile")) {
                userSelectedTheme = false
            }
            Button(L("settings.general.theme.dark", table: "Profile")) {
                userSelectedTheme = true
            }
            Button(L("general.cancel", table: "MainScreen"), role: .cancel) { }
        }
        .confirmationDialog(L("settings.general.selectLanguage", table: "Profile"), isPresented: $showLanguagePicker, titleVisibility: .visible) {
            Button(L("settings.language.turkish", table: "Profile")) {
                languageManager.changeLanguage(to: "tr")
            }
            Button(L("settings.language.english", table: "Profile")) {
                languageManager.changeLanguage(to: "en")
            }
            Button(L("general.cancel", table: "MainScreen"), role: .cancel) { }
        }
        .environment(\.locale, Locale(identifier: languageManager.currentLanguage))
    }
    
    /// Seçili temanın görüntülenen metnini döndürür
    private func getThemeDisplayText() -> String {
        if let userChoice = userSelectedTheme {
            return userChoice ? L("settings.general.theme.dark", table: "Profile") : L("settings.general.theme.light", table: "Profile")
        } else {
            return L("settings.general.theme.system", table: "Profile")
        }
    }
    
    /// Seçili dilin görüntülenen metnini döndürür
    private func getLanguageDisplayText() -> String {
        return languageManager.currentLanguage == "tr" ? L("settings.language.turkish", table: "Profile") : L("settings.language.english", table: "Profile")
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
    let subtitle: String?
    let destination: Destination
    
    init(icon: String, title: String, subtitle: String? = nil, destination: Destination) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.destination = destination
    }
    
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
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.appSecondaryText)
                    }
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

struct SettingsExternalLinkRow: View {
    let icon: String
    let title: String
    let url: String
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
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
                    
                    Text(url)
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
        .environmentObject(LanguageManager.shared)
    }
}
