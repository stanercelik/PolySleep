import SwiftUI
import SwiftData
import AVFoundation
import Lottie
import RevenueCat
import RevenueCatUI

struct ProfileScreenView: View {
    @StateObject var viewModel: ProfileScreenViewModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @State private var showEmojiPicker = false
    @State private var isPickingCoreEmoji = true
    @State private var showLoginSheet = false
    @State private var showLogoutSheet = false
    @State private var navigateToSettings = false
    @StateObject private var authManager = AuthManager.shared
    @State private var showSuccessMessage = false
    @State private var adaptationTimer: Timer?
    @State private var showingCelebration = false
    @State private var isPaywallPresented = false
    
    init() {
        self._viewModel = StateObject(wrappedValue: ProfileScreenViewModel(languageManager: LanguageManager.shared))
    }
    
    var body: some View {
        return ZStack {
            // Ana NavigationStack
            NavigationStack {
                ZStack {
                    Color.appBackground
                        .ignoresSafeArea()
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: PSSpacing.xl) {
                            // Schedule Change Undo Banner
                            if viewModel.hasUndoData() {
                                UndoScheduleChangeCard(viewModel: viewModel)
                            }
                            
                            // Profile Header Card
                            ProfileHeaderCard(
                                showLoginSheet: $showLoginSheet, 
                                showLogoutSheet: $showLogoutSheet,
                                navigateToSettings: $navigateToSettings, 
                                authManager: authManager
                            )
                            
                            // Stats Grid
                            StatsGridSection(viewModel: viewModel)
                            
                            // Adaptation Completed Celebration Card or Adaptation Phase Card
                            if viewModel.isAdaptationCompleted {
                                AdaptationCompletedCard(viewModel: viewModel, showingCelebration: $showingCelebration)
                            } else {
                                // Adaptation Phase Card (only show if not completed)
                                AdaptationPhaseCard(viewModel: viewModel)
                            }
                            
                            // Adaptation Debug Section (Premium only)
                            if revenueCatManager.userState == .premium {
                                AdaptationDebugCard(viewModel: viewModel)
                            }
                            
                            // Customization Card
                            CustomizationCard(
                                viewModel: viewModel, 
                                showEmojiPicker: $showEmojiPicker, 
                                isPickingCoreEmoji: $isPickingCoreEmoji
                            )
                            .requiresPremium()
                            
                            // Premium Upgrade Card - Premium kullanıcılar için gizle
                            if revenueCatManager.userState != .premium {
                                PremiumUpgradeCard()
                                    .onTapGesture {
                                        isPaywallPresented.toggle()
                                    }
                            }
                            
                            // Debug Section (Premium Toggle)
                            DebugPremiumCard()
                        }
                        .padding(.horizontal, PSSpacing.lg)
                        .padding(.vertical, PSSpacing.sm)
                    }
                    
                    // Başarılı giriş mesajı
                    if showSuccessMessage {
                        VStack {
                            Text(L("profile.login.success", table: "Profile"))
                                .font(PSTypography.body)
                                .padding(PSSpacing.md)
                                .background(Color.appPrimary)
                                .foregroundColor(.appTextOnPrimary)
                                .cornerRadius(PSCornerRadius.small)
                                .shadow(radius: PSSpacing.xs / 2)
                                .padding(.top, PSSpacing.lg)
                            
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
                .sheet(isPresented: $isPaywallPresented) {
                    PaywallView()
                }
                .navigationDestination(isPresented: $navigateToSettings) {
                    SettingsView()
                }
                .onAppear {
                    viewModel.setModelContext(modelContext)
                    startAdaptationTimer()
                    
                    // Undo banner için güncelleme timer'ı
                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                        viewModel.objectWillChange.send()
                    }
                }
                .onDisappear {
                    stopAdaptationTimer()
                }
            }
            .id(languageManager.currentLanguage)
            
            // Celebration Overlay - NavigationStack'in DIŞINDA tam ekranı kaplar
            if showingCelebration {
                CelebrationOverlay(isShowing: $showingCelebration)
            }
        }
    }
    
    // MARK: - Timer Functions
    private func startAdaptationTimer() {
        stopAdaptationTimer() // Mevcut timer'ı durdur
        
        // Her gece yarısında adaptasyon fazını kontrol et
        adaptationTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { (_: Timer) in
            // Her saat kontrol et, ama sadece gece yarısı geçtiyse güncelle
            Task {
                await viewModel.loadData()
            }
        }
    }
    
    private func stopAdaptationTimer() {
        adaptationTimer?.invalidate()
        adaptationTimer = nil
    }
}

// MARK: - Premium Upgrade Card
struct PremiumUpgradeCard: View {
    var body: some View {
        VStack(spacing: PSSpacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: PSSpacing.sm) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .font(PSTypography.title1)
                            .foregroundColor(.yellow)
                        
                        Text(L("profile.premium.title", table: "Profile"))
                            .font(PSTypography.headline)
                            .foregroundColor(.appTextOnPrimary)
                    }
                    
