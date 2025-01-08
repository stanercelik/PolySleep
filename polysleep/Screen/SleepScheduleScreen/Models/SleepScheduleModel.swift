import Foundation

struct SleepScheduleModel: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: LocalizedDescription
    let totalSleepHours: Double
    let schedule: [SleepBlock]
    
    struct LocalizedDescription: Codable, Equatable {
        let en: String
        let tr: String
        
        func localized() -> String {
            let language = Bundle.main.preferredLocalizations.first ?? "en"
            return language == "tr" ? tr : en
        }
    }
    
    struct SleepBlock: Codable, Equatable {
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
        
        var endTime: String {
            let components = startTime.split(separator: ":")
            guard components.count == 2,
                  let hour = Int(components[0]),
                  let minute = Int(components[1]) else {
                return startTime
            }
            
            var totalMinutes = hour * 60 + minute + duration
            if totalMinutes >= 24 * 60 {
                totalMinutes -= 24 * 60
            }
            
            let endHour = totalMinutes / 60
            let endMinute = totalMinutes % 60
            
            return String(format: "%02d:%02d", endHour, endMinute)
        }
        
        var timeRangeDescription: String {
            let blockType = isCore ? 
                NSLocalizedString("sleepBlock.core", comment: "Core sleep block") : 
                NSLocalizedString("sleepBlock.nap", comment: "Nap block")
            
            let durationStr = formattedDuration
            return "\(startTime)-\(endTime)   \(durationStr) \(blockType.lowercased())"
        }
    }
}

struct SleepSchedulesResponse: Codable, Equatable {
    let sleepSchedules: [SleepScheduleModel]
}
