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
                            SleepQualityRatingView(
                                startTime: lastBlock.start,
                                endTime: lastBlock.end,
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
                        Text("⚠️")
                            .font(.largeTitle)
                        
                        Text(LocalizedStringKey(errorMessage))
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.appText)
                        
                        Button(action: {
                            Task {
                                await viewModel.loadScheduleFromSupabase()
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
                        Text(NSLocalizedString("mainScreen.scheduleDescription.title", tableName: "MainScreen", comment: ""))
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Image(systemName: showScheduleDescription ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.appText)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        Capsule()
                            .fill(Color.appPrimary.opacity(0.2))
                    )
                }
            }
            
            // Toplam uyku süresi
            HStack {
                Text(String(format: NSLocalizedString("mainScreen.totalSleepLabel", tableName: "MainScreen", comment: ""), viewModel.totalSleepTimeFormatted))
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
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appCardBackground.opacity(0.7))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
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
            HStack {
                Text("🛌 ")
                    .font(.title3)
                Text("mainScreen.sleepBlocks", tableName: "MainScreen")
                    .font(.title3)
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
                .padding(.horizontal)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.isEditing)
            }
        }
    }
}

// MARK: - Uadd Sleep Block Button
struct AddBlockButton: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        Button(action: {
            viewModel.showAddBlockSheet = true
        }) {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                
                Text(NSLocalizedString("mainScreen.addSleepBlock", tableName: "MainScreen", comment: ""))
                    .font(.callout)
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(.appAccent)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.appAccent, lineWidth: 2)
            )
        }
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
    
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Ana kart içeriği
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(block.isCore ? String("🛏️") : String("⚡️"))
                            .font(.title2)
                        Text("\(block.startTime) - \(block.endTime)")
                            .font(.headline)
                            .foregroundColor(.appText)
                    }
                    
                    Text(
                        block.isCore
                        ? NSLocalizedString("mainScreen.sleepBlockCore", tableName: "MainScreen", comment: "")
                        : NSLocalizedString("mainScreen.sleepBlockNap", tableName: "MainScreen", comment: "")
                    )
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
                    
                }
                .padding()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appCardBackground)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
                
                // Düzenleme modu aktifken görünecek düzenleme ve silme butonları
                if viewModel.isEditing {
                    // Düzenleme butonu - Sol üstte
                    Button(action: {
                        hapticFeedback(style: .light)
                        viewModel.prepareForEditing(block)
                        showingEditSheet = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.appCardBackground)
                                .frame(width: 34, height: 34)
                                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                            
                            Circle()
                                .fill(Color.appPrimary.opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.appPrimary)
                        }
                    }
                    .scaleEffect(buttonScale)
                    .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 10) {
                        // Uzun basıldığında
                    } onPressingChanged: { pressing in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            buttonScale = pressing ? 0.9 : 1.0
                        }
                    }
                    .position(x: 16, y: 16)
                    .zIndex(1)
                    
                    // Silme butonu - Sağ üstte
                    Button(action: {
                        hapticFeedback(style: .medium)
                        showDeleteConfirmation = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.appCardBackground)
                                .frame(width: 34, height: 34)
                                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                            
                            Circle()
                                .fill(Color.red.opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.red)
                        }
                    }
                    .scaleEffect(buttonScale)
                    .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 10) {
                        // Uzun basıldığında
                    } onPressingChanged: { pressing in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            buttonScale = pressing ? 0.9 : 1.0
                        }
                    }
                    .position(x: geometry.size.width - 16, y: 16)
                    .zIndex(1)
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditSleepBlockSheet(viewModel: viewModel)
            }
            .confirmationDialog(
                NSLocalizedString("sleepBlock.delete.title", comment: "Uyku bloğunu sil"),
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(NSLocalizedString("sleepBlock.delete.confirm", comment: "Sil"), role: .destructive) {
                    withAnimation {
                        viewModel.deleteBlock(block)
                    }
                    hapticFeedback(style: .rigid)
                }
                Button(NSLocalizedString("general.cancel", comment: "İptal"), role: .cancel) {}
            } message: {
                Text(NSLocalizedString("sleepBlock.delete.message", comment: "Bu uyku bloğunu silmek istediğinizden emin misiniz?"))
            }
        }
        .frame(width: UIScreen.main.bounds.width / 2, height: 90)
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
                        NSLocalizedString("sleepBlock.startTime", tableName: "MainScreen", comment: ""),
                        selection: $viewModel.editingBlockStartTime,
                        displayedComponents: .hourAndMinute
                    )
                    
                    DatePicker(
                        NSLocalizedString("sleepBlock.endTime", tableName: "MainScreen", comment: ""),
                        selection: $viewModel.editingBlockEndTime,
                        displayedComponents: .hourAndMinute
                    )
                }
                
                Section {
                    Text("sleepBlock.autoType", tableName: "MainScreen")
                        .font(.footnote)
                        .foregroundColor(.appSecondaryText)
                }
            }
            .navigationTitle(NSLocalizedString("sleepBlock.edit", tableName: "MainScreen", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("general.cancel", tableName: "MainScreen", comment: "")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("general.save", tableName: "MainScreen", comment: "")) {
                        if viewModel.validateEditingBlock() {
                            viewModel.updateBlock()
                            dismiss()
                        }
                    }
                }
            }
            .alert(
                NSLocalizedString("sleepBlock.error.title", tableName: "MainScreen", comment: ""),
                isPresented: $viewModel.showBlockError
            ) {
                Button(NSLocalizedString("general.ok", tableName: "MainScreen", comment: ""), role: .cancel) {}
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
        VStack(spacing: 8) {
            HStack {
                Text(NSLocalizedString("mainScreen.dailyStatus", tableName: "MainScreen", comment: ""))
                    .font(.title3)
                    .foregroundColor(.appText)
                Spacer()
            }
            
            HStack(spacing: 8) {
                InfoCard(
                    icon: "🔄",
                    title: NSLocalizedString("mainScreen.progress", tableName: "MainScreen", comment: ""),
                    value: "\(Int(viewModel.dailyProgress * 100))%",
                    color: .appAccent
                )
                
                InfoCard(
                    icon: "⏰",
                    title: NSLocalizedString("mainScreen.nextSleepBlock", tableName: "MainScreen", comment: ""),
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("💡 ")
                    .font(.title3)
                Text(NSLocalizedString("mainScreen.todaysTip", tableName: "MainScreen", comment: ""))
                    .font(.title3)
                    .foregroundColor(.appText)
            }
            
            HStack(alignment: .top) {
                Text(viewModel.dailyTip, tableName: "Tips")
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appCardBackground)
                    .shadow(
                        color: Color.black.opacity(0.05),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Info Card
struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
            }
            
            Text(value)
                .font(.headline)
                .foregroundColor(.appText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBackground)
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
    }
}

#Preview {
    let config = ModelConfiguration()
    let container = try! ModelContainer(for: SleepScheduleStore.self, configurations: config)
    MainScreenView(viewModel: MainScreenViewModel())
        .modelContainer(container)
}