                    Text(L("profile.premium.description", table: "Profile"))
                        .font(PSTypography.body)
                        .foregroundColor(.appTextOnPrimary.opacity(0.9))
                }
                
                Spacer()
                
                VStack {
                    Text(L("profile.premium.upgrade", table: "Profile"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextOnPrimary)
                        .padding(.horizontal, PSSpacing.lg)
                        .padding(.vertical, PSSpacing.sm)
                        .background(
                            Capsule()
                                .fill(Color.appTextOnPrimary.opacity(0.25))
                        )
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(PSTypography.title1)
                        .foregroundColor(.appTextOnPrimary.opacity(0.7))
                }
            }
            
            // Premium Features
            HStack(spacing: PSSpacing.xl) {
                PremiumFeature(icon: "chart.line.uptrend.xyaxis", title: L("profile.premium.features.statistics", table: "Profile"))
                PremiumFeature(icon: "bell.badge", title: L("profile.premium.features.notifications", table: "Profile"))
                PremiumFeature(icon: "paintbrush", title: L("profile.premium.features.themes", table: "Profile"))
            }
        }
        .padding(PSSpacing.lg)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.appSecondary, Color.appAccent]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(PSCornerRadius.extraLarge)
        .shadow(color: Color.appSecondary.opacity(0.3), radius: PSSpacing.sm, x: 0, y: PSSpacing.xs)
        .contentShape(Rectangle()) // Tıklama alanını genişletmek için
    }
}

struct PremiumFeature: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: PSSpacing.xs) {
            Image(systemName: icon)
                .font(PSTypography.title1)
                .foregroundColor(.appTextOnPrimary)
            
            Text(title)
                .font(PSTypography.caption)
                .foregroundColor(.appTextOnPrimary.opacity(0.9))
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
    @State private var showImagePicker = false
    @State private var showActionSheet = false
    
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
    
    // Avatar ve Kamera İkonu Bölümü
    @ViewBuilder
    private func avatarSection() -> some View {
        ZStack(alignment: .bottomTrailing) {
            Button(action: {
                showActionSheet = true
            }) {
                Group {
                    if let user = authManager.currentUser, let imageData = user.profileImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 88, height: 88)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.appPrimary.opacity(0.8), lineWidth: 3)
                            )
                            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 3)
                    } else if let user = authManager.currentUser, !user.displayName.isEmpty {
                        Text(getUserInitials().uppercased())
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.appTextOnPrimary)
                            .frame(width: 88, height: 88)
                            .background(
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.appPrimary, Color.appAccent]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.appTextOnPrimary.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 3)
                    } else {
                        Text("U")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.appTextOnPrimary)
                            .frame(width: 88, height: 88)
                            .background(
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.appPrimary, Color.appAccent]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.appTextOnPrimary.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 3)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Kamera ikonu overlay
            Button(action: {
                showActionSheet = true
            }) {
                Image(systemName: "camera.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.appAccent)
                    .background(Circle().fill(Color.appBackground).scaleEffect(1.2))
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .offset(x: 4, y: 4)
        }
        .padding(.leading, PSSpacing.xs)
    }

    // Kullanıcı Bilgileri ve Düzenleme Butonu Bölümü
    @ViewBuilder
    private func userInfoSection() -> some View {
        VStack(alignment: .leading, spacing: PSSpacing.xs) {
            if let user = authManager.currentUser {
                HStack(alignment: .firstTextBaseline, spacing: PSSpacing.sm) { // İsim ve Düzenle ikonu için
                    let displayName = user.displayName.isEmpty ? L("profile.user.defaultName", table: "Profile") : user.displayName
                    Text(displayName)
                        .font(dynamicDisplayNameFont(forName: displayName))
                        .foregroundColor(.appText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7) // Daha fazla küçülmeye izin ver
                    
                    Button(action: { // Düzenleme Butonu
                        showLoginSheet = true
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2) // Ayarlar ikonuyla benzer büyüklükte
                            .foregroundColor(Color.appAccent)
                    }
                }
                 
                Text(L("profile.user.localAccount", table: "Profile"))
                    .font(PSTypography.caption)
                    .foregroundColor(.appTextSecondary)
                    .padding(.vertical, PSSpacing.xs)
                    .padding(.horizontal, PSSpacing.sm)
                    .background(Capsule().fill(Color.appSecondary.opacity(0.15)))
            }
        }
    }

    // Ayarlar Butonu Bölümü
    @ViewBuilder
    private func settingsButtonSection() -> some View {
        Button(action: {
            navigateToSettings = true
        }) {
            Image(systemName: "gearshape.fill")
                .font(.title2)
                .foregroundColor(.appTextSecondary)
        }
        .padding(PSSpacing.sm)
        .background(Color.appTextSecondary.opacity(0.1))
        .clipShape(Circle())
    }
    
    // Kullanıcı adı için dinamik font boyutu hesaplayan fonksiyon
    private func dynamicDisplayNameFont(forName name: String) -> Font {
        let length = name.count
        if length <= 12 {
            return PSTypography.title1
        } else if length <= 18 {
            return .system(size: 26, weight: .bold)
        } else if length <= 25 {
            return .system(size: 20, weight: .bold)
        } else {
            return .system(size: 18, weight: .bold)
        }
    }
    
    var body: some View {
        VStack(spacing: PSSpacing.lg) {
            // Profile Avatar & Info
            HStack(alignment: .center, spacing: PSSpacing.lg) { // Ana HStack için genel boşluk
                avatarSection()
                userInfoSection() // İsim, düzenle ikonu ve hesap tipini içerir
                Spacer() // Butonları sağa iter
                
                // Sağ taraftaki butonlar için grup ve aralarındaki boşluk
                //HStack(spacing: PSSpacing.md) { // Sadece Ayarlar butonu kaldı
                //    editButtonSection() // userInfoSection içine taşındı
                    settingsButtonSection()
                //}
            }
            .padding(.horizontal, PSSpacing.lg)
            .padding(.vertical, PSSpacing.md)
            
        }
        .background(Color.appCardBackground)
        .cornerRadius(PSCornerRadius.extraLarge)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
        .confirmationDialog(L("profile.avatar.options.title", table: "Profile"), isPresented: $showActionSheet) {
            Button(L("profile.avatar.options.selectPhoto", table: "Profile")) {
                showImagePicker = true
            }
            
            if authManager.currentUser?.profileImageData != nil {
                Button(L("profile.avatar.options.removePhoto", table: "Profile"), role: .destructive) {
                    authManager.updateProfileImage(nil)
                }
            }
            
            Button(L("profile.avatar.options.editProfile", table: "Profile")) {
                showLoginSheet = true
            }
            
            Button(L("profile.avatar.options.cancel", table: "Profile"), role: .cancel) { }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker { image in
                if let image = image,
                   let imageData = image.jpegData(compressionQuality: 0.8) {
                    authManager.updateProfileImage(imageData)
                }
            }
        }
    }
}

