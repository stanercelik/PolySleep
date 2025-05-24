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
                    VStack(spacing: 24) {
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
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
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.appPrimary)
                
                Text(L("history.stats.title", table: "History"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
                
                Spacer()
                
                // Quick insights
                Text(L("history.stats.thisWeek", table: "History"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.appSecondaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.appSecondary.opacity(0.15))
                    )
            }
            
            // Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
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
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
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
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.appText)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.appSecondaryText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.title2)
                    .foregroundColor(.appSecondary)
                
                Text(L("history.filter.title", table: "History"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
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
                .padding(.horizontal, 4)
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

// MARK: - Modern Filter Chip
struct ModernFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .white : .appText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected ? 
                        LinearGradient(
                            gradient: Gradient(colors: [.appPrimary, .appSecondary]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [.appCardBackground, .appCardBackground]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? Color.clear : Color.appSecondaryText.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isSelected ? Color.appPrimary.opacity(0.3) : Color.clear,
                        radius: isSelected ? 8 : 0,
                        x: 0,
                        y: isSelected ? 4 : 0
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
        VStack(spacing: 24) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.appPrimary.opacity(0.1), Color.appSecondary.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "bed.double")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.appPrimary.opacity(0.6))
            }
            
            VStack(spacing: 12) {
                Text(L("history.noRecords.title", table: "History"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.appText)
                
                Text(L("history.noRecords.message", table: "History"))
                    .font(.body)
                    .foregroundColor(.appSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button(action: {
                // Add new record action will be handled by parent
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)
                    Text(L("history.addNewRecord", table: "History"))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.appPrimary, .appSecondary]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.appPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - History Content Section
struct HistoryContentSection: View {
    @ObservedObject var viewModel: HistoryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(.appAccent)
                
                Text(L("history.timeline.title", table: "History"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
                
                Spacer()
                
                Text(String(format: L("history.timeline.count", table: "History"), viewModel.historyItems.count))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.appSecondaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.appAccent.opacity(0.15))
                    )
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 4)
            
            LazyVStack(spacing: 12) {
                ForEach(groupedByMonth(items: viewModel.historyItems), id: \.month) { monthGroup in
                    MonthSection(month: monthGroup.month, items: monthGroup.days, viewModel: viewModel)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private func groupedByMonth(items: [HistoryModel]) -> [(month: String, days: [HistoryModel])] {
        let grouped = Dictionary(grouping: items) { item -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: item.date)
        }
        
        return grouped.map { (month: $0.key, days: $0.value) }
            .sorted { item1, item2 in
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
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
        VStack(spacing: 12) {
            // Month Header
            HStack {
                Text(month)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.appPrimary)
                
                Spacer()
                
                Text(String(format: L("history.month.entries", table: "History"), items.count))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.appSecondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.appPrimary.opacity(0.1))
                    )
            }
            
            // Days
            VStack(spacing: 8) {
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
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectDateForDetail(item.date)
            }
        }) {
            VStack(spacing: 16) {
                // Header Row
                HStack {
                    // Date & Day Info
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.appText)
                            
                            Text(dayOfWeek(from: item.date))
                                .font(.subheadline)
                                .foregroundColor(.appSecondaryText)
                        }
                        
                        if Calendar.current.isDateInToday(item.date) {
                            TodayBadge()
                        }
                    }
                    
                    Spacer()
                    
                    // Rating
                    if item.sleepEntries?.isEmpty ?? true {
                        Text(L("history.noRecord", table: "History"))
                            .font(.caption)
                            .foregroundColor(.appSecondaryText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.gray.opacity(0.1))
                            )
                    } else {
                        HStack(spacing: 4) {
                            Text(String(format: "%.1f", item.averageRating))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.appPrimary)
                            
                            Image(systemName: "star.fill")
                                .font(.subheadline)
                                .foregroundColor(.yellow)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.yellow.opacity(0.1))
                        )
                    }
                }
                
                // Sleep Entries Preview
                if let entries = item.sleepEntries, !entries.isEmpty {
                    let entriesToDisplay = entries.sorted { $0.startTime < $1.startTime }.prefix(2)
                    VStack(spacing: 8) {
                        ForEach(Array(entriesToDisplay)) { entry in
                            ModernSleepEntryRow(entry: entry)
                        }
                        
                        if entries.count > 2 {
                            HStack {
                                Text(String(format: L("history.moreBlocks", table: "History"), entries.count - 2))
                                    .font(.caption)
                                    .foregroundColor(.appPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.appSecondaryText)
                            }
                            .padding(.horizontal, 8)
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "moon.zzz")
                            .font(.title2)
                            .foregroundColor(.appSecondaryText.opacity(0.5))
                        
                        Text(L("history.noRecord", table: "History"))
                            .font(.body)
                            .foregroundColor(.appSecondaryText)
                        
                        Spacer()
                    }
                    .padding(.vertical, 20)
                }
                
                // Footer Stats
                HStack(spacing: 20) {
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
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(item.completionStatus.color))
                            .frame(width: 8, height: 8)
                        
                        Text(item.completionStatus.localizedTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.appSecondaryText)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(item.completionStatus.color).opacity(0.1))
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.appSecondaryText.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
            )
        }
        .buttonStyle(ModernCardButtonStyle())
    }
    
    private func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

// MARK: - Today Badge
struct TodayBadge: View {
    var body: some View {
        Text(L("history.today", table: "History"))
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(todayBadgeBackground)
            .foregroundColor(.white)
            .shadow(color: Color.appPrimary.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    private var todayBadgeBackground: some View {
        Capsule()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [.appPrimary, .appSecondary]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
}

// MARK: - Modern Sleep Entry Row
struct ModernSleepEntryRow: View {
    let entry: SleepEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Type Icon
            Image(systemName: entry.isCore ? "bed.double.fill" : "powersleep")
                .font(.callout)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
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
                .shadow(color: (entry.isCore ? Color.appPrimary : Color.appSecondary).opacity(0.3), radius: 4, x: 0, y: 2)
            
            // Entry Info
            VStack(alignment: .leading, spacing: 2) {
                Text("\(formatTime(entry.startTime)) - \(formatTime(entry.endTime))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
                
                Text(entry.isCore ? L("sleep.type.core", table: "History") : L("sleep.type.nap", table: "History"))
                    .font(.caption)
                    .foregroundColor(.appSecondaryText)
            }
            
            Spacer()
            
            // Duration Badge
            Text(formatEntryDuration(entry.duration))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(entry.isCore ? .appPrimary : .appSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill((entry.isCore ? Color.appPrimary : Color.appSecondary).opacity(0.1))
                )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

// MARK: - Stat Pill
struct StatPill: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.appText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
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
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.appPrimary, .appSecondary]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.appPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
                        )
                }
                .buttonStyle(FloatingButtonStyle())
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Custom Button Styles
struct ModernCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct FloatingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Scale Button Style (from existing code)
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Card Button Style (from existing code)
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
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
                                .stroke(isSelected ? Color.clear : Color.appSecondaryText.opacity(0.3), lineWidth: 1)
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
