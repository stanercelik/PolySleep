import SwiftUI

struct AddSleepBlockSheet: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker(NSLocalizedString("sleepBlock.startTime", tableName: "MainScreen", comment: ""),
                              selection: $viewModel.newBlockStartTime,
                              displayedComponents: .hourAndMinute)
                    
                    DatePicker(NSLocalizedString("sleepBlock.endTime", tableName: "MainScreen", comment: ""),
                              selection: $viewModel.newBlockEndTime,
                              displayedComponents: .hourAndMinute)
                }
                
                if !viewModel.model.schedule.schedule.isEmpty {
                    Section(header: Text("sleepBlock.existing.title", tableName: "MainScreen")) {
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
                                Text(NSLocalizedString(block.isCore ? "sleepBlock.type.core" : "sleepBlock.type.nap", tableName: "MainScreen", comment: ""))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("sleepBlock.add", tableName: "MainScreen", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("general.cancel", tableName: "MainScreen", comment: "")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("general.save", tableName: "MainScreen", comment: "" )) {
                        if viewModel.validateNewBlock() {
                            viewModel.addNewBlock()
                            dismiss()
                        }
                    }
                }
            }
            .alert(NSLocalizedString("sleepBlock.error.title", tableName: "MainScreen", comment: ""),
                   isPresented: $viewModel.showBlockError) {
                Button(NSLocalizedString("general.ok", tableName: "MainScreen", comment: ""), role: .cancel) {}
            } message: {
                Text(viewModel.blockErrorMessage)
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .inactive {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }
}
