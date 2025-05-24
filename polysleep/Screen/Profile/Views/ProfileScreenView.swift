import SwiftUI
import SwiftData

struct ProfileScreenView: View {
    @StateObject var viewModel: ProfileScreenViewModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showEmojiPicker = false
    @State private var isPickingCoreEmoji = true
    @State private var showLoginSheet = false
    @State private var showLogoutSheet = false
    @State private var navigateToSettings = false
    @StateObject private var authManager = AuthManager.shared
    @State private var showSuccessMessage = false
    
    init() {
        self._viewModel = StateObject(wrappedValue: ProfileScreenViewModel(languageManager: LanguageManager.shared))
    }
    
    var body: some View {
        return NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Profile Header Card
                        ProfileHeaderCard(
                            showLoginSheet: $showLoginSheet, 
                            showLogoutSheet: $showLogoutSheet,
                            navigateToSettings: $navigateToSettings, 
                            authManager: authManager
                        )
                        
                        // Stats Grid
                        StatsGridSection(viewModel: viewModel)
                        
                        // Adaptation Phase Card
                        AdaptationPhaseCard(viewModel: viewModel)
                        
                        // Customization Card
                        CustomizationCard(
                            viewModel: viewModel, 
                            showEmojiPicker: $showEmojiPicker, 
                            isPickingCoreEmoji: $isPickingCoreEmoji
                        )
                        
                        // Premium Upgrade Card
                        PremiumUpgradeCard()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                
                // Başarılı giriş mesajı
                if showSuccessMessage {
                    VStack {
                        Text(L("profile.login.success", table: "Profile"))
                            .padding()
                            .background(Color.appPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                            .padding(.top, 16)
                        
                        Spacer()
                    }
                    .transition(.move(edge: .top))
                    .animation(.easeInOut, value: showSuccessMessage)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                showSuccessMessage = false
                            }
                        }
                    }
                }
            }
            .navigationTitle(L("profile.title", table: "Profile"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showEmojiPicker) {
                EmojiPickerView(
                    selectedEmoji: isPickingCoreEmoji ? $viewModel.selectedCoreEmoji : $viewModel.selectedNapEmoji,
                    onSave: {
                        if isPickingCoreEmoji {
                            viewModel.saveEmojiPreference(coreEmoji: viewModel.selectedCoreEmoji)
                        } else {
                            viewModel.saveEmojiPreference(napEmoji: viewModel.selectedNapEmoji)
                        }
                    }
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showLoginSheet) {
                LoginSheetView(authManager: authManager, onSuccessfulLogin: {
                    showSuccessMessage = true
                })
                .presentationDetents([.height(350)])
            }
            .sheet(isPresented: $showLogoutSheet) {
                LogoutSheetView(authManager: authManager)
                    .presentationDetents([.height(200)])
            }
            .navigationDestination(isPresented: $navigateToSettings) {
                SettingsView()
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
        .id(languageManager.currentLanguage)
    }
}

// MARK: - Premium Upgrade Card
struct PremiumUpgradeCard: View {
    var body: some View {
        Button(action: {
            // Premium işlevselliği
        }) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .font(.title2)
                                .foregroundColor(.yellow)
                            
                            Text(L("profile.premium.title", table: "Profile"))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Text(L("profile.premium.description", table: "Profile"))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text(L("profile.premium.upgrade", table: "Profile"))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.25))
                            )
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // Premium Features
                HStack(spacing: 20) {
                    PremiumFeature(icon: "chart.line.uptrend.xyaxis", title: L("profile.premium.features.statistics", table: "Profile"))
                    PremiumFeature(icon: "bell.badge", title: L("profile.premium.features.notifications", table: "Profile"))
                    PremiumFeature(icon: "paintbrush", title: L("profile.premium.features.themes", table: "Profile"))
                }
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.appSecondary, Color.appAccent]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: Color.appSecondary.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PremiumFeature: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Profile Header Card
struct ProfileHeaderCard: View {
    @Binding var showLoginSheet: Bool
    @Binding var showLogoutSheet: Bool
    @Binding var navigateToSettings: Bool
    @ObservedObject var authManager: AuthManager
    
