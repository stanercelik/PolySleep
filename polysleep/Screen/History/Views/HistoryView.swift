import SwiftUI
import SwiftData

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    
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
                            HistoryContentSection(viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, PSSpacing.lg)
                    .padding(.vertical, PSSpacing.sm)
                }
                
                // Floating Action Button
                ModernFloatingActionButton(action: {
                    viewModel.isAddSleepEntryPresented = true
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                })
            }
            .navigationTitle(L("Sleep History", table: "History"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.isDayDetailPresented) {
                if viewModel.selectedDay != nil {
                    DayDetailView(viewModel: viewModel)
                }
            }
            .sheet(isPresented: $viewModel.isAddSleepEntryPresented) {
                AddSleepEntrySheet(viewModel: viewModel)
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
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
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: PSIconSize.medium))
                        .foregroundColor(.appPrimary)
                    
                    Text(L("history.stats.title", table: "History"))
                        .font(PSTypography.headline)
                        .foregroundColor(.appText)
                    
                    Spacer()
                    
                    // Quick insights
                    PSStatusBadge(L("history.stats.thisWeek", table: "History"), color: .appSecondary)
                }
                
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
        let avgMinutes = Int(avgDuration / 60) // Convert seconds to minutes and then to Int
        return formatDuration(avgMinutes)
    }
    
    private func calculateAverageRating() -> Double {
        let ratings = viewModel.historyItems.map { $0.averageRating }
        return ratings.isEmpty ? 0.0 : ratings.reduce(0, +) / Double(ratings.count)
    }
    
    private func calculateCurrentStreak() -> Int {
        // Bu gerçek implementasyonla değiştirilecek
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
                HStack {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: PSIconSize.medium))
                        .foregroundColor(.appSecondary)
                    
                    Text(L("history.filter.title", table: "History"))
                        .font(PSTypography.headline)
                        .foregroundColor(.appText)
                    
                    Spacer()
                }
                
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
            icon: "bed.double", // İkon sistemimizde daha uygun bir ikonla değiştirilebilir
            title: L("history.noRecords.title", table: "History"),
            message: L("history.noRecords.message", table: "History"),
            actionTitle: L("history.addNewRecord", table: "History"),
            action: {
                // Add new record action will be handled by parent
                // Bu eylem, viewModel.isAddSleepEntryPresented = true gibi bir şeyi tetikleyebilir
            }
        )
        // PSEmptyState zaten kendi arkaplanını ve padding'ini yönetiyor.
        // Gölge ve köşe yuvarlaklığı gibi ekstra özelleştirmeler gerekirse
        // .background(...) .cornerRadius(...) .shadow(...) modifier'ları eklenebilir,
        // ancak genellikle PSEmptyState'in varsayılan görünümü yeterli olmalıdır.
    }
}

// MARK: - History Content Section
struct HistoryContentSection: View {
    @ObservedObject var viewModel: HistoryViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        PSCard(padding: 0) {
            VStack(alignment: .leading, spacing: PSSpacing.lg) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: PSIconSize.medium))
                        .foregroundColor(.appAccent)
                    
                    Text(L("history.timeline.title", table: "History"))
                        .font(PSTypography.headline)
                        .foregroundColor(.appText)
                    
                    Spacer()
                    
                    PSStatusBadge(
                        String(format: L("history.timeline.count", table: "History"), viewModel.historyItems.count),
                        color: .appAccent
                    )
                }
                .padding(.horizontal, PSSpacing.lg)
                .padding(.top, PSSpacing.lg)
                
                LazyVStack(spacing: PSSpacing.md) {
                    ForEach(groupedByMonth(items: viewModel.historyItems), id: \.month) { monthGroup in
                        MonthSection(month: monthGroup.month, items: monthGroup.days, viewModel: viewModel)
                    }
                }
                .padding(.horizontal, PSSpacing.lg)
                .padding(.bottom, PSSpacing.lg)
            }
        }
    }
    
    private func groupedByMonth(items: [HistoryModel]) -> [(month: String, days: [HistoryModel])] {
        let grouped = Dictionary(grouping: items) { item -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            formatter.locale = Locale(identifier: languageManager.currentLanguage == "tr" ? "tr_TR" : "en_US")
            return formatter.string(from: item.date)
        }
        
        return grouped.map { (month: $0.key, days: $0.value) }
            .sorted { item1, item2 in
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                formatter.locale = Locale(identifier: languageManager.currentLanguage == "tr" ? "tr_TR" : "en_US")
                guard let date1 = formatter.date(from: item1.month),
                      let date2 = formatter.date(from: item2.month) else {
                    return false
                }
                return date1 > date2
            }
    }
}

