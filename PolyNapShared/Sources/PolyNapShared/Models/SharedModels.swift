import Foundation

#if canImport(SwiftData)
import SwiftData
#endif

// MARK: - Shared Enums

public enum SleepType: String, Codable, CaseIterable {
    case core = "Core"
    case powerNap = "Power Nap"
    
    public var healthKitValue: Int {
        switch self {
        case .core:
            return 0 // HKCategoryValueSleepAnalysis.asleep
        case .powerNap:
            return 1 // HKCategoryValueSleepAnalysis.awake (nap olarak değerlendirilebilir)
        }
    }
}

public enum SleepQuality: Int, Codable, CaseIterable {
    case terrible = 1
    case poor = 2
    case okay = 3
    case good = 4
    case excellent = 5
    
    public var emoji: String {
        switch self {
        case .terrible: return "😴"
        case .poor: return "😪"
        case .okay: return "😐"
        case .good: return "😊"
        case .excellent: return "😄"
        }
    }
}

// MARK: - Shared Data Models

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
@available(iOS 17.0, watchOS 10.0, macOS 14.0, *)
@Model
public final class SharedUser {
    @Attribute(.unique) public var id: UUID
    public var email: String?
    public var displayName: String?
    public var avatarUrl: String?
    public var isAnonymous: Bool
    public var preferences: String? // JSON string
    public var createdAt: Date
    public var updatedAt: Date
    public var isPremium: Bool

    // İlişkiler
    @Relationship(deleteRule: .cascade, inverse: \SharedUserSchedule.user)
    public var schedules: [SharedUserSchedule]? = []

    @Relationship(deleteRule: .cascade, inverse: \SharedSleepEntry.user)
    public var sleepEntries: [SharedSleepEntry]? = []

    public init(id: UUID = UUID(),
                email: String? = nil,
                displayName: String? = nil,
                avatarUrl: String? = nil,
                isAnonymous: Bool = false,
                preferences: String? = nil,
                createdAt: Date = Date(),
                updatedAt: Date = Date(),
                isPremium: Bool = false) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.isAnonymous = isAnonymous
        self.preferences = preferences
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPremium = isPremium
    }
}

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
@available(iOS 17.0, watchOS 10.0, macOS 14.0, *)
@Model
public final class SharedUserSchedule {
    @Attribute(.unique) public var id: UUID
    public var user: SharedUser? // İlişki: User'a ait
    public var name: String
    public var scheduleDescription: String? // JSON string
    public var totalSleepHours: Double?
    public var adaptationPhase: Int?
    public var createdAt: Date
    public var updatedAt: Date
    public var isActive: Bool

    // İlişkiler
    @Relationship(deleteRule: .cascade, inverse: \SharedSleepBlock.schedule)
    public var sleepBlocks: [SharedSleepBlock]? = []

    public init(id: UUID = UUID(),
                user: SharedUser? = nil,
                name: String,
                scheduleDescription: String? = nil,
                totalSleepHours: Double? = nil,
                adaptationPhase: Int? = nil,
                createdAt: Date = Date(),
                updatedAt: Date = Date(),
                isActive: Bool = false) {
        self.id = id
        self.user = user
        self.name = name
        self.scheduleDescription = scheduleDescription
        self.totalSleepHours = totalSleepHours
        self.adaptationPhase = adaptationPhase
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isActive = isActive
    }
}

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
@available(iOS 17.0, watchOS 10.0, macOS 14.0, *)
@Model
public final class SharedSleepBlock {
    @Attribute(.unique) public var id: UUID
    public var schedule: SharedUserSchedule?
    public var startTime: String // "23:00" formatında
    public var endTime: String   // "01:00" formatında
    public var durationMinutes: Int
    public var isCore: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var syncId: String?

    public var sleepType: SleepType {
        return isCore ? .core : .powerNap
    }

    public init(id: UUID = UUID(),
                schedule: SharedUserSchedule? = nil,
                startTime: String,
                endTime: String,
                durationMinutes: Int,
                isCore: Bool = false,
                createdAt: Date = Date(),
                updatedAt: Date = Date(),
                syncId: String? = nil) {
        self.id = id
        self.schedule = schedule
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.isCore = isCore
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncId = syncId
    }
}

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
@available(iOS 17.0, watchOS 10.0, macOS 14.0, *)
@Model
public final class SharedSleepEntry {
    @Attribute(.unique) public var id: UUID
    public var user: SharedUser?
    public var date: Date
    public var blockId: String?
    public var emoji: String?
    public var rating: Int // 1-5 arası
    public var startTime: Date
    public var endTime: Date
    public var durationMinutes: Int
    public var isCore: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var syncId: String?

    public var sleepType: SleepType {
        return isCore ? .core : .powerNap
    }
    
    public var quality: SleepQuality? {
        return SleepQuality(rawValue: rating)
    }
    
    public var duration: TimeInterval {
        return Double(durationMinutes * 60)
    }

    public init(id: UUID = UUID(),
                user: SharedUser? = nil,
                date: Date,
                startTime: Date,
                endTime: Date,
                durationMinutes: Int,
                isCore: Bool,
                blockId: String? = nil,
                emoji: String? = nil,
                rating: Int = 0,
                createdAt: Date = Date(),
                updatedAt: Date = Date(),
                syncId: String? = nil) {
        self.id = id
        self.user = user
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.isCore = isCore
        self.blockId = blockId
        self.emoji = emoji
        self.rating = rating
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncId = syncId ?? UUID().uuidString
    }
    