    private func hasDisplayName() -> Bool {
        guard let user = authManager.currentUser else { return false }
        return !user.displayName.isEmpty
    }
    
    private func getUserInitials() -> String {
        guard let user = authManager.currentUser, !user.displayName.isEmpty else {
            return "U"
        }
        let names = user.displayName.split(separator: " ")
        if names.count >= 2 {
            return String(names[0].prefix(1)) + String(names[1].prefix(1))
        } else {
            return String(user.displayName.prefix(1))
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile Avatar & Info
            HStack(alignment: .center, spacing: 16) {
                // Avatar
                Button(action: {
                    showLoginSheet = true
                }) {
                    if let user = authManager.currentUser, !user.displayName.isEmpty {
                        Text(getUserInitials().uppercased())
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.appPrimary, Color.appAccent]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            )
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.appSecondaryText.opacity(0.6))
                    }
                }
                .scaleEffect(1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasDisplayName())
                
                VStack(alignment: .leading, spacing: 8) {
                    // Name
                    if let user = authManager.currentUser {
                        Text(user.displayName.isEmpty ? L("profile.user.defaultName", table: "Profile") : user.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.appText)
                        
                        Text(L("profile.user.localAccount", table: "Profile"))
                            .font(.subheadline)
                            .foregroundColor(.appSecondaryText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.appSecondary.opacity(0.15))
                            )
                    }
                    
                    // Edit Profile Button
                    Button(action: {
                        showLoginSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                                .font(.caption)
                            Text(L("profile.user.editProfile", table: "Profile"))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.appPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.appPrimary.opacity(0.1))
                        )
                    }
                }
                
                Spacer()
                
                // Settings Button
                Button(action: {
                    navigateToSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.appSecondaryText.opacity(0.8))
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color.appSecondaryText.opacity(0.1))
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Çıkış Sheet Görünümü
struct LogoutSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authManager: AuthManager
    
    var body: some View {
        return VStack(spacing: 24) {
            // Başlık
            Text(L("profile.logout.title", table: "Profile"))
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.appText)
                .padding(.top, 24)
            
            // Kullanıcı email bilgisi
            if let user = authManager.currentUser {
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
            }
            
            // Çıkış butonu
            Button(action: {
                Task {
                    await authManager.signOut()
                    dismiss()
                }
            }) {
                Text(L("profile.login.signout", table: "Profile"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.8))
                    )
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
}

// MARK: - Giriş Sheet Görünümü
struct LoginSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authManager: AuthManager
    var onSuccessfulLogin: () -> Void
    
    @State private var displayName: String = ""
    
    var body: some View {
        return VStack(spacing: 24) {
            // Başlık
            Text(L("profile.edit.title", table: "Profile"))
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.appText)
                .padding(.top, 24)
            
            // Açıklama
            Text(L("profile.edit.description", table: "Profile"))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.appSecondaryText)
                .padding(.horizontal, 24)
            
            // Kullanıcı adı düzenleme formu
            VStack(spacing: 16) {
                // İsim girişi
                TextField(
                    L("profile.edit.name.placeholder", table: "Profile"),
                    text: $displayName
                )
                .padding()
                .background(Color.appCardBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.appSecondaryText.opacity(0.3), lineWidth: 1)
                )
                
                // Kaydet butonu
                Button(action: {
                    if !displayName.isEmpty {
                        authManager.updateDisplayName(displayName)
                        dismiss()
                        onSuccessfulLogin()
                    }
                }) {
                    Text(L("profile.edit.save", table: "Profile"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appPrimary)
                        )
                }
                .disabled(displayName.isEmpty || authManager.isLoading)
            }
            .padding(.horizontal, 24)
            
            // Hata mesajı
            if let error = authManager.authError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 24)
            }
            
            // Yükleniyor göstergesi
            if authManager.isLoading {
                ProgressView()
                    .padding(.top, 8)
            }
            
            Spacer()
        }
        .onAppear {
            // Mevcut kullanıcı adını yükle
            if let currentUser = authManager.currentUser {
                displayName = currentUser.displayName
            }
        }
    }
}

