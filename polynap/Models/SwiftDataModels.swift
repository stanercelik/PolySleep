import Foundation
import SwiftData

// MARK: - User Model
@Model
final class User {
    @Attribute(.unique) var id: UUID
    var email: String?
    var displayName: String?
    var avatarUrl: String?
    var isAnonymous: Bool
    var preferences: String? // JSONB için String veya Data kullanılabilir, sonra parse edilir
    var createdAt: Date
    var updatedAt: Date
    var isPremium: Bool

    // İlişkiler
    @Relationship(deleteRule: .cascade, inverse: \UserSchedule.user)
    var schedules: [UserSchedule]? = []

    // OnboardingAnswerData.swift dosyası güncellenerek User ilişkisi eklendi
    @Relationship(deleteRule: .cascade, inverse: \OnboardingAnswerData.user)
    var onboardingAnswers: [OnboardingAnswerData]? = []

    @Relationship(deleteRule: .cascade, inverse: \SleepEntry.user)
    var sleepEntries: [SleepEntry]? = []

    init(id: UUID = UUID(),
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

// MARK: - UserSchedule Model
@Model
final class UserSchedule {
    @Attribute(.unique) var id: UUID
    var user: User? // İlişki: User'a ait
    var name: String
    var scheduleDescription: String? // JSONB için String veya Data, 'description' Swift'te özel bir anlam taşıdığı için 'scheduleDescription'
    var totalSleepHours: Double?
    var adaptationPhase: Int?
    var createdAt: Date
    var updatedAt: Date
    var isActive: Bool

    // İlişkiler
    @Relationship(deleteRule: .cascade, inverse: \UserSleepBlock.schedule)
    var sleepBlocks: [UserSleepBlock]? = []

    init(id: UUID = UUID(),
         user: User? = nil,
         name: String,
         scheduleDescription: String? = nil, // JSON string
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

// MARK: - UserSleepBlock Model
@Model
final class UserSleepBlock {
    @Attribute(.unique) var id: UUID
    var schedule: UserSchedule? // İlişki: UserSchedule'a ait
    var startTime: Date // TIME tipi için Date kullanılabilir, sadece saat/dakika kısmı relevant olacak
    var endTime: Date   // TIME tipi için Date kullanılabilir, sadece saat/dakika kısmı relevant olacak
    var durationMinutes: Int
    var isCore: Bool
    var createdAt: Date
    var updatedAt: Date
    var syncId: String?

    init(id: UUID = UUID(),
         schedule: UserSchedule? = nil,
         startTime: Date,
         endTime: Date,
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

// MARK: - ScheduleEntity Model
@Model
final class ScheduleEntity {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var name: String
    var descriptionJson: String // JSON formatında lokalize açıklamalar
    var totalSleepHours: Double
    var isActive: Bool
    var isDeleted: Bool
    var createdAt: Date
    var updatedAt: Date
    var syncId: String?

    @Relationship(deleteRule: .cascade, inverse: \SleepBlockEntity.schedule)
    var sleepBlocks: [SleepBlockEntity] = []

    init(id: UUID = UUID(),
         userId: UUID,
         name: String = "",
         descriptionJson: String = "{}",
         totalSleepHours: Double = 0.0,
         isActive: Bool = false,
         isDeleted: Bool = false,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         syncId: String? = UUID().uuidString) {
        self.id = id
        self.userId = userId
        self.name = name
        self.descriptionJson = descriptionJson
        self.totalSleepHours = totalSleepHours
        self.isActive = isActive
        self.isDeleted = isDeleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncId = syncId
    }
}

// MARK: - SleepBlockEntity Model
@Model
final class SleepBlockEntity {
    @Attribute(.unique) var id: UUID
    var schedule: ScheduleEntity?
    var startTime: String // Saat formatı: "23:00"
    var endTime: String   // Saat formatı: "01:00"
    var durationMinutes: Int
    var isCore: Bool
    var isDeleted: Bool
    var createdAt: Date
    var updatedAt: Date
    var syncId: String?

    init(id: UUID = UUID(),
         schedule: ScheduleEntity? = nil,
         startTime: String,
         endTime: String,
         durationMinutes: Int,
         isCore: Bool = false,
         isDeleted: Bool = false,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         syncId: String? = UUID().uuidString) {
        self.id = id
        self.schedule = schedule
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.isCore = isCore
        self.isDeleted = isDeleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncId = syncId
    }
}

// MARK: - SleepEntryEntity Model
@Model
final class SleepEntryEntity {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var blockId: String?
    var emoji: String?
    var rating: Int
    var isDeleted: Bool
    var createdAt: Date
    var updatedAt: Date
    var syncId: String?

    init(id: UUID = UUID(),
         userId: UUID,
         date: Date = Date(),
         blockId: String? = nil,
         emoji: String? = nil,
         rating: Int = 0,
         isDeleted: Bool = false,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         syncId: String? = UUID().uuidString) {
        self.id = id
        self.userId = userId
        self.date = date
        self.blockId = blockId
        self.emoji = emoji
        self.rating = rating
        self.isDeleted = isDeleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncId = syncId
    }
}

// MARK: - PendingChange Model
@Model
final class PendingChange {
    @Attribute(.unique) var id: UUID
    var entityName: String
    var entityId: String
    var operationType: String // "create", "update", "delete"
    var payload: String? // JSON formatında veri
    var createdAt: Date
    var attempts: Int
    var lastAttemptAt: Date?
    var errorInfo: String?

    init(id: UUID = UUID(),
         entityName: String,
         entityId: String,
         operationType: String,
         payload: String? = nil,
         createdAt: Date = Date(),
         attempts: Int = 0,
         lastAttemptAt: Date? = nil,
         errorInfo: String? = nil) {
        self.id = id
        self.entityName = entityName
        self.entityId = entityId
        self.operationType = operationType
        self.payload = payload
        self.createdAt = createdAt
        self.attempts = attempts
        self.lastAttemptAt = lastAttemptAt
        self.errorInfo = errorInfo
    }
}

// MARK: - AlarmSettings Model
@Model
final class AlarmSettings {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var isEnabled: Bool
    var soundName: String
    var volume: Double // 0.0 - 1.0
    var vibrationEnabled: Bool
    var snoozeEnabled: Bool
    var snoozeDurationMinutes: Int
    var maxSnoozeCount: Int
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(),
         userId: UUID,
         isEnabled: Bool = true,
         soundName: String = "Alarm 1.caf",
         volume: Double = 0.8,
         vibrationEnabled: Bool = true,
         snoozeEnabled: Bool = true,
         snoozeDurationMinutes: Int = 5,
         maxSnoozeCount: Int = 3,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.isEnabled = isEnabled
        self.soundName = soundName
        self.volume = volume
        self.vibrationEnabled = vibrationEnabled
        self.snoozeEnabled = snoozeEnabled
        self.snoozeDurationMinutes = snoozeDurationMinutes
        self.maxSnoozeCount = maxSnoozeCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - AlarmNotification Model
@Model
final class AlarmNotification {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var scheduleId: UUID
    var blockId: UUID
    var notificationIdentifier: String
    var scheduledTime: Date
    var isActive: Bool
    var createdAt: Date
    var firedAt: Date?
    var snoozedCount: Int
    
    init(id: UUID = UUID(),
         userId: UUID,
         scheduleId: UUID,
         blockId: UUID,
         notificationIdentifier: String,
         scheduledTime: Date,
         isActive: Bool = true,
         createdAt: Date = Date(),
         firedAt: Date? = nil,
         snoozedCount: Int = 0) {
        self.id = id
        self.userId = userId
        self.scheduleId = scheduleId
        self.blockId = blockId
        self.notificationIdentifier = notificationIdentifier
        self.scheduledTime = scheduledTime
        self.isActive = isActive
        self.createdAt = createdAt
        self.firedAt = firedAt
        self.snoozedCount = snoozedCount
    }
}

// MARK: - ScheduleChangeUndoData Model
struct ScheduleChangeUndoData: Codable {
    let scheduleId: UUID
    let changeDate: Date
    let previousStreak: Int
    let previousAdaptationPhase: Int
    let previousAdaptationDate: Date
} 