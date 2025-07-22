import SwiftUI
import SwiftData
import RevenueCat
import RevenueCatUI
import HealthKit

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("userSelectedTheme") private var userSelectedTheme: Bool?
    @AppStorage("coreNotificationTime") private var coreNotificationTime: Double = 30 // Dakika
    @AppStorage("napNotificationTime") private var napNotificationTime: Double = 15 // Dakika
    @AppStorage("showRatingNotification") private var showRatingNotification = true
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
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
                            
                            Image(systemName: "gearshape.2.fill")
                                .font(.system(size: PSIconSize.headerIcon / 1.8))
                                .foregroundColor(.appTextOnPrimary)
                        }
                        
                        VStack(spacing: PSSpacing.sm) {
                            Text(L("settings.title", table: "Profile"))
                                .font(PSTypography.title1)
                                .foregroundColor(.appText)
                            
                            Text(L("settings.subtitle", table: "Profile"))
                                .font(PSTypography.body)
                                .foregroundColor(.appTextSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                    .padding(.top, PSSpacing.sm)
                    .padding(.horizontal, PSSpacing.xl)
                    
                    // Profile & Account Section
                    ModernSettingsSection(
                        title: L("settings.about.title", table: "Profile"),
                        icon: "person.2.fill",
                        iconColor: .appAccent,
                        isMinimal: true
                    ) {
                        VStack(spacing: PSSpacing.md) {
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
                        VStack(spacing: PSSpacing.md) {
                            ModernNavigationRow(
                                icon: "bell.badge.fill",
                                title: L("settings.notifications.settings", table: "Profile"),
                                subtitle: L("settings.notifications.subtitle", table: "Profile"),
                                destination: NotificationSettingsView()
                            )
                            
                            ModernDivider()
                            
                            ModernNavigationRow(
                                icon: "alarm.fill",
                                title: L("settings.alarms.title", table: "Profile"),
                                subtitle: L("settings.alarms.subtitle", table: "Profile"),
                                destination: AlarmSettingsView()
                            )
                        }
                    }
                    
                    // Advanced Section
                    ModernSettingsSection(
                        title: L("settings.advanced.title", table: "Profile"),
                        icon: "slider.horizontal.3",
                        iconColor: .orange,
                        isMinimal: true
                    ) {
                        VStack(spacing: PSSpacing.md) {
                            AdaptationUndoRow()
                            
                            ModernDivider()
                            
                            RestartOnboardingRow()
                        }
                    }
                    
                    // Integrations Section
                    ModernSettingsSection(
                        title: L("settings.integrations", table: "Settings"),
                        icon: "link.circle.fill",
                        iconColor: .green,
                        isMinimal: true
                    ) {
                        VStack(spacing: PSSpacing.md) {
                            HealthKitIntegrationRow()
                        }
                    }
                    
                    // General Settings Section
                    ModernSettingsSection(
                        title: L("settings.general.title", table: "Profile"),
                        icon: "gearshape.fill",
                        iconColor: .blue,
                        isMinimal: true
                    ) {
                        VStack(spacing: PSSpacing.md) {
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
                        VStack(spacing: PSSpacing.md) {
                            // Rating Section - sadece daha önce rating vermediyse göster
                            if !hasUserRatedBefore() {
                                ModernActionRow(
                                    icon: "star.fill",
                                    title: L("settings.other.rate", table: "Profile"),
                                    subtitle: L("settings.other.rate.subtitle", table: "Profile"),
                                    value: "",
                                    action: {
                                        RatingManager.shared.requestRating {
                                            // Rating tamamlandı
                                        }
                                    }
                                )
                                
                                ModernDivider()
                            }
                            
                            ModernNavigationRow(
                                icon: "info.circle.fill",
                                title: L("settings.other.disclaimer", table: "Profile"),
                                subtitle: L("settings.other.disclaimer.subtitle", table: "Profile"),
                                destination: DisclaimerView()
                            )
                            
                            ModernDivider()
                            
                            ModernNavigationRow(
                                icon: "envelope.fill",
                                title: L("feedback.title", table: "Profile"),
                                subtitle: L("feedback.settings.subtitle", table: "Profile"),
                                destination: FeedbackView()
                            )
                        }
                    }
                    

                    
                    // Enhanced Version Info
                    VStack(spacing: PSSpacing.md) {
                        HStack(spacing: PSSpacing.sm) {
                            VStack(alignment: .center , spacing: PSSpacing.xs) {
                                Text("PolyNap")
                                    .font(PSTypography.headline)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.appText)
                                
                                Text("v1.2.0")
                                    .font(.caption)
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                        
                        Text(L("settings.copyright", table: "Profile"))
                            .font(.caption2)
                            .foregroundColor(.appTextSecondary.opacity(0.7))
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
            Button(L("general.cancel", table: "Profile"), role: .cancel) { }
        }
        .confirmationDialog(L("settings.general.selectLanguage", table: "Profile"), isPresented: $showLanguagePicker, titleVisibility: .visible) {
            Button(L("settings.language.turkish", table: "Profile")) {
                languageManager.changeLanguage(to: "tr")
            }
            Button(L("settings.language.english", table: "Profile")) {
                languageManager.changeLanguage(to: "en")
            }
            Button(L("settings.language.japanese", table: "Profile")) {
                languageManager.changeLanguage(to: "ja")
            }
            Button(L("settings.language.german", table: "Profile")) {
                languageManager.changeLanguage(to: "de")
            }
            Button(L("settings.language.malay", table: "Profile")) {
                languageManager.changeLanguage(to: "ms")
            }
            Button(L("settings.language.thai", table: "Profile")) {
                languageManager.changeLanguage(to: "th")
            }
            Button(L("general.cancel", table: "Profile"), role: .cancel) { }
        }
        .environment(\.locale, Locale(identifier: languageManager.currentLanguage))
    }
    
    /// Kullanıcının daha önce rating verip vermediğini kontrol eder
    private func hasUserRatedBefore() -> Bool {
        return UserDefaults.standard.bool(forKey: "has_requested_review")
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
        switch languageManager.currentLanguage {
        case "tr":
            return L("settings.language.turkish", table: "Profile")
        case "ja":
            return L("settings.language.japanese", table: "Profile")
        case "de":
            return L("settings.language.german", table: "Profile")
        default:
            return L("settings.language.english", table: "Profile")
        }
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
                            .foregroundColor(.appTextSecondary)
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
                            .foregroundColor(.appTextSecondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Chevron icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.appTextSecondary.opacity(0.6))
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
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Value badge - sadece value boş değilse göster
                if !value.isEmpty {
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
                } else {
                    // Boş value için chevron icon göster
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appTextSecondary.opacity(0.6))
                }
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
                        .foregroundColor(.appTextSecondary)
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
                        Color.appTextSecondary.opacity(colorScheme == .light ? 0.2 : 0.1),
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

// MARK: - Adaptation Undo Row
struct AdaptationUndoRow: View {
    @StateObject private var viewModel = ProfileScreenViewModel(languageManager: LanguageManager.shared)
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showingUndoAlert = false
    @State private var isUndoing = false
    @State private var undoError: String? = nil
    @StateObject private var paywallManager = PaywallManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(L("settings.adaptation.undo.title", table: "Profile"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appText)
                
                Text(viewModel.hasRawUndoData() ? L("settings.adaptation.undo.available", table: "Profile") : L("settings.adaptation.undo.notAvailable", table: "Profile"))
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Action button
            if viewModel.hasRawUndoData() {
                PSStatusBadge(
                    L("settings.adaptation.undo.button", table: "Profile"),
                    icon: "arrow.uturn.backward",
                    color: .orange,
                    backgroundColor: Color.orange.opacity(0.15)
                )
                .onTapGesture {
                    handleUndoTap()
                }
            } else {
                PSStatusBadge(
                    L("settings.adaptation.undo.notAvailableStatus", table: "Profile"),
                    icon: "xmark.circle",
                    color: .appTextSecondary,
                    backgroundColor: Color.appTextSecondary.opacity(0.1)
                )
            }
        }
        .padding(.vertical, 8)
        .alert(L("settings.adaptation.undo.alert.title", table: "Profile"), isPresented: $showingUndoAlert) {
            Button(L("general.cancel", table: "Profile"), role: .cancel) {}
            Button(L("settings.adaptation.undo.button", table: "Profile"), role: .destructive) {
                performUndo()
            }
        } message: {
            Text(L("settings.adaptation.undo.alert.message", table: "Profile"))
        }
        .alert(L("general.error", table: "Profile"), isPresented: .init(get: { undoError != nil }, set: { if !$0 { undoError = nil } })) {
            Button(L("general.ok", table: "Profile"), role: .cancel) {
                undoError = nil
            }
        } message: {
            Text(undoError ?? L("general.unknownError", table: "Profile"))
        }
        .environment(\.locale, Locale(identifier: languageManager.currentLanguage))
        .onAppear {
            // ViewModelContext gerekli değil, sadece repository kullanacağız
        }
    }
    
    private func handleUndoTap() {
        // Premium kontrolü
        if revenueCatManager.userState != .premium {
            paywallManager.presentPaywall(trigger: .premiumFeatureAccess)
            return
        }
        
        showingUndoAlert = true
    }
    
    private func performUndo() {
        isUndoing = true
        
        Task {
            do {
                try await viewModel.undoScheduleChange()
                await MainActor.run {
                    isUndoing = false
                }
            } catch {
                await MainActor.run {
                    undoError = error.localizedDescription
                    isUndoing = false
                }
            }
        }
    }
}

// MARK: - HealthKit Integration Row
struct HealthKitIntegrationRow: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var isConnecting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Apple Sağlık")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appText)
                
                Text(getStatusText())
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Status badge or action button
            statusBadge
        }
        .padding(.vertical, 8)
        .onAppear {
            Task {
                await healthKitManager.getAuthorizationStatus { status in
                    DispatchQueue.main.async {
                        healthKitManager.authorizationStatus = status
                    }
                }
            }
        }
        .alert("Hata", isPresented: $showingError) {
            Button("Tamam", role: .cancel) {
                showingError = false
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        switch healthKitManager.authorizationStatus {
        case .notDetermined:
            if isConnecting {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
            } else {
                PSStatusBadge(
                    L("settings.health.connect", table: "Settings"),
                    icon: "plus.circle.fill",
                    color: .green,
                    backgroundColor: Color.green.opacity(0.15)
                )
                .onTapGesture {
                    Task {
                        await requestHealthKitPermission()
                    }
                }
            }
            
        case .sharingAuthorized:
            PSStatusBadge(
                L("settings.health.connected", table: "Settings"),
                icon: "checkmark.circle.fill",
                color: .green,
                backgroundColor: Color.green.opacity(0.15)
            )
            
        case .sharingDenied:
            PSStatusBadge(
                L("settings.health.denied", table: "Settings"),
                icon: "xmark.circle.fill",
                color: .red,
                backgroundColor: Color.red.opacity(0.15)
            )
            .onTapGesture {
                openHealthSettings()
            }
            
        @unknown default:
            PSStatusBadge(
                "Bilinmiyor",
                icon: "questionmark.circle.fill",
                color: .appTextSecondary,
                backgroundColor: Color.appTextSecondary.opacity(0.1)
            )
        }
    }
    
    private func getStatusText() -> String {
        if !healthKitManager.isHealthDataAvailable {
            return "Bu cihazda HealthKit kullanılamıyor"
        }
        
        switch healthKitManager.authorizationStatus {
        case .notDetermined:
            return L("settings.health.status.notDetermined", table: "Settings")
        case .sharingAuthorized:
            return L("settings.health.status.authorized", table: "Settings")
        case .sharingDenied:
            return L("settings.health.status.denied", table: "Settings")
        @unknown default:
            return L("settings.health.status.unknown", table: "Settings")
        }
    }
    
    private func requestHealthKitPermission() async {
        guard !isConnecting else { return }
        
        isConnecting = true
        defer { isConnecting = false }
        
        let result = await healthKitManager.requestAuthorization()
        
        switch result {
        case .success(_):
            // Success, status will be updated automatically
            break
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func openHealthSettings() {
        guard let url = URL(string: "x-apple-health://") else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Fallback to general settings
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }
}

// MARK: - Restart Onboarding Row
struct RestartOnboardingRow: View {
    @State private var showingRestartAlert = false
    @State private var isRestarting = false
    @State private var userPreferences: UserPreferences?
    @State private var restartCount = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @StateObject private var paywallManager = PaywallManager.shared
    
    var isPremiumRequired: Bool {
        return restartCount >= 1
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.appPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(L("settings.onboarding.restart.title", table: "Profile"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.appText)
                    
                    // Crown icon for premium requirement
                    if isPremiumRequired {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.yellow)
                    }
                }
                
                Text(L("settings.onboarding.restart.subtitle", table: "Profile"))
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Action button
            PSStatusBadge(
                L("settings.onboarding.restart.button", table: "Profile"),
                icon: "arrow.clockwise",
                color: isPremiumRequired && revenueCatManager.userState != .premium ? .yellow : .appPrimary,
                backgroundColor: isPremiumRequired && revenueCatManager.userState != .premium ? Color.yellow.opacity(0.15) : Color.appPrimary.opacity(0.15)
            )
            .onTapGesture {
                handleRestartTap()
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .alert(
            L("settings.onboarding.restart.alert.title", table: "Profile"),
            isPresented: $showingRestartAlert
        ) {
            Button(L("common.cancel", table: "Common"), role: .cancel) {}
            Button(L("settings.onboarding.restart.alert.confirm", table: "Profile"), role: .destructive) {
                Task {
                    await restartOnboarding()
                }
            }
        } message: {
            Text(L("settings.onboarding.restart.alert.message", table: "Profile"))
        }
        .overlay {
            if isRestarting {
                ProgressView()
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
        .onAppear {
            loadUserPreferences()
        }
    }
    
    private func loadUserPreferences() {
        do {
            let descriptor = FetchDescriptor<UserPreferences>()
            let preferences = try modelContext.fetch(descriptor)
            
            if let preference = preferences.first {
                userPreferences = preference
                restartCount = preference.onboardingRestartCount
            }
        } catch {
            print("❌ RestartOnboardingRow: UserPreferences yüklenirken hata: \(error.localizedDescription)")
        }
    }
    
    private func handleRestartTap() {
        // Check if premium is required and user is not premium
        if isPremiumRequired && revenueCatManager.userState != .premium {
            paywallManager.presentPaywall(trigger: .premiumFeatureAccess)
            return
        }
        
        showingRestartAlert = true
    }
    
    private func restartOnboarding() async {
        isRestarting = true
        defer { isRestarting = false }
        
        // Increment restart count
        await incrementRestartCount()
        
        // Reset user preferences to restart onboarding
        await resetUserPreferencesForOnboarding()
        
        // Dismiss settings and trigger onboarding restart
        await MainActor.run {
            dismiss()
            
            // Trigger onboarding restart by posting notification
            NotificationCenter.default.post(name: .restartOnboarding, object: nil)
        }
    }
    
    private func incrementRestartCount() async {
        do {
            let descriptor = FetchDescriptor<UserPreferences>()
            let preferences = try modelContext.fetch(descriptor)
            
            for preference in preferences {
                preference.onboardingRestartCount += 1
                restartCount = preference.onboardingRestartCount
            }
            
            try modelContext.save()
            print("✅ RestartOnboardingRow: Restart count artırıldı: \(restartCount)")
        } catch {
            print("❌ RestartOnboardingRow: Restart count artırılırken hata: \(error.localizedDescription)")
        }
    }
    
    private func resetUserPreferencesForOnboarding() async {
        do {
            let descriptor = FetchDescriptor<UserPreferences>()
            let preferences = try modelContext.fetch(descriptor)
            
            for preference in preferences {
                preference.hasCompletedOnboarding = false
                preference.hasSkippedOnboarding = false
                preference.hasCompletedQuestions = false
                // onboardingRestartCount'ı sıfırlamıyoruz - kullanıcının geçmişi
            }
            
            try modelContext.save()
            print("✅ RestartOnboardingRow: UserPreferences onboarding için sıfırlandı")
        } catch {
            print("❌ RestartOnboardingRow: UserPreferences sıfırlanırken hata: \(error.localizedDescription)")
        }
    }
}

extension Notification.Name {
    static let restartOnboarding = Notification.Name("restartOnboarding")
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
        }
        .environmentObject(LanguageManager.shared)
        .environmentObject(RevenueCatManager.shared)
    }
}