// MARK: - Stats Grid Section
struct StatsGridSection: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.appPrimary)
                
                Text(L("profile.stats.title", table: "Profile"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                // Current Streak
                StatCard(
                    icon: "flame.fill",
                    title: L("profile.stats.currentStreak", table: "Profile"),
                    value: "\(viewModel.currentStreak)",
                    subtitle: L("profile.stats.days", table: "Profile"),
                    color: .orange,
                    gradientColors: [.orange, .red]
                )
                
                // Longest Streak
                StatCard(
                    icon: "trophy.fill",
                    title: L("profile.stats.longestStreak", table: "Profile"),
                    value: "\(viewModel.longestStreak)",
                    subtitle: L("profile.stats.days", table: "Profile"),
                    color: .appSecondary,
                    gradientColors: [.appSecondary, .appAccent]
                )
                
                // Total Sessions
                StatCard(
                    icon: "moon.zzz.fill",
                    title: L("profile.stats.totalSleep", table: "Profile"),
                    value: "\(calculateTotalSessions())",
                    subtitle: L("profile.stats.sessions", table: "Profile"),
                    color: .purple,
                    gradientColors: [.purple, .blue]
                )
                
                // Success Rate
                StatCard(
                    icon: "checkmark.seal.fill",
                    title: L("profile.stats.successRate", table: "Profile"),
                    value: "\(calculateSuccessRate())%",
                    subtitle: L("profile.stats.completion", table: "Profile"),
                    color: .green,
                    gradientColors: [.green, .mint]
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private func calculateTotalSessions() -> Int {
        // Bu gerçek implementasyonla değiştirilecek
        return viewModel.currentStreak + viewModel.longestStreak
    }
    
    private func calculateSuccessRate() -> Int {
        // Bu gerçek implementasyonla değiştirilecek
        let total = calculateTotalSessions()
        if total == 0 { return 0 }
        return min(95, 70 + (total * 2))
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let gradientColors: [Color]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(color)
                    )
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.appText)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.appText)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.appSecondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: gradientColors.map { $0.opacity(0.3) }),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Adaptation Phase Card
struct AdaptationPhaseCard: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingResetAlert = false
    @State private var isResetting = false
    @State private var resetError: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile.fill")
                    .font(.title2)
                    .foregroundColor(.appAccent)
                
                Text(L("profile.adaptation.title", table: "Profile"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
                
                Spacer()
                
                if viewModel.activeSchedule != nil {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title3)
                            .foregroundColor(.appSecondaryText.opacity(0.7))
                    }
                    .disabled(isResetting)
                }
            }
            
            if let schedule = viewModel.activeSchedule {
                AdaptationProgressCard(
                    duration: viewModel.adaptationDuration,
                    currentPhase: viewModel.adaptationPhase,
                    phaseDescription: viewModel.adaptationPhaseDescription,
                    showingResetAlert: $showingResetAlert,
                    isResetting: isResetting,
                    viewModel: viewModel
                )
            } else {
                EmptyAdaptationCard()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .alert(L("profile.adaptation.reset.title", table: "Profile"), isPresented: $showingResetAlert) {
            Button(L("general.cancel", table: "Profile"), role: .cancel) { }
            Button(L("profile.adaptation.reset.confirm", table: "Profile"), role: .destructive) {
                resetAdaptationPhase()
            }
        } message: {
            Text(L("profile.adaptation.reset.message", table: "Profile"))
        }
        .alert(L("general.error", table: "Profile"), isPresented: .init(get: { resetError != nil }, set: { if !$0 { resetError = nil } })) {
            Button(L("general.ok", table: "Profile"), role: .cancel) {
                resetError = nil
            }
        } message: {
            Text(resetError ?? L("general.unknownError", table: "Profile"))
        }
    }
    
    private func resetAdaptationPhase() {
        isResetting = true
        
        Task {
            do {
                try await viewModel.resetAdaptationPhase()
                
                await MainActor.run {
                    isResetting = false
                }
            } catch {
                await MainActor.run {
                    resetError = error.localizedDescription
                    isResetting = false
                }
            }
        }
    }
}

