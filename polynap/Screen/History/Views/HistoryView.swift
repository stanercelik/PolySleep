import SwiftUI
import SwiftData

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    
    // Analytics
    private let analyticsManager = AnalyticsManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: PSSpacing.xl) {
                        // Stats Overview Card
                        SleepStatsOverviewCard(viewModel: viewModel)
                        
                        // Filter Section
                        FilterSectionCard(viewModel: viewModel)
                        
                        // History Content
                        if viewModel.historyItems.isEmpty {
                            EmptyStateCard()
                        } else {
                            HistoryTimelineSection(viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, PSSpacing.lg)
                    .padding(.vertical, PSSpacing.sm)
                }
                
                // Floating Action Button
                ModernFloatingActionButton(action: {
                    // Analytics: FAB Add Sleep Entry button tap
                    analyticsManager.logFeatureUsed(
                        featureName: "add_sleep_entry_fab",
                        action: "button_tap"
                    )
                    
                    // Önce tüm sheet state'lerini sıfırla
                    viewModel.isDayDetailPresented = false
                    viewModel.selectedDay = nil
                    
                    // Sonra add sheet'i aç
                    DispatchQueue.main.async {
                        viewModel.isAddSleepEntryPresented = true
                    }
                })
            }
            .navigationTitle(L("Sleep History", table: "History"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.isDayDetailPresented) {
                viewModel.selectedDay = nil
            } content: {
                if viewModel.selectedDay != nil {
                    DayDetailView(viewModel: viewModel)
                }
            }
            .onChange(of: viewModel.isDayDetailPresented) { isPresented in
                if isPresented {
                    // Analytics: Day detail navigation
                    analyticsManager.logFeatureUsed(
                        featureName: "day_detail_navigation",
                        action: "day_selected"
                    )
                }
            }
            .sheet(isPresented: $viewModel.isAddSleepEntryPresented) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.reloadData()
                }
            } content: {
                AddSleepEntrySheet(viewModel: viewModel)
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
                
                // Analytics: History screen görüntüleme
                analyticsManager.logScreenView(
                    screenName: "history_screen",
                    screenClass: "HistoryView"
                )
            }

        }
        .accentColor(Color.appPrimary)
        .id(languageManager.currentLanguage)
    }
}

// MARK: - Sleep Stats Overview Card
struct SleepStatsOverviewCard: View {
    @ObservedObject var viewModel: HistoryViewModel
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.lg) {
                // Header
                PSSectionHeader(
                    L("history.stats.title", table: "History"),
                    icon: "chart.bar.fill"
                )
                
                // Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: PSSpacing.md),
                    GridItem(.flexible(), spacing: PSSpacing.md)
                ], spacing: PSSpacing.md) {
                    QuickStatCard(
                        icon: "bed.double.fill",
                        title: L("history.stats.totalSessions", table: "History"),
                        value: "\(calculateTotalSessions())",
                        gradientColors: [.appPrimary, .blue]
                    )
                    
                    QuickStatCard(
                        icon: "clock.fill",
                        title: L("history.stats.avgDuration", table: "History"),
                        value: calculateAverageDuration(),
                        gradientColors: [.appSecondary, .green]
                    )
                    
                    QuickStatCard(
                        icon: "star.fill",
                        title: L("history.stats.avgRating", table: "History"),
                        value: String(format: "%.1f", calculateAverageRating()),
                        gradientColors: [.orange, .yellow]
                    )
                    
                    QuickStatCard(
                        icon: "calendar.badge.clock",
                        title: L("history.stats.streak", table: "History"),
                        value: "\(calculateCurrentStreak())",
                        gradientColors: [.purple, .pink]
                    )
                }
            }
        }
    }
    
    private func calculateTotalSessions() -> Int {
        return viewModel.historyItems.compactMap { $0.sleepEntries?.count }.reduce(0, +)
    }
    
    private func calculateAverageDuration() -> String {
        let totalDuration = viewModel.historyItems.compactMap { $0.totalSleepDuration }.reduce(0, +)
        let avgDuration = viewModel.historyItems.isEmpty ? 0 : totalDuration / Double(viewModel.historyItems.count)
        let avgMinutes = Int(avgDuration / 60)
        return formatDuration(avgMinutes)
    }
    
    private func calculateAverageRating() -> Double {
        let ratings = viewModel.historyItems.map { $0.averageRating }
        return ratings.isEmpty ? 0.0 : ratings.reduce(0, +) / Double(ratings.count)
    }
    
    private func calculateCurrentStreak() -> Int {
        return viewModel.historyItems.count > 0 ? 7 : 0
    }
}

