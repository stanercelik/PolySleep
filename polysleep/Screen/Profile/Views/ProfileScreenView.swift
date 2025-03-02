import SwiftUI
import SwiftData
import Supabase

struct ProfileScreenView: View {
    @StateObject var viewModel = ProfileScreenViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showEmojiPicker = false
    @State private var isPickingCoreEmoji = true
    @State private var showLoginSheet = false
    @State private var navigateToSettings = false
    @StateObject private var authManager = AuthManager.shared
    @State private var showSuccessMessage = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Premium Butonu
                        PremiumButton()
                        
                        // Profil Bilgileri
                        ProfileHeaderSection(showLoginSheet: $showLoginSheet, navigateToSettings: $navigateToSettings, authManager: authManager)
                        
                        // Streak Bölümü
                        StreakSection(viewModel: viewModel)
                        
                        // İlerleme Bölümü
                        ProgressSection(viewModel: viewModel)
                        
                        // Rozet Bölümü
                        BadgesSection(viewModel: viewModel)
                        
                        // Emoji Özelleştirme
                        EmojiCustomizationSection(viewModel: viewModel, showEmojiPicker: $showEmojiPicker, isPickingCoreEmoji: $isPickingCoreEmoji)
                    }
                    .padding(.horizontal)
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
            .sheet(isPresented: $viewModel.showBadgeDetail, content: {
                if let badge = viewModel.selectedBadge {
                    BadgeDetailView(badge: badge)
                        .presentationDetents([.medium])
                }
            })
            .navigationDestination(isPresented: $navigateToSettings) {
                Text("Ayarlar") // Burada gerçek Ayarlar sayfası olacak
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
        Button(action: {
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
    @Binding var navigateToSettings: Bool
    @ObservedObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                // Profil resmi (giriş yapılmışsa kullanıcı bilgisi, yapılmamışsa anonim)
                Button(action: {
                    if !authManager.isAuthenticated {
                        showLoginSheet = true
                    }
                }) {
                    if authManager.isAuthenticated, let user = authManager.currentUser {
                        // Kullanıcı giriş yapmışsa
                        Group {
                            if user.userMetadata["provider"] as? String == "apple" {
                                // Apple ile giriş yapıldıysa
                                ZStack {
                                    Circle()
                                        .fill(Color.black)
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "applelogo")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                            } else {
                                // Diğer sağlayıcılar için
                                Text(String(user.email?.prefix(1) ?? "U"))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(
                                        Circle()
                                            .fill(Color.appPrimary)
                                    )
                            }
                        }
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
                    if authManager.isAuthenticated, let user = authManager.currentUser {
                        if user.userMetadata["provider"] as? String == "apple" {
                            if let fullName = user.userMetadata["full_name"] as? String, !fullName.isEmpty {
                                Text(fullName)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.appText)
                            } else {
                                Text("Apple")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.appText)
                            }
                        } else {
                            Text("profile.backup.title", tableName: "Profile")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.appText)
                        }
                    } else {
                        Text("profile.backup.title", tableName: "Profile")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.appText)
                    }
                    
                    // Rozetler
                    HStack(spacing: 8) {
                        // Maksimum 3 rozet göster
                        ForEach(0..<min(3, 3)) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.appAccent)
                        }
                        
                        // Başarı sayısı
                        Text("3 \(Text("profile.achievements", tableName: "Profile"))")
                            .font(.caption)
                            .foregroundColor(.appSecondaryText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.appCardBackground)
                            )
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
            
            // Kullanıcı giriş yapmışsa çıkış butonu göster
            if authManager.isAuthenticated, let user = authManager.currentUser {
                VStack(spacing: 12) {
                    // Kullanıcı email bilgisi
                    Text("\(Text("profile.login.status.signed", tableName: "Profile")): \(user.email ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.appSecondaryText)
                    
                    // Çıkış butonu
                    Button(action: {
                        Task {
                            await authManager.signOut()
                        }
                    }) {
                        Text("profile.login.signout", tableName: "Profile")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.8))
                            )
                    }
                }
                .padding(.top, 8)
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