// MARK: - Month Section
struct MonthSection: View {
    let month: String
    let items: [HistoryModel]
    @ObservedObject var viewModel: HistoryViewModel
    
    var body: some View {
        VStack(spacing: PSSpacing.md) {
            // Month Header
            HStack {
                Text(month)
                    .font(PSTypography.title1)
                    .foregroundColor(.appPrimary)
                
                Spacer()
                
                PSStatusBadge(
                    String(format: L("history.month.entries", table: "History"), items.count),
                    color: .appPrimary
                )
            }
            
            // Days
            VStack(spacing: PSSpacing.sm) {
                ForEach(items.sorted { $0.date > $1.date }) { item in
                    ModernDayCard(item: item, viewModel: viewModel)
                }
            }
        }
    }
}

// MARK: - Modern Day Card
struct ModernDayCard: View {
    let item: HistoryModel
    @ObservedObject var viewModel: HistoryViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.md) {
                // Header: Date and Today Badge
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
                    if Calendar.current.isDateInToday(item.date) {
                        PSStatusBadge(L("history.today", table: "History"), color: .appPrimary)
                    }
                }
                
                // Rating Stars
                if let rating = item.sleepEntries?.first?.rating, rating > 0 {
                    HStack(spacing: PSSpacing.xs) {
                        ForEach(1...5, id: \.self) { starIndex in
                            Image(systemName: starIndex <= rating ? "star.fill" : "star")
                                .font(.system(size: PSIconSize.small))
                                .foregroundColor(starIndex <= rating ? Color.appAccent : Color.appTextSecondary.opacity(0.5))
                        }
                    }
                }
                
                // Sleep Entries or No Record Message
                if let entries = item.sleepEntries, !entries.isEmpty {
                    VStack(spacing: PSSpacing.sm) {
                        ForEach(entries) { entry in
                            ModernSleepEntryRow(entry: entry)
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
                
                // Footer Stats
                HStack(spacing: PSSpacing.lg) {
                    StatPill(
                        icon: "clock",
                        value: formatDuration(Int(item.totalSleepDuration / 60)),
                        color: .appPrimary
                    )
                    
                    StatPill(
                        icon: "bed.double",
                        value: String(format: L("history.blocksCount", table: "History"), (item.sleepEntries?.count ?? 0)),
                        color: .appSecondary
                    )
                    
                    Spacer()
                    
                    // Status Indicator
                    PSStatusBadge(
                        item.completionStatus.localizedTitle,
                        icon: "circle.fill",
                        color: Color(item.completionStatus.color)
                    )
                }
            }
        }
        .onTapGesture {
            DispatchQueue.main.async {
                // viewModel.selectDay(item) // Geçici olarak yorum satırı yapıldı
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    private func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: languageManager.currentLanguage == "tr" ? "tr_TR" : "en_US")
        return formatter.string(from: date)
    }
}

// MARK: - Modern Sleep Entry Row
struct ModernSleepEntryRow: View {
    let entry: SleepEntry
    
    var body: some View {
        HStack(spacing: PSSpacing.md) {
            // Type Icon
            Image(systemName: entry.isCore ? "bed.double.fill" : "powersleep")
                .font(.system(size: PSIconSize.small))
                .foregroundColor(.white)
                .frame(width: PSIconSize.medium, height: PSIconSize.medium)
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
        }
        .padding(PSSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: PSCornerRadius.small)
                .fill(Color.appBackground.opacity(0.5))
        )
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
                
                Button(action: action) {
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

// MARK: - Filter Chip (Original - keeping for backward compatibility)
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? .white : .appText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.appPrimary : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? Color.clear : Color.appTextSecondary.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
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
    return formatter.string(from: date)
}

private func formatEntryDuration(_ duration: TimeInterval) -> String {
    let minutes = Int(duration / 60)
    return formatDuration(minutes)
}
