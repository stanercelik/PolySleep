import SwiftUI
import SwiftData

// MARK: - Redacted Shimmer Effect Modifier
struct RedactedShimmerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .modifier(
                AnimatedMaskModifier(
                    direction: .topLeading,
                    duration: 1.5
                )
            )
    }
}

struct AnimatedMaskModifier: ViewModifier {
    enum Direction {
        case topLeading
        case bottomTrailing
        
        var start: UnitPoint {
            switch self {
            case .topLeading: return .topLeading
            case .bottomTrailing: return .bottomTrailing
            }
        }
        
        var end: UnitPoint {
            switch self {
            case .topLeading: return .bottomTrailing
            case .bottomTrailing: return .topLeading
            }
        }
    }
    
    let direction: Direction
    let duration: Double
    @State private var isAnimated = false
    
    func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    gradient: Gradient(
                        stops: [
                            .init(color: .black.opacity(0.5), location: 0),
                            .init(color: .black, location: 0.3),
                            .init(color: .black, location: 0.7),
                            .init(color: .black.opacity(0.5), location: 1)
                        ]
                    ),
                    startPoint: isAnimated ? direction.end : direction.start,
                    endPoint: isAnimated ? direction.start : direction.end
                )
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: duration)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimated = true
                }
            }
    }
}

struct MainScreenView: View {
    @StateObject private var viewModel: MainScreenViewModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var alarmManager: AlarmManager
    
    // Analytics
    private let analyticsManager = AnalyticsManager.shared
    
    init(viewModel: MainScreenViewModel? = nil) {
        let initialViewModel = viewModel ?? MainScreenViewModel(languageManager: LanguageManager.shared)
        _viewModel = StateObject(wrappedValue: initialViewModel)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: PSSpacing.md) {
                        // Header Section
                        HeaderSection(viewModel: viewModel)
                        
                        // Sleep Quality Rating Card
                        if viewModel.showSleepQualityRating, let lastBlock = viewModel.lastSleepBlock {
                            if let startTime = TimeFormatter.time(from: lastBlock.startTime),
                               let endTime = TimeFormatter.time(from: lastBlock.endTime) {
                            
                            let now = Date()
                            let startDate = Calendar.current.date(
                                bySettingHour: startTime.hour,
                                minute: startTime.minute,
                                second: 0,
                                of: now
                            ) ?? now
                            
                            let endDate = Calendar.current.date(
                                bySettingHour: endTime.hour,
                                minute: endTime.minute,
                                second: 0,
                                of: now
                            ) ?? now
                            
                                SleepQualityRatingCard(
                                    startTime: startDate,
                                    endTime: endDate,
                                    isPresented: $viewModel.showSleepQualityRating,
                                    viewModel: viewModel
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        
                        // Status Cards Grid
                        StatusCardsGrid(viewModel: viewModel)
                        
                        // Sleep Chart
                        SleepChartSection(viewModel: viewModel)
                        
                        // Sleep Blocks
                        SleepBlocksSection(viewModel: viewModel)
                        
                        // Daily Tip
                        DailyTipSection(viewModel: viewModel)
                    }
                    .padding(.horizontal, PSSpacing.lg)
                    .padding(.top, PSSpacing.sm)
                    .padding(.bottom, PSSpacing.xl)
                }
                
                // Error Overlay
                if let errorMessage = viewModel.errorMessage {
                    ErrorOverlayCard(errorMessage: errorMessage, viewModel: viewModel)
                }
            }
            .navigationTitle(L("mainScreen.title", table: "MainScreen"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: shareSchedule) {
                        Image(systemName: "square.and.arrow.up")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.appPrimary)
                    }
                }
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
                
