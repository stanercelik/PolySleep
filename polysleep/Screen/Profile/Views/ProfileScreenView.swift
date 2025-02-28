import SwiftUI
import SwiftData

struct ProfileScreenView: View {
    @StateObject var viewModel = ProfileScreenViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showEmojiPicker = false
    @State private var isPickingCoreEmoji = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
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
            .sheet(isPresented: $viewModel.showBadgeDetail, content: {
                if let badge = viewModel.selectedBadge {
                    BadgeDetailView(badge: badge)
                        .presentationDetents([.medium])
                }
            })
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
    }
}

// MARK: - Streak Bölümü
struct StreakSection: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    
    var body: some View {
        VStack(spacing: 16) {
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
        .padding(.top, 8)
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
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
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