// MARK: - Çıkış Sheet Görünümü
struct LogoutSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authManager: AuthManager
    
    var body: some View {
        return VStack(spacing: PSSpacing.xl) {
            // Başlık
            Text(L("profile.logout.title", table: "Profile"))
                .font(PSTypography.headline)
                .foregroundColor(.appText)
                .padding(.top, PSSpacing.xl)
            
            // Kullanıcı email bilgisi
            if let user = authManager.currentUser {
                Text(user.email)
                    .font(PSTypography.subheadline)
                    .foregroundColor(.appTextSecondary)
            }
            
            // Çıkış butonu
            PSPrimaryButton(L("profile.login.signout", table: "Profile"), destructive: true, customBackgroundColor: Color.red.opacity(0.8)) {
                Task {
                    await authManager.signOut()
                    dismiss()
                }
            }
            .padding(.horizontal, PSSpacing.xl)
            
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
    private let maxDisplayNameLength = 25
    
    var body: some View {
        return VStack(spacing: PSSpacing.xl) {
            // Başlık
            Text(L("profile.edit.title", table: "Profile"))
                .font(PSTypography.headline)
                .foregroundColor(.appText)
                .padding(.top, PSSpacing.xl)
            
            // Açıklama
            Text(L("profile.edit.description", table: "Profile"))
                .font(PSTypography.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.appTextSecondary)
                .padding(.horizontal, PSSpacing.xl)
            
            // Kullanıcı adı düzenleme formu
            VStack(spacing: PSSpacing.lg) {
                // İsim girişi
                TextField(
                    L("profile.edit.name.placeholder", table: "Profile"),
                    text: $displayName
                )
                .font(PSTypography.body)
                .padding(PSSpacing.md)
                .background(Color.appCardBackground)
                .cornerRadius(PSCornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
                .onChange(of: displayName) { oldValue, newValue in
                    if newValue.count > maxDisplayNameLength {
                        displayName = String(newValue.prefix(maxDisplayNameLength))
                    }
                }
                
                // Kaydet butonu
                PSPrimaryButton(L("profile.edit.save", table: "Profile")) {
                    if !displayName.isEmpty {
                        authManager.updateDisplayName(displayName)
                        dismiss()
                        onSuccessfulLogin()
                    }
                }
                .disabled(displayName.isEmpty || authManager.isLoading)
            }
            .padding(.horizontal, PSSpacing.xl)
            
            // Hata mesajı
            if let error = authManager.authError {
                Text(error)
                    .font(PSTypography.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, PSSpacing.xl)
            }
            
            // Yükleniyor göstergesi
            if authManager.isLoading {
                ProgressView()
                    .padding(.top, PSSpacing.sm)
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
                    .foregroundColor(.appTextSecondary)
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
                            .foregroundColor(.appTextSecondary.opacity(0.7))
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
                .foregroundColor(.appTextSecondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(L("profile.adaptation.empty.title", table: "Profile"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appText)
                
                Text(L("profile.adaptation.empty.description", table: "Profile"))
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
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
                        .foregroundColor(.appTextSecondary)
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
                .foregroundColor(.appTextSecondary)
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
            
            // İki tarih arasındaki tam gün farkını hesapla
            let startOfStartDate = calendar.startOfDay(for: startDate)
            let startOfCurrentDate = calendar.startOfDay(for: currentDate)
            
            let components = calendar.dateComponents([.day], from: startOfStartDate, to: startOfCurrentDate)
            let daysPassed = components.day ?? 0
            
            // 1. gün = adaptasyon başladığı gün (daysPassed = 0)
            // 2. gün = bir sonraki gün (daysPassed = 1)
            // vs.
            let currentDay = daysPassed + 1
            
            return min(currentDay, duration)
        }
        return 1
    }
    
    private func getPhaseColor(_ phase: Int) -> Color {
        let colors: [Color] = [.blue, .purple, .appSecondary, .orange, .green, .pink]
        return colors[safe: phase] ?? .appSecondary
    }
    
    private func getStatusDescription() -> String {
        let completedDays = calculateRealCompletedDays()
        let remainingDays = max(0, duration - completedDays)
        
        switch currentPhase {
        case 0:
            return String(format: L("profile.adaptation.phase0.description", table: "Profile"), completedDays, duration)
        case 1:
            return String(format: L("profile.adaptation.phase1.description", table: "Profile"), completedDays, remainingDays)
        case 2:
            return String(format: L("profile.adaptation.phase2.description", table: "Profile"), completedDays, remainingDays)
        case 3:
            return String(format: L("profile.adaptation.phase3.description", table: "Profile"), completedDays, remainingDays)
        case 4:
            if duration == 28 {
                return String(format: L("profile.adaptation.phase4.28day.description", table: "Profile"), completedDays, remainingDays)
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
                    .foregroundColor(.appTextSecondary)
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
                    .foregroundColor(.appTextSecondary)
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
                            .foregroundColor(.appTextSecondary.opacity(0.7))
                        
                        Text(duration)
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
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
                    .background(Color.appTextSecondary.opacity(0.2))
                
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
                    .foregroundColor(.appTextSecondary)
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
                .foregroundColor(.appTextSecondary)
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

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    let onImageSelected: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false // Custom crop kullanacağız
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            guard let image = info[.originalImage] as? UIImage else {
                parent.onImageSelected(nil)
                parent.dismiss()
                return
            }
            
            // Custom crop view göster
            let cropViewController = CircularCropViewController(image: image) { croppedImage in
                self.parent.onImageSelected(croppedImage)
                self.parent.dismiss()
            }
            
            picker.present(cropViewController, animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onImageSelected(nil)
            parent.dismiss()
        }
    }
}

// MARK: - Circular Crop View Controller
class CircularCropViewController: UIViewController {
    private let sourceImage: UIImage
    private let onComplete: (UIImage?) -> Void
    
    private var scrollView: UIScrollView!
    private var imageView: UIImageView!
    private var cropOverlayView: UIView!
    private var circularMask: CAShapeLayer!
    private var borderLayer: CAShapeLayer!
    
    private var cropSize: CGFloat = 0
    private var cropCenter: CGPoint = .zero
    
    init(image: UIImage, onComplete: @escaping (UIImage?) -> Void) {
        self.sourceImage = image
        self.onComplete = onComplete
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupCropArea()
        setupInitialZoom()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Navigation Bar
        let navBar = UINavigationBar()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.barStyle = .black
        navBar.tintColor = .white
        view.addSubview(navBar)
        
        let navItem = UINavigationItem(title: L("profile.avatar.crop.title", table: "Profile"))
        let cancelButton = UIBarButtonItem(
            title: L("profile.avatar.options.cancel", table: "Profile"),
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        let doneButton = UIBarButtonItem(
            title: L("profile.avatar.crop.done", table: "Profile"),
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )
        
        navItem.leftBarButtonItem = cancelButton
        navItem.rightBarButtonItem = doneButton
        navBar.setItems([navItem], animated: false)
        
        // Instruction Label
        let instructionLabel = UILabel()
        instructionLabel.text = L("profile.avatar.crop.instruction", table: "Profile")
        instructionLabel.textColor = .white
        instructionLabel.textAlignment = .center
        instructionLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        instructionLabel.numberOfLines = 0
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
        
        // Scroll View
        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 3.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Image View
        imageView = UIImageView(image: sourceImage)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        
        // Crop Overlay
        cropOverlayView = UIView()
        cropOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        cropOverlayView.isUserInteractionEnabled = false
        cropOverlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cropOverlayView)
        
        // Constraints
        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            instructionLabel.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 16),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            scrollView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            cropOverlayView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            cropOverlayView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            cropOverlayView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            cropOverlayView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])
    }
    
    private func setupCropArea() {
        guard cropOverlayView.bounds.width > 0 && cropOverlayView.bounds.height > 0 else { return }
        
        // Crop alanının boyutunu hesapla
        let availableSize = min(cropOverlayView.bounds.width, cropOverlayView.bounds.height)
        cropSize = availableSize * 0.75 // %75'ini kullan
        cropCenter = CGPoint(x: cropOverlayView.bounds.midX, y: cropOverlayView.bounds.midY)
        
        // Mevcut layer'ları temizle
        circularMask?.removeFromSuperlayer()
        borderLayer?.removeFromSuperlayer()
        
        // Circular mask oluştur
        circularMask = CAShapeLayer()
        let path = UIBezierPath(rect: cropOverlayView.bounds)
        let circlePath = UIBezierPath(
            arcCenter: cropCenter,
            radius: cropSize / 2,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: false
        )
        path.append(circlePath)
        path.usesEvenOddFillRule = true
        
        circularMask.path = path.cgPath
        circularMask.fillRule = .evenOdd
        circularMask.fillColor = UIColor.black.cgColor
        
        cropOverlayView.layer.mask = circularMask
        
        // Çember çerçevesi ekle
        borderLayer = CAShapeLayer()
        borderLayer.path = circlePath.cgPath
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.lineWidth = 3.0
        borderLayer.shadowColor = UIColor.black.cgColor
        borderLayer.shadowOffset = CGSize(width: 0, height: 1)
        borderLayer.shadowOpacity = 0.3
        borderLayer.shadowRadius = 2
        cropOverlayView.layer.addSublayer(borderLayer)
    }
    
    private func setupInitialZoom() {
        guard let image = imageView.image else { return }
        
        // Image'ın gerçek boyutlarını hesapla
        let imageSize = image.size
        let imageAspectRatio = imageSize.width / imageSize.height
        let viewAspectRatio = scrollView.bounds.width / scrollView.bounds.height
        
        var imageDisplaySize: CGSize
        
        if imageAspectRatio > viewAspectRatio {
            // Image daha geniş
            imageDisplaySize = CGSize(
                width: scrollView.bounds.width,
                height: scrollView.bounds.width / imageAspectRatio
            )
        } else {
            // Image daha uzun veya kare
            imageDisplaySize = CGSize(
                width: scrollView.bounds.height * imageAspectRatio,
                height: scrollView.bounds.height
            )
        }
        
        // Crop alanını dolduracak minimum zoom'u hesapla
        let minZoomForCrop = max(
            cropSize / imageDisplaySize.width,
            cropSize / imageDisplaySize.height
        )
        
        // Zoom scale'leri güncelle
        scrollView.minimumZoomScale = minZoomForCrop * 0.8 // Biraz daha küçük olabilsin
        scrollView.maximumZoomScale = minZoomForCrop * 4.0 // 4x zoom
        
        // Başlangıçta crop alanını dolduracak şekilde zoom yap
        scrollView.setZoomScale(minZoomForCrop * 1.1, animated: false)
        
        // Image'ı merkeze getir
        centerImageInScrollView()
    }
    
    private func centerImageInScrollView() {
        let scrollViewSize = scrollView.bounds.size
        let imageViewSize = imageView.frame.size
        
        let horizontalInset = max(0, (scrollViewSize.width - imageViewSize.width) / 2)
        let verticalInset = max(0, (scrollViewSize.height - imageViewSize.height) / 2)
        
        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
        
        // Crop alanının merkezine getir
        let cropCenterInScrollView = cropCenter
        let imageCenter = CGPoint(
            x: imageViewSize.width / 2,
            y: imageViewSize.height / 2
        )
        
        let offsetX = imageCenter.x - cropCenterInScrollView.x
        let offsetY = imageCenter.y - cropCenterInScrollView.y
        
        scrollView.setContentOffset(CGPoint(x: offsetX, y: offsetY), animated: false)
    }
    
    @objc private func cancelTapped() {
        onComplete(nil)
    }
    
    @objc private func doneTapped() {
        let croppedImage = createCroppedImage()
        onComplete(croppedImage)
    }
    
    private func createCroppedImage() -> UIImage? {
        guard let image = imageView.image else { return nil }
        
        // ScrollView'daki görünür alanı hesapla
        let zoomScale = scrollView.zoomScale
        let contentOffset = scrollView.contentOffset
        let contentInset = scrollView.contentInset
        
        // Crop alanının ScrollView koordinatlarındaki konumu
        let cropRect = CGRect(
            x: cropCenter.x - cropSize / 2,
            y: cropCenter.y - cropSize / 2,
            width: cropSize,
            height: cropSize
        )
        
        // ScrollView koordinatlarını image koordinatlarına çevir
        let imageViewBounds = imageView.bounds
        let imageSize = image.size
        
        // Image'ın gerçek boyutlarını hesapla (aspect fit)
        let imageAspectRatio = imageSize.width / imageSize.height
        let imageViewAspectRatio = imageViewBounds.width / imageViewBounds.height
        
        var imageDisplaySize: CGSize
        var imageDisplayOrigin: CGPoint
        
        if imageAspectRatio > imageViewAspectRatio {
            // Image daha geniş - width'e göre scale
            imageDisplaySize = CGSize(
                width: imageViewBounds.width,
                height: imageViewBounds.width / imageAspectRatio
            )
            imageDisplayOrigin = CGPoint(
                x: 0,
                y: (imageViewBounds.height - imageDisplaySize.height) / 2
            )
        } else {
            // Image daha uzun - height'e göre scale
            imageDisplaySize = CGSize(
                width: imageViewBounds.height * imageAspectRatio,
                height: imageViewBounds.height
            )
            imageDisplayOrigin = CGPoint(
                x: (imageViewBounds.width - imageDisplaySize.width) / 2,
                y: 0
            )
        }
        
        // Zoom ve offset'i hesaba kat
        let scaledImageSize = CGSize(
            width: imageDisplaySize.width * zoomScale,
            height: imageDisplaySize.height * zoomScale
        )
        
        let scaledImageOrigin = CGPoint(
            x: imageDisplayOrigin.x * zoomScale - contentOffset.x + contentInset.left,
            y: imageDisplayOrigin.y * zoomScale - contentOffset.y + contentInset.top
        )
        
        // Crop alanının image koordinatlarındaki karşılığı
        let cropInImageCoords = CGRect(
            x: (cropRect.minX - scaledImageOrigin.x) / zoomScale,
            y: (cropRect.minY - scaledImageOrigin.y) / zoomScale,
            width: cropSize / zoomScale,
            height: cropSize / zoomScale
        )
        
        // Image koordinatlarını pixel koordinatlarına çevir
        let scaleX = imageSize.width / imageDisplaySize.width
        let scaleY = imageSize.height / imageDisplaySize.height
        
        let finalCropRect = CGRect(
            x: max(0, cropInImageCoords.minX * scaleX),
            y: max(0, cropInImageCoords.minY * scaleY),
            width: min(imageSize.width, cropInImageCoords.width * scaleX),
            height: min(imageSize.height, cropInImageCoords.height * scaleY)
        )
        
        // Crop işlemi
        guard finalCropRect.width > 0 && finalCropRect.height > 0,
              let cgImage = image.cgImage?.cropping(to: finalCropRect) else {
            return makeCircularImage(from: image)
        }
        
        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        return makeCircularImage(from: croppedImage)
    }
    
    private func makeCircularImage(from image: UIImage) -> UIImage? {
        let size = image.size
        let minSize = min(size.width, size.height)
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: minSize, height: minSize), false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        let rect = CGRect(x: 0, y: 0, width: minSize, height: minSize)
        
        // Circular path oluştur
        context.addEllipse(in: rect)
        context.clip()
        
        // Image'ı center'a çiz
        let imageRect = CGRect(
            x: (minSize - size.width) / 2,
            y: (minSize - size.height) / 2,
            width: size.width,
            height: size.height
        )
        image.draw(in: imageRect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - UIScrollViewDelegate
extension CircularCropViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageInScrollView()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        centerImageInScrollView()
    }
}

struct ProfileScreenView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileScreenView()
            .environmentObject(LanguageManager.shared)
    }
}

// MARK: - Debug Premium Card
struct DebugPremiumCard: View {
    @State private var isPremium: Bool = UserDefaults.standard.bool(forKey: "debug_premium_status")
    
    var body: some View {
        PSCard {
            VStack(spacing: PSSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: PSSpacing.xs) {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: PSIconSize.small))
                                .foregroundColor(.orange)
                            
                            Text("Debug Modu")
                                .font(PSTypography.headline)
                                .foregroundColor(.appText)
                        }
                        
                        Text("Premium durumunu değiştirin")
                            .font(PSTypography.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    Spacer()
                }
                
                HStack {
                    Text("Premium Durumu")
                        .font(PSTypography.body)
                        .foregroundColor(.appText)
                    
                    Spacer()
                    
                    Toggle("", isOn: $isPremium)
                        .tint(.appPrimary)
                        .scaleEffect(0.8)
                        .onChange(of: isPremium) { oldValue, newValue in
                            UserDefaults.standard.set(newValue, forKey: "debug_premium_status")
                            
                            // MainScreenViewModel'lere değişikliği bildir
                            NotificationCenter.default.post(
                                name: NSNotification.Name("PremiumStatusChanged"),
                                object: nil,
                                userInfo: ["isPremium": newValue]
                            )
                        }
                }
                
                HStack {
                    Image(systemName: isPremium ? "crown.fill" : "person.fill")
                        .font(.caption)
                        .foregroundColor(isPremium ? .yellow : .gray)
                    
                    Text(isPremium ? "Premium Kullanıcı" : "Free Kullanıcı")
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                    
                    Spacer()
                }
                .padding(.top, PSSpacing.xs)
            }
        }
    }
}

