import SwiftUI
import SwiftData

struct ProfileScreenView: View {
    @StateObject var viewModel = ProfileScreenViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showEmojiPicker = false
    @State private var isPickingCoreEmoji = true
    @State private var showLoginSheet = false
    @State private var showLogoutSheet = false
    @State private var navigateToSettings = false
    @StateObject private var authManager = AuthManager.shared
    @State private var showSuccessMessage = false
    
    var body: some View {
        return NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Premium Butonu
                        PremiumButton()
                        
                        // Profil Bilgileri
                        ProfileHeaderSection(
                            showLoginSheet: $showLoginSheet, 
                            showLogoutSheet: $showLogoutSheet,
                            navigateToSettings: $navigateToSettings, 
                            authManager: authManager
                        )
                        
                        // Streak Bölümü
                        StreakSection(viewModel: viewModel)
                        
                        // Adaptasyon Aşaması Bölümü
                        AdaptationPhaseSection(viewModel: viewModel)
                        
                        // Emoji Özelleştirme
                        EmojiCustomizationSection(viewModel: viewModel, showEmojiPicker: $showEmojiPicker, isPickingCoreEmoji: $isPickingCoreEmoji)
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 24)
                }
                
                // Başarılı giriş mesajı
                if showSuccessMessage {
                    VStack {
                        Text("profile.login.success", tableName: "Profile")
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
            .navigationTitle("Profil")
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
    }
}

// MARK: - Premium Butonu
struct PremiumButton: View {
    var body: some View {
        return Button(action: {
            // Premium işlevselliği
        }) {
            HStack {
                Text("profile.premium.button", tableName: "Profile")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("profile.premium.go", tableName: "Profile")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                    )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appSecondary)
            )
        }
        .padding(.top, 16)
    }
}

// MARK: - Profil Başlık Bölümü
struct ProfileHeaderSection: View {
    @Binding var showLoginSheet: Bool
    @Binding var showLogoutSheet: Bool
    @Binding var navigateToSettings: Bool
    @ObservedObject var authManager: AuthManager
    
    // Kullanıcının displayName değeri olup olmadığını kontrol et
    private func hasDisplayName() -> Bool {
        guard let user = authManager.currentUser else { return false }
        return !user.displayName.isEmpty
    }
    
