import Foundation

struct SleepSchedule {
    struct SleepBlock {
        let startTime: Date
        let duration: Double
    }

    let sleepBlocks: [SleepBlock]

    var totalSleepHours: Double {
        return sleepBlocks.reduce(0.0) { total, block in
            total + block.duration / 3600
        }
    }

    var formattedTotalSleepTime: String {
        let totalSeconds = sleepBlocks.reduce(0) { $0 + $1.duration }
        let hours = Int(totalSeconds) / 3600
        let minutes = Int(totalSeconds) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
}
