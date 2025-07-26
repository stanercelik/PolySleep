import SwiftUI
import SwiftData

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var mainScreenViewModel: MainScreenViewModel
    
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
                        
                        // Unified Sleep Timeline - includes both manual and HealthKit data
                        if viewModel.historyItems.isEmpty && viewModel.healthKitData.isEmpty {
                            EmptyStateCard()
                        } else {
                            HistoryTimelineSection(viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, PSSpacing.lg)
                    .padding(.vertical, PSSpacing.sm)
                    .padding(.bottom, 100)
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
                AddSleepEntrySheet(
                    viewModel: viewModel,
                    availableBlocks: mainScreenViewModel.model.schedule.schedule
                )
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
                
                // HealthKit verilerini direkt yükle (first load için) - küçük delay ile
                Task {
                    // Context'in set edilmesini bekle
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 saniye
                    await viewModel.loadHealthKitData()
                }
                
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

// MARK: - Modern Sleep Timeline Section
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
                        String(format: L("history.timeline.count", table: "History"), getTotalDaysCount()),
                        color: .appAccent
                    )
                }
                .padding(.horizontal, PSSpacing.lg)
                .padding(.top, PSSpacing.lg)
                
                // Unified Timeline Content with Visual Connectors
                // Using PSSpacing.sm (8pt) for tighter timeline flow as requested by UX designer
                LazyVStack(spacing: PSSpacing.sm) {
                    let unifiedDays = getUnifiedDailyData()
                    ForEach(Array(unifiedDays.enumerated()), id: \.element.date) { index, dayData in
                        TimelineCardWrapper(
                            dayData: dayData,
                            viewModel: viewModel,
                            isFirst: index == 0,
                            isLast: index == unifiedDays.count - 1
                        )
                        .padding(.horizontal, PSSpacing.sm)
                        .id(dayData.date) // Stable identity for better animation performance
                    }
                }
                .padding(.vertical, PSSpacing.md)
                .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: viewModel.historyItems.count)
            }
        }
    }
    
    private func getTotalDaysCount() -> Int {
        return getUnifiedDailyData().count
    }
    
    private func getUnifiedDailyData() -> [UnifiedDayData] {
        var unifiedDays: [UnifiedDayData] = []
        
        // Merge manual entries and HealthKit data with time-based deduplication
        let allDates = Set(viewModel.historyItems.map { Calendar.current.startOfDay(for: $0.date) })
            .union(Set(viewModel.healthKitData.map { Calendar.current.startOfDay(for: $0.startDate) }))
        
        for date in allDates.sorted(by: >) {
            let manualEntries = viewModel.historyItems.filter { 
                Calendar.current.isDate($0.date, inSameDayAs: date) 
            }
            
            let healthKitEntries = viewModel.healthKitData.filter { 
                Calendar.current.isDate($0.startDate, inSameDayAs: date) 
            }
            
            // Smart deduplication: Filter out HealthKit entries that overlap with manual entries
            let filteredHealthKitEntries = filterOverlappingHealthKitEntries(
                healthKitEntries: healthKitEntries,
                manualEntries: manualEntries.first?.sleepEntries ?? []
            )
            
            let dayData = UnifiedDayData(
                date: date,
                manualEntries: manualEntries.first?.sleepEntries ?? [],
                healthKitEntries: filteredHealthKitEntries,
                rating: manualEntries.first?.averageRating ?? 0
            )
            
            unifiedDays.append(dayData)
        }
        
        return unifiedDays
    }
    
    /// Filters HealthKit entries that overlap with manual entries
    private func filterOverlappingHealthKitEntries(
        healthKitEntries: [HealthKitSleepSample],
        manualEntries: [SleepEntry]
    ) -> [HealthKitSleepSample] {
        return healthKitEntries.filter { healthKitEntry in
            // Check if this HealthKit entry overlaps with any manual entry
            !manualEntries.contains { manualEntry in
                timeRangesOverlap(
                    start1: healthKitEntry.startDate,
                    end1: healthKitEntry.endDate,
                    start2: manualEntry.startTime,
                    end2: manualEntry.endTime
                )
            }
        }
    }
    
    /// Checks if two time ranges overlap
    private func timeRangesOverlap(start1: Date, end1: Date, start2: Date, end2: Date) -> Bool {
        // Two ranges overlap if start1 < end2 AND start2 < end1
        return start1 < end2 && start2 < end1
    }
}

