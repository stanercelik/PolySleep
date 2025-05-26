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
                                            Color.appPrimary.opacity(0.8),
                                            Color.appAccent.opacity(0.6)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                                .shadow(
                                    color: Color.appPrimary.opacity(0.3),
                                    radius: 12,
                                    x: 0,
                                    y: 6
                                )
                            
                            Image(systemName: "gearshape.2.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text(L("settings.title", table: "Profile"))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.appText)
                            
                            Text(L("settings.subtitle", table: "Profile"))
                                .font(.subheadline)
                                .foregroundColor(.appSecondaryText)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 24)
                    
                    // Profile & Account Section
                    ModernSettingsSection(
                        title: L("settings.about.title", table: "Profile"),
                        icon: "person.2.fill",
                        iconColor: .appAccent,
                        isMinimal: true
                    ) {
                        VStack(spacing: 12) {
                            ModernNavigationRow(
                                icon: "person.circle.fill",
                                title: L("settings.about.personalInfo", table: "Profile"),
                                subtitle: L("settings.about.personalInfo.subtitle", table: "Profile"),
                                destination: PersonalInfoView()
                            )
                        }
                    }
                    
                    // Notifications Section
                    ModernSettingsSection(
                        title: L("settings.notifications.title", table: "Profile"),
                        icon: "bell.fill",
                        iconColor: .appSecondary,
                        isMinimal: true
                    ) {
                        VStack(spacing: 12) {
                            ModernNavigationRow(
                                icon: "bell.badge.fill",
                                title: L("settings.notifications.settings", table: "Profile"),
                                subtitle: L("settings.notifications.subtitle", table: "Profile"),
                                destination: NotificationSettingsView()
                            )
                            
                            ModernDivider()
                            
                            ModernNavigationRow(
                                icon: "alarm.fill",
                                title: "Alarm Ayarları",
                                subtitle: "Uyku bloğu bitiminde çalacak alarm ayarları",
                                destination: AlarmSettingsView()
                            )
                        }
                    }
                    
                    // General Settings Section
                    ModernSettingsSection(
                        title: L("settings.general.title", table: "Profile"),
                        icon: "gearshape.fill",
                        iconColor: .blue,
                        isMinimal: true
                    ) {
                        VStack(spacing: 12) {
                            // Theme Setting
                            ModernActionRow(
                                icon: "moon.circle.fill",
                                title: L("settings.general.theme", table: "Profile"),
                                subtitle: L("settings.general.selectTheme", table: "Profile"),
                                value: getThemeDisplayText(),
                                action: { showThemePicker = true }
                            )
                            
                            ModernDivider()
                            
                            // Language Setting
                            ModernActionRow(
                                icon: "globe.americas.fill",
                                title: L("settings.general.language", table: "Profile"),
                                subtitle: L("settings.general.selectLanguage", table: "Profile"),
                                value: getLanguageDisplayText(),
                                action: { showLanguagePicker = true }
                            )
                        }
                    }
                    
                    // Support & More Section
                    ModernSettingsSection(
                        title: L("settings.other.title", table: "Profile"),
                        icon: "heart.fill",
                        iconColor: .red,
                        isMinimal: true
                    ) {
                        VStack(spacing: 12) {
                            ModernNavigationRow(
                                icon: "info.circle.fill",
                                title: L("settings.other.disclaimer", table: "Profile"),
                                subtitle: L("settings.other.disclaimer.subtitle", table: "Profile"),
                                destination: DisclaimerView()
                            )
                            
                            ModernDivider()
                            
                            ModernExternalLinkRow(
                                icon: "envelope.fill",
                                title: L("settings.other.feedback", table: "Profile"),
                                url: "mailto:support@polysleep.app"
                            )
                            
                            ModernDivider()
                            
                            ModernExternalLinkRow(
                                icon: "star.fill",
                                title: L("settings.other.rateApp", table: "Profile"),
                                url: "https://apps.apple.com/app/polysleep/id123456789"
                            )
                        }
                    }
                    
                    // Enhanced Version Info
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image("AppIcon")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .cornerRadius(8)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            VStack(spacing: 2) {
                                Text("PolySleep")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.appText)
                                
                                Text("v1.0.0")
                                    .font(.caption)
                                    .foregroundColor(.appSecondaryText)
                            }
                        }
                        
                        Text(L("settings.copyright", table: "Profile"))
                            .font(.caption2)
                            .foregroundColor(.appSecondaryText.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
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

// MARK: - Modern Components

// Modern settings section with enhanced styling
struct ModernSettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let isMinimal: Bool
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // Section Header - conditional based on isMinimal
            if !isMinimal {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(iconColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.appText)
                        
                        Text(L("settings.section.subtitle", table: "Profile"))
                            .font(.caption)
                            .foregroundColor(.appSecondaryText)
                    }
                    
                    Spacer()
                }
            } else {
                // Minimal header - just title with small icon
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(iconColor)
                    
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appText)
                    
                    Spacer()
                }
                .padding(.bottom, 8)
            }
            
            content
        }
        .padding(isMinimal ? 16 : 20)
        .background(
            RoundedRectangle(cornerRadius: isMinimal ? 12 : 16)
                .fill(Color.appCardBackground)
                .overlay(
                    // Subtle border for light mode
                    RoundedRectangle(cornerRadius: isMinimal ? 12 : 16)
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
                    Color.black.opacity(isMinimal ? 0.04 : 0.08) : 
                    Color.black.opacity(isMinimal ? 0.2 : 0.3),
                    radius: colorScheme == .light ? (isMinimal ? 8 : 12) : (isMinimal ? 12 : 16),
                    x: 0,
                    y: colorScheme == .light ? (isMinimal ? 3 : 6) : (isMinimal ? 4 : 8)
                )
        )
    }
}

// Modern navigation row with enhanced styling
struct ModernNavigationRow<Destination: View>: View {
    let icon: String
    let title: String
    let subtitle: String?
    let destination: Destination
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    init(icon: String, title: String, subtitle: String? = nil, destination: Destination) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.destination = destination
    }
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.appText)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.appSecondaryText)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Chevron icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.appSecondaryText.opacity(0.6))
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(ModernNavigationButtonStyle())
    }
}

// Modern action row for buttons with enhanced styling
struct ModernActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let value: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.appText)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.appSecondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Value badge
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.appSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.appSecondary.opacity(0.15))
                    )
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(ModernActionButtonStyle())
    }
}

// Modern external link row with enhanced styling
struct ModernExternalLinkRow: View {
    let icon: String
    let title: String
    let url: String
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 16) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.appText)
                    
                    Text(url.replacingOccurrences(of: "mailto:", with: "").replacingOccurrences(of: "https://", with: ""))
                        .font(.caption)
                        .foregroundColor(.appSecondaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // External link icon
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.appPrimary.opacity(0.6))
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(ModernActionButtonStyle())
    }
}

// Modern divider
struct ModernDivider: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.appSecondaryText.opacity(colorScheme == .light ? 0.2 : 0.1),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.horizontal, 16)
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
