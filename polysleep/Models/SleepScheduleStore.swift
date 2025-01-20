import SwiftUI
import SwiftData

@Model
final class SleepScheduleStore {
    var scheduleId: String
    var selectedDate: Date
    
    init(scheduleId: String, selectedDate: Date = Date()) {
        self.scheduleId = scheduleId
        self.selectedDate = selectedDate
    }
}
