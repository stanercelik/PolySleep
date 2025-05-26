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

extension View {
    @ViewBuilder func redactedShimmer(if condition: Bool) -> some View {
        if condition {
            self.modifier(RedactedShimmerModifier())
        } else {
            self
        }
    }
}

struct MainScreenView: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    
    init(viewModel: MainScreenViewModel? = nil) {
        if let viewModel = viewModel {
            self.viewModel = viewModel
        } else {
            self.viewModel = MainScreenViewModel(languageManager: LanguageManager.shared)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        // Header Section
                        HeaderSection(viewModel: viewModel)
                            .redacted(reason: viewModel.isLoading ? .placeholder : [])
                            .redactedShimmer(if: viewModel.isLoading)
                        
                        // Sleep Quality Rating Card
                        if viewModel.showSleepQualityRating, let lastBlock = viewModel.lastSleepBlock {
                            let startTime = TimeFormatter.time(from: lastBlock.startTime)!
                            let endTime = TimeFormatter.time(from: lastBlock.endTime)!
                            
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
                        
                        // Status Cards Grid
                        StatusCardsGrid(viewModel: viewModel)
                            .redacted(reason: viewModel.isLoading ? .placeholder : [])
                            .redactedShimmer(if: viewModel.isLoading)
                        
                        // Sleep Chart
                        SleepChartSection(viewModel: viewModel)
                            .redacted(reason: viewModel.isLoading ? .placeholder : [])
                            .redactedShimmer(if: viewModel.isLoading)
                        
                        // Sleep Blocks
                        SleepBlocksSection(viewModel: viewModel)
                            .redacted(reason: viewModel.isLoading ? .placeholder : [])
                            .redactedShimmer(if: viewModel.isLoading)
                        
                        // Daily Tip
                        DailyTipSection(viewModel: viewModel)
                            .redacted(reason: viewModel.isLoading ? .placeholder : [])
                            .redactedShimmer(if: viewModel.isLoading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: toggleEditMode) {
                        Image(systemName: viewModel.isEditing ? "checkmark" : "pencil")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(viewModel.isEditing ? .appSecondary : .appPrimary)
                            .fontWeight(.medium)
                    }
                }
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
        .sheet(isPresented: $viewModel.showAddBlockSheet) {
            AddSleepBlockSheet(viewModel: viewModel)
        }
        .id(languageManager.currentLanguage)
    }
    
    private func shareSchedule() {
        let activityVC = UIActivityViewController(
            activityItems: [viewModel.shareScheduleInfo()],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func toggleEditMode() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            viewModel.isEditing.toggle()
        }
    }
}

// MARK: - Header Section
struct HeaderSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @State private var showScheduleDescription = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Ana bilgi kartı
            VStack(spacing: 12) {
                // Program adı ve toplam uyku
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.model.schedule.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.appText)
                        
                        // Durum badge
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.isInSleepTime ? "moon.fill" : "sun.max.fill")
                                .font(.caption)
                                .foregroundColor(viewModel.isInSleepTime ? .appSecondary : .appAccent)
                            
                            Text(viewModel.sleepStatusMessage)
                                .font(.subheadline)
                                .foregroundColor(.appSecondaryText)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.quaternary)
                        )
                    }
                    
                    Spacer()
                    
                    // Toplam uyku süresi
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(L("mainScreen.totalSleepLabel", table: "MainScreen"))
                            .font(.caption2)
                            .foregroundColor(.appSecondaryText)
                        
                        Text(viewModel.totalSleepTimeFormatted)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.appPrimary)
                    }
                }
                
                // Program açıklaması toggle
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showScheduleDescription.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        
                        Text(L("mainScreen.scheduleDescription.title", table: "MainScreen"))
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Image(systemName: showScheduleDescription ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.appPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.appPrimary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
                
                // Program açıklaması
                if showScheduleDescription {
                    Text(viewModel.scheduleDescription)
                        .font(.footnote)
                        .foregroundColor(.appSecondaryText)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }
            }
            .padding(16)
            .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 16))
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
        ], spacing: 12) {
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.appSecondaryText)
                .lineLimit(1)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.appText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Sleep Chart Section