    var body: some View {
        return HStack(alignment: .top, spacing: 10) {
            // Profil resmi - Artık sadece offline kullanıcı var
            Button(action: {
                // Profil bilgilerini düzenlemek için login sheet'i göster
                showLoginSheet = true
            }) {
                // Yerel kullanıcı profil resmi
                if let user = authManager.currentUser, !user.displayName.isEmpty {
                    // Kullanıcının adının baş harfini avatar olarak kullan
                    Text(String(user.displayName.prefix(1).uppercased()))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(Color.appPrimary)
                        )
                } else {
                    // Anonim profil resmi
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.appSecondaryText)
                        .background(
                            Circle()
                                .fill(Color.appCardBackground)
                                .frame(width: 60, height: 60)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // Başlık
                if let user = authManager.currentUser {
                    if !user.displayName.isEmpty {
                        Text(user.displayName)
                            .font(.headline)
                            .fontWeight(.bold)
                    } else {
                        Text(NSLocalizedString("localUser.defaultName", tableName: "Auth", comment: "Default local user name"))
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    
                    // Kullanıcı durumu
                    Text("profile.user.local", tableName: "Profile")
                        .font(.subheadline)
                        .foregroundColor(.appSecondaryText)
                } else {
                    // Bu durum gerçekleşmemeli, çünkü offline modda her zaman bir kullanıcı var
                    Text("profile.login.title", tableName: "Profile")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("profile.login.status.unsigned", tableName: "Profile")
                        .font(.subheadline)
                        .foregroundColor(.appSecondaryText)
                }
            }
            
            Spacer()
            
            // Ayarlar butonu
            Button(action: {
                navigateToSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.appSecondaryText)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
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
            Text("profile.logout.title", tableName: "Profile")
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
                Text("profile.login.signout", tableName: "Profile")
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
            Text("profile.edit.title", tableName: "Profile")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.appText)
                .padding(.top, 24)
            
            // Açıklama
            Text("profile.edit.description", tableName: "Profile")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.appSecondaryText)
                .padding(.horizontal, 24)
            
            // Kullanıcı adı düzenleme formu
            VStack(spacing: 16) {
                // İsim girişi
                TextField(
                    NSLocalizedString("profile.edit.name.placeholder", tableName: "Profile", comment: "Placeholder for display name"),
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
                    Text("profile.edit.save", tableName: "Profile")
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

// MARK: - Streak Bölümü
struct StreakSection: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    
    var body: some View {
        return VStack(alignment: .leading, spacing: 12) {
            Text("profile.streak.title", tableName: "Profile")
                .font(.headline)
                .foregroundColor(.appText)
            
            HStack(spacing: 20) {
                // Mevcut Streak
                VStack(spacing: 8) {
                    Text(String(viewModel.currentStreak))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.appPrimary)
                    
                    Text("profile.streak.current", tableName: "Profile")
                        .font(.caption)
                        .foregroundColor(.appSecondaryText)
                    
                    Text(viewModel.currentStreak == 1 ? "profile.streak.day" : "profile.streak.days", tableName: "Profile")
                        .font(.caption2)
                        .foregroundColor(.appSecondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appCardBackground)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                
                // En Uzun Streak
                VStack(spacing: 8) {
                    Text(String(viewModel.longestStreak))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.appSecondary)
                    
                    Text("profile.streak.longest", tableName: "Profile")
                        .font(.caption)
                        .foregroundColor(.appSecondaryText)
                    
                    Text(viewModel.longestStreak == 1 ? "profile.streak.day" : "profile.streak.days", tableName: "Profile")
                        .font(.caption2)
                        .foregroundColor(.appSecondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appCardBackground)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Adaptasyon Aşaması Bölümü
struct AdaptationPhaseSection : View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingResetAlert = false
    @State private var isResetting = false
    @State private var resetError: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Adaptasyon Aşaması")
                .font(.headline)
                .foregroundColor(.appText)
            
            if let schedule = viewModel.activeSchedule {
                AdaptationProgressView(
                    duration: viewModel.adaptationDuration,
                    currentPhase: viewModel.adaptationPhase,
                    phaseDescription: viewModel.adaptationPhaseDescription,
                    showingResetAlert: $showingResetAlert,
                    isResetting: isResetting
                )
            } else {
                // Eğer aktif program yoksa, boş bir görünüm göster
                EmptyAdaptationView()
            }
        }
        .alert("Adaptasyonu Sıfırla", isPresented: $showingResetAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sıfırla", role: .destructive) {
                resetAdaptationPhase()
            }
        } message: {
            Text("Adaptasyon süreci 1. günden tekrar başlatılacak. Bu işlemi gerçekleştirmek istediğinize emin misiniz?")
        }
        .alert("Hata", isPresented: .init(get: { resetError != nil }, set: { if !$0 { resetError = nil } })) {
            Button("Tamam", role: .cancel) {
                resetError = nil
            }
        } message: {
            Text(resetError ?? "Bilinmeyen bir hata oluştu")
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

// MARK: - Boş Adaptasyon Görünümü
struct EmptyAdaptationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Aktif program bulunamadı")
                .font(.subheadline)
                .foregroundColor(.appSecondaryText)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Adaptasyon İlerleme Görünümü
struct AdaptationProgressView: View {
    let duration: Int // Toplam gün sayısı
    let currentPhase: Int
    let phaseDescription: String
    @Binding var showingResetAlert: Bool
    let isResetting: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        // Hesaplamalar
        let completedDays = calculateCompletedDays()
        let progress = Float(completedDays) / Float(duration)
        let phaseColor = phaseColors[safe: currentPhase] ?? .appSecondary
        
        VStack(alignment: .leading, spacing: 20) {
            // Aşama Bilgisi
            PhaseInfoView(
                phaseColor: phaseColor,
                description: phaseDescription,
                statusText: getAdaptationStatusText(phase: currentPhase, completedDays: completedDays, duration: duration),
                showingResetAlert: $showingResetAlert,
                isResetting: isResetting
            )
            
            // İlerleme göstergesi
            ProgressIndicatorView(
                completedDays: completedDays,
                totalDays: duration,
                progress: progress,
                currentPhase: currentPhase,
                phaseColor: phaseColor
            )
            
            // Adaptasyon ipuçları
            adaptationTip(for: currentPhase)
                .padding(.top, 8)
            
            // Adaptasyon zaman çizelgesi
            adaptationTimelineView(for: currentPhase, totalDays: duration)
                .padding(.top, 8)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.3), value: currentPhase)
    }
    
    // Aşama renkleri
    private var phaseColors: [Color] {
        [.blue, .purple, .appSecondary, .orange, .green, .pink]
    }
    
    // Tamamlanan gün sayısını hesapla
    private func calculateCompletedDays() -> Int {
        if duration == 28 {
            // 28 günlük adaptasyon süresi için aşamalar
            switch currentPhase {
            case 0: return 0  // Başlangıç aşaması
            case 1: return 6  // Uyum aşaması
            case 2: return 12 // Adaptasyon aşaması
            case 3: return 18 // İleri adaptasyon
            case 4: return 24 // Tam adaptasyon
            case 5...: return 28 // Tam adaptasyon+
            default: return 0
            }
        } else {
            // 21 günlük adaptasyon süresi için aşamalar
            switch currentPhase {
            case 0: return 0  // Başlangıç aşaması
            case 1: return 6  // Uyum aşaması
            case 2: return 12 // Adaptasyon aşaması
            case 3: return 18 // İleri adaptasyon
            case 4...: return 21 // Tam adaptasyon
            default: return 0
            }
        }
    }
    
    // Adaptasyon ipuçları View'ı
    private func adaptationTip(for phase: Int) -> some View {
        let (title, description) = adaptationPhaseInfo(phase)
        
        let phaseColor = phaseColors[safe: phase] ?? .appSecondary
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(phaseColor)
                
                Text("Adaptasyon İpucu")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
            }
            
            if !title.isEmpty {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appText)
            }
            
            Text(description)
                .font(.footnote)
                .foregroundColor(.appSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(phaseColor.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(phaseColor.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    // Adaptasyon zaman çizelgesi View'ı
    private func adaptationTimelineView(for phase: Int, totalDays: Int) -> some View {
        let phaseColors = self.phaseColors
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appText)
                
                Text("Adaptasyon Süreci")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                // Fazla kod yükünü azaltmak için zaman çizelgesini daha basit gösterelim
                TimelineItemsView(phase: phase, totalDays: totalDays, phaseColors: phaseColors)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }
    
    // Adaptasyon aşaması bilgisi
    private func adaptationPhaseInfo(_ phase: Int) -> (String, String) {
        switch phase {
        case 0:
            return ("Başlangıç Aşaması", "Uyku programına yeni başladın. Program günlük rutinin haline gelene kadar sabırla devam et. Güvenliğin için uyanık kalmakta zorlanıyorsan kısa molalar ver.")
        case 1:
            return ("Uyum Aşaması", "Vücudun yeni uyku düzenine alışmaya başladı. Uyku kaliteni artırmak için düzenli uyuma saatlerine dikkat etmelisin. Bu kritik dönemde programa sadık kalmak çok önemli.")
        case 2:
            return ("Adaptasyon Aşaması", "İyi ilerliyorsun! Bu aşamada uyku kalitenin artmaya başladığını göreceksin. REM ve derin uyku verimliliğin artıyor. Programına sadık kalmaya devam et.")
        case 3:
            return ("İleri Adaptasyon", "Harika! Vücudun yeni uyku düzenine oldukça iyi adapte oldu. Artık daha verimli uyuyorsun ve enerjik hissediyorsun. Uyku paterni neredeyse tamamlanmak üzere.")
        case 4:
            return ("Tam Adaptasyon", "Tebrikler! Polifazik uyku düzenine tamamen adapte oldun. Bu düzeni korumak için programına sadık kalmaya devam et. Artık maksimum uyku verimliliğine sahipsin.")
        case 5:
            return ("Tam Adaptasyon+", "Mükemmel! Zor bir uyku programına tamamen uyum sağladın. Vücudun artık yeni düzende tamamen verimli çalışıyor. Bu düzeni sürdürdükçe faydalarını en üst düzeyde göreceksin.")
        default:
            return ("Adaptasyon Henüz Başlamadı", "Adaptasyon sürecine başlamak için programa uygun şekilde uyumaya başla.")
        }
    }
    
    // Adaptasyon durumu metni
    private func getAdaptationStatusText(phase: Int, completedDays: Int, duration: Int) -> String {
        switch phase {
        case 0:
            return "Başlangıç günüdür. Yeni uyku programına alışma sürecin şimdi başlıyor."
        case 1:
            return "Uyum aşamasındasın (1-7 gün). Bu kritik dönemde programa sadık kalmak çok önemli."
        case 2:
            return "Adaptasyon aşamasındasın (8-14 gün). Uyku kalitenin artmaya başlaması bekleniyor."
        case 3:
            return "İleri adaptasyon aşamasındasın (15-20 gün). Vücudun yeni düzene neredeyse alıştı."
        case 4:
            if duration == 28 {
                return "Tam adaptasyon aşamasındasın (21-27 gün). Programda istikrarlı kalman önemli."
            } else {
                return "Tam adaptasyon! (21+ gün) Polifazik uyku düzenine tamamen adapte oldun."
            }
        case 5...:
            return "Tam adaptasyon+! (28+ gün) En zor uyku programlarına bile tamamen adapte oldun."
        default:
            return "Adaptasyon aşaması henüz başlamadı."
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
            
            // Adaptasyon sıfırlama butonu
            Button(action: {
                showingResetAlert = true
            }) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(phaseColor)
            }
            .disabled(isResetting)
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
                Text("Adaptasyon İlerlemesi")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appText)
                
                Spacer()
                
                Text(String(format: "%d / %d gün", completedDays, totalDays))
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
            Text(String(format: "%%%d Tamamlandı", Int(progress * 100)))
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
                .frame(width: max(0, min(UIScreen.main.bounds.width * 0.7, CGFloat(progress) * UIScreen.main.bounds.width * 0.7)), height: 12)
                .shadow(color: phaseColor.opacity(0.4), radius: 2, x: 0, y: 1)
            
            // İlerleme göstergesi noktaları
            ProgressDots(currentPhase: currentPhase, totalDays: totalDays)
        }
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
                title: "Başlangıç Aşaması", 
                duration: "0 gün", 
                status: phase >= 0 ? (phase > 0 ? "Tamamlandı" : "Devam Ediyor") : "Bekliyor", 
                isCompleted: phase > 0,
                isActive: phase == 0,
                color: phaseColors[safe: 0] ?? .blue
            )
            
            // Uyum aşaması
            timelineItem(
                icon: "2.circle.fill", 
                title: "Uyum Aşaması", 
                duration: "1-7 gün", 
                status: phase >= 1 ? (phase > 1 ? "Tamamlandı" : "Devam Ediyor") : "Bekliyor", 
                isCompleted: phase > 1, 
                isActive: phase == 1,
                color: phaseColors[safe: 1] ?? .purple
            )
            
            // Adaptasyon aşaması
            timelineItem(
                icon: "3.circle.fill", 
                title: "Adaptasyon Aşaması", 
                duration: "8-14 gün", 
                status: phase >= 2 ? (phase > 2 ? "Tamamlandı" : "Devam Ediyor") : "Bekliyor", 
                isCompleted: phase > 2, 
                isActive: phase == 2,
                color: phaseColors[safe: 2] ?? .appSecondary
            )
            
            // İleri adaptasyon
            timelineItem(
                icon: "4.circle.fill", 
                title: "İleri Adaptasyon", 
                duration: "15-20 gün", 
                status: phase >= 3 ? (phase > 3 ? "Tamamlandı" : "Devam Ediyor") : "Bekliyor", 
                isCompleted: phase > 3, 
                isActive: phase == 3,
                color: phaseColors[safe: 3] ?? .orange
            )
            
            if totalDays == 28 {
                // 28 günlük program için tam adaptasyon
                timelineItem(
                    icon: "5.circle.fill", 
                    title: "Tam Adaptasyon", 
                    duration: "21-27 gün", 
                    status: phase >= 4 ? (phase > 4 ? "Tamamlandı" : "Devam Ediyor") : "Bekliyor", 
                    isCompleted: phase > 4, 
                    isActive: phase == 4,
                    color: phaseColors[safe: 4] ?? .green
                )
                
                // 28 günlük program için tam adaptasyon+
                timelineItem(
                    icon: "checkmark.circle.fill", 
                    title: "Tam Adaptasyon+", 
                    duration: "28+ gün", 
                    status: phase >= 5 ? "Devam Ediyor" : "Bekliyor", 
                    isCompleted: false, 
                    isActive: phase >= 5,
                    isLast: true,
                    color: phaseColors[safe: 5] ?? .pink
                )
            } else {
                // 21 günlük program için tam adaptasyon
                timelineItem(
                    icon: "checkmark.circle.fill", 
                    title: "Tam Adaptasyon", 
                    duration: "21+ gün", 
                    status: phase >= 4 ? "Devam Ediyor" : "Bekliyor", 
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
        HStack(alignment: .top, spacing: 12) {
            // Icon ve dikey çizgi
            VStack(spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isCompleted ? .green : (isActive ? color : .gray.opacity(0.5)))
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(isCompleted ? .green.opacity(0.1) : (isActive ? color.opacity(0.1) : .clear))
                            .frame(width: 36, height: 36)
                            .opacity(isCompleted || isActive ? 1 : 0)
                    )
                
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 2, height: 30)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(isActive ? color : .appText)
                    .fontWeight(isActive ? .bold : .medium)
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(.appSecondaryText)
                        
                        Text(duration)
                            .font(.caption)
                            .foregroundColor(.appSecondaryText)
                    }
                    
                    Spacer()
                    
                    Text(status)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(statusColor(status: status))
                        )
                        .foregroundColor(.white)
                }
            }
            .padding(.trailing, 8)
        }
    }
    
    // Durum rengi
    private func statusColor(status: String) -> Color {
        switch status {
        case "Tamamlandı":
            return .green
        case "Devam Ediyor":
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

// MARK: - Emoji Özelleştirme Bölümü
struct EmojiCustomizationSection: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    @Binding var showEmojiPicker: Bool
    @Binding var isPickingCoreEmoji: Bool
    
    var body: some View {
        return VStack(alignment: .leading, spacing: 12) {
            Text("Emoji Özelleştirme")
                .font(.headline)
                .foregroundColor(.appText)
            
            VStack(spacing: 16) {
                // Ana Uyku Emojisi
                HStack {
                    Text("Ana Uyku Bloğu Emojisi")
                        .font(.subheadline)
                        .foregroundColor(.appText)
                    
                    Spacer()
                    
                    Button(action: {
                        isPickingCoreEmoji = true
                        showEmojiPicker = true
                    }) {
                        Text(viewModel.selectedCoreEmoji)
                            .font(.system(size: 24))
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.appPrimary.opacity(0.1))
                            )
                    }
                }
                
                Divider()
                
                // Şekerleme Emojisi
                HStack {
                    Text("Şekerleme Bloğu Emojisi")
                        .font(.subheadline)
                        .foregroundColor(.appText)
                    
                    Spacer()
                    
                    Button(action: {
                        isPickingCoreEmoji = false
                        showEmojiPicker = true
                    }) {
                        Text(viewModel.selectedNapEmoji)
                            .font(.system(size: 24))
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.appPrimary.opacity(0.1))
                            )
                    }
                }
                
                // Bilgi notu
                Text("Seçtiğin emojiler takvim, uyku takibi ve grafikler gibi uygulamanın tüm bölümlerinde kullanılacaktır.")
                    .font(.caption)
                    .foregroundColor(.appSecondaryText)
                    .padding(.top, 6)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appCardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
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
            Text("Emoji Seç")
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
                Text("Kaydet")
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
    }
}
