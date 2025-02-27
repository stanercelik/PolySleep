import Foundation
import SwiftData

enum SortOption: String, CaseIterable {
    case newestFirst = "Newest First"
    case oldestFirst = "Oldest First"
    case highestRated = "Highest Rated"
    case lowestRated = "Lowest Rated"
}

enum SleepType: Int, Codable {
    case core
    case powerNap
    
    var title: String {
        switch self {
        case .core:
            return NSLocalizedString("sleep.type.core", tableName: "History" ,comment: "")
        case .powerNap:
            return NSLocalizedString("sleep.type.nap", tableName: "History", comment: "")
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

@Model
final class SleepEntry: Identifiable {
    var id: UUID
    var type: SleepType
    var startTime: Date
    var endTime: Date
    var rating: Int
    var parentHistory: HistoryModel?
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    init(id: UUID, type: SleepType, startTime: Date, endTime: Date, rating: Int) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.rating = rating
    }
}

struct HistoryItem: Identifiable {
    let id: String
    let date: Date
    let sleepEntries: [SleepEntry]
    
    var totalSleepDuration: TimeInterval {
        sleepEntries.reduce(0) { $0 + $1.duration }
    }
    
    var averageRating: Double {
        guard !sleepEntries.isEmpty else { return 0 }
        let totalRating = sleepEntries.reduce(0) { $0 + $1.rating }
        return Double(totalRating) / Double(sleepEntries.count)
    }
}

enum CompletionStatus: Int, Codable {
    case completed
    case partial
    case missed
    
    var color: String {
        switch self {
        case .completed:
            return "SuccessColor"
        case .partial:
            return "WarningColor"
        case .missed:
            return "ErrorColor"
        }
    }
}

@Model
final class HistoryModel {
    var id: String
    var date: Date
    @Relationship(deleteRule: .cascade) var sleepEntries: [SleepEntry]
    var completionStatus: CompletionStatus
    
    var totalSleepDuration: TimeInterval {
        sleepEntries.reduce(0) { $0 + $1.duration }
    }
    
    var averageRating: Double {
        guard !sleepEntries.isEmpty else { return 0 }
        let totalRating = sleepEntries.reduce(0) { $0 + $1.rating }
        return Double(totalRating) / Double(sleepEntries.count)
    }
    
    init(date: Date, sleepEntries: [SleepEntry] = []) {
        self.id = UUID().uuidString
        self.date = date
        self.sleepEntries = sleepEntries
        self.completionStatus = .missed
        
        // Tamamlanma durumunu hesapla
        if !sleepEntries.isEmpty {
            let totalSleep = sleepEntries.reduce(0) { $0 + $1.duration }
            
            if totalSleep >= 21600 { // 6 saat veya daha fazla
                self.completionStatus = .completed
            } else if totalSleep >= 10800 { // 3 saat veya daha fazla
                self.completionStatus = .partial
            }
        }
    }
}