// MARK: - Unified Day Data Model
struct UnifiedDayData {
    let date: Date
    let manualEntries: [SleepEntry]
    let healthKitEntries: [HealthKitSleepSample]
    let rating: Double
    
    var totalSleepDuration: TimeInterval {
        let manualDuration = manualEntries.reduce(0) { $0 + $1.duration }
        let healthKitDuration = healthKitEntries.reduce(0) { $0 + $1.duration }
        return manualDuration + healthKitDuration
    }
    
    var coreBlocksCount: Int {
        return manualEntries.filter { $0.isCore }.count
    }
    
    var napBlocksCount: Int {
        return manualEntries.filter { !$0.isCore }.count + healthKitEntries.count
    }
    
    var totalBlocksCount: Int {
        return manualEntries.count + healthKitEntries.count
    }
}

// MARK: - Timeline Card Wrapper with Visual Connectors
struct TimelineCardWrapper: View {
    let dayData: UnifiedDayData
    @ObservedObject var viewModel: HistoryViewModel
    let isFirst: Bool
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: PSSpacing.md) {
            // Timeline Connector
            TimelineConnector(
                isFirst: isFirst,
                isLast: isLast,
                hasData: dayData.totalBlocksCount > 0
            )
            
            // Main Card Content
            DailySleepCard(
                dayData: dayData,
                viewModel: viewModel
            )
        }
    }
}

// MARK: - Timeline Visual Connector
struct TimelineConnector: View {
    let isFirst: Bool
    let isLast: Bool
    let hasData: Bool
    
    private let lineWidth: CGFloat = 2
    private let nodeSize: CGFloat = 10 // Slightly larger for better visibility
    
    var body: some View {
        VStack(spacing: 0) {
            // Top line (hidden for first item)
            Rectangle()
                .fill(isFirst ? Color.clear : lineColor)
                .frame(width: lineWidth, height: PSSpacing.xl)
            
            // Timeline node with enhanced styling
            Circle()
                .fill(nodeColor)
                .frame(width: nodeSize, height: nodeSize)
                .overlay(
                    Circle()
                        .stroke(Color.appCardBackground, lineWidth: 2)
                )
                .overlay(
                    // Inner dot for data indicators
                    Circle()
                        .fill(hasData ? Color.white : Color.clear)
                        .frame(width: nodeSize * 0.4, height: nodeSize * 0.4)
                )
                .shadow(color: nodeColor.opacity(0.4), radius: 3, x: 0, y: 1)
            
            // Bottom line (hidden for last item) - Height adjusted for PSSpacing.sm
            Rectangle()
                .fill(isLast ? Color.clear : lineColor)
                .frame(width: lineWidth)
                .frame(minHeight: PSSpacing.xl + PSSpacing.sm) // Reduced from PSSpacing.lg to PSSpacing.sm
        }
        .frame(width: max(nodeSize, lineWidth))
    }
    
    private var nodeColor: Color {
        hasData ? Color.appPrimary : Color.appBorder.opacity(0.6)
    }
    
    private var lineColor: Color {
        hasData ? Color.appPrimary.opacity(0.3) : Color.appBorder.opacity(0.3)
    }
}

// MARK: - Daily Sleep Card - Expandable Design
struct DailySleepCard: View {
    let dayData: UnifiedDayData
    @ObservedObject var viewModel: HistoryViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var isExpanded = false
    @State private var showingActionsMenu = false
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: SleepEntry?

    private var displayRating: Double {
        dayData.manualEntries.isEmpty ? 0.0 : dayData.rating
    }

