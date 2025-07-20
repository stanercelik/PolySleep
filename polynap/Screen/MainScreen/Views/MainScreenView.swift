import SwiftUI
import SwiftData

// MARK: - Modern Segmented Control
struct ModernSegmentedControl: View {
    @Binding var selectedSegment: Int
    @Namespace private var animation
    
    private let segments = [
        ("chart.pie.fill", L("mainScreen.segment.overview", table: "MainScreen")),
        ("list.bullet.clipboard.fill", L("mainScreen.segment.details", table: "MainScreen"))
    ]
    
    var body: some View {
        HStack(spacing: PSSpacing.xs) {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                let isSelected = selectedSegment == index
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.1)) {
                        selectedSegment = index
                    }
                }) {
                    HStack(spacing: PSSpacing.xs) {
                        Image(systemName: segment.0)
                            .font(.system(size: 15, weight: .medium))
                            .symbolVariant(isSelected ? .fill : .none)
                            .symbolRenderingMode(.hierarchical)
                        
                        Text(segment.1)
                            .font(PSTypography.caption.weight(.semibold))
                    }
                    .foregroundColor(isSelected ? .appTextOnPrimary : .appTextSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: PSCornerRadius.small)
                                .fill(Color.appPrimary)
                                .matchedGeometryEffect(id: "selectedSegment", in: animation)
                        }
                    }
                    .scaleEffect(isSelected ? 1.0 : 0.96)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(PSSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                .fill(Color.appCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                        .stroke(Color.appPrimary.opacity(0.06), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

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
                
                VStack(spacing: 0) {
                    // Modern Segmented Control
                    ModernSegmentedControl(selectedSegment: $viewModel.selectedSegment)
                        .padding(.horizontal, PSSpacing.lg)
                        .padding(.top, PSSpacing.sm)
                        .padding(.bottom, PSSpacing.md)
                    
                    // Content based on selected segment
                    Group {
                        if viewModel.selectedSegment == 0 {
                            MinimalSegmentView(viewModel: viewModel)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        } else {
                            DetailedSegmentView(viewModel: viewModel)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                    }
                    .animation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.2), value: viewModel.selectedSegment)
                    
                    // Error Overlay
                    if let errorMessage = viewModel.errorMessage {
                        ErrorOverlayCard(errorMessage: errorMessage, viewModel: viewModel)
                    }
                    
                    // Sleep Quality Rating Card (Global overlay)
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
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .zIndex(100)
                        }
                    }
                }
            }
            .navigationTitle(L("mainScreen.title", table: "MainScreen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Cancel button for edit mode
                    if viewModel.isChartEditMode {
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            viewModel.cancelChartEdit()
                        }) {
                            Text(L("common.cancel", table: "Common"))
                                .font(PSTypography.caption.weight(.medium))
                                .foregroundColor(.appTextSecondary)
                                .padding(.horizontal, PSSpacing.sm)
                                .padding(.vertical, PSSpacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: PSCornerRadius.small)
                                        .fill(Color.appTextSecondary.opacity(0.1))
                                )
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    } else {
                        Button(action: shareSchedule) {
                            Image(systemName: "square.and.arrow.up")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(.appPrimary)
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        if viewModel.isChartEditMode {
                            viewModel.saveChartEdit()
                        } else {
                            // Eğer detailed segment'tayken edit'e basılırsa, önce overview'e geç
                            if viewModel.selectedSegment != 0 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.selectedSegment = 0
                                }
                                // Biraz bekle, sonra edit modunu başlat
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    viewModel.startChartEdit()
                                }
                            } else {
                                viewModel.startChartEdit()
                            }
                        }
                    }) {
                        HStack(spacing: PSSpacing.xs) {
                            Image(systemName: viewModel.isChartEditMode ? "checkmark" : "pencil")
                                .symbolRenderingMode(.hierarchical)
                                .font(.system(size: 16, weight: .medium))
                            
                            if viewModel.isChartEditMode {
                                Text(L("mainScreen.chart.save", table: "MainScreen"))
                                    .font(PSTypography.caption.weight(.medium))
                            } else {
                                Text(L("mainScreen.chart.edit", table: "MainScreen"))
                                    .font(PSTypography.caption.weight(.medium))
                            }
                        }
                        .foregroundColor(viewModel.isChartEditMode ? .appSuccess : .appPrimary)
                        .padding(.horizontal, PSSpacing.sm)
                        .padding(.vertical, PSSpacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: PSCornerRadius.small)
                                .fill(
                                    viewModel.isChartEditMode ? 
                                    Color.appSuccess.opacity(0.1) : 
                                    Color.appPrimary.opacity(0.1)
                                )
                        )
                    }
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isChartEditMode)
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