struct SleepChartSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label {
                    Text(L("mainScreen.sleepChart.title", table: "MainScreen"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appText)
                } icon: {
                    Image(systemName: "chart.pie.fill")
                        .foregroundColor(.appPrimary)
                }
                
                Spacer()
            }
            
            CircularSleepChart(schedule: viewModel.model.schedule.toSleepScheduleModel)
                .frame(height: 280)
        }
        .padding(16)
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Sleep Blocks Section
struct SleepBlocksSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label {
                    Text(L("mainScreen.sleepBlocks", table: "MainScreen"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appText)
                } icon: {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(.appPrimary)
                }
                
                Spacer()
                
                if viewModel.isEditing {
                    Text(L("mainScreen.editing.mode", table: "MainScreen"))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.appSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.appSecondary.opacity(0.15), in: Capsule())
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
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
                .padding(.horizontal, 4)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isEditing)
            }
        }
        .padding(16)
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Daily Tip Section
struct DailyTipSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label {
                    Text(L("mainScreen.dailyTip.title", table: "MainScreen"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appText)
                } icon: {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                }
                
                Spacer()
            }
            
            Text(viewModel.dailyTip, tableName: "Tips")
                .font(.subheadline)
                .foregroundColor(.appSecondaryText)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Sleep Quality Rating Card
struct SleepQualityRatingCard: View {
    let startTime: Date
    let endTime: Date
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        SleepQualityRatingView(
            startTime: startTime,
            endTime: endTime,
            isPresented: $isPresented,
            viewModel: viewModel
        )
        .padding(16)
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Error Overlay Card
struct ErrorOverlayCard: View {
    let errorMessage: String
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text(LocalizedStringKey(errorMessage))
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.appText)
            
            Button(action: {
                Task {
                    await viewModel.loadScheduleFromRepository()
                }
            }) {
                Label(L("mainscreen.error.retry", table: "MainScreen"), systemImage: "arrow.clockwise")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.appPrimary, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(24)
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 40)
    }
}

// MARK: - Add Sleep Block Card
struct AddSleepBlockCard: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        Button(action: {
            viewModel.showAddBlockSheet = true
        }) {
            VStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.appAccent)
                
                Text(L("mainScreen.addSleepBlock", table: "MainScreen"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.appAccent)
            }
            .frame(width: 140, height: 80)
            .background(Color.appAccent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: block.isCore ? "moon.fill" : "powersleep")
                    .font(.title3)
                    .foregroundColor(block.isCore ? .appPrimary : .appAccent)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(block.startTime) - \(block.endTime)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appText)
                    
                    Text(block.isCore ? L("mainScreen.sleepBlockCore", table: "MainScreen") : L("mainScreen.sleepBlockNap", table: "MainScreen"))
                        .font(.caption2)
                        .foregroundColor(.appSecondaryText)
                }
                
                Spacer()
                
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
                            .font(.caption)
                            .foregroundColor(.appSecondaryText)
                            .padding(8)
                            .background(.quaternary, in: Circle())
                    }
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
        }
        .frame(width: 140, height: 80)
        .padding(12)
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
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
                    
                    DatePicker(
                        L("sleepBlock.endTime", table: "MainScreen"),
                        selection: $viewModel.editingBlockEndTime,
                        displayedComponents: .hourAndMinute
                    )
                }
                
                Section {
                    Text(L("sleepBlock.autoType", table: "MainScreen"))
                        .font(.footnote)
                        .foregroundColor(.appSecondaryText)
                }
            }
            .navigationTitle(L("sleepBlock.edit", table: "MainScreen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("general.cancel", table: "MainScreen")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("general.save", table: "MainScreen")) {
                        if viewModel.validateEditingBlock() {
                            viewModel.updateBlock()
                            dismiss()
                        }
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
            .foregroundColor(.appSecondaryText)
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