// MARK: - Empty Adaptation Card
struct EmptyAdaptationCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 48))
                .foregroundColor(.appSecondaryText.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(L("profile.adaptation.empty.title", table: "Profile"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appText)
                
                Text(L("profile.adaptation.empty.description", table: "Profile"))
                    .font(.caption)
                    .foregroundColor(.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Adaptation Progress Card
struct AdaptationProgressCard: View {
    let duration: Int
    let currentPhase: Int
    let phaseDescription: String
    @Binding var showingResetAlert: Bool
    let isResetting: Bool
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: ProfileScreenViewModel
    
    var body: some View {
        let completedDays = calculateRealCompletedDays()
        let progress = Float(completedDays) / Float(duration)
        let phaseColor = getPhaseColor(currentPhase)
        
        VStack(spacing: 20) {
            // Header dengan progress info
            HStack(spacing: 16) {
                // Phase icon
                ZStack {
                    Circle()
                        .fill(phaseColor)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: phaseColor.opacity(0.3), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(phaseDescription)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.appText)
                    
                    Text(String(format: L("profile.adaptation.dayProgress", table: "Profile"), completedDays, duration))
                        .font(.subheadline)
                        .foregroundColor(.appSecondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(phaseColor)
                }
            }
            
            // Modern progress bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 10)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [phaseColor.opacity(0.7), phaseColor]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(6, geometry.size.width * CGFloat(progress)), height: 10)
                            .animation(.easeInOut(duration: 0.6), value: progress)
                    }
                }
                .frame(height: 10)
            }
            
            // Status description
            Text(getStatusDescription())
                .font(.footnote)
                .foregroundColor(.appSecondaryText)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(phaseColor.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(phaseColor.opacity(0.15), lineWidth: 1)
                        )
                )
        }
        .animation(.easeInOut(duration: 0.3), value: currentPhase)
    }
    
    private func calculateRealCompletedDays() -> Int {
        if let schedule = viewModel.activeSchedule {
            let calendar = Calendar.current
            let startDate = schedule.updatedAt
            let currentDate = Date()
            let components = calendar.dateComponents([.day], from: startDate, to: currentDate)
            let daysPassed = (components.day ?? 0) + 1 // 1. günden başla
            return min(daysPassed, duration)
        }
        return 1
    }
    
    private func getPhaseColor(_ phase: Int) -> Color {
        let colors: [Color] = [.blue, .purple, .appSecondary, .orange, .green, .pink]
        return colors[safe: phase] ?? .appSecondary
    }
    
    private func getStatusDescription() -> String {
        let completedDays = calculateRealCompletedDays()
        
        switch currentPhase {
        case 0:
            return L("profile.adaptation.phase0.description", table: "Profile")
        case 1:
            return String(format: L("profile.adaptation.phase1.description", table: "Profile"), completedDays)
        case 2:
            return String(format: L("profile.adaptation.phase2.description", table: "Profile"), completedDays)
        case 3:
            return String(format: L("profile.adaptation.phase3.description", table: "Profile"), completedDays)
        case 4:
            if duration == 28 {
                return String(format: L("profile.adaptation.phase4.28day.description", table: "Profile"), completedDays)
            } else {
                return String(format: L("profile.adaptation.phase4.21day.description", table: "Profile"), completedDays)
            }
        case 5...:
            return String(format: L("profile.adaptation.phase5.description", table: "Profile"), completedDays)
        default:
            return L("profile.adaptation.default.description", table: "Profile")
        }
    }
}

// MARK: - Aşama Bilgi Görünümü
struct PhaseInfoView: View {
    let phaseColor: Color
    let description: String
    let statusText: String
    @Binding var showingResetAlert: Bool
    let isResetting: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(phaseColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                )
                .shadow(color: phaseColor.opacity(0.5), radius: 4, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(description)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.appText)
                
