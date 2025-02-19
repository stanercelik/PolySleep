import SwiftUI
import SwiftData

@Model
final class SleepScheduleStore {
    var scheduleId: String
    var selectedDate: Date
    var name: String
    var scheduleDescription: LocalizedDescription
    var totalSleepHours: Double
    var schedule: [SleepBlock]
    
    init(scheduleId: String, 
         selectedDate: Date = Date(),
         name: String = "",
         scheduleDescription: LocalizedDescription = LocalizedDescription(en: "", tr: ""),
         totalSleepHours: Double = 0.0,
         schedule: [SleepBlock] = []) {
        self.scheduleId = scheduleId
        self.selectedDate = selectedDate
        self.name = name
        self.scheduleDescription = scheduleDescription
        self.totalSleepHours = totalSleepHours
        self.schedule = schedule
    }
}