// MARK: - Minimal Segment View (Overview)
struct MinimalSegmentView: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @State private var chartDragInfo: String? = nil
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: PSSpacing.xl) {
                // Header with schedule name
                VStack(spacing: PSSpacing.md) {
                    Text(viewModel.model.schedule.name)
                        .font(PSTypography.title1.weight(.semibold))
                        .foregroundColor(.appPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(2)
                }
                .padding(.top, PSSpacing.md)


                // Bilgi Kartı (Sonraki Uyku & Toplam Uyku)
                PSCard(padding: PSSpacing.md) {
                    HStack(alignment: .center, spacing: PSSpacing.lg) {
                        VStack(alignment: .leading, spacing: PSSpacing.xs) {
                            Text(L("mainScreen.nextSleepBlock", table: "MainScreen"))
                                .font(PSTypography.caption)
                                .foregroundColor(.appTextSecondary)
                            Text(viewModel.nextSleepBlockFormatted)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.appSecondary)
                        }

                        Spacer()

                        VStack(alignment: .leading, spacing: PSSpacing.xs) {
                            Text(L("mainScreen.totalSleep", table: "MainScreen"))
                                .font(PSTypography.caption)
                                .foregroundColor(.appTextSecondary)
                            Text(viewModel.totalSleepTimeFormatted)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.appPrimary)
                        }

                        Spacer()

                        PSStatusBadge(
                            viewModel.sleepStatusMessage,
                            icon: viewModel.isInSleepTime ? "moon.fill" : "sun.max.fill",
                            color: viewModel.isInSleepTime ? .appSecondary : .appAccent,
                            style: .compact
                        )
                    }
                }
            }
            .padding(.horizontal, PSSpacing.lg)
            .padding(.bottom, PSSpacing.lg)
                
                // Circular Sleep Chart with Edit Mode
                PSCard(padding: PSSpacing.md) {
                    VStack(spacing: PSSpacing.sm) {
                        // Chart
                        EditableCircularSleepChart(
                            viewModel: viewModel,
                            chartSize: .extraLarge,
                            activeDragInfo: $chartDragInfo
                        )
                        .aspectRatio(1, contentMode: .fit)
                        .frame(minHeight: 280)
                        
                        // Chart edit instructions
                        if viewModel.isChartEditMode {
                            if let dragInfo = chartDragInfo {
                                // Canlı sürükleme feedback'i
                                Text(dragInfo)
                                    .font(.system(.caption, design: .monospaced).weight(.medium))
                                    .foregroundColor(.appPrimary)
                                    .padding(.top, PSSpacing.sm)
                                    .transition(.opacity)
                                    .id(dragInfo)
                            } else {
                                // Edit mode talimatları
                                ChartEditControls(viewModel: viewModel)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }
                    .padding(PSSpacing.sm)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isChartEditMode)
                }
                .padding(.horizontal, PSSpacing.lg)
                
        }
        .accessibilityLabel(L("mainScreen.segment.overview", table: "MainScreen"))
    }
}

// MARK: - Chart Edit UI Components