                Text(statusText)
                    .font(.footnote)
                    .foregroundColor(.appSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - İlerleme Göstergesi
struct ProgressIndicatorView: View {
    let completedDays: Int
    let totalDays: Int
    let progress: Float
    let currentPhase: Int
    let phaseColor: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("profile.adaptation.progressTitle", table: "Profile"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appText)
                
                Spacer()
                
                Text(String(format: L("profile.adaptation.dayCount", table: "Profile"), completedDays, totalDays))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.appSecondaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ? 
                                  Color.gray.opacity(0.2) : 
                                  Color.black.opacity(0.05))
                    )
            }
            
            // İlerleme çubuğu ve noktalar
            ProgressBarView(progress: progress, phaseColor: phaseColor, currentPhase: currentPhase, totalDays: totalDays)
            
            // İlerleme yüzdesi
            Text(String(format: L("profile.adaptation.percentCompleted", table: "Profile"), Int(progress * 100)))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(phaseColor)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - İlerleme Çubuğu Görünümü
struct ProgressBarView: View {
    let progress: Float
    let phaseColor: Color
    let currentPhase: Int
    let totalDays: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Arka plan
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 12)
                
                // İlerleme
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [phaseColor.opacity(0.7), phaseColor]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(8, geometry.size.width * CGFloat(progress)), height: 12)
                    .shadow(color: phaseColor.opacity(0.4), radius: 2, x: 0, y: 1)
                
                // İlerleme göstergesi noktaları
                ProgressDots(currentPhase: currentPhase, totalDays: totalDays)
            }
        }
        .frame(height: 12)
    }
}

// MARK: - İlerleme Noktaları Görünümü
struct ProgressDots: View {
    let currentPhase: Int
    let totalDays: Int
    
    var body: some View {
        HStack(spacing: 0) {
            let phaseCount = totalDays == 28 ? 6 : 5 // 28 günlük program için 6 aşama, 21 günlük için 5 aşama
            
            ForEach(0..<phaseCount, id: \.self) { i in
                ProgressDot(
                    isCompleted: i <= currentPhase,
                    isActive: i == currentPhase,
                    phaseColor: phaseColorForIndex(i)
                )
                .padding(.leading, i == 0 ? 0 : (UIScreen.main.bounds.width * 0.7 - 96) / CGFloat(phaseCount - 1))
            }
            
            Spacer()
        }
    }
    
    private func phaseColorForIndex(_ index: Int) -> Color {
        let colors: [Color] = [.blue, .purple, .appSecondary, .orange, .green, .pink]
        return colors[safe: index] ?? .appSecondary
    }
}

// MARK: - İlerleme Noktası
struct ProgressDot: View {
    let isCompleted: Bool
    let isActive: Bool
    let phaseColor: Color
    
    var body: some View {
        Circle()
            .fill(isCompleted ? phaseColor : Color.gray.opacity(0.3))
            .frame(width: 16, height: 16)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .opacity(isCompleted ? 1 : 0)
            )
            .background(
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                    .opacity(isActive ? 1 : 0)
                    .scaleEffect(1.5)
            )
    }
}

// MARK: - Zaman Çizelgesi Öğeleri
struct TimelineItemsView: View {
    let phase: Int
    let totalDays: Int
    let phaseColors: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Başlangıç aşaması
            timelineItem(
                icon: "1.circle.fill", 
                title: L("profile.adaptation.timeline.phase1.title", table: "Profile"), 
                duration: L("profile.adaptation.timeline.phase1.duration", table: "Profile"), 
                status: phase >= 0 ? (phase > 0 ? L("profile.adaptation.timeline.completed", table: "Profile") : L("profile.adaptation.timeline.inProgress", table: "Profile")) : L("profile.adaptation.timeline.waiting", table: "Profile"), 
                isCompleted: phase > 0,
                isActive: phase == 0,
                color: phaseColors[safe: 0] ?? .blue
            )
            