// MARK: - Giriş Sheet Görünümü
struct LoginSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authManager: AuthManager
    var onSuccessfulLogin: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Başlık
            Text("profile.login.title", tableName: "Profile")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.appText)
                .padding(.top, 24)
            
            // Açıklama
            Text("profile.login.description", tableName: "Profile")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.appSecondaryText)
                .padding(.horizontal, 24)
            
            // Giriş butonları
            VStack(spacing: 16) {
                // Apple ile giriş
                Button(action: {
                    print("PolySleep Debug: Apple ID ile giriş butonu tıklandı")
                    Task {
                        print("PolySleep Debug: Apple ID ile giriş Task başladı")
                        await authManager.signInWithApple()
                        print("PolySleep Debug: Apple ID ile giriş Task tamamlandı")
                        if authManager.isAuthenticated {
                            print("PolySleep Debug: Kullanıcı kimliği doğrulandı, sheet kapatılıyor")
                            dismiss()
                            onSuccessfulLogin()
                        } else {
                            print("PolySleep Debug: Kullanıcı kimliği doğrulanamadı")
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 20))
                        
                        Text("profile.login.apple", tableName: "Profile")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black)
                    )
                }
                .disabled(authManager.isLoading)
                
                // Google ile giriş
                Button(action: {
                    Task {
                        await authManager.signInWithGoogle()
                        if authManager.isAuthenticated {
                            dismiss()
                            onSuccessfulLogin()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 20))
                        
                        Text("profile.login.google", tableName: "Profile")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
                }
                .disabled(authManager.isLoading)
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
    }
}

// MARK: - Streak Bölümü
struct StreakSection: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

// MARK: - İlerleme Bölümü
struct ProgressSection: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("profile.progress.title", tableName: "Profile")
                .font(.headline)
                .foregroundColor(.appText)
            
            VStack(spacing: 12) {
                // İlerleme çubuğu
                ProgressBar(value: viewModel.dailyProgress)
                    .frame(height: 12)
                
                HStack {
                    Text("\(viewModel.completedDays)/\(viewModel.totalDays) \(Text("profile.progress.completed", tableName: "Profile"))")
                        .font(.caption)
                        .foregroundColor(.appSecondaryText)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.dailyProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.appPrimary)
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
}

// MARK: - Rozet Bölümü
struct BadgesSection: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("profile.badges.title", tableName: "Profile")
                .font(.headline)
                .foregroundColor(.appText)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(viewModel.badges) { badge in
                    BadgeView(badge: badge)
                        .onTapGesture {
                            viewModel.showBadgeDetails(badge: badge)
                        }
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
}

// MARK: - Rozet Görünümü
struct BadgeView: View {
    let badge: Badge
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: badge.icon)
                .font(.system(size: 24))
                .foregroundColor(badge.isUnlocked ? .appAccent : .gray.opacity(0.5))
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(badge.isUnlocked ? Color.appAccent.opacity(0.2) : Color.gray.opacity(0.1))
                )
            
            Text(badge.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(badge.isUnlocked ? .appText : .appSecondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(1)
        }
        .frame(height: 80)
        .opacity(badge.isUnlocked ? 1.0 : 0.6)
    }
}

// MARK: - Rozet Detay Görünümü
struct BadgeDetailView: View {
    let badge: Badge
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Rozet ikonu
            Image(systemName: badge.icon)
                .font(.system(size: 60))
                .foregroundColor(badge.isUnlocked ? .appAccent : .gray.opacity(0.5))
                .frame(width: 100, height: 100)
                .background(
                    Circle()
                        .fill(badge.isUnlocked ? Color.appAccent.opacity(0.2) : Color.gray.opacity(0.1))
                )
            
            // Rozet adı
            Text(badge.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.appText)
            
            // Durum
            Text(badge.isUnlocked ? "profile.badges.unlocked" : "profile.badges.locked", tableName: "Profile")
                .font(.subheadline)
                .foregroundColor(badge.isUnlocked ? .appSecondary : .appSecondaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(badge.isUnlocked ? Color.appSecondary.opacity(0.2) : Color.gray.opacity(0.1))
                )
            
            // Açıklama
            Text(badge.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.appSecondaryText)
                .padding(.horizontal)
            
            Spacer()
            
            // Kapat butonu
            Button(action: {
                dismiss()
            }) {
                Text("general.ok", tableName: "MainScreen")
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
        .padding(.top, 40)
        .padding(.bottom, 24)
    }
}

// MARK: - Emoji Özelleştirme Bölümü
struct EmojiCustomizationSection: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    @Binding var showEmojiPicker: Bool
    @Binding var isPickingCoreEmoji: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("profile.emoji.title", tableName: "Profile")
                .font(.headline)
                .foregroundColor(.appText)
            
            VStack(spacing: 16) {
                // Ana Uyku Emojisi
                HStack {
                    Text("profile.emoji.core", tableName: "Profile")
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
                    Text("profile.emoji.nap", tableName: "Profile")
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
            }
            .padding()
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
        VStack(spacing: 20) {
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
                Text("general.save", tableName: "MainScreen")
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

// MARK: - İlerleme Çubuğu
struct ProgressBar: View {
    var value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.appSecondary)
                    .frame(width: min(CGFloat(self.value) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .animation(.linear(duration: 0.6), value: value)
            }
        }
    }
}

struct ProfileScreenView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileScreenView()
    }
}
