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
            // LanguageManager.shared'i kullanarak yeni bir viewModel oluştur
            self.viewModel = MainScreenViewModel(languageManager: LanguageManager.shared)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header Card
                        HeaderCard(viewModel: viewModel)
                            .redacted(reason: viewModel.isLoading ? .placeholder : [])
                            .redactedShimmer(if: viewModel.isLoading)
                            .opacity(viewModel.isLoading ? 0.7 : 1.0)
                        
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
                        
                        // Sleep Chart Card
                        SleepChartCard(viewModel: viewModel)
                            .redacted(reason: viewModel.isLoading ? .placeholder : [])
                            .redactedShimmer(if: viewModel.isLoading)
                            .opacity(viewModel.isLoading ? 0.7 : 1.0)
                        
                        // Sleep Blocks Card
                        SleepBlocksCard(viewModel: viewModel)
                            .redacted(reason: viewModel.isLoading ? .placeholder : [])
                            .redactedShimmer(if: viewModel.isLoading)
                            .opacity(viewModel.isLoading ? 0.7 : 1.0)
                        
                        // Info Cards Section
                        InfoCardsSection(viewModel: viewModel)
                            .redacted(reason: viewModel.isLoading ? .placeholder : [])
                            .redactedShimmer(if: viewModel.isLoading)
                            .opacity(viewModel.isLoading ? 0.7 : 1.0)
                        
                        // Daily Tip Card
                        DailyTipCard(viewModel: viewModel)
                            .redacted(reason: viewModel.isLoading ? .placeholder : [])
                            .redactedShimmer(if: viewModel.isLoading)
                            .opacity(viewModel.isLoading ? 0.7 : 1.0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                
                // Hata durumları için overlay
                if let errorMessage = viewModel.errorMessage {
                    ErrorOverlayCard(errorMessage: errorMessage, viewModel: viewModel)
                }
            }
            .navigationTitle(L("mainScreen.title", table: "MainScreen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        let activityVC = UIActivityViewController(
                            activityItems: [viewModel.shareScheduleInfo()],
                            applicationActivities: nil
                        )
                        
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first,
                           let rootVC = window.rootViewController {
                            rootVC.present(activityVC, animated: true)
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .symbolRenderingMode(.hierarchical)
                            .fontWeight(.semibold)
                            .foregroundColor(.appPrimary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.isEditing.toggle()
                        }
                    }) {
                        Image(systemName: viewModel.isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .fontWeight(viewModel.isEditing ? .bold : .black)
                            .foregroundColor(viewModel.isEditing ? .appSecondary : .appPrimary)
                            .font(.title3)
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
}

// MARK: - Header Card
struct HeaderCard: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @State private var showScheduleDescription: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Ana başlık ve durum
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.model.schedule.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.appText)
                    
                    HStack(spacing: 8) {
                        Text(viewModel.isInSleepTime ? L("mainScreen.sleepTimeIcon", table: "MainScreen") : L("mainScreen.wakeTimeIcon", table: "MainScreen"))
                            .font(.subheadline)
                        
                        Text(viewModel.sleepStatusMessage)
                            .font(.subheadline)
                            .foregroundColor(.appSecondaryText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(viewModel.isInSleepTime ? Color.appSecondary.opacity(0.15) : Color.appAccent.opacity(0.15))
                    )
                }
                
                Spacer()
                
                // Toplam uyku süresi
                VStack(alignment: .trailing, spacing: 4) {
                    Text(L("mainScreen.totalSleepLabel", table: "MainScreen"))
                        .font(.caption)
                        .foregroundColor(.appSecondaryText)
                    
                    Text(viewModel.totalSleepTimeFormatted)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.appPrimary)
                }
            }
            
            // Program açıklaması toggle
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
                }
                .foregroundColor(.appPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appPrimary.opacity(0.1))
                )
            }
            
            // Program açıklaması
            if showScheduleDescription {
                Text(viewModel.scheduleDescription)
                    .font(.footnote)
                    .foregroundColor(.appText)
                    .lineSpacing(4)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.appPrimary.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                    ))
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

