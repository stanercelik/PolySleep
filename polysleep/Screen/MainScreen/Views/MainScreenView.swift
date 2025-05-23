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
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        HeaderView(viewModel: viewModel)
                            .redacted(reason: viewModel.isLoading ? .placeholder : [])
                            .redactedShimmer(if: viewModel.isLoading)
                            .opacity(viewModel.isLoading ? 0.7 : 1.0)
                        
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
                            
                            SleepQualityRatingView(
                                startTime: startDate,
                                endTime: endDate,
                                isPresented: $viewModel.showSleepQualityRating,
                                viewModel: viewModel
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .padding(.horizontal)
                        }
                        
                        CircularSleepChart(schedule: viewModel.model.schedule.toSleepScheduleModel)
                            .frame(height: UIScreen.main.bounds.height * 0.35)
                            .padding(.horizontal)
                            .redacted(reason: viewModel.isLoading ? .placeholder : [])
                            .redactedShimmer(if: viewModel.isLoading)
                            .opacity(viewModel.isLoading ? 0.7 : 1.0)
                        
                        SleepBlocksSection(viewModel: viewModel)
                            .redacted(reason: viewModel.isLoading ? .placeholder : [])
                            .redactedShimmer(if: viewModel.isLoading)
                            .opacity(viewModel.isLoading ? 0.7 : 1.0)
                        
                        InfoCardsSection(viewModel: viewModel)
                            .redacted(reason: viewModel.isLoading ? .placeholder : [])
                            .redactedShimmer(if: viewModel.isLoading)
                            .opacity(viewModel.isLoading ? 0.7 : 1.0)
                        
                        TipSection(viewModel: viewModel)
                            .padding(.bottom, 16)
                            .redacted(reason: viewModel.isLoading ? .placeholder : [])
                            .redactedShimmer(if: viewModel.isLoading)
                            .opacity(viewModel.isLoading ? 0.7 : 1.0)
                    }
                }
                
                // Hata durumları için overlay
                if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Text(NSLocalizedString("mainScreen.errorIcon", tableName: "MainScreen", comment: "Error icon emoji"))
                            .font(.largeTitle)
                        
                        Text(LocalizedStringKey(errorMessage))
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.appText)
                        
                        Button(action: {
                            Task {
                                // Offline-first: Supabase yerine Repository'den yüklüyoruz
                                await viewModel.loadScheduleFromRepository()
                            }
                        }) {
                            Text(LocalizedStringKey("mainscreen.error.retry"))
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.appPrimary)
                                .cornerRadius(10)
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appCardBackground)
                            .shadow(color: Color.black.opacity(0.1), radius: 10)
                    )
                    .padding(.horizontal, 40)
                }
            }
            .navigationBarItems(
                leading: Button(action: {
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
                },
                trailing: HStack(spacing: 16) {
                    
                    Image(systemName: viewModel.isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .fontWeight(viewModel.isEditing ? .bold : .black)
                        .foregroundColor(viewModel.isEditing ? .appSecondary : .appPrimary)
                        .font(.title3)
                        /*.contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))*/
                        .onTapGesture {
                            viewModel.isEditing.toggle()
                        }
                }
            )
            /*.toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 4) {
                        Text(viewModel.isInSleepTime ? "💤" : "⏰")
                            .font(.headline)
                        Text(viewModel.sleepStatusMessage)
                            .font(.headline)
                            .foregroundColor(.appText)
                    }
                }
            }*/
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
        .sheet(isPresented: $viewModel.showAddBlockSheet) {
            AddSleepBlockSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Header
struct HeaderView: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @State private var showCustomizedTooltip: Bool = false
    @State private var showScheduleDescription: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            // Program adı ve bilgi düğmesi
            HStack(spacing: 8) {
                Text(viewModel.model.schedule.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.appText)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showScheduleDescription.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(NSLocalizedString("mainScreen.scheduleDescription.title", tableName: "MainScreen", comment: "Schedule description title"))
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Image(systemName: showScheduleDescription ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.appText)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        Capsule()
                            .fill(Color.appPrimary.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(Color.appPrimary.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
            
            // Toplam uyku süresi
            HStack {
                Text(String(format: NSLocalizedString("mainScreen.totalSleepLabel", tableName: "MainScreen", comment: "Total sleep time label"), viewModel.totalSleepTimeFormatted))
                    .font(.caption)
                    .foregroundColor(.appSecondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            
            // Program açıklaması (açılır/kapanır panel)
            if showScheduleDescription {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .background(Color.appAccent.opacity(0.2))
                        .padding(.vertical, 8)
                    
                    Text(viewModel.scheduleDescription)
                        .font(.footnote)
                        .foregroundColor(.appText)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appCardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            colorScheme == .light ? 
                                            Color.gray.opacity(0.12) : 
                                            Color.clear,
                                            lineWidth: 1
                                        )
                                )
                                .shadow(
                                    color: colorScheme == .light ? 
                                    Color.black.opacity(0.06) : 
                                    Color.black.opacity(0.25),
                                    radius: colorScheme == .light ? 6 : 10,
                                    x: 0,
                                    y: colorScheme == .light ? 3 : 5
                                )
                        )
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                    removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                ))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.appBackground)
    }
}

// MARK: - Sleep Block Section
struct SleepBlocksSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(NSLocalizedString("mainScreen.sleepBlocksIcon", tableName: "MainScreen", comment: "Sleep blocks icon emoji"))
                    .font(.title3)
                Text(NSLocalizedString("mainScreen.sleepBlocks", tableName: "MainScreen", comment: "Sleep blocks section title"))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
            }
            .padding(.horizontal)
            
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
                .padding(.horizontal, viewModel.isEditing ? 16 : 16)
                .padding(.trailing, viewModel.isEditing ? 50 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.isEditing)
            }
        }
    }
}

