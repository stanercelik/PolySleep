import SwiftUI

struct AddSleepBlockSheet: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker(String(localized: "sleepBlock.startTime"),
                              selection: $viewModel.newBlockStartTime,
                              displayedComponents: .hourAndMinute)
                    
                    DatePicker(String(localized: "sleepBlock.endTime"),
                              selection: $viewModel.newBlockEndTime,
                              displayedComponents: .hourAndMinute)
                    
                    Toggle(String(localized: "sleepBlock.isCore"), isOn: $viewModel.newBlockIsCore)
                        .tint(.appAccent)
                }
                
                if !viewModel.model.schedule.schedule.isEmpty {
                    Section(header: Text(String(localized: "sleepBlock.existing.title"))) {
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
                                Text(String(localized: block.isCore ? "sleepBlock.type.core" : "sleepBlock.type.nap"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "sleepBlock.add"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "general.cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "general.save")) {
                        if viewModel.validateNewBlock() {
                            viewModel.addNewBlock()
                            dismiss()
                        }
                    }
                }
            }
            .alert(String(localized: "sleepBlock.error.title"),
                   isPresented: $viewModel.showBlockError) {
                Button(String(localized: "general.ok"), role: .cancel) {}
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