// MARK: - Quick Stat Card
struct QuickStatCard: View {
    let icon: String
    let title: String
    let value: String
    let gradientColors: [Color]
    
    var body: some View {
        VStack(spacing: PSSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: PSIconSize.medium * 0.8))
                    .foregroundColor(.white)
                    .frame(width: PSIconSize.medium + PSSpacing.sm, height: PSIconSize.medium + PSSpacing.sm)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: gradientColors),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: PSSpacing.xs) {
                Text(value)
                    .font(PSTypography.headline)
                    .foregroundColor(.appText)
                
                Text(title)
                    .font(PSTypography.caption)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(PSSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                .fill(Color.appCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: gradientColors.map { $0.opacity(0.2) }),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Filter Section Card
struct FilterSectionCard: View {
    @ObservedObject var viewModel: HistoryViewModel
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.lg) {
                PSSectionHeader(
                    L("history.filter.title", table: "History"),
                    icon: "line.3.horizontal.decrease.circle.fill"
                )
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: PSSpacing.md) {
                        ForEach(TimeFilter.allCases, id: \.self) { filter in
                            ModernFilterChip(
                                title: filter.localizedTitle,
                                isSelected: viewModel.selectedFilter == filter,
                                action: { 
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.setFilter(filter)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, PSSpacing.xs)
                }
            }
        }
    }
}

// MARK: - Modern Filter Chip
struct ModernFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: PSSpacing.xs) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextOnPrimary)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Text(title)
                    .font(PSTypography.button)
                    .foregroundColor(isSelected ? .appTextOnPrimary : .appText)
            }
            .padding(.horizontal, PSSpacing.lg)
            .padding(.vertical, PSSpacing.sm + PSSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: PSCornerRadius.button)
                    .fill(
                        isSelected ? 
                        LinearGradient(
                            gradient: Gradient(colors: [.appPrimary, .appSecondary]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.appCardBackground, Color.appCardBackground]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: PSCornerRadius.button)
                            .stroke(
                                isSelected ? Color.clear : Color.appBorder.opacity(0.5),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isSelected ? Color.appPrimary.opacity(0.3) : Color.clear,
                        radius: isSelected ? PSSpacing.sm : 0,
                        x: 0,
                        y: isSelected ? PSSpacing.xs : 0
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Empty State Card
struct EmptyStateCard: View {
    var body: some View {
        PSEmptyState(
            icon: "bed.double",
            title: L("history.noRecords.title", table: "History"),
            message: L("history.noRecords.message", table: "History"),
            actionTitle: L("history.addNewRecord", table: "History"),
            action: {
                // Add new record action will be handled by parent
            }
        )
    }
}

// MARK: - History Timeline Section
struct HistoryTimelineSection: View {
    @ObservedObject var viewModel: HistoryViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        PSCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: PSSpacing.lg) {
                    PSSectionHeader(
                        L("history.timeline.title", table: "History"),
                        icon: "calendar",
                        action: nil,
                        actionIcon: nil
                    )
                    
                    PSStatusBadge(
                        String(format: L("history.timeline.count", table: "History"), viewModel.historyItems.count),
                        color: .appAccent
                    )
                }
                .padding(.horizontal, PSSpacing.lg)
                .padding(.top, PSSpacing.lg)
                
                // Timeline Content
                LazyVStack(spacing: 0) {
                    let monthGroups = groupedByMonth(items: viewModel.historyItems)
                    ForEach(monthGroups, id: \.month) { monthGroup in
                        HistoryMonthSection(
                            month: monthGroup.month,
                            items: monthGroup.days,
                            viewModel: viewModel,
                            isLastMonth: monthGroup.month == monthGroups.last?.month
                        )
                    }
                }
                .padding(.bottom, PSSpacing.lg)
            }
        }
    }
    
    private func groupedByMonth(items: [HistoryModel]) -> [(month: String, days: [HistoryModel])] {
        let grouped = Dictionary(grouping: items) { item -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            formatter.locale = languageManager.currentLocale
            return formatter.string(from: item.date)
        }
        
        return grouped.map { (month: $0.key, days: $0.value) }
            .sorted { item1, item2 in
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                formatter.locale = languageManager.currentLocale
                guard let date1 = formatter.date(from: item1.month),
                      let date2 = formatter.date(from: item2.month) else {
                    return false
                }
                return date1 > date2
            }
    }
}

