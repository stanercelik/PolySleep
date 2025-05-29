import SwiftUI

/// Uyku düzeni seçimi için kompakt view
struct ScheduleSelectionView: View {
    let availableSchedules: [SleepScheduleModel]
    @Binding var selectedSchedule: UserScheduleModel
    let onScheduleSelected: (SleepScheduleModel) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var isProcessing = false
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollTime = Date()
    @State private var isPremium: Bool = false
    @State private var scrollVelocity: CGFloat = 0
    @State private var isScrolling: Bool = false
    
    // FREE ÖNCE, PREMIUM SONRA + ALFABETİK SIRALAMA
    private var sortedSchedules: [SleepScheduleModel] {
        let allSchedules = SleepScheduleService.shared.getAllSchedules()
        let freeSchedules = allSchedules.filter { !$0.isPremium }.sorted { $0.name < $1.name }
        let premiumSchedules = allSchedules.filter { $0.isPremium }.sorted { $0.name < $1.name }
        return freeSchedules + premiumSchedules
    }
    
    /// String ID'den deterministik UUID oluşturur (MainScreenViewModel ile aynı algoritma)
    private func generateDeterministicUUID(from stringId: String) -> UUID {
        // PolySleep namespace UUID'si (sabit bir UUID) - MainScreenViewModel ile aynı
        let namespace = UUID(uuidString: "6BA7B810-9DAD-11D1-80B4-00C04FD430C8") ?? UUID()
        
        // String'i Data'ya dönüştür
        let data = stringId.data(using: .utf8) ?? Data()
        
        // MD5 hash ile deterministik UUID oluştur
        var digest = [UInt8](repeating: 0, count: 16)
        
        // Basit hash algoritması
        let namespaceBytes = withUnsafeBytes(of: namespace.uuid) { Array($0) }
        let stringBytes = Array(data)
        
        for (index, byte) in (namespaceBytes + stringBytes).enumerated() {
            digest[index % 16] ^= byte
        }
        
        // UUID'nin version ve variant bitlerini ayarla (version 5 için)
        digest[6] = (digest[6] & 0x0F) | 0x50  // Version 5
        digest[8] = (digest[8] & 0x3F) | 0x80  // Variant 10
        
        // UUID oluştur
        let uuid = NSUUID(uuidBytes: digest) as UUID
        return uuid
    }
    