            // Uyum aşaması
            timelineItem(
                icon: "2.circle.fill", 
                title: L("profile.adaptation.timeline.phase2.title", table: "Profile"), 
                duration: L("profile.adaptation.timeline.phase2.duration", table: "Profile"), 
                status: phase >= 1 ? (phase > 1 ? L("profile.adaptation.timeline.completed", table: "Profile") : L("profile.adaptation.timeline.inProgress", table: "Profile")) : L("profile.adaptation.timeline.waiting", table: "Profile"), 
                isCompleted: phase > 1, 
                isActive: phase == 1,
                color: phaseColors[safe: 1] ?? .purple
            )
            
            // Adaptasyon aşaması
            timelineItem(
                icon: "3.circle.fill", 
                title: L("profile.adaptation.timeline.phase3.title", table: "Profile"), 
                duration: L("profile.adaptation.timeline.phase3.duration", table: "Profile"), 
                status: phase >= 2 ? (phase > 2 ? L("profile.adaptation.timeline.completed", table: "Profile") : L("profile.adaptation.timeline.inProgress", table: "Profile")) : L("profile.adaptation.timeline.waiting", table: "Profile"), 
                isCompleted: phase > 2, 
                isActive: phase == 2,
                color: phaseColors[safe: 2] ?? .appSecondary
            )
            
            // İleri adaptasyon
            timelineItem(
                icon: "4.circle.fill", 
                title: L("profile.adaptation.timeline.phase4.title", table: "Profile"), 
                duration: L("profile.adaptation.timeline.phase4.duration", table: "Profile"), 
                status: phase >= 3 ? (phase > 3 ? L("profile.adaptation.timeline.completed", table: "Profile") : L("profile.adaptation.timeline.inProgress", table: "Profile")) : L("profile.adaptation.timeline.waiting", table: "Profile"), 
                isCompleted: phase > 3, 
                isActive: phase == 3,
                color: phaseColors[safe: 3] ?? .orange
            )
            
            if totalDays == 28 {
                // 28 günlük program için tam adaptasyon
                timelineItem(
                    icon: "5.circle.fill", 
                    title: L("profile.adaptation.timeline.phase5.title", table: "Profile"), 
                    duration: L("profile.adaptation.timeline.phase5.duration", table: "Profile"), 
                    status: phase >= 4 ? (phase > 4 ? L("profile.adaptation.timeline.completed", table: "Profile") : L("profile.adaptation.timeline.inProgress", table: "Profile")) : L("profile.adaptation.timeline.waiting", table: "Profile"), 
                    isCompleted: phase > 4, 
                    isActive: phase == 4,
                    color: phaseColors[safe: 4] ?? .green
                )
                
                // 28 günlük program için tam adaptasyon+
                timelineItem(
                    icon: "checkmark.circle.fill", 
                    title: L("profile.adaptation.timeline.phase6.title", table: "Profile"), 
                    duration: L("profile.adaptation.timeline.phase6.duration", table: "Profile"), 
                    status: phase >= 5 ? L("profile.adaptation.timeline.inProgress", table: "Profile") : L("profile.adaptation.timeline.waiting", table: "Profile"), 
                    isCompleted: false, 
                    isActive: phase >= 5,
                    isLast: true,
                    color: phaseColors[safe: 5] ?? .pink
                )
            } else {
                // 21 günlük program için tam adaptasyon
                timelineItem(
                    icon: "checkmark.circle.fill", 
                    title: L("profile.adaptation.timeline.phase5.title", table: "Profile"), 
                    duration: L("profile.adaptation.timeline.phase5.21day.duration", table: "Profile"), 
                    status: phase >= 4 ? L("profile.adaptation.timeline.inProgress", table: "Profile") : L("profile.adaptation.timeline.waiting", table: "Profile"), 
                    isCompleted: false, 
                    isActive: phase >= 4,
                    isLast: true,
                    color: phaseColors[safe: 4] ?? .green
                )
            }
        }
    }
    
    // Zaman çizelgesi öğesi
    private func timelineItem(
        icon: String, 
        title: String, 
        duration: String, 
        status: String, 
        isCompleted: Bool, 
        isActive: Bool = false,
        isLast: Bool = false,
        color: Color = .appSecondary
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon ve dikey çizgi
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : (isActive ? color : Color.gray.opacity(0.2)))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: isCompleted ? Color.green.opacity(0.3) : (isActive ? color.opacity(0.3) : Color.clear), radius: 4, x: 0, y: 2)
                
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? Color.green.opacity(0.6) : Color.gray.opacity(0.2))
                        .frame(width: 2, height: 24)
                        .padding(.top, 4)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(isActive ? color : .appText)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.appSecondaryText.opacity(0.7))
                        
                        Text(duration)
                            .font(.caption)
                            .foregroundColor(.appSecondaryText)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    Text(status)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(statusColor(status: status))
                        )
                        .foregroundColor(.white)
                }
            }
            .padding(.trailing, 8)
        }
        .padding(.vertical, 4)
    }
    
    // Durum rengi
    private func statusColor(status: String) -> Color {
        switch status {
        case L("profile.adaptation.timeline.completed", table: "Profile"):
            return .green
        case L("profile.adaptation.timeline.inProgress", table: "Profile"):
            return .appSecondary
        default:
            return .gray.opacity(0.5)
        }
    }
}