                // Analytics: Main screen görüntüleme
                analyticsManager.logScreenView(
                    screenName: "main_screen",
                    screenClass: "MainScreenView"
                )
            }
        }
        .sheet(isPresented: $viewModel.showAddBlockSheet) {
            AddSleepBlockSheet(viewModel: viewModel)
        }
        .onChange(of: viewModel.showAddBlockSheet) { isPresented in
            if isPresented {
                // Analytics: Add Sleep Block sheet açılma
                analyticsManager.logFeatureUsed(
                    featureName: "add_sleep_block",
                    action: "sheet_opened"
                )
            }
        }
        .sheet(isPresented: $viewModel.showScheduleSelection) {
            ScheduleSelectionView(
                availableSchedules: viewModel.availableSchedules,
                selectedSchedule: Binding(
                    get: { viewModel.model.schedule },
                    set: { _ in }
                ),
                onScheduleSelected: viewModel.selectSchedule,
                isPremiumUser: viewModel.isPremium
            )
            .environmentObject(languageManager)
        }
        .id(languageManager.currentLanguage)
    }
    
    private func shareSchedule() {
        // Analytics: Schedule share
        analyticsManager.logFeatureUsed(
            featureName: "main_schedule_share",
            action: "share_button_tap"
        )
        
        let activityVC = UIActivityViewController(
            activityItems: [viewModel.shareScheduleInfo],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Header Section
struct HeaderSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @State private var showScheduleDescription = false
    
    var body: some View {
        PSCard {
            VStack(spacing: PSSpacing.lg) {
                // Ana bilgi kartı
                VStack(spacing: PSSpacing.md) {
                    // Program adı ve toplam uyku - VStack olarak yeniden düzenlendi
                    VStack(spacing: PSSpacing.md) {
                    // Üst satır: Program adı + toplam uyku
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.model.schedule.name)
                                .font(PSTypography.headline)
                                .foregroundColor(.appPrimary)
                            
                            // Program değiştirme butonu
                            Button(action: {
                                viewModel.showScheduleSelectionSheet()
                            }) {
                                HStack(spacing: 4) {
                                    Text(L("mainScreen.changeSchedule.button", table: "MainScreen"))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.appTextSecondary)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.appTextSecondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Spacer()
                        
                        // Toplam uyku süresi
                        VStack(alignment: .trailing, spacing: PSSpacing.xs) {
                            Text(L("mainScreen.totalSleepLabel", table: "MainScreen"))
                                .font(PSTypography.caption)
                                .foregroundColor(.appTextSecondary)
                            
                            Text(viewModel.totalSleepTimeFormatted)
                                .font(PSTypography.headline)
                                .foregroundColor(.appPrimary)
                        }
                    }
                    
                    // Alt satır: Durum badge
                    HStack {
                        PSStatusBadge(
                            viewModel.sleepStatusMessage,
                            icon: viewModel.isInSleepTime ? "moon.fill" : "sun.max.fill",
                            color: viewModel.isInSleepTime ? .appSecondary : .appAccent
                        )
                        
                        Spacer()
                    }
                }
                
                // Program açıklaması toggle
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showScheduleDescription.toggle()
                    }
                }) {
                    HStack(spacing: PSSpacing.sm) {
                        Image(systemName: "info.circle")
                            .font(PSTypography.caption)
                        
                        Text(L("mainScreen.scheduleDescription.title", table: "MainScreen"))
                            .font(PSTypography.caption)
                        
                        Spacer()
                        
                        Image(systemName: showScheduleDescription ? "chevron.up" : "chevron.down")
                            .font(PSTypography.caption)
                    }
                    .foregroundColor(.appPrimary)
                    .padding(.horizontal, PSSpacing.md)
                    .padding(.vertical, PSSpacing.sm)
                    .background(Color.appPrimary.opacity(0.1), in: RoundedRectangle(cornerRadius: PSCornerRadius.small))
                }
                
                // Program açıklaması
                if showScheduleDescription {
                    Text(viewModel.scheduleDescription)
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(PSSpacing.md)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: PSCornerRadius.medium))
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }
                }
            }
        }
    }
}

// MARK: - Status Cards Grid
struct StatusCardsGrid: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: PSSpacing.md) {
            StatusCard(
                icon: "chart.line.uptrend.xyaxis",
                title: L("mainScreen.progress", table: "MainScreen"),
                value: "\(Int(viewModel.dailyProgress * 100))%",
                color: .appAccent
            )
            
            StatusCard(
                icon: "clock.fill",
                title: L("mainScreen.nextSleepBlock", table: "MainScreen"),
                value: viewModel.nextSleepBlockFormatted,
                color: .appSecondary
            )
        }
    }
}

// MARK: - Status Card
struct StatusCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: PSIconSize.medium))
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                Text(title)
                    .font(PSTypography.caption)
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(1)
                
                Text(value)
                    .font(PSTypography.headline)
                    .foregroundColor(.appText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Sleep Chart Section
struct SleepChartSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        PSCard {
            VStack(spacing: PSSpacing.lg) {
                PSSectionHeader(
                    L("mainScreen.sleepChart.title", table: "MainScreen"),
                    icon: "chart.pie.fill"
                )
                
                CircularSleepChart(schedule: viewModel.model.schedule.toSleepScheduleModel)
                    .frame(height: 280)
            }
        }
    }
}