// MARK: - History Month Section
struct HistoryMonthSection: View {
    let month: String
    let items: [HistoryModel]
    @ObservedObject var viewModel: HistoryViewModel
    let isLastMonth: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Month Header with enhanced design
            VStack(spacing: PSSpacing.md) {
                HStack {
                    HStack(spacing: PSSpacing.sm) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: PSIconSize.medium))
                            .foregroundColor(.appPrimary)
                        
                        Text(month)
                            .font(PSTypography.title1)
                            .foregroundColor(.appPrimary)
                    }
                    
                    Spacer()
                    
                    PSStatusBadge(
                        String(format: L("history.month.entries", table: "History"), items.count),
                        icon: "calendar",
                        color: .appPrimary
                    )
                }
                
                // Month separator with gradient
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.appPrimary.opacity(0.6), .appPrimary.opacity(0.1)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
            }
            .padding(.horizontal, PSSpacing.lg)
            .padding(.vertical, PSSpacing.lg)
            .background(Color.appPrimary.opacity(0.03))
            
            // Days in month
            LazyVStack(spacing: PSSpacing.lg) {
                ForEach(items.sorted { $0.date > $1.date }) { item in
                    ModernDayCard(item: item, viewModel: viewModel)
                        .padding(.horizontal, PSSpacing.lg)
                }
            }
            .padding(.vertical, PSSpacing.lg)
            
            // Month bottom separator (if not last month)
            if !isLastMonth {
                Rectangle()
                    .fill(Color.appBorder.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, PSSpacing.lg)
            }
        }
    }
}

