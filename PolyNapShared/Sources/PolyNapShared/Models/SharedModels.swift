import Foundation
import SwiftData

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
        self.syncId = syncId
    }
} 