// MARK: - Sleep Blocks Section
struct SleepBlocksSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        PSCard {
            VStack(spacing: PSSpacing.lg) {
                HStack {
                    PSSectionHeader(
                        L("mainScreen.sleepBlocks", table: "MainScreen"),
                        icon: "bed.double.fill"
                    )
                    
                    Spacer()
                    
                    // Düzenleme modu aktifken edit butonu
                    if viewModel.isEditing {
                        HStack(spacing: PSSpacing.sm) {
                            PSStatusBadge(
                                L("mainScreen.editing.mode", table: "MainScreen"),
                                color: .appSecondary
                            )
                            
                            PSIconButton(
                                icon: "checkmark",
                                backgroundColor: Color.appSecondary.opacity(0.15),
                                foregroundColor: .appSecondary
                            ) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    viewModel.isEditing.toggle()
                                }
                            }
                        }
                    } else {
                        PSIconButton(icon: "pencil") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.isEditing.toggle()
                            }
                        }
                    }
                }
            
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: PSSpacing.md) {
                    if viewModel.isEditing {
                        AddSleepBlockCard(viewModel: viewModel)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8, anchor: .leading).combined(with: .opacity),
                                removal: .scale(scale: 0.8, anchor: .leading).combined(with: .opacity)
                            ))
                    }
                    
                    ForEach(viewModel.model.schedule.schedule) { block in
                        SleepBlockCard(
                            block: block,
                            nextBlock: viewModel.model.schedule.nextBlock,
                            nextBlockTime: viewModel.nextSleepBlockFormatted,
                            viewModel: viewModel
                        )
                    }
                    }
                    .padding(.horizontal, PSSpacing.xs)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isEditing)
                }
            }
        }
    }
}

// MARK: - Daily Tip Section
struct DailyTipSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        PSCard {
            VStack(spacing: PSSpacing.lg) {
                PSSectionHeader(
                    L("mainScreen.dailyTip.title", table: "MainScreen"),
                    icon: "lightbulb.fill"
                )
                
                Text(viewModel.dailyTip, tableName: "Tips")
                    .font(PSTypography.body)
                    .foregroundColor(.appTextSecondary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(PSSpacing.md)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: PSCornerRadius.medium))
            }
        }
    }
}

// MARK: - Sleep Quality Rating Card
struct SleepQualityRatingCard: View {
    let startTime: Date
    let endTime: Date
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        PSCard {
            SleepQualityRatingView(
                startTime: startTime,
                endTime: endTime,
                isPresented: $isPresented,
                viewModel: viewModel
            )
        }
    }
}

// MARK: - Error Overlay Card
struct ErrorOverlayCard: View {
    let errorMessage: String
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        PSErrorState(
            title: L("mainscreen.error.title", table: "MainScreen"),
            message: errorMessage
        ) {
            Task {
                await viewModel.loadScheduleFromRepository()
            }
        }
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: PSCornerRadius.extraLarge))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, PSSpacing.xxxl)
    }
}

// MARK: - Add Sleep Block Card
struct AddSleepBlockCard: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        Button(action: {
            viewModel.showAddBlockSheet = true
        }) {
            VStack(alignment: .leading, spacing: PSSpacing.sm) {
                HStack(spacing: PSSpacing.sm) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: PSIconSize.medium))
                        .foregroundColor(.appAccent)
                    
                    VStack(alignment: .leading, spacing: PSSpacing.xs) {
                        Text(L("mainScreen.addSleepBlock", table: "MainScreen"))
                            .font(PSTypography.button)
                            .foregroundColor(.appAccent)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                    
                    Spacer(minLength: 0)
                }
            }
            .frame(minWidth: 150, maxWidth: .infinity)
            .frame(height: 85)
            .padding(PSSpacing.md)
            .background(Color.appAccent.opacity(0.1), in: RoundedRectangle(cornerRadius: PSCornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                    .stroke(Color.appAccent.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6, 3]))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sleep Block Card
struct SleepBlockCard: View {
    let block: SleepBlock
    let nextBlock: SleepBlock?
    let nextBlockTime: String
    
    @State private var showingEditSheet = false
    @State private var showDeleteConfirmation = false
    @ObservedObject var viewModel: MainScreenViewModel
    
    // Kullanıcının seçtiği emojiler
    private var coreEmoji: String {
        UserDefaults.standard.string(forKey: "selectedCoreEmoji") ?? "🌙"
    }
    