// MARK: - Sleep Chart Card
struct SleepChartCard: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Text("📊")
                        .font(.title3)
                    Text(L("mainScreen.sleepChart.title", table: "MainScreen"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appText)
                }
                
                Spacer()
            }
            
            CircularSleepChart(schedule: viewModel.model.schedule.toSleepScheduleModel)
                .frame(height: UIScreen.main.bounds.height * 0.3)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Sleep Blocks Card
struct SleepBlocksCard: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Text(L("mainScreen.sleepBlocksIcon", table: "MainScreen"))
                        .font(.title3)
                    Text(L("mainScreen.sleepBlocks", table: "MainScreen"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appText)
                }
                
                Spacer()
                
                if viewModel.isEditing {
                    Text(L("mainScreen.editing.mode", table: "MainScreen"))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.appSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.appSecondary.opacity(0.15))
                        )
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if viewModel.isEditing {
                        AddBlockButton(viewModel: viewModel)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.1, anchor: .leading)
                                    .combined(with: .opacity)
                                    .combined(with: .offset(x: -20, y: 0)),
                                removal: .scale(scale: 0.1, anchor: .leading)
                                    .combined(with: .opacity)
                                    .combined(with: .offset(x: -20, y: 0))
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
                .padding(.top, viewModel.isEditing ? 20 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.isEditing)
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

// MARK: - Sleep Quality Rating Card
struct SleepQualityRatingCard: View {
    let startTime: Date
    let endTime: Date
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("mainScreen.sleepQuality.title", table: "MainScreen"))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.appText)
                    
                    Text(L("mainScreen.sleepQuality.subtitle", table: "MainScreen"))
                        .font(.subheadline)
                        .foregroundColor(.appSecondaryText)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.appSecondaryText.opacity(0.6))
                }
            }
            
            SleepQualityRatingView(
                startTime: startTime,
                endTime: endTime,
                isPresented: $isPresented,
                viewModel: viewModel
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Daily Tip Card
struct DailyTipCard: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Text("💡")
                        .font(.title3)
                    Text(L("mainScreen.dailyTip.title", table: "MainScreen"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appText)
                }
                
                Spacer()
            }
            
            TipSection(viewModel: viewModel)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Error Overlay Card
struct ErrorOverlayCard: View {
    let errorMessage: String
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text(L("mainScreen.errorIcon", table: "MainScreen"))
                .font(.largeTitle)
            
            Text(LocalizedStringKey(errorMessage))
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.appText)
            
            Button(action: {
                Task {
                    await viewModel.loadScheduleFromRepository()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                    Text(L("mainscreen.error.retry", table: "MainScreen"))
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appPrimary)
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 40)
    }
}