    /// Schedule'ın seçili olup olmadığını kontrol eder
    private func isScheduleSelected(_ schedule: SleepScheduleModel) -> Bool {
        let scheduleUUID = generateDeterministicUUID(from: schedule.id)
        let repositoryCompatibleId = scheduleUUID.uuidString
        return selectedSchedule.id == repositoryCompatibleId
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: PSSpacing.md) {
                            // Başlık ve açıklama - daha kompakt
                            VStack(spacing: PSSpacing.sm) {
                                Text(L("scheduleSelection.subtitle", table: "MainScreen"))
                                    .font(PSTypography.caption)
                                    .foregroundColor(.appTextSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, PSSpacing.md)
                            }
                            .padding(.top, PSSpacing.xs)
                            
                            // Schedule kartları
                            ForEach(sortedSchedules.indices, id: \.self) { index in
                                let schedule = sortedSchedules[index]
                                
                                // Bölüm başlığı - Free'den Premium'a geçerken
                                if index == 0 {
                                    // İlk free schedule
                                    ScheduleSectionHeader(title: L("scheduleSelection.freeSchedules", table: "MainScreen"))
                                } else if index > 0 && !sortedSchedules[index-1].isPremium && schedule.isPremium {
                                    // Premium bölümü başlangıcı
                                    ScheduleSectionHeader(title: L("scheduleSelection.premiumSchedules", table: "MainScreen"))
                                }
                                
                                if schedule.isPremium && !isPremium {
                                    // Premium schedule for free users
                                    PremiumLockedScheduleCard(
                                        schedule: schedule,
                                        isSelected: isScheduleSelected(schedule)
                                    )
                                    .id(schedule.id)
                                } else {
                                    // Available schedule
                                    CompactScheduleCard(
                                        schedule: schedule,
                                        isSelected: isScheduleSelected(schedule),
                                        isProcessing: isProcessing,
                                        onSelect: {
                                            selectScheduleWithScrollCheck(schedule)
                                        }
                                    )
                                    .id(schedule.id)
                                }
                            }
                        }
                        .padding(.horizontal, PSSpacing.lg)
                        .padding(.bottom, PSSpacing.lg)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        scrollOffset = geo.frame(in: .global).minY
                                    }
                                    .onChange(of: geo.frame(in: .global).minY) { oldValue, newValue in
                                        let currentTime = Date()
                                        let timeDiff = currentTime.timeIntervalSince(lastScrollTime)
                                        
                                        if timeDiff > 0 {
                                            scrollVelocity = abs(newValue - oldValue) / timeDiff
                                            isScrolling = scrollVelocity > 50 // 50 points/second threshold
                                        }
                                        
                                        scrollOffset = newValue
                                        lastScrollTime = currentTime
                                        
                                        // Auto-stop scroll detection after 0.5 seconds of no movement
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            if Date().timeIntervalSince(lastScrollTime) >= 0.5 {
                                                isScrolling = false
                                                scrollVelocity = 0
                                            }
                                        }
                                    }
                            }
                        )
                    }
                }
            }
            .navigationTitle(L("scheduleSelection.title", table: "MainScreen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text(L("general.cancel", table: "MainScreen"))
                            .font(PSTypography.button)
                            .foregroundColor(.appPrimary)
                    }
                    .disabled(isProcessing)
                }
            }
            .onAppear {
                loadPremiumStatus()
            }
        }
    }
    
    private func loadPremiumStatus() {
        // Debug için UserDefaults kontrolü
        if UserDefaults.standard.object(forKey: "debug_premium_status") != nil {
            isPremium = UserDefaults.standard.bool(forKey: "debug_premium_status")
        } else {
            isPremium = AuthManager.shared.currentUser?.isPremium ?? false
        }
    }
    
    private func selectScheduleWithScrollCheck(_ schedule: SleepScheduleModel) {
        // Aktif scroll kontrolü - hem zaman hem de velocity bazlı
        let timeSinceLastScroll = Date().timeIntervalSince(lastScrollTime)
        
        if isScrolling || timeSinceLastScroll < 0.4 || scrollVelocity > 30 {
            print("🚫 Scroll sırasında tıklama engellendi - isScrolling: \(isScrolling), timeSince: \(timeSinceLastScroll), velocity: \(scrollVelocity)")
            return
        }
        
        // Çift tıklamayı önle
        guard !isProcessing else { 
            print("🚫 İşlem devam ediyor, çift tıklama engellendi")
            return 
        }
        
        print("✅ Schedule seçimi onaylandı: \(schedule.name)")
        
        withAnimation(.easeInOut(duration: 0.2)) {
            isProcessing = true
        }
        
        // Hafif gecikme ile kullanıcı feedback'i ver
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onScheduleSelected(schedule)
            
            // İşlem tamamlandıktan sonra dismiss et
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                dismiss()
            }
        }
    }
}

/// Kompakt uyku düzeni kartı
struct CompactScheduleCard: View {
    let schedule: SleepScheduleModel
    let isSelected: Bool
    let isProcessing: Bool
    let onSelect: () -> Void
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var isExpanded = false
    
    var scheduleDescription: String {
        let currentLang = languageManager.currentLanguage
        if currentLang == "tr" {
            return schedule.description.tr
        } else {
            return schedule.description.en
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: PSSpacing.sm) {
                // Ana header - kompakt
                HStack(spacing: PSSpacing.md) {
                    // Schedule ikonu
                    Image(systemName: getScheduleIcon())
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .appPrimary : .appAccent)
                        .frame(width: 24, height: 24)
                    
                    // İsim ve bilgiler
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: PSSpacing.xs) {
                            Text(schedule.name)
                                .font(PSTypography.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.appText)
                                .lineLimit(1)
                            
                            if schedule.isPremium {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.yellow)
                            }
                        }
                        
                        Text(String(format: "%.1f %@", schedule.totalSleepHours, L("scheduleSelection.hours", table: "MainScreen")))
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    Spacer()
                    
                    // Block bilgileri - kompakt
                    HStack(spacing: PSSpacing.xs) {
                        let coreBlocks = schedule.schedule.filter { $0.isCore }
                        let napBlocks = schedule.schedule.filter { !$0.isCore }
                        
                        if !coreBlocks.isEmpty {
                            CompactBlockInfo(
                                icon: "moon.fill",
                                count: coreBlocks.count,
                                color: .appPrimary
                            )
                        }
                        
                        if !napBlocks.isEmpty {
                            CompactBlockInfo(
                                icon: "powersleep",
                                count: napBlocks.count,
                                color: .appAccent
                            )
                        }
                    }
                    