// MARK: - Schedule Change Undo Banner
struct UndoScheduleChangeCard: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    @State private var isUndoing = false
    @State private var undoError: String? = nil
    
    // Computed properties for alert binding
    private var isShowingUndoError: Binding<Bool> {
        Binding(
            get: { undoError != nil },
            set: { if !$0 { undoError = nil } }
        )
    }
    
    private var undoErrorMessage: String {
        undoError ?? L("general.unknownError", table: "Profile")
    }
    
    // Extracted background view to fix compiler error
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: PSCornerRadius.large)
            .fill(Color.orange.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: PSCornerRadius.large)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
    }

    var body: some View {
        PSCard {
            VStack(spacing: PSSpacing.md) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: PSIconSize.medium))
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: PSSpacing.xs) {
                        Text(L("profile.scheduleChange.undo.title", table: "Profile"))
                            .font(PSTypography.headline)
                            .foregroundColor(.appText)
                        
                        Text(L("profile.scheduleChange.undo.message", table: "Profile"))
                            .font(PSTypography.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    Spacer()
                }
                
                Button(action: {
                    undoScheduleChange()
                }) {
                    HStack {
                        if isUndoing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: PSIconSize.small))
                        }
                        
                        Text(L("profile.scheduleChange.undo.button", table: "Profile"))
                            .font(PSTypography.body)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, PSSpacing.lg)
                    .padding(.vertical, PSSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                            .fill(Color.orange)
                    )
                }
                .disabled(isUndoing)
            }
        }
        .background(cardBackground)
        .alert(
            L("general.error", table: "Profile"),
            isPresented: isShowingUndoError
        ) {
            Button(L("general.ok", table: "Profile"), role: .cancel) {
                undoError = nil
            }
        } message: {
            Text(undoErrorMessage)
        }
    }
    
    private func undoScheduleChange() {
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

// MARK: - Adaptation Debug Card
struct AdaptationDebugCard: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    @State private var isSettingDebugDay = false
    @State private var debugError: String? = nil
    
    // Computed properties for alert binding
    private var isShowingDebugError: Binding<Bool> {
        Binding(
            get: { debugError != nil },
            set: { if !$0 { debugError = nil } }
        )
    }
    
    private var debugErrorMessage: String {
        debugError ?? L("general.unknownError", table: "Profile")
    }
    
    // Extracted background view to fix compiler error
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: PSCornerRadius.large)
            .fill(Color.purple.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: PSCornerRadius.large)
                    .stroke(Color.purple.opacity(0.2), lineWidth: 1)
            )
    }

    var body: some View {
        PSCard {
            VStack(spacing: PSSpacing.lg) {
                // Header
                HStack {
                    Image(systemName: "ladybug.fill")
                        .font(.system(size: PSIconSize.medium))
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: PSSpacing.xs) {
                        Text(L("profile.adaptation.debug.title", table: "Profile"))
                            .font(PSTypography.headline)
                            .foregroundColor(.appText)
                        
                        Text(L("profile.adaptation.debug.description", table: "Profile"))
                            .font(PSTypography.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    Spacer()
                }
                
                if let schedule = viewModel.activeSchedule {
                    VStack(spacing: PSSpacing.md) {
                        // Current day info
                        HStack {
                            Text(L("profile.adaptation.debug.currentDay", table: "Profile"))
                                .font(PSTypography.body)
                                .foregroundColor(.appText)
                            
                            Spacer()
                            
                            Text("\(getCurrentDay(schedule: schedule)). gün")
                                .font(PSTypography.body)
                                .foregroundColor(.appPrimary)
                                .padding(.horizontal, PSSpacing.md)
                                .padding(.vertical, PSSpacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: PSCornerRadius.small)
                                        .fill(Color.appPrimary.opacity(0.1))
                                )
                        }
                        
                        // Debug slider
                        VStack(alignment: .leading, spacing: PSSpacing.sm) {
                            HStack {
                                Text(L("profile.adaptation.debug.setDay", table: "Profile"))
                                    .font(PSTypography.body)
                                    .foregroundColor(.appText)
                                
                                Spacer()
                                
                                Text("\(viewModel.debugAdaptationDay). gün")
                                    .font(PSTypography.body)
                                    .foregroundColor(.purple)
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { Double(viewModel.debugAdaptationDay) },
                                    set: { viewModel.debugAdaptationDay = Int($0) }
                                ),
                                in: 1...Double(viewModel.maxDebugDays),
                                step: 1
                            )
                            .tint(.purple)
                            
                            HStack {
                                Text("1. gün")
                                    .font(PSTypography.caption)
                                    .foregroundColor(.appTextSecondary)
                                
                                Spacer()
                                
                                Text("\(viewModel.maxDebugDays). gün")
                                    .font(PSTypography.caption)
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                        
                        // Apply button
                        Button(action: {
                            setDebugDay()
                        }) {
                            HStack {
                                if isSettingDebugDay {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: PSIconSize.small))
                                }
                                
                                Text(L("profile.adaptation.debug.apply", table: "Profile"))
                                    .font(PSTypography.body)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, PSSpacing.lg)
                            .padding(.vertical, PSSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                                    .fill(Color.purple)
                            )
                        }
                        .disabled(isSettingDebugDay)
                    }
                } else {
                    Text(L("profile.adaptation.debug.noSchedule", table: "Profile"))
                        .font(PSTypography.body)
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, PSSpacing.md)
                }
            }
        }
        .background(cardBackground)
        .alert(
            L("general.error", table: "Profile"),
            isPresented: isShowingDebugError
        ) {
            Button(L("general.ok", table: "Profile"), role: .cancel) {
                debugError = nil
            }
        } message: {
            Text(debugErrorMessage)
        }
    }
    
    private func getCurrentDay(schedule: UserSchedule) -> Int {
        let calendar = Calendar.current
        let startDate = schedule.updatedAt
        let currentDate = Date()
        
        let startOfStartDate = calendar.startOfDay(for: startDate)
        let startOfCurrentDate = calendar.startOfDay(for: currentDate)
        
        let components = calendar.dateComponents([.day], from: startOfStartDate, to: startOfCurrentDate)
        let daysPassed = components.day ?? 0
        
        return daysPassed + 1
    }
    
    private func setDebugDay() {
        isSettingDebugDay = true
        
        Task {
            do {
                try await viewModel.setAdaptationDebugDay(viewModel.debugAdaptationDay)
                await MainActor.run {
                    isSettingDebugDay = false
                }
            } catch {
                await MainActor.run {
                    debugError = error.localizedDescription
                    isSettingDebugDay = false
                }
            }
        }
    }
}

