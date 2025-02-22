import SwiftUI
import SwiftData

struct MainScreenView: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var scrollOffset: CGFloat = 0
    
    private let headerHeight: CGFloat = 100
    private let chartHeight: CGFloat = 200
    
    /// Scroll ilerlemesine göre (0...1) ilerleme değeri
    private var progress: CGFloat {
        let maxOffset: CGFloat = headerHeight
        return min(max(-scrollOffset / maxOffset, 0), 1)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self,
                                        value: geometry.frame(in: .named("scroll")).minY)
                    }
                    .frame(height: 0)
                    
                    VStack(spacing: 16) {
                        HeaderView(viewModel: viewModel, progress: progress)
                        
                        CircularSleepChart(schedule: viewModel.model.schedule.toSleepScheduleModel)
                            .frame(height: 200)
                            .padding(.horizontal)
                            .padding(.vertical, 42)
                        
                        SleepBlocksSection(viewModel: viewModel)
                        
                        InfoCardsSection(viewModel: viewModel)
                        
                        TipSection(viewModel: viewModel)
                    }
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            
            .navigationBarItems(trailing:
                Image(systemName: viewModel.isEditing ? "checkmark" : "pencil")
                    .symbolRenderingMode(.hierarchical)
                    .fontWeight(viewModel.isEditing ? .bold : .black)
                    .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
                    .onTapGesture {
                        viewModel.isEditing.toggle()
                    }
            )
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
        .sheet(isPresented: $viewModel.showAddBlockSheet) {
            AddSleepBlockSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Main Content
struct MainContent: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Binding var scrollOffset: CGFloat
    let progress: CGFloat
    
    var body: some View {
        VStack(spacing: 16) {
            HeaderView(viewModel: viewModel, progress: progress)
            
            CircularSleepChart(schedule: viewModel.model.schedule.toSleepScheduleModel)
                .frame(height: 200)
                .padding(.horizontal)
                .padding(.vertical, 42)
            
            SleepBlocksSection(viewModel: viewModel)
            
            InfoCardsSection(viewModel: viewModel)
            
            TipSection(viewModel: viewModel)
        }
        .padding(.bottom, 16)
    }
}

// MARK: - Header
struct HeaderView: View {
    @ObservedObject var viewModel: MainScreenViewModel
    let progress: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.isEditing {
                HStack(spacing: 8) {
                    if viewModel.isEditingTitle {
                        HStack {
                            TextField(
                                String(localized: "schedule.name.placeholder"),
                                text: $viewModel.editingTitle
                            )
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .submitLabel(.done)
                            .onSubmit {
                                viewModel.saveTitleChanges()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: {
                                viewModel.saveTitleChanges()
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.appAccent)
                            }
                        }
                    } else {
                        Text(viewModel.model.schedule.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onTapGesture {
                                viewModel.startTitleEditing()
                            }
                        
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(.appAccent)
                    }
                }
            } else {
                Text(viewModel.model.schedule.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 38)
    }
}

// MARK: - Sleep Block Section
struct SleepBlocksSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "mainScreen.sleepBlocks"))
                .font(.title3)
                .foregroundColor(.appText)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if viewModel.isEditing {
                        AddBlockButton(viewModel: viewModel)
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
                
                Text(String(localized: "mainScreen.addSleepBlock"))
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
    
    @State private var showingActionSheet = false
    @State private var showingEditSheet = false
    
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(block.isCore ? String(localized: "🛏️") : String(localized: "⚡️"))
                    .font(.title2)
                Text(
                    block.isCore
                    ? String(localized: "mainScreen.sleepBlockCore")
                    : String(localized: "mainScreen.sleepBlockNap")
                )
                .font(.headline)
            }
            .foregroundColor(block.isCore ? .green : .blue)
            
            Text("\(block.startTime) - \(block.endTime)")
                .font(.subheadline)
                .foregroundColor(.appText)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBackground)
        )
        .onLongPressGesture(minimumDuration: 0.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                showingActionSheet = true
            }
        }
        .confirmationDialog("", isPresented: $showingActionSheet) {
            Button(String(localized: "general.edit")) {
                viewModel.prepareForEditing(block)
                showingEditSheet = true
            }
            
            Button(String(localized: "general.delete"), role: .destructive) {
                viewModel.deleteBlock(block)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditSleepBlockSheet(viewModel: viewModel)
        }
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
                    Toggle(String(localized: "sleepBlock.isCore"), isOn: $viewModel.editingBlockIsCore)
                        .tint(.appAccent)
                }
                
                Section {
                    DatePicker(
                        String(localized: "sleepBlock.startTime"),
                        selection: $viewModel.editingBlockStartTime,
                        displayedComponents: .hourAndMinute
                    )
                    
                    DatePicker(
                        String(localized: "sleepBlock.endTime"),
                        selection: $viewModel.editingBlockEndTime,
                        displayedComponents: .hourAndMinute
                    )
                }
            }
            .navigationTitle(String(localized: "sleepBlock.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "general.cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "general.save")) {
                        if viewModel.validateEditingBlock() {
                            viewModel.updateBlock()
                            dismiss()
                        }
                    }
                }
            }
            .alert(
                String(localized: "sleepBlock.error.title"),
                isPresented: $viewModel.showBlockError
            ) {
                Button(String(localized: "general.ok"), role: .cancel) {}
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
            HStack(spacing: 8) {
                InfoCard(
                    icon: "💤",
                    title: String(localized: "mainScreen.totalSleep"),
                    value: viewModel.totalSleepTimeFormatted,
                    color: .appPrimary
                )
                
                InfoCard(
                    icon: "📈",
                    title: String(localized: "mainScreen.progress"),
                    value: "\(Int(viewModel.dailyProgress * 100))%",
                    color: .appAccent
                )
            }
            
            HStack(spacing: 8) {
                InfoCard(
                    icon: "🔥",
                    title: String(localized: "mainScreen.streak"),
                    value: "\(viewModel.currentStreak)",
                    color: .appSecondary
                )
                
                InfoCard(
                    icon: "🕒",
                    title: String(localized: "mainScreen.nextSleepBlock"),
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
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "mainScreen.todaysTip"))
                .font(.headline)
                .foregroundColor(.appText)
            
            HStack(spacing: 12) {
                Text("💡")
                    .font(.title2)
                
                Text(viewModel.dailyTip)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.headline)
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