    private var hasManualActions: Bool {
        !dayData.manualEntries.isEmpty
    }

    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: 0) {
                closedCardContent
                
                if isExpanded {
                    expandedCardContent
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)).combined(with: .offset(y: -10)),
                            removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)).combined(with: .offset(y: -10))
                        ))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: isExpanded)
                }
            }
        }
        .shadow(color: Color.appPrimary.opacity(0.08), radius: 8, x: 0, y: 2)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .alert(L("history.alert.delete.title", table: "History"), isPresented: $showingDeleteAlert) {
            Button(L("history.alert.delete.cancel", table: "History"), role: .cancel) {}
            Button(L("history.alert.delete.confirm", table: "History"), role: .destructive) {
                if let entry = entryToDelete {
                    viewModel.deleteSleepEntry(entry)
                    entryToDelete = nil
                }
            }
        }
        .actionSheet(isPresented: $showingActionsMenu) {
            ActionSheet(
                title: Text(L("history.actions.title", table: "History")),
                buttons: [
                    .default(Text(L("history.actions.edit", table: "History"))) {
                        // Handle edit action
                    },
                    .destructive(Text(L("history.actions.delete", table: "History"))) {
                        // Handle delete day action
                    },
                    .cancel()
                ]
            )
        }
    }
    
    private var closedCardContent: some View {
        Button(action: {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) { 
                isExpanded.toggle() 
            }
        }) {
            HStack(alignment: .center, spacing: PSSpacing.sm) {
                // MARK: - Date Section
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Calendar.current.component(.day, from: dayData.date))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.appPrimary)
                        
                        Text(monthString(from: dayData.date, format: "MMM"))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.appTextSecondary)
                            .padding(.top, 5) // Align with day number
                    }
                    
                    Text(relativeTimeString(from: dayData.date))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(relativeTimeColor(from: dayData.date))
                        .padding(.leading, 2)
                }
                .padding(.trailing, PSSpacing.xxs)
                .frame(maxHeight: .infinity, alignment: .top)
                
                // MARK: - Sleep Details Section
                VStack(alignment: .leading, spacing: 0) {
                    // Top part: Total duration and block counts
                    VStack(alignment: .leading, spacing: PSSpacing.sm) {
                        Text("\(L("history.card.total", table: "History")): \(formatDuration(Int(dayData.totalSleepDuration / 60)))")
                            .font(PSTypography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.appText)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: PSSpacing.sm) {
                            if dayData.coreBlocksCount > 0 {
                                HStack(spacing: PSSpacing.xs) { Text("🌙").font(.system(size: 14)); Text("x \(dayData.coreBlocksCount)").font(PSTypography.caption).foregroundColor(.appTextSecondary) }
                            }
                            if dayData.coreBlocksCount > 0 && dayData.napBlocksCount > 0 {
                                Text("・").font(PSTypography.caption).foregroundColor(.appTextSecondary.opacity(0.5))
                            }
                            if dayData.napBlocksCount > 0 {
                                HStack(spacing: PSSpacing.xs) { Text("💤").font(.system(size: 14)); Text("x \(dayData.napBlocksCount)").font(PSTypography.caption).foregroundColor(.appTextSecondary) }
                            }
                        }
                    }
                    
                    Spacer(minLength: PSSpacing.md)
                    
                    // Bottom part: Star rating
                    HStack(spacing: PSSpacing.sm) {
                        StarsView(rating: displayRating, size: PSIconSize.small, primaryColor: .appAccent, emptyColor: .appTextSecondary.opacity(0.2))
                        Text(String(format: "%.1f", displayRating))
                            .font(PSTypography.caption.weight(.semibold))
                            .foregroundColor(.appTextSecondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, PSSpacing.sm)
                
                
                // MARK: - Action Buttons Section
                VStack(alignment: .trailing) {
                    Button(action: {
                        if hasManualActions { showingActionsMenu = true } 
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: PSIconSize.small))
                            .foregroundColor(.appTextSecondary)
                            .rotationEffect(.degrees(90))
                            .padding(PSSpacing.lg) // Increase tappable area
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    .disabled(!hasManualActions)
                    .opacity(hasManualActions ? 1.0 : 0.4)
                    .onTapGesture {
                        if hasManualActions { showingActionsMenu = true }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: PSIconSize.small, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0), value: isExpanded)
                        .padding(PSSpacing.lg)
                }
                .padding(.leading, PSSpacing.xxs)
                .frame(maxHeight: .infinity, alignment: .center)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var expandedCardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .background(Color.appBorder.opacity(0.3))
                .padding(.horizontal, PSSpacing.lg)
                .padding(.vertical, PSSpacing.sm)
            
            LazyVStack(spacing: PSSpacing.sm) {
                ForEach(dayData.manualEntries) { entry in
                    SleepEntryDetailRow(entry: .manual(entry), onDelete: {
                        entryToDelete = entry
                        showingDeleteAlert = true
                    })
                    .drawingGroup() // GPU acceleration for complex views
                }
                ForEach(dayData.healthKitEntries, id: \.startDate) { sample in
                    SleepEntryDetailRow(entry: .healthKit(sample), onDelete: nil)
                        .drawingGroup() // GPU acceleration for complex views
                }
            }
            .padding(.vertical, PSSpacing.lg)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .clipped() // Prevents layout issues during animation
    }
    
    private func monthString(from date: Date, format: String = "MMMM") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = languageManager.currentLocale
        return formatter.string(from: date)
    }
    
    private func relativeTimeString(from date: Date) -> String {
        let calendar = Calendar.current, now = Date()
        if calendar.isDateInToday(date) { return L("history.relative.today", table: "History") }
        if calendar.isDateInYesterday(date) { return L("history.relative.yesterday", table: "History") }
        let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
        if days <= 7 { return String(format: L("history.relative.daysAgo", table: "History"), days) }
        let weeks = days / 7
        return weeks == 1 ? L("history.relative.oneWeekAgo", table: "History") : String(format: L("history.relative.weeksAgo", table: "History"), weeks)
    }
    
    private func relativeTimeColor(from date: Date) -> Color {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return .appPrimary.opacity(0.9) }
        if calendar.isDateInYesterday(date) { return .appSecondary.opacity(0.8) }
        return .appAccent.opacity(0.7)
    }
}

