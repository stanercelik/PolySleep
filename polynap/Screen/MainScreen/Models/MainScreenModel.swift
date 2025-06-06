import Foundation
import SwiftData

struct MainScreenModel {
    var schedule: UserScheduleModel
    var currentDay: Int
    var totalDays: Int
    var expandedTimeBlock: Bool
    
    init(schedule: UserScheduleModel, currentDay: Int = 1, totalDays: Int = 21, expandedTimeBlock: Bool = false) {
        self.schedule = schedule
        self.currentDay = currentDay
        self.totalDays = totalDays
        self.expandedTimeBlock = expandedTimeBlock
    }
}