// MARK: - Adaptation Completed Celebration Card
struct AdaptationCompletedCard: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    @Binding var showingCelebration: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: PSSpacing.lg) {
            // Trophy Icon and Title
            HStack(spacing: PSSpacing.md) {
                                                 // Trophy Lottie Animation
                LottieView(animation: .named("trophy"))
                    .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .loop)))
                    .animationSpeed(0.8)
                    .frame(width: 60, height: 60)
                
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text(L("profile.adaptation.completed.title", table: "Profile"))
                        .font(PSTypography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.appText)
                    
                    Text(String(format: L("profile.adaptation.completed.days", table: "Profile"), viewModel.completedAdaptationDays))
                        .font(PSTypography.body)
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
            }
            
            // Congratulations Message
            Text(L("profile.adaptation.completed.message", table: "Profile"))
                .font(PSTypography.body)
                .foregroundColor(.appText)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            // Celebrate Button
            Button(action: {
                showingCelebration = true
            }) {
                HStack(spacing: PSSpacing.sm) {
                    Image(systemName: "party.popper.fill")
                        .font(.system(size: PSIconSize.small))
                    
                    Text(L("profile.adaptation.completed.celebrate", table: "Profile"))
                        .font(PSTypography.body)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, PSSpacing.lg)
                .padding(.vertical, PSSpacing.md)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.orange, .pink]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(PSCornerRadius.medium)
                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .scaleEffect(showingCelebration ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: showingCelebration)
        }
        .padding(PSSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: PSCornerRadius.large)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.orange.opacity(0.05),
                            Color.pink.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: PSCornerRadius.large)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.orange.opacity(0.3), .pink.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
                 .shadow(color: .orange.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Celebration Overlay
struct CelebrationOverlay: View {
    @Binding var isShowing: Bool
    
    var body: some View {
        // Direkt animasyonu başlat, arkaplan şeffaf ve ekranı kaplasın
        LottieView(animation: .named("celebration"))
            .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
            .animationSpeed(1.0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .allowsHitTesting(false) // Kullanıcı etkileşimini engelleme
            .onAppear {
                // Animasyon bitince otomatik kapat
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isShowing = false
                    }
                }
            }
    }
}