// MARK: - Sleep Entry Detail Row for Expanded State
struct SleepEntryDetailRow: View {
    let entry: SleepEntryType
    let onDelete: (() -> Void)?
    
    enum SleepEntryType {
        case manual(SleepEntry)
        case healthKit(HealthKitSleepSample)
    }
    
    var body: some View {
        HStack(spacing: PSSpacing.md) {
            Image(systemName: iconName)
                .font(.system(size: PSIconSize.medium))
                .foregroundColor(iconColor)
                .frame(width: 30, alignment: .center)
            
            VStack(alignment: .leading, spacing: PSSpacing.xs) {
                Text(timeRange)
                    .font(PSTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appText)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    Text(duration)
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                    
                    Spacer()
                    
                    DataSourceIndicator(isFromHealthKit: isFromHealthKit)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: PSIconSize.medium))
                        .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
                .frame(width: 30, alignment: .center)
            } else {
                Spacer().frame(width: 30)
            }
        }
        .padding(.vertical, PSSpacing.sm)
        .padding(.horizontal, PSSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: PSCornerRadius.small)
                .fill(Color.appBackground.opacity(0.3))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle()) // Better hit testing performance
    }
    
    private var iconName: String {
        switch entry {
        case .manual(let sleepEntry): return sleepEntry.isCore ? "moon.fill" : "powersleep"
        case .healthKit(let sample): return sample.type == .asleep ? "moon.fill" : "powersleep"
        }
    }
    
    private var iconColor: Color {
        switch entry {
        case .manual(let sleepEntry): return sleepEntry.isCore ? .appPrimary : .appSecondary
        case .healthKit: return .green
        }
    }
    
    private var timeRange: String {
        switch entry {
        case .manual(let sleepEntry): return "\(formatTime(sleepEntry.startTime)) - \(formatTime(sleepEntry.endTime))"
        case .healthKit(let sample): return "\(formatTime(sample.startDate)) - \(formatTime(sample.endDate))"
        }
    }
    
    private var duration: String {
        switch entry {
        case .manual(let sleepEntry): return formatEntryDuration(sleepEntry.duration)
        case .healthKit(let sample):
            let hours = Int(sample.duration) / 3600, minutes = (Int(sample.duration) % 3600) / 60
            return String(format: "%dh %dm", hours, minutes)
        }
    }
    
    private var isFromHealthKit: Bool {
        switch entry {
        case .manual: return false
        case .healthKit: return true
        }
    }
}

// MARK: - Data Source Indicator
struct DataSourceIndicator: View {
    let isFromHealthKit: Bool
    
    var body: some View {
        HStack(spacing: PSSpacing.xs) {
            Image(systemName: isFromHealthKit ? "heart.circle.fill" : "pencil.circle.fill")
                .font(.system(size: PSIconSize.small - 2))
                .foregroundColor(isFromHealthKit ? .green : .appSecondary)
            
            Text(isFromHealthKit ? L("history.source.health", table: "History") : L("history.source.manual", table: "History"))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
        .padding(.horizontal, PSSpacing.xs)
        .padding(.vertical, 2)
        .background(RoundedRectangle(cornerRadius: PSCornerRadius.small - 2).fill(Color.appBackground.opacity(0.5)))
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