    /// Watch connectivity için dictionary formatına çevirir
    public var dictionary: [String: Any] {
        return [
            "id": id.uuidString,
            "date": date.timeIntervalSince1970,
            "startTime": startTime.timeIntervalSince1970,
            "endTime": endTime.timeIntervalSince1970,
            "durationMinutes": durationMinutes,
            "isCore": isCore,
            "blockId": blockId ?? "",
            "emoji": emoji ?? "",
            "rating": rating,
            "createdAt": createdAt.timeIntervalSince1970,
            "updatedAt": updatedAt.timeIntervalSince1970,
            "syncId": syncId ?? ""
        ]
    }
}

// MARK: - Adaptation Progress Model

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
@available(iOS 17.0, watchOS 10.0, macOS 14.0, *)
@Model
public final class SharedAdaptationProgress {
    @Attribute(.unique) public var id: UUID
    public var user: SharedUser?
    public var schedule: SharedUserSchedule?
    public var currentPhase: Int
    public var totalPhases: Int
    public var daysSinceStart: Int
    public var estimatedTotalDays: Int
    public var progressPercentage: Double // 0.0 - 1.0
    public var isCompleted: Bool
    public var phaseName: String
    public var phaseDescription: String
    public var createdAt: Date
    public var updatedAt: Date

    public var remainingDays: Int {
        return max(0, estimatedTotalDays - daysSinceStart)
    }
    
    public var phaseProgress: Double {
        guard totalPhases > 0 else { return 0.0 }
        return Double(currentPhase) / Double(totalPhases)
    }

    public init(id: UUID = UUID(),
                user: SharedUser? = nil,
                schedule: SharedUserSchedule? = nil,
                currentPhase: Int = 1,
                totalPhases: Int = 4,
                daysSinceStart: Int = 0,
                estimatedTotalDays: Int = 30,
                progressPercentage: Double = 0.0,
                isCompleted: Bool = false,
                phaseName: String = "Başlangıç",
                phaseDescription: String = "Adaptasyon süreci başladı",
                createdAt: Date = Date(),
                updatedAt: Date = Date()) {
        self.id = id
        self.user = user
        self.schedule = schedule
        self.currentPhase = currentPhase
        self.totalPhases = totalPhases
        self.daysSinceStart = daysSinceStart
        self.estimatedTotalDays = estimatedTotalDays
        self.progressPercentage = progressPercentage
        self.isCompleted = isCompleted
        self.phaseName = phaseName
        self.phaseDescription = phaseDescription
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Watch Sync Models

public enum WatchSyncMessageType: String, Codable {
    case scheduleSync
    case scheduleUpdate
    case scheduleActivated
    case userPreferencesSync
    case sleepDataBatch
    case fullDataSyncRequest
    case syncComplete
}

public struct WatchSyncPayload<T: Codable>: Codable {
    public var type: WatchSyncMessageType
    public var timestamp: Date
    public var data: T?
    
    public init(type: WatchSyncMessageType, data: T?) {
        self.type = type
        self.timestamp = Date()
        self.data = data
    }
}

public struct WSSchedulePayload: Codable {
    public let id: UUID
    public let name: String
    public let description: String
    public let totalSleepHours: Double
    public let isActive: Bool
    public let adaptationPhase: Int
    public let sleepBlocks: [WSSleepBlock]
    public let adaptationData: WSAdaptationData?

    public init(id: UUID, name: String, description: String, totalSleepHours: Double, isActive: Bool, adaptationPhase: Int, sleepBlocks: [WSSleepBlock], adaptationData: WSAdaptationData?) {
        self.id = id
        self.name = name
        self.description = description
        self.totalSleepHours = totalSleepHours
        self.isActive = isActive
        self.adaptationPhase = adaptationPhase
        self.sleepBlocks = sleepBlocks
        self.adaptationData = adaptationData
    }
}

public struct WSSleepBlock: Codable, Identifiable {
    public let id: UUID
    public let startTime: String
    public let endTime: String
    public let durationMinutes: Int
    public let isCore: Bool

    public init(id: UUID, startTime: String, endTime: String, durationMinutes: Int, isCore: Bool) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.isCore = isCore
    }
}

public struct WSAdaptationData: Codable {
    public let adaptationPhase: Int
    public let adaptationPercentage: Double
    public let totalEntries: Int
    public let last7DaysEntries: Int
    public let averageRating: Double

    public init(adaptationPhase: Int, adaptationPercentage: Double, totalEntries: Int, last7DaysEntries: Int, averageRating: Double) {
        self.adaptationPhase = adaptationPhase
        self.adaptationPercentage = adaptationPercentage
        self.totalEntries = totalEntries
        self.last7DaysEntries = last7DaysEntries
        self.averageRating = averageRating
    }
}

public struct WSUserPreferences: Codable {
    public let userId: UUID
    public let displayName: String
    public let isPremium: Bool

    public init(userId: UUID, displayName: String, isPremium: Bool) {
        self.userId = userId
        self.displayName = displayName
        self.isPremium = isPremium
    }
} 