                    // Seçili indikator - küçük
                    ZStack {
                        Circle()
                            .stroke(
                                isSelected ? Color.appPrimary : Color.appTextSecondary.opacity(0.3),
                                lineWidth: 1.5
                            )
                            .frame(width: 18, height: 18)
                        
                        if isSelected {
                            Circle()
                                .fill(Color.appPrimary)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isProcessing ? 0.8 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isProcessing)
                        }
                    }
                }
                
                // Açıklama toggle butonu - isteğe bağlı
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: PSSpacing.xs) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                        
                        Text(isExpanded ? L("scheduleSelection.hide", table: "MainScreen") : L("scheduleSelection.details", table: "MainScreen"))
                            .font(.system(size: 11, weight: .medium))
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.appTextSecondary)
                }
                .buttonStyle(.plain)
                
                // Genişletilmiş açıklama
                if isExpanded {
                    Text(scheduleDescription)
                        .font(.system(size: 13))
                        .foregroundColor(.appText)
                        .lineSpacing(1)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, PSSpacing.sm)
                        .padding(.vertical, PSSpacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: PSCornerRadius.small)
                                .fill(Color.appBackground.opacity(0.5))
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }
            }
            .padding(PSSpacing.md)
            .background(cardBackground)
            .shadow(
                color: isSelected ? Color.appPrimary.opacity(0.1) : Color.black.opacity(0.03),
                radius: isSelected ? 4 : 2,
                x: 0,
                y: isSelected ? 2 : 1
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 0.99 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        .disabled(isProcessing)
        .opacity(isProcessing && !isSelected ? 0.6 : 1.0)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: PSCornerRadius.large)
            .fill(Color.appCardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: PSCornerRadius.large)
                    .stroke(
                        isSelected ? Color.appPrimary : Color.clear,
                        lineWidth: 1.5
                    )
            )
    }
    
    private func getScheduleIcon() -> String {
        let name = schedule.name.lowercased()
        
        if name.contains("biphasic") || name.contains("çift") {
            return "moon.stars.fill"
        } else if name.contains("everyman") || name.contains("her") {
            return "clock.fill"
        } else if name.contains("uberman") || name.contains("uber") {
            return "brain.head.profile.fill"
        } else if name.contains("dymaxion") {
            return "diamond.fill"
        } else if name.contains("triphasic") || name.contains("üç") {
            return "triangle.fill"
        } else {
            return "bed.double.fill"
        }
    }
}

// MARK: - Kompakt Block Info
struct CompactBlockInfo: View {
    let icon: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.appText)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.1))
        )
    }
}

/// Premium kilitli schedule kartı
struct PremiumLockedScheduleCard: View {
    let schedule: SleepScheduleModel
    let isSelected: Bool
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var isExpanded = false
    @State private var showPremiumAlert = false
    
    var scheduleDescription: String {
        let currentLang = languageManager.currentLanguage
        if currentLang == "tr" {
            return schedule.description.tr
        } else {
            return schedule.description.en
        }
    }
    
    var body: some View {
        Button(action: {
            showPremiumAlert = true
        }) {
            VStack(spacing: PSSpacing.sm) {
                // Premium overlay with blur effect
                ZStack {
                    // Ana kart içeriği - bulanık
                    VStack(spacing: PSSpacing.sm) {
                        // Ana header - kompakt
                        HStack(spacing: PSSpacing.md) {
                            // Schedule ikonu
                            Image(systemName: getScheduleIcon())
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.gray)
                                .frame(width: 24, height: 24)
                            
                            // İsim ve bilgiler
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: PSSpacing.xs) {
                                    Text(schedule.name)
                                        .font(PSTypography.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                    
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.yellow)
                                }
                                
                                Text(String(format: "%.1f %@", schedule.totalSleepHours, L("scheduleSelection.hours", table: "MainScreen")))
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            // Block bilgileri - kompakt
                            HStack(spacing: PSSpacing.xs) {
                                let coreBlocks = schedule.schedule.filter { $0.isCore }
                                let napBlocks = schedule.schedule.filter { !$0.isCore }
                                
                                if !coreBlocks.isEmpty {
                                    CompactBlockInfo(
                                        icon: "moon.fill",
                                        count: coreBlocks.count,
                                        color: .gray
                                    )
                                }
                                
                                if !napBlocks.isEmpty {
                                    CompactBlockInfo(
                                        icon: "powersleep",
                                        count: napBlocks.count,
                                        color: .gray
                                    )
                                }
                            }
                            
                            // Kilit ikonu
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        
                        // Açıklama toggle butonu
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isExpanded.toggle()
                            }
                        }) {
                            HStack(spacing: PSSpacing.xs) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 12))
                                
