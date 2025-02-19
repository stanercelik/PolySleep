import Foundation

struct UserScheduleModel {
    let id: String
    let name: String
    let description: LocalizedDescription
    let totalSleepHours: Double
    let schedule: [SleepBlock]
    
    static var defaultSchedule: UserScheduleModel {
        UserScheduleModel(
            id: "default",
            name: "Default",
            description: LocalizedDescription(
                en: "Default sleep schedule",
                tr: "Varsayılan uyku programı"
            ),
            totalSleepHours: 8.0,
            schedule: [
                SleepBlock(
                    startTime: "23:00",
                    duration: 480,
                    type: "core",
                    isCore: true
                )
            ]
        )
    }
}

extension UserScheduleModel {
    var toSleepScheduleModel: SleepScheduleModel {
        SleepScheduleModel(
            id: id,
            name: name,
            description: description,
            totalSleepHours: totalSleepHours,
            schedule: schedule
        )
    }
}
