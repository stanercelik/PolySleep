import Foundation
import SwiftUI

struct UserScheduleModel {
    var id: String
    var name: String
    var description: LocalizedDescription
    var totalSleepHours: Double
    var schedule: [SleepBlock]
    var isPremium: Bool
    
    private func sortBlocks(_ blocks: [SleepBlock]) -> [SleepBlock] {
        return blocks.sorted { block1, block2 in
            let time1 = TimeFormatter.time(from: block1.startTime)!
            let time2 = TimeFormatter.time(from: block2.startTime)!
            let minutes1 = time1.hour * 60 + time1.minute
            let minutes2 = time2.hour * 60 + time2.minute
            return minutes1 < minutes2
        }
    }

    init(id: String, name: String, description: LocalizedDescription, totalSleepHours: Double, schedule: [SleepBlock], isPremium: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.totalSleepHours = totalSleepHours
        self.schedule = schedule
        self.isPremium = isPremium
        self.schedule = sortBlocks(self.schedule)
    }
    
    static var defaultSchedule: UserScheduleModel {
        let schedule = [
            SleepBlock(
                startTime: "23:00",
                duration: 120,
                type: "core",
                isCore: true
            ),
            SleepBlock(
                startTime: "04:00",
                duration: 30,
                type: "nap",
                isCore: false
            ),
            SleepBlock(
                startTime: "08:00",
                duration: 30,
                type: "nap",
                isCore: false
            ),
            SleepBlock(
                startTime: "12:00",
                duration: 30,
                type: "nap",
                isCore: false
            ),
            SleepBlock(
                startTime: "19:00",
                duration: 120,
                type: "core",
                isCore: true
            )
        ]
        
        return UserScheduleModel(
            id: "default",
            name: "Trifazik Uyku Programı",
            description: LocalizedDescription(
                en: "The Triphasic Sleep Schedule consists of three sleep periods spread throughout the day: two 30-minute naps and one core sleep period of 4.5 hours. This pattern aims to maximize deep sleep and REM sleep while reducing overall sleep time. It's designed for those who want to experiment with polyphasic sleep and need to maintain high cognitive performance.",
                tr: "Trifazik Uyku Programı, gün boyunca dağılmış üç uyku periyodundan oluşur: iki 30 dakikalık şekerleme ve bir 4.5 saatlik ana uyku dönemi. Bu düzen, toplam uyku süresini azaltırken derin uyku ve REM uykusunu en üst düzeye çıkarmayı amaçlar. Polifazik uyku denemek ve yüksek bilişsel performans sürdürmek isteyenler için tasarlanmıştır."
            ),
            totalSleepHours: 8.0,
            schedule: [],
            isPremium: false
        )
    }
    
    var nextBlock: SleepBlock? {
        guard !schedule.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = currentTime.hour! * 60 + currentTime.minute!
        
        for block in schedule {
            let startComponents = TimeFormatter.time(from: block.startTime)!
            let startMinutes = startComponents.hour * 60 + startComponents.minute
            
            if startMinutes > currentMinutes {
                return block
            }
        }
        
        return schedule.first
    }
    
    var currentBlock: SleepBlock? {
        guard !schedule.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = currentTime.hour! * 60 + currentTime.minute!
        
        for block in schedule {
            let startComponents = TimeFormatter.time(from: block.startTime)!
            let startMinutes = startComponents.hour * 60 + startComponents.minute
            
            let endComponents = TimeFormatter.time(from: block.endTime)!
            let endMinutes = endComponents.hour * 60 + endComponents.minute
            
            if endMinutes < startMinutes {
                if currentMinutes >= startMinutes || currentMinutes <= endMinutes {
                    return block
                }
            } else {
                if currentMinutes >= startMinutes && currentMinutes <= endMinutes {
                    return block
                }
            }
        }
        
        return nil
    }
    
    var remainingTimeToNextBlock: Int {
        guard let next = nextBlock else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = currentTime.hour! * 60 + currentTime.minute!
        
        let startComponents = TimeFormatter.time(from: next.startTime)!
        let startMinutes = startComponents.hour * 60 + startComponents.minute
        
        if startMinutes <= currentMinutes {
            return (24 * 60 - currentMinutes) + startMinutes
        } else {
            return startMinutes - currentMinutes
        }
    }
}

extension UserScheduleModel {
    var toSleepScheduleModel: SleepScheduleModel {
        SleepScheduleModel(
            id: id,
            name: name,
            description: description,
            totalSleepHours: totalSleepHours,
            schedule: schedule,
            isPremium: isPremium
        )
    }
}