struct ChartEditControls: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        VStack(spacing: PSSpacing.xs) {
            HStack(spacing: PSSpacing.xs) {
                Image(systemName: "hand.draw")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextSecondary)
                Text(L("mainScreen.chart.instruction.move", table: "MainScreen"))
                    .font(PSTypography.caption)
                    .foregroundColor(.appTextSecondary)
            }
            
            HStack(spacing: PSSpacing.xs) {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextSecondary)
                Text(L("mainScreen.chart.instruction.delete", table: "MainScreen"))
                    .font(PSTypography.caption)
                    .foregroundColor(.appTextSecondary)
            }
            
            HStack(spacing: PSSpacing.xs) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextSecondary)
                Text(L("mainScreen.chart.instruction.add", table: "MainScreen"))
                    .font(PSTypography.caption)
                    .foregroundColor(.appTextSecondary)
            }
        }
        .padding(.horizontal, PSSpacing.md)
        .padding(.vertical, PSSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                .fill(Color.appTextSecondary.opacity(0.05))
        )
    }

}

// MARK: - Detailed Segment View
struct DetailedSegmentView: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: PSSpacing.lg) {
                // Schedule Management Section
                ScheduleManagementSection(viewModel: viewModel)
                
                // Quick Status Section
                ProgressInfoSection(viewModel: viewModel)
                
                // Sleep Blocks Section
                SleepBlocksSection(viewModel: viewModel)
                
                // Daily Tip Section
                DailyTipSection(viewModel: viewModel)
            }
            .padding(.horizontal, PSSpacing.lg)
            .padding(.top, PSSpacing.md)
            .padding(.bottom, PSSpacing.xl)
        }
        .accessibilityLabel(L("mainScreen.segment.details", table: "MainScreen"))
    }
}

// MARK: - Schedule Management Section
struct ScheduleManagementSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @State private var showScheduleDescription = false
    
    var body: some View {
        PSCard {
            VStack(spacing: PSSpacing.md) {
                // Schedule name and change button
                HStack(spacing: PSSpacing.md) {
                    VStack(alignment: .leading, spacing: PSSpacing.xs) {
                        Text(viewModel.model.schedule.name)
                            .font(PSTypography.headline.weight(.semibold))
                            .foregroundColor(.appPrimary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Program değiştirme butonu - daha modern
                    Button(action: {
                        viewModel.showScheduleSelectionSheet()
                    }) {
                        HStack(spacing: PSSpacing.xs) {
                            Text(L("mainScreen.changeSchedule.button", table: "MainScreen"))
                                .font(PSTypography.caption.weight(.medium))
                                .foregroundColor(.appPrimary)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.appPrimary)
                        }
                        .padding(.horizontal, PSSpacing.sm)
                        .padding(.vertical, PSSpacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: PSCornerRadius.small)
                                .fill(Color.appPrimary.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                // Program açıklaması toggle
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showScheduleDescription.toggle()
                    }
                }) {
                    HStack(spacing: PSSpacing.sm) {
                        Image(systemName: "info.circle")
                            .font(.system(size: PSIconSize.small))
                        
                        Text(L("mainScreen.scheduleDescription.title", table: "MainScreen"))
                            .font(PSTypography.caption.weight(.medium))
                        
                        Spacer()
                        
                        Image(systemName: showScheduleDescription ? "chevron.up" : "chevron.down")
                            .font(.system(size: PSIconSize.small))
                    }
                    .foregroundColor(.appTextSecondary)
                    .padding(.horizontal, PSSpacing.md)
                    .padding(.vertical, PSSpacing.sm)
                    .background(Color.appTextSecondary.opacity(0.05), in: RoundedRectangle(cornerRadius: PSCornerRadius.small))
                }
                
                // Program açıklaması
                if showScheduleDescription {
                    Text(viewModel.scheduleDescription)
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(PSSpacing.sm)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: PSCornerRadius.medium))
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }
            }
        }
    }
}

