import SwiftUI
import SwiftData

@MainActor
class MainScreenViewModel: ObservableObject {
    @Published private(set) var model: MainScreenModel
    @Published var selectedTimeBlock: SleepBlock?
    private var modelContext: ModelContext?
    
    init() {
        self.model = MainScreenModel(schedule: UserScheduleModel.defaultSchedule)
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadSavedSchedule()
    }
    
    private func loadSavedSchedule() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<SleepScheduleStore>()
            let savedSchedules = try context.fetch(descriptor)
            
            if let latestSchedule = savedSchedules.first {
                let scheduleModel = UserScheduleModel(
                    id: latestSchedule.scheduleId,
                    name: latestSchedule.name,
                    description: latestSchedule.scheduleDescription,
                    totalSleepHours: latestSchedule.totalSleepHours,
                    schedule: latestSchedule.schedule
                )
                
                model = MainScreenModel(schedule: scheduleModel)
                print("✅ Loaded saved schedule: \(scheduleModel.name)")
            }
        } catch {
            print("❌ Error loading saved schedule: \(error)")
        }
    }
    
    func toggleTimeBlockExpansion() {
        model = MainScreenModel(
            schedule: model.schedule,
            currentDay: model.currentDay,
            totalDays: model.totalDays,
            expandedTimeBlock: !model.expandedTimeBlock
        )
    }
    
    func updateSelectedTimeBlock(_ block: SleepBlock?) {
        selectedTimeBlock = block
    }
    
    func updateTimeBlock(startTime: String, endTime: String) {
        // Update time block and save to SwiftData
        // Implementation will be added based on your data structure
    }
}
