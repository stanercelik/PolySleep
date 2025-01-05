import Foundation

struct SleepScheduleModel: Codable, Identifiable {
    let id: String
    let name: String
    let description: LocalizedDescription
    let totalSleepHours: Double
    let schedule: [SleepBlock]
    
    struct LocalizedDescription: Codable {
        let en: String
        let tr: String
        
        func localized() -> String {
            let language = Bundle.main.preferredLocalizations.first ?? "en"
            return language == "tr" ? tr : en
        }
    }
    
    struct SleepBlock: Codable {
        let type: String
        let startTime: String
        let duration: Int
        
        var isCore: Bool {
            type == "core"
        }
        
        var formattedDuration: String {
            let hours = duration / 60
            let minutes = duration % 60
            if hours > 0 {
                return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
            }
            return "\(minutes)m"
        }
    }
}

struct SleepSchedulesResponse: Codable {
    let sleepSchedules: [SleepScheduleModel]
}