// MARK: - Progress Info Section
struct ProgressInfoSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        PSCard {
            HStack(alignment: .center, spacing: PSSpacing.md) {
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text(L("mainScreen.nextSleepBlock", table: "MainScreen"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                    Text(viewModel.nextSleepBlockFormatted)
                        .font(PSTypography.subheadline)
                        .fontWeight(.semibold)
                }
                Spacer()
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    Text(L("mainScreen.totalSleep", table: "MainScreen"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                    Text(viewModel.totalSleepTimeFormatted)
                        .font(PSTypography.subheadline)
                        .fontWeight(.semibold)
                }
                Spacer()
                PSStatusBadge(
                    viewModel.sleepStatusMessage,
                    icon: viewModel.isInSleepTime ? "moon.fill" : "sun.max.fill",
                    color: viewModel.isInSleepTime ? .appSecondary : .appAccent,
                    style: .compact
                )
            }
        }
    }
}

// MARK: - Status Cards Grid (Legacy - kept for backward compatibility)
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
    @State private var chartDragInfo: String? = nil
    
    var body: some View {
        VStack(spacing: PSSpacing.md) {
            
            ZStack(alignment: .bottom) {
                EditableCircularSleepChart(
                    viewModel: viewModel,
                    activeDragInfo: $chartDragInfo
                )
                    .frame(height: 300)
                    .padding(.horizontal, -PSSpacing.lg)

                // Canlı zaman ve geri bildirim göstergesi
                if viewModel.isChartEditMode {
                    let (text, color) = feedbackTextAndColor()
                    
                    if let text = text, let color = color {
                        Text(text)
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(color)
                            .padding(.vertical, PSSpacing.sm)
                            .padding(.horizontal, PSSpacing.md)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: PSCornerRadius.medium))
                            .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                            .id("feedback_\(text)") // Animasyonun tekrarlanması için
                            .padding(.bottom, 10) // Chart'ın biraz altında durması için
                    }
                }
            }
            
            if viewModel.isChartEditMode {
                ChartEditControls(viewModel: viewModel)
            }
        }
    }
    
    private func feedbackTextAndColor() -> (String?, Color?) {
        // Önce edit feedback mesajını kontrol et
        if !viewModel.editFeedbackMessage.isEmpty {
            let color: Color = {
                switch viewModel.editFeedbackType {
                case .success:
                    return .appSuccess
                case .collision, .tooShort:
                    return .appError
                case .resizing, .moving:
                    return .appInfo
                default:
                    return .appTextSecondary
                }
            }()
            return (viewModel.editFeedbackMessage, color)
        }
        
        // Sonra canlı zaman gösterimini kontrol et
        if let liveTime = viewModel.liveBlockTimeString {
            return (liveTime, .appPrimary)
        }
        
        return (nil, nil)
    }
}