// MARK: - Modern Day Card with Edit/Delete capabilities
struct ModernDayCard: View {
    let item: HistoryModel
    @ObservedObject var viewModel: HistoryViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: SleepEntry?
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.md) {
                // Header: Date and Actions
                HStack {
                    VStack(alignment: .leading, spacing: PSSpacing.xs) {
                        Text(item.date, style: .date)
                            .font(PSTypography.headline)
                            .foregroundColor(.appText)
                        Text(dayOfWeek(from: item.date))
                            .font(PSTypography.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: PSSpacing.sm) {
                        if Calendar.current.isDateInToday(item.date) {
                            PSStatusBadge(L("history.today", table: "History"), color: .appPrimary)
                        }
                        
                        // Edit day button
                        PSIconButton(
                            icon: "square.and.pencil",
                            size: PSIconSize.medium,
                            backgroundColor: Color.appSecondary.opacity(0.15),
                            foregroundColor: .appSecondary
                        ) {
                            viewModel.selectDateForDetail(item.date)
                        }
                    }
                }
                
                // Rating Stars with half-star support
                if let entries = item.sleepEntries, !entries.isEmpty, item.averageRating > 0 {
                    HStack(spacing: PSSpacing.xs) {
                        StarsView(
                            rating: item.averageRating,
                            size: PSIconSize.small,
                            primaryColor: .appAccent,
                            emptyColor: .appTextSecondary.opacity(0.3)
                        )
                        Text(String(format: "%.1f", item.averageRating))
                            .font(PSTypography.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                }
                
                // Separator
                if let entries = item.sleepEntries, !entries.isEmpty {
                    Divider()
                        .background(Color.appBorder.opacity(0.3))
                }
                
                // Sleep Entries with enhanced design
                if let entries = item.sleepEntries, !entries.isEmpty {
                    VStack(spacing: PSSpacing.md) {
                        ForEach(entries) { entry in
                            ModernSleepEntryRow(
                                entry: entry,
                                onDelete: {
                                    entryToDelete = entry
                                    showingDeleteAlert = true
                                }
                            )
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "moon.zzz")
                            .font(.system(size: PSIconSize.medium))
                            .foregroundColor(.appTextSecondary.opacity(0.5))
                        
                        Text(L("history.noRecord", table: "History"))
                            .font(PSTypography.body)
                            .foregroundColor(.appTextSecondary)
                        
                        Spacer()
                    }
                    .padding(.vertical, PSSpacing.lg)
                }
                
                // Footer Stats with enhanced design
                if let entries = item.sleepEntries, !entries.isEmpty {
                    Divider()
                        .background(Color.appBorder.opacity(0.3))
                    
                    HStack(spacing: PSSpacing.lg) {
                        StatPill(
                            icon: "clock",
                            value: formatDuration(Int(item.totalSleepDuration / 60)),
                            color: .appPrimary
                        )
                        
                        StatPill(
                            icon: "bed.double",
                            value: String(format: L("history.blocksCount", table: "History"), entries.count),
                            color: .appSecondary
                        )
                        
                        Spacer()
                        
                        PSStatusBadge(
                            item.completionStatus.localizedTitle,
                            icon: "circle.fill",
                            color: item.completionStatus.color
                        )
                    }
                }
            }
        }
        .alert("Delete Sleep Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let entry = entryToDelete {
                    // Delete işlemini async olarak yap
                    Task { @MainActor in
                        viewModel.deleteSleepEntry(entry)
                        
                        // Local state'i temizle
                        entryToDelete = nil
                        
                        // Haptic feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this sleep entry? This action cannot be undone.")
        }
        .onTapGesture {
            viewModel.selectDateForDetail(item.date)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    private func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = languageManager.currentLocale
        return formatter.string(from: date)
    }
}

// MARK: - Modern Sleep Entry Row with Delete capability
struct ModernSleepEntryRow: View {
    let entry: SleepEntry
    let onDelete: () -> Void
    
    // Kullanıcının seçtiği emojiler
    private var coreEmoji: String {
        UserDefaults.standard.string(forKey: "selectedCoreEmoji") ?? "🌙"
    }
    
    private var napEmoji: String {
        UserDefaults.standard.string(forKey: "selectedNapEmoji") ?? "💤"
    }
    
    var body: some View {
        HStack(spacing: PSSpacing.md) {
            // Kişiselleştirilmiş emoji kullan
            Text(entry.isCore ? coreEmoji : napEmoji)
                .font(.system(size: PSIconSize.small))
                .frame(width: PSIconSize.medium + 8, height: PSIconSize.medium + 8)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: entry.isCore ? [.appPrimary, .blue] : [.appSecondary, .green]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: (entry.isCore ? Color.appPrimary : Color.appSecondary).opacity(0.3), radius: PSSpacing.xs, x: 0, y: PSSpacing.xs / 2)
            
            // Entry Info
            VStack(alignment: .leading, spacing: PSSpacing.xs) {
                Text("\(formatTime(entry.startTime)) - \(formatTime(entry.endTime))")
                    .font(PSTypography.body)
                    .foregroundColor(.appText)
                
                Text(entry.isCore ? L("sleep.type.core", table: "History") : L("sleep.type.nap", table: "History"))
                    .font(PSTypography.caption)
                    .foregroundColor(.appTextSecondary)
            }
            
            Spacer()
            
            // Duration Badge
            PSStatusBadge(
                formatEntryDuration(entry.duration),
                color: entry.isCore ? .appPrimary : .appSecondary
            )
            
            // Delete Button
            PSIconButton(
                icon: "trash",
                size: PSIconSize.medium,
                backgroundColor: Color.red.opacity(0.15),
                foregroundColor: .red
            ) {
                onDelete()
            }
        }
        .padding(PSSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                .fill(Color.appBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                        .stroke(Color.appBorder.opacity(0.2), lineWidth: 0.5)
                )
        )
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Stat Pill
struct StatPill: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: PSSpacing.xs) {
            Image(systemName: icon)
                .font(PSTypography.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(PSTypography.caption)
                .foregroundColor(.appText)
        }
        .padding(.horizontal, PSSpacing.sm)
        .padding(.vertical, PSSpacing.xs)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Modern Floating Action Button
struct ModernFloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button(action: {
                    // UI feedback önce gelsin
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    // Action'ı çağır
                    action()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: PSIconSize.medium, weight: .bold))
                        .foregroundColor(.appTextOnPrimary)
                        .frame(width: PSIconSize.extraLarge + PSSpacing.sm, height: PSIconSize.extraLarge + PSSpacing.sm)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.appPrimary, .appSecondary]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.appPrimary.opacity(0.4), radius: PSSpacing.md, x: 0, y: PSSpacing.sm)
                        )
                }
                .buttonStyle(FloatingButtonStyle())
                .padding(.trailing, PSSpacing.xl)
                .padding(.bottom, PSSpacing.xl)
            }
        }
    }
}

// MARK: - Helper Functions
private func formatDuration(_ minutes: Int) -> String {
    let hours = minutes / 60
    let mins = minutes % 60
    if hours > 0 {
        return String(format: "%dh %dm", hours, mins)
    } else {
        return String(format: "%dm", mins)
    }
}

private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.locale = LanguageManager.shared.currentLocale
    return formatter.string(from: date)
}

private func formatEntryDuration(_ duration: TimeInterval) -> String {
    let minutes = Int(duration / 60)
    return formatDuration(minutes)
}