// MARK: - Array Extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Customization Card
struct CustomizationCard: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    @Binding var showEmojiPicker: Bool
    @Binding var isPickingCoreEmoji: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "face.smiling.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text(L("profile.customization.title", table: "Profile"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
            }
            
            VStack(spacing: 16) {
                // Core Sleep Emoji
                CustomizationRow(
                    icon: "moon.fill",
                    title: L("profile.customization.coreBlock.title", table: "Profile"),
                    subtitle: L("profile.customization.coreBlock.subtitle", table: "Profile"),
                    currentEmoji: viewModel.selectedCoreEmoji,
                    color: .blue
                ) {
                    isPickingCoreEmoji = true
                    showEmojiPicker = true
                }
                
                Divider()
                    .background(Color.appSecondaryText.opacity(0.2))
                
                // Nap Emoji
                CustomizationRow(
                    icon: "powersleep",
                    title: L("profile.customization.napBlock.title", table: "Profile"),
                    subtitle: L("profile.customization.napBlock.subtitle", table: "Profile"),
                    currentEmoji: viewModel.selectedNapEmoji,
                    color: .green
                ) {
                    isPickingCoreEmoji = false
                    showEmojiPicker = true
                }
                
                // Info note
                InfoCard(
                    text: L("profile.customization.infoText", table: "Profile")
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct CustomizationRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let currentEmoji: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
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
            
            Button(action: action) {
                Text(currentEmoji)
                    .font(.system(size: 28))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(color.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(color.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
        }
        .padding(.vertical, 4)
    }
}

struct InfoCard: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.appSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Emoji Seçici Görünümü
struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    let emojiOptions = ["😴", "💤", "🌙", "🌚", "🌜", "🌛", "🛌", "🧠", "⚡", "⏰", "🔋", "🔆", "🌞", "☀️", "🌅", "🌄"]
    
    var body: some View {
        return VStack(spacing: 20) {
            Text(L("profile.emojiPicker.title", table: "Profile"))
                .font(.headline)
                .padding(.top)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                ForEach(emojiOptions, id: \.self) { emoji in
                    Button(action: {
                        selectedEmoji = emoji
                    }) {
                        Text(emoji)
                            .font(.system(size: 32))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedEmoji == emoji ? Color.appPrimary.opacity(0.2) : Color.clear)
                            )
                    }
                }
            }
            .padding()
            
            Button(action: {
                onSave()
                dismiss()
            }) {
                Text(L("profile.emojiPicker.save", table: "Profile"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appPrimary)
                    )
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

struct ProfileScreenView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileScreenView()
            .environmentObject(LanguageManager.shared)
    }
}