    private var napEmoji: String {
        UserDefaults.standard.string(forKey: "selectedNapEmoji") ?? "💤"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.sm) {
            HStack(spacing: PSSpacing.sm) {
                // Kişiselleştirilmiş emoji kullan
                Text(block.isCore ? coreEmoji : napEmoji)
                    .font(.system(size: PSIconSize.medium - 4))
                    .frame(width: PSIconSize.medium + 12, height: PSIconSize.medium + 12)
                    .background(
                        Circle()
                            .fill(block.isCore ? Color.appPrimary.opacity(0.15) : Color.appSecondary.opacity(0.15))
                    )
                
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    // Saatleri yan yana daha düzgün göstermek için
                    HStack(spacing: PSSpacing.xs) {
                        Text(TimeFormatter.formattedString(from: block.startTime))
                            .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                            .foregroundColor(.appText)
                        
                        Text("—")
                            .font(PSTypography.body)
                            .foregroundColor(.appTextSecondary)
                        
                        Text(TimeFormatter.formattedString(from: block.endTime))
                            .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                            .foregroundColor(.appText)
                    }
                    
                    Text(block.isCore ? L("mainScreen.sleepBlockCore", table: "MainScreen") : L("mainScreen.sleepBlockNap", table: "MainScreen"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
            }
        }
        .overlay(alignment: .topTrailing) {
            // Context menu butonu - card'ın tam sağ üst köşesinde
            if viewModel.isEditing {
                Menu {
                    Button(action: {
                        viewModel.prepareForEditing(block)
                        showingEditSheet = true
                    }) {
                        Label(L("general.edit", table: "MainScreen"), systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        showDeleteConfirmation = true
                    }) {
                        Label(L("general.delete", table: "MainScreen"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.appBackground.opacity(0.9))
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.appTextSecondary.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .offset(x: 0, y: 0)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .frame(minWidth: 150, maxWidth: .infinity)
        .frame(height: 85)
        .padding(PSSpacing.md)
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: PSCornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                .stroke(block.isCore ? Color.appPrimary.opacity(0.2) : Color.appAccent.opacity(0.2), lineWidth: 1)
        )
        .sheet(isPresented: $showingEditSheet) {
            EditSleepBlockSheet(viewModel: viewModel)
        }
        .confirmationDialog(
            L("sleepBlock.delete.title", table: "MainScreen"),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L("sleepBlock.delete.confirm", table: "MainScreen"), role: .destructive) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.deleteBlock(block)
                }
            }
            Button(L("general.cancel", table: "MainScreen"), role: .cancel) {}
        } message: {
            Text(L("sleepBlock.delete.message", table: "MainScreen"))
        }
    }
}

// MARK: - Edit Sleep Block Sheet
struct EditSleepBlockSheet: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        L("sleepBlock.startTime", table: "MainScreen"),
                        selection: $viewModel.editingBlockStartTime,
                        displayedComponents: .hourAndMinute
                    )
                    .font(PSTypography.body)
                    
                    DatePicker(
                        L("sleepBlock.endTime", table: "MainScreen"),
                        selection: $viewModel.editingBlockEndTime,
                        displayedComponents: .hourAndMinute
                    )
                    .font(PSTypography.body)
                }
                
                Section(header: Text(L("sleepBlock.typeTitle", table: "MainScreen")).font(PSTypography.caption)) {
                    Text(L("sleepBlock.autoType", table: "MainScreen"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                }
            }
            .navigationTitle(L("sleepBlock.edit", table: "MainScreen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Text(L("general.cancel", table: "MainScreen"))
                            .font(PSTypography.button)
                            .foregroundColor(.appPrimary)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        if viewModel.validateEditingBlock() {
                            viewModel.updateBlock()
                            dismiss()
                        }
                    }) {
                        Text(L("general.save", table: "MainScreen"))
                            .font(PSTypography.button)
                    }
                }
            }
            .alert(
                L("sleepBlock.error.title", table: "MainScreen"),
                isPresented: $viewModel.showBlockError
            ) {
                Button(L("general.ok", table: "MainScreen"), role: .cancel) {}
            } message: {
                Text(viewModel.blockErrorMessage)
            }
        }
    }
}

// MARK: - Legacy Components (Backward Compatibility)

// MARK: - Header Card
struct HeaderCard: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @State private var showScheduleDescription: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HeaderSection(viewModel: viewModel)
    }
}

// MARK: - Sleep Chart Card
struct SleepChartCard: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        SleepChartSection(viewModel: viewModel)
    }
}

// MARK: - Sleep Blocks Card
struct SleepBlocksCard: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        SleepBlocksSection(viewModel: viewModel)
    }
}

// MARK: - Info Cards Section
struct InfoCardsSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        StatusCardsGrid(viewModel: viewModel)
    }
}

// MARK: - Daily Tip Card
struct DailyTipCard: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        DailyTipSection(viewModel: viewModel)
    }
}

// MARK: - Add Block Button
struct AddBlockButton: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        AddSleepBlockCard(viewModel: viewModel)
    }
}

// MARK: - Tip Section
struct TipSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Text(viewModel.dailyTip, tableName: "Tips")
            .font(.subheadline)
            .foregroundColor(.appTextSecondary)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Main Info Card
struct MainInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        StatusCard(icon: icon, title: title, value: value, color: color)
    }
}

// MARK: - Edit Action Button
struct EditActionButton: View {
    let systemImage: String
    let backgroundColor: Color
    let isPressed: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(backgroundColor, in: Circle())
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let config = ModelConfiguration()
    let container = try! ModelContainer(for: SleepScheduleStore.self, configurations: config)
    MainScreenView(viewModel: MainScreenViewModel(languageManager: LanguageManager.shared))
        .modelContainer(container)
        .environmentObject(LanguageManager.shared)
}

