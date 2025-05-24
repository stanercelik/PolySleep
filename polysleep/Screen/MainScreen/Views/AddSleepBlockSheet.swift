import SwiftUI

struct AddSleepBlockSheet: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                Form {
                    Section {
                        DatePicker(L("sleepBlock.startTime", table: "MainScreen"),
                                  selection: $viewModel.newBlockStartTime,
                                  displayedComponents: .hourAndMinute)
                        
                        DatePicker(L("sleepBlock.endTime", table: "MainScreen"),
                                  selection: $viewModel.newBlockEndTime,
                                  displayedComponents: .hourAndMinute)
                    }
                    
                    Section {
                        Text(L("sleepBlock.autoType", table: "MainScreen"))
                            .font(.footnote)
                            .foregroundColor(.appSecondaryText)
                    }
                    
                    if !viewModel.model.schedule.schedule.isEmpty {
                        Section(header: Text(L("sleepBlock.existing.title", table: "MainScreen"))) {
                            ForEach(viewModel.model.schedule.schedule.sorted { block1, block2 in
                                let time1 = TimeFormatter.time(from: block1.startTime)!
                                let time2 = TimeFormatter.time(from: block2.startTime)!
                                let minutes1 = time1.hour * 60 + time1.minute
                                let minutes2 = time2.hour * 60 + time2.minute
                                return minutes1 < minutes2
                            }) { block in
                                HStack {
                                    Image(systemName: block.isCore ? "moon.fill" : "moon")
                                        .foregroundColor(block.isCore ? .appAccent : .secondary)
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
                    }
                }
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
                            viewModel.addNewBlock()
                            dismiss()
                        }
                    }
                }
            }
            .alert(L("sleepBlock.error.title", table: "MainScreen"),
                   isPresented: $viewModel.showBlockError) {
                Button(L("general.ok", table: "MainScreen"), role: .cancel) {}
            } message: {
                Text(viewModel.blockErrorMessage)
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .inactive {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .id(languageManager.currentLanguage)
    }
}