                                Text(isExpanded ? L("scheduleSelection.hide", table: "MainScreen") : L("scheduleSelection.details", table: "MainScreen"))
                                    .font(.system(size: 11, weight: .medium))
                                
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                        
                        // Genişletilmiş açıklama
                        if isExpanded {
                            Text(scheduleDescription)
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .lineSpacing(1)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, PSSpacing.sm)
                                .padding(.vertical, PSSpacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: PSCornerRadius.small)
                                        .fill(Color.gray.opacity(0.1))
                                )
                                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                        }
                    }
                    .blur(radius: 1.5)
                    .opacity(0.6)
                    
                    // Premium teşvik overlay
                    VStack(spacing: PSSpacing.sm) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.yellow)
                        
                        Text(L("scheduleSelection.premiumRequired", table: "MainScreen"))
                            .font(PSTypography.button)
                            .fontWeight(.bold)
                            .foregroundColor(.appPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text(L("scheduleSelection.upgradePrompt", table: "MainScreen"))
                            .font(.system(size: 11))
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, PSSpacing.md)
                }
            }
            .padding(PSSpacing.md)
            .background(premiumCardBackground)
            .shadow(
                color: Color.yellow.opacity(0.1),
                radius: 3,
                x: 0,
                y: 1
            )
        }
        .buttonStyle(.plain)
        .alert(L("scheduleSelection.premiumAlert.title", table: "MainScreen"), isPresented: $showPremiumAlert) {
            Button(L("scheduleSelection.premiumAlert.upgrade", table: "MainScreen")) {
                // Premium upgrade navigation
            }
            Button(L("general.cancel", table: "MainScreen"), role: .cancel) {}
        } message: {
            Text(L("scheduleSelection.premiumAlert.message", table: "MainScreen"))
        }
    }
    
    private var premiumCardBackground: some View {
        RoundedRectangle(cornerRadius: PSCornerRadius.large)
            .fill(Color.appCardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: PSCornerRadius.large)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.yellow.opacity(0.3), .orange.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
    }
    
    private func getScheduleIcon() -> String {
        let name = schedule.name.lowercased()
        
        if name.contains("biphasic") || name.contains("çift") {
            return "moon.stars.fill"
        } else if name.contains("everyman") || name.contains("her") {
            return "clock.fill"
        } else if name.contains("uberman") || name.contains("uber") {
            return "brain.head.profile.fill"
        } else if name.contains("dymaxion") {
            return "diamond.fill"
        } else if name.contains("triphasic") || name.contains("üç") {
            return "triangle.fill"
        } else {
            return "bed.double.fill"
        }
    }
}

/// Schedule bölüm başlığı
struct ScheduleSectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(PSTypography.headline)
                .fontWeight(.bold)
                .foregroundColor(.appText)
            
            Spacer()
        }
        .padding(.horizontal, PSSpacing.xs)
        .padding(.top, PSSpacing.md)
        .padding(.bottom, PSSpacing.xs)
    }
}

#Preview {
    let schedule1 = SleepScheduleModel(
        id: "biphasic",
        name: "Biphasic Sleep",
        description: LocalizedDescription(
            en: "A sleep pattern with one core sleep period and one short nap during the day.",
            tr: "Bir ana uyku dönemi ve gün içinde kısa bir şekerlemeden oluşan uyku düzeni."
        ),
        totalSleepHours: 6.5,
        schedule: [
            SleepBlock(startTime: "23:00", duration: 360, type: "core", isCore: true),
            SleepBlock(startTime: "14:00", duration: 30, type: "nap", isCore: false)
        ],
        isPremium: false
    )
    
    let schedule2 = SleepScheduleModel(
        id: "everyman",
        name: "Everyman",
        description: LocalizedDescription(
            en: "One core sleep of a few hours plus multiple short naps throughout the day.",
            tr: "Birkaç saatlik bir ana uyku ile gün içinde birden fazla kısa uykulardan oluşur."
        ),
        totalSleepHours: 4.5,
        schedule: [
            SleepBlock(startTime: "22:00", duration: 180, type: "core", isCore: true),
            SleepBlock(startTime: "04:00", duration: 20, type: "nap", isCore: false),
            SleepBlock(startTime: "08:00", duration: 20, type: "nap", isCore: false),
            SleepBlock(startTime: "14:00", duration: 20, type: "nap", isCore: false)
        ],
        isPremium: true
    )
    
    ScheduleSelectionView(
        availableSchedules: [schedule1, schedule2],
        selectedSchedule: .constant(UserScheduleModel.defaultSchedule),
        onScheduleSelected: { _ in }
    )
    .environmentObject(LanguageManager.shared)
} 