// MARK: - Uadd Sleep Block Button
struct AddBlockButton: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: {
            viewModel.showAddBlockSheet = true
        }) {
            VStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.appAccent)
                
                Text(NSLocalizedString("mainScreen.addSleepBlock", tableName: "MainScreen", comment: "Add sleep block button title"))
                    .font(.callout)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.appAccent)
            }
            .frame(width: UIScreen.main.bounds.width / 2, height: 90)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appAccent.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appAccent.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(
                        color: colorScheme == .light ? 
                        Color.appAccent.opacity(0.15) : 
                        Color.appAccent.opacity(0.25),
                        radius: colorScheme == .light ? 4 : 8,
                        x: 0,
                        y: colorScheme == .light ? 2 : 4
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - sleep Block Card
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
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(block.isCore ? 
                         NSLocalizedString("mainScreen.coreBlockIcon", tableName: "MainScreen", comment: "Core sleep block icon emoji") : 
                         NSLocalizedString("mainScreen.napBlockIcon", tableName: "MainScreen", comment: "Nap sleep block icon emoji"))
                        .font(.title2)
                    Text("\(block.startTime) - \(block.endTime)")
                        .font(.headline)
                        .foregroundColor(.appText)
                }
                
                Text(
                    block.isCore
                    ? NSLocalizedString("mainScreen.sleepBlockCore", tableName: "MainScreen", comment: "Core sleep block label")
                    : NSLocalizedString("mainScreen.sleepBlockNap", tableName: "MainScreen", comment: "Nap sleep block label")
                )
                .font(.subheadline)
                .foregroundColor(.appSecondaryText)
                
            }
            .padding(16)
            .frame(width: UIScreen.main.bounds.width / 2, height: 90)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                colorScheme == .light ? 
                                Color.gray.opacity(0.15) : 
                                Color.clear,
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: colorScheme == .light ? 
                        Color.black.opacity(0.08) : 
                        Color.black.opacity(0.3),
                        radius: colorScheme == .light ? 8 : 12,
                        x: 0,
                        y: colorScheme == .light ? 4 : 6
                    )
            )
            
            // Düzenleme modu aktifken görünecek aksiyon butonları
            if viewModel.isEditing {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        // Düzenleme butonu
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
                        
                        // Silme butonu
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
                    }
                    .offset(x: 10, y: 0)
                    .zIndex(2)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.3).combined(with: .opacity).combined(with: .offset(x: 10, y: -10)),
                        removal: .scale(scale: 0.3).combined(with: .opacity).combined(with: .offset(x: 10, y: -10))
                    ))
                }
                .frame(width: UIScreen.main.bounds.width / 2, height: 90)
            }
        }
            .sheet(isPresented: $showingEditSheet) {
                EditSleepBlockSheet(viewModel: viewModel)
            }
            .confirmationDialog(
                NSLocalizedString("sleepBlock.delete.title", tableName: "MainScreen", comment: "Delete sleep block confirmation title"),
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(NSLocalizedString("sleepBlock.delete.confirm", tableName: "MainScreen", comment: "Delete confirmation button"), role: .destructive) {
                    withAnimation {
                        viewModel.deleteBlock(block)
                    }
                    hapticFeedback(style: .rigid)
                }
                Button(NSLocalizedString("general.cancel", tableName: "MainScreen", comment: "Cancel button"), role: .cancel) {}
            } message: {
                Text(NSLocalizedString("sleepBlock.delete.message", tableName: "MainScreen", comment: "Delete confirmation message"))
            }
        }
    }
    
    private func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
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
                        NSLocalizedString("sleepBlock.startTime", tableName: "MainScreen", comment: "Start time picker label"),
                        selection: $viewModel.editingBlockStartTime,
                        displayedComponents: .hourAndMinute
                    )
                    
                    DatePicker(
                        NSLocalizedString("sleepBlock.endTime", tableName: "MainScreen", comment: "End time picker label"),
                        selection: $viewModel.editingBlockEndTime,
                        displayedComponents: .hourAndMinute
                    )
                }
                
                Section {
                    Text(NSLocalizedString("sleepBlock.autoType", tableName: "MainScreen", comment: "Auto type explanation text"))
                        .font(.footnote)
                        .foregroundColor(.appSecondaryText)
                }
            }
            .navigationTitle(NSLocalizedString("sleepBlock.edit", tableName: "MainScreen", comment: "Edit sleep block navigation title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("general.cancel", tableName: "MainScreen", comment: "Cancel button")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("general.save", tableName: "MainScreen", comment: "Save button")) {
                        if viewModel.validateEditingBlock() {
                            viewModel.updateBlock()
                            dismiss()
                        }
                    }
                }
            }
            .alert(
                NSLocalizedString("sleepBlock.error.title", tableName: "MainScreen", comment: "Sleep block error title"),
                isPresented: $viewModel.showBlockError
            ) {
                Button(NSLocalizedString("general.ok", tableName: "MainScreen", comment: "OK button"), role: .cancel) {}
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
        VStack(spacing: 12) {
            HStack {
                Text(NSLocalizedString("mainScreen.dailyStatus", tableName: "MainScreen", comment: "Daily status section title"))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
                Spacer()
            }
            
            HStack(spacing: 12) {
                MainInfoCard(
                    icon: NSLocalizedString("mainScreen.progressIcon", tableName: "MainScreen", comment: "Progress icon emoji"),
                    title: NSLocalizedString("mainScreen.progress", tableName: "MainScreen", comment: "Progress card title"),
                    value: "\(Int(viewModel.dailyProgress * 100))%",
                    color: .appAccent
                )
                
                MainInfoCard(
                    icon: NSLocalizedString("mainScreen.nextSleepBlockIcon", tableName: "MainScreen", comment: "Next sleep block icon emoji"),
                    title: NSLocalizedString("mainScreen.nextSleepBlock", tableName: "MainScreen", comment: "Next sleep block card title"),
                    value: viewModel.nextSleepBlockFormatted,
                    color: .appSecondary
                )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Tip Section
struct TipSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(NSLocalizedString("mainScreen.tipIcon", tableName: "MainScreen", comment: "Tip icon emoji"))
                    .font(.title3)
                Text(NSLocalizedString("mainScreen.todaysTip", tableName: "MainScreen", comment: "Today's tip section title"))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.dailyTip, tableName: "Tips")
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                colorScheme == .light ? 
                                Color.gray.opacity(0.12) : 
                                Color.clear,
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: colorScheme == .light ? 
                        Color.black.opacity(0.06) : 
                        Color.black.opacity(0.25),
                        radius: colorScheme == .light ? 6 : 10,
                        x: 0,
                        y: colorScheme == .light ? 3 : 5
                    )
            )
        }
        .padding(.horizontal)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
                    .fontWeight(.medium)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.appText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            colorScheme == .light ? 
                            Color.gray.opacity(0.12) : 
                            Color.clear,
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: colorScheme == .light ? 
                    Color.black.opacity(0.06) : 
                    Color.black.opacity(0.25),
                    radius: colorScheme == .light ? 6 : 10,
                    x: 0,
                    y: colorScheme == .light ? 3 : 5
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
            NSLocalizedString("general.edit", tableName: "MainScreen", comment: "Edit accessibility hint") : 
            NSLocalizedString("general.delete", tableName: "MainScreen", comment: "Delete accessibility hint")))
    }
}

#Preview {
    let config = ModelConfiguration()
    let container = try! ModelContainer(for: SleepScheduleStore.self, configurations: config)
    MainScreenView(viewModel: MainScreenViewModel())
        .modelContainer(container)
}

