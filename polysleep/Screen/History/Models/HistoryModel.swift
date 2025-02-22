import Foundation

enum SortOption: String, CaseIterable {
    case newestFirst = "Newest First"
    case oldestFirst = "Oldest First"
    case highestRated = "Highest Rated"
    case lowestRated = "Lowest Rated"
}

enum SleepType {
    case core
    case powerNap
    
    var title: String {
        switch self {
        case .core:
            return "Core Sleep"
        case .powerNap:
            return "Power Nap"
        }
    }
    
    var icon: String {
        switch self {
        case .core:
            return "bed.double.fill"
        case .powerNap:
            return "bolt.fill"
        }
    }
}

struct SleepEntry: Identifiable {
    let id = UUID()
    let type: SleepType
    let startTime: Date
    let endTime: Date
    let rating: Int
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}

struct HistoryModel: Identifiable {
    let id = UUID()
    let date: Date
    var sleepEntries: [SleepEntry]
    
    var totalSleepDuration: TimeInterval {
        sleepEntries.reduce(0) { $0 + $1.duration }
    }
    
    var averageRating: Double {
        let totalRating = sleepEntries.reduce(0) { $0 + $1.rating }
        return Double(totalRating) / Double(sleepEntries.count)
    }
    
    var completionStatus: CompletionStatus {
        let hasCoreSleep = sleepEntries.contains { $0.type == .core }
        let hasPowerNap = sleepEntries.contains { $0.type == .powerNap }
        
        if hasCoreSleep && hasPowerNap {
            return .complete
        } else if hasCoreSleep || hasPowerNap {
            return .partial
        } else {
            return .missed
        }
    }
}

enum CompletionStatus {
    case complete
    case partial
    case missed
    
    var color: String {
        switch self {
        case .complete:
            return "SecondaryColor"
        case .partial:
            return "AccentColor"
        case .missed:
            return "ErrorColor"
        }
    }
}
