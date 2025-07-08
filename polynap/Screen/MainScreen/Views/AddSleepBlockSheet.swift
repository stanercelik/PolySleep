import SwiftUI

struct AddSleepBlockSheet: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var languageManager: LanguageManager
    
    // Analytics
    private let analyticsManager = AnalyticsManager.shared
    
    // Kullanıcının seçtiği emojiler
    private var coreEmoji: String {
        UserDefaults.standard.string(forKey: "selectedCoreEmoji") ?? "🌙"
    }
    
    private var napEmoji: String {
        UserDefaults.standard.string(forKey: "selectedNapEmoji") ?? "💤"
    }
    
    private var sortedSchedule: [SleepBlock] {
        viewModel.model.schedule.schedule.sorted { block1, block2 in
            guard let time1 = TimeFormatter.time(from: block1.startTime),
                  let time2 = TimeFormatter.time(from: block2.startTime) else {
                return false
            }
            let minutes1 = time1.hour * 60 + time1.minute
            let minutes2 = time2.hour * 60 + time2.minute
            return minutes1 < minutes2
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                addBlockForm
                    .scrollContentBackground(.hidden)
            }
            .navigationTitle(L("sleepBlock.add", table: "MainScreen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("general.cancel", table: "MainScreen")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("general.save", table: "MainScreen")) {
                        if viewModel.validateNewBlock() {
                            // Analytics: Sleep block ekleme
                            let duration = Int(viewModel.newBlockEndTime.timeIntervalSince(viewModel.newBlockStartTime) / 60)
                            analyticsManager.logSleepEntryAdded(
                                sleepType: "manual_block",
                                duration: duration
                            )
                            
                            viewModel.addNewBlock()
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                // Analytics: Add Sleep Block sheet görüntüleme
                analyticsManager.logScreenView(
                    screenName: "add_sleep_block_sheet",
                    screenClass: "AddSleepBlockSheet"
                )
            }
            .alert(L("sleepBlock.error.title", table: "MainScreen"),
                   isPresented: $viewModel.showBlockError) {
                Button(L("general.ok", table: "MainScreen"), role: .cancel) {}
            } message: {
                Text(viewModel.blockErrorMessage)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .inactive {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .id(languageManager.currentLanguage)
    }
    
    private var addBlockForm: some View {
        Form {
            timeSelectionSection
            typeInfoSection
            existingBlocksSection
        }
    }
    
    private var timeSelectionSection: some View {
        Section {
            DatePicker(L("sleepBlock.startTime", table: "MainScreen"),
                      selection: $viewModel.newBlockStartTime,
                      displayedComponents: .hourAndMinute)
            
            DatePicker(L("sleepBlock.endTime", table: "MainScreen"),
                      selection: $viewModel.newBlockEndTime,
                      displayedComponents: .hourAndMinute)
        }
    }
    
    private var typeInfoSection: some View {
        Section {
            Text(L("sleepBlock.autoType", table: "MainScreen"))
                .font(.footnote)
                .foregroundColor(.appTextSecondary)
        }
    }
    
    @ViewBuilder
    private var existingBlocksSection: some View {
        if !viewModel.model.schedule.schedule.isEmpty {
            Section(header: Text(L("sleepBlock.existing.title", table: "MainScreen"))) {
                ForEach(sortedSchedule) { block in
                    existingBlockRow(for: block)
                }
            }
        }
    }
    
    private func existingBlockRow(for block: SleepBlock) -> some View {
        HStack {
            // Kişiselleştirilmiş emoji kullan
            Text(block.isCore ? coreEmoji : napEmoji)
                .font(.system(size: 14))
                .frame(width: 20, height: 20)
            Text("\(block.startTime) - \(block.endTime)")
                .foregroundColor(.primary)
            Spacer()
            Text(L(block.isCore ? "sleepBlock.type.core" : "sleepBlock.type.nap", table: "MainScreen"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