// MARK: - Add Sleep Block Button
struct AddBlockButton: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: {
            viewModel.showAddBlockSheet = true
        }) {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundColor(.appAccent)
                
                Text(L("mainScreen.addSleepBlock", table: "MainScreen"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.appAccent)
            }
            .frame(width: UIScreen.main.bounds.width / 2.2, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appAccent.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.appAccent.opacity(0.3), lineWidth: 2)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sleep Block Card
struct SleepBlockCard: View {
    let block: SleepBlock
    let nextBlock: SleepBlock?
    let nextBlockTime: String
    
    @State private var showingEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var buttonScale = 1.0
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        ZStack {
            // Ana kart içeriği
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text(block.isCore ? 
                         L("mainScreen.coreBlockIcon", table: "MainScreen") : 
                         L("mainScreen.napBlockIcon", table: "MainScreen"))
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(block.startTime) - \(block.endTime)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.appText)
                        
                        Text(
                            block.isCore
                            ? L("mainScreen.sleepBlockCore", table: "MainScreen")
                            : L("mainScreen.sleepBlockNap", table: "MainScreen")
                        )
                        .font(.caption)
                        .foregroundColor(.appSecondaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(block.isCore ? Color.appPrimary.opacity(0.15) : Color.appAccent.opacity(0.15))
                        )
                    }
                    
                    Spacer()
                }
            }
            .padding(16)
            .frame(width: UIScreen.main.bounds.width / 2.2, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                block.isCore ? 
                                Color.appPrimary.opacity(0.2) : 
                                Color.appAccent.opacity(0.2), 
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
            
            // Düzenleme modu aktifken görünecek aksiyon butonları
            if viewModel.isEditing {
                // Silme butonu - Sol üst köşe
                VStack {
                    HStack {
                        EditActionButton(
                            systemImage: "trash",
                            backgroundColor: Color.red,
                            isPressed: buttonScale != 1.0
                        ) {
                            hapticFeedback(style: .medium)
                            showDeleteConfirmation = true
                        }
                        .scaleEffect(buttonScale)
                        .onLongPressGesture(minimumDuration: 0.05, maximumDistance: 10) {
                            // Uzun basış aksiyonu
                        } onPressingChanged: { pressing in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                buttonScale = pressing ? 0.92 : 1.0
                            }
                        }
                        .offset(x: -12, y: -8)
                        
                        Spacer()
                        
                        // Düzenleme butonu - Sağ üst köşe
                        EditActionButton(
                            systemImage: "pencil",
                            backgroundColor: Color.appPrimary,
                            isPressed: buttonScale != 1.0
                        ) {
                            hapticFeedback(style: .light)
                            viewModel.prepareForEditing(block)
                            showingEditSheet = true
                        }
                        .scaleEffect(buttonScale)
                        .onLongPressGesture(minimumDuration: 0.05, maximumDistance: 10) {
                            // Uzun basış aksiyonu
                        } onPressingChanged: { pressing in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                buttonScale = pressing ? 0.92 : 1.0
                            }
                        }
                        .offset(x: 12, y: -8)
                    }
                    Spacer()
                }
                .frame(width: UIScreen.main.bounds.width / 2.2, height: 100)
                .zIndex(2)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.3).combined(with: .opacity),
                    removal: .scale(scale: 0.3).combined(with: .opacity)
                ))
                .padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditSleepBlockSheet(viewModel: viewModel)
        }
        .confirmationDialog(
            L("sleepBlock.delete.title", table: "MainScreen"),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L("sleepBlock.delete.confirm", table: "MainScreen"), role: .destructive) {
                withAnimation {
                    viewModel.deleteBlock(block)
                }
                hapticFeedback(style: .rigid)
            }
            Button(L("general.cancel", table: "MainScreen"), role: .cancel) {}
        } message: {
            Text(L("sleepBlock.delete.message", table: "MainScreen"))
        }
    }
    
    private func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// MARK: - Edit Sleep Block Sheet
struct EditSleepBlockSheet: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
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

// MARK: - Info Cards
struct InfoCardsSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Text("📈")
                        .font(.title3)
                    Text(L("mainScreen.dailyStatus", table: "MainScreen"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appText)
                }
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                MainInfoCard(
                    icon: L("mainScreen.progressIcon", table: "MainScreen"),
                    title: L("mainScreen.progress", table: "MainScreen"),
                    value: "\(Int(viewModel.dailyProgress * 100))%",
                    color: .appAccent
                )
                
                MainInfoCard(
                    icon: L("mainScreen.nextSleepBlockIcon", table: "MainScreen"),
                    title: L("mainScreen.nextSleepBlock", table: "MainScreen"),
                    value: viewModel.nextSleepBlockFormatted,
                    color: .appSecondary
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
}

// MARK: - Tip Section
struct TipSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.dailyTip, tableName: "Tips")
                .font(.subheadline)
                .foregroundColor(.appSecondaryText)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appPrimary.opacity(0.15), lineWidth: 1)
                )
        )
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
                    .fontWeight(.medium)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.appText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
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
            ZStack {
                // Dış gölge halesi
                Circle()
                    .fill(backgroundColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .blur(radius: 4)
                
                // Ana buton
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 36, height: 36)
                    .shadow(
                        color: backgroundColor.opacity(0.4),
                        radius: 6,
                        x: 0,
                        y: 3
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.clear
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                // İkon
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .scaleEffect(isPressed ? 0.85 : 1.0)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibility(addTraits: .isButton)
        .accessibility(hint: Text(systemImage == "pencil" ? 
            L("general.edit", table: "MainScreen") : 
            L("general.delete", table: "MainScreen")))
    }
}

#Preview {
    let config = ModelConfiguration()
    let container = try! ModelContainer(for: SleepScheduleStore.self, configurations: config)
    MainScreenView(viewModel: MainScreenViewModel(languageManager: LanguageManager.shared))
        .modelContainer(container)
        .environmentObject(LanguageManager.shared)
}