// MARK: - Sleep Blocks Section
struct SleepBlocksSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        PSCard {
            VStack(spacing: PSSpacing.md) {
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
            VStack(spacing: PSSpacing.md) {
                PSSectionHeader(
                    L("mainScreen.dailyTip.title", table: "MainScreen"),
                    icon: "lightbulb.fill"
                )
                
                Text(viewModel.dailyTip, tableName: "Tips")
                    .font(PSTypography.subheadline)
                    .foregroundColor(.appTextSecondary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(PSSpacing.sm)
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
                .stroke(block.isCore ? Color.appPrimary.opacity(0.2) : Color.appSecondary.opacity(0.2), lineWidth: 1)
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



#Preview {
    let config = ModelConfiguration()
    let container = try! ModelContainer(for: SleepScheduleStore.self, configurations: config)
    MainScreenView(viewModel: MainScreenViewModel(languageManager: LanguageManager.shared))
        .modelContainer(container)
        .environmentObject(LanguageManager.shared)
}




// MARK: - FloatingSleepBlockView
struct FloatingSleepBlockView: View {
    let block: SleepBlock
    let position: CGPoint
    let isReadyToDelete: Bool
    let isValidDrop: Bool
    
    var body: some View {
        VStack(spacing: PSSpacing.xs) {
            Text(block.isCore ? "Core" : "Nap")
                .font(PSTypography.caption.weight(.bold))
                .foregroundColor(isReadyToDelete ? .white : .appText)
            
            Text("\(block.startTime) - \(block.endTime)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(isReadyToDelete ? .white.opacity(0.8) : .appTextSecondary)
        }
        .padding(.horizontal, PSSpacing.md)
        .padding(.vertical, PSSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                .fill(isReadyToDelete ? Color.appError : (isValidDrop ? Color.appSuccess.opacity(0.2) : Color.appCardBackground))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                .stroke(isReadyToDelete ? Color.clear : (isValidDrop ? Color.appSuccess : Color.appPrimary.opacity(0.2)), lineWidth: 1)
        )
        .scaleEffect(isReadyToDelete ? 1.1 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isReadyToDelete)
        .position(position)
        .allowsHitTesting(false)
        .drawingGroup() // Animasyon performansı için
    }
}

// MARK: - PlusButtonView
struct PlusButtonView: View {
    @ObservedObject var viewModel: MainScreenViewModel
    let center: CGPoint
    let radius: CGFloat
    
    var body: some View {
        Image(systemName: "plus.circle.fill")
            .font(.system(size: 44))
            .foregroundColor(.appAccent)
            .background(Circle().fill(Color.appBackground))
            .position(x: center.x + radius + 40, y: center.y + radius + 40)
            .allowsHitTesting(!viewModel.isDraggingNewBlock)
            .gesture(
                DragGesture(minimumDistance: 5, coordinateSpace: .local)
                    .onChanged { value in
                        if !viewModel.isDraggingNewBlock {
                            viewModel.startDraggingNewBlock(at: value.location, center: center, radius: radius)
                        }
                        viewModel.updateNewBlockDrag(to: value.location, center: center, radius: radius)
                    }
                    .onEnded { _ in
                        viewModel.endNewBlockDrag()
                    }
            )
    }
}

// MARK: - TrashAreaView
struct TrashAreaView: View {
    @ObservedObject var viewModel: MainScreenViewModel
    let center: CGPoint
    let radius: CGFloat
    
    var body: some View {
        let trashRadius: CGFloat = viewModel.isInTrashZone ? 45 : 40
        
        ZStack {
            Circle()
                .fill(viewModel.isInTrashZone ? Color.appError.opacity(0.3) : Color.appTextSecondary.opacity(0.1))
                .frame(width: trashRadius * 2, height: trashRadius * 2)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: viewModel.isInTrashZone)
                .allowsHitTesting(false)
            
            Image(systemName: "trash.fill")
                .font(.system(size: viewModel.isInTrashZone ? 28 : 24))
                .foregroundColor(viewModel.isInTrashZone ? .white : .appTextSecondary)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: viewModel.isInTrashZone)
                .allowsHitTesting(false)
        }
        .position(x: center.x - radius - 40, y: center.y + radius + 40)
        .transition(.scale.combined(with: .opacity))
        .allowsHitTesting(false)
    }
}



// MARK: - ArcGestureArea
struct ArcGestureArea: Shape {
    let startAngle: Double
    let endAngle: Double
    let center: CGPoint
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )
        return path.strokedPath(.init(lineWidth: 40)) // Geniş bir dokunma alanı
    }
}

// MARK: - TimeMarkersView
struct TimeMarkersView: View {
    let center: CGPoint
    let radius: CGFloat
    
    var body: some View {
        ForEach(0..<24) { hour in
            let angle = Double(hour) * 15.0 - 90
            let position = CGPoint(
                x: center.x + radius * cos(angle * .pi / 180),
                y: center.y + radius * sin(angle * .pi / 180)
            )
            
            Text("\(hour)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.appTextSecondary)
                .position(position)
        }
    }
}

// MARK: - CurrentTimeIndicator
struct CurrentTimeIndicator: View {
    let center: CGPoint
    let radius: CGFloat
    
    var body: some View {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let totalMinutes = hour * 60 + minute
        let angle = (Double(totalMinutes) / 1440.0) * 360.0 - 90
        
        let indicatorPosition = CGPoint(
            x: center.x + radius * cos(angle * .pi / 180),
            y: center.y + radius * sin(angle * .pi / 180)
        )
        
        Circle()
            .fill(Color.appAccent)
            .frame(width: 10, height: 10)
            .position(indicatorPosition)
    }
}



