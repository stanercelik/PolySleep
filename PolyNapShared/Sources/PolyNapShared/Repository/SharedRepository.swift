import Foundation
import SwiftData
import Combine
import OSLog

/// Ana Shared Repository hub'ı - Tüm shared repository modüllerini koordine eder
/// iOS ve watchOS platformları arasında ortak data access katmanı sağlar
@MainActor
public class SharedRepository: ObservableObject {
    public static let shared = SharedRepository()
    
    // MARK: - Sub-Repository References
    
    private let baseRepository = SharedBaseRepository()
    public let userRepository = SharedUserRepository.shared
    public let scheduleRepository = SharedScheduleRepository.shared
    public let sleepEntryRepository = SharedSleepEntryRepository.shared
    
    private let logger = Logger(subsystem: "com.tanercelik.polynap.shared", category: "SharedRepository")
    
    // MARK: - Initialization
    
    private init() {
        logger.debug("🗂️ SharedRepository hub başlatıldı")
    }
    
    // MARK: - ModelContext Management
    
    /// ModelContext'i tüm shared modüllerde ayarlar
    public func setModelContext(_ context: ModelContext) {
        baseRepository.setModelContext(context)
        userRepository.setModelContext(context)
        scheduleRepository.setModelContext(context)
        sleepEntryRepository.setModelContext(context)
        
        logger.debug("🗂️ Tüm shared repository'lerde ModelContext ayarlandı")
    }
    
    /// Merkezi shared ModelContext'e erişim
    public func getModelContext() -> ModelContext? {
        return baseRepository.getModelContext()
    }
    
    // MARK: - User Management (Delegated to SharedUserRepository)
    
    /// Kullanıcı ID'si ile SharedUser nesnesini getirir
    public func getUserById(_ id: UUID) async throws -> SharedUser? {
        return try await userRepository.getUserById(id)
    }
    
    /// Yeni SharedUser oluşturur veya mevcut kullanıcıyı getirir
    public func createOrGetUser(id: UUID, 
                               email: String? = nil, 
                               displayName: String? = nil,
                               isAnonymous: Bool = false,
                               isPremium: Bool = false) async throws -> SharedUser {
        return try await userRepository.createOrGetUser(
            id: id,
            email: email,
            displayName: displayName,
            isAnonymous: isAnonymous,
            isPremium: isPremium
        )
    }
    
    /// SharedUser bilgilerini günceller
    public func updateUser(_ user: SharedUser, 
                          email: String? = nil, 
                          displayName: String? = nil,
                          avatarUrl: String? = nil,
                          isPremium: Bool? = nil,
                          preferences: String? = nil) async throws {
        try await userRepository.updateUser(
            user,
            email: email,
            displayName: displayName,
            avatarUrl: avatarUrl,
            isPremium: isPremium,
            preferences: preferences
        )
    }
    
    // MARK: - Schedule Management (Delegated to SharedScheduleRepository)
    
    /// Tüm SharedUserSchedule'ları getirir
    public func getAllSchedules() throws -> [SharedUserSchedule] {
        return try scheduleRepository.getAllSchedules()
    }
    
    /// Aktif olan SharedUserSchedule'ı getirir
    public func getActiveSchedule() throws -> SharedUserSchedule? {
        return try scheduleRepository.getActiveSchedule()
    }
    
    /// Belirli kullanıcının SharedUserSchedule'larını getirir
    public func getSchedulesForUser(_ userId: UUID) throws -> [SharedUserSchedule] {
        return try scheduleRepository.getSchedulesForUser(userId)
    }
    
    /// Yeni SharedUserSchedule oluşturur
    public func createSchedule(user: SharedUser,
                              name: String,
                              description: String? = nil,
                              totalSleepHours: Double? = nil,
                              adaptationPhase: Int? = nil,
                              isActive: Bool = false) async throws -> SharedUserSchedule {
        return try await scheduleRepository.createSchedule(
            user: user,
            name: name,
            description: description,
            totalSleepHours: totalSleepHours,
            adaptationPhase: adaptationPhase,
            isActive: isActive
        )
    }
    
    /// SharedUserSchedule günceller
    public func updateSchedule(_ schedule: SharedUserSchedule,
                              name: String? = nil,
                              description: String? = nil,
                              totalSleepHours: Double? = nil,
                              adaptationPhase: Int? = nil,
                              isActive: Bool? = nil) async throws {
        try await scheduleRepository.updateSchedule(
            schedule,
            name: name,
            description: description,
            totalSleepHours: totalSleepHours,
            adaptationPhase: adaptationPhase,
            isActive: isActive
        )
    }
    
    /// Belirli schedule'ı aktive eder, diğerlerini deaktive eder
    public func setActiveSchedule(_ scheduleId: UUID) async throws {
        try await scheduleRepository.setActiveSchedule(scheduleId)
    }
    
    /// Tüm schedule'ları deaktive eder
    public func deactivateAllSchedules() async throws {
        try await scheduleRepository.deactivateAllSchedules()
    }
    
    // MARK: - Sleep Block Management (Delegated to SharedScheduleRepository)
    
    /// SharedSleepBlock oluşturur
    public func createSleepBlock(schedule: SharedUserSchedule,
                                startTime: String,
                                endTime: String,
                                durationMinutes: Int,
                                isCore: Bool = false,
                                syncId: String? = nil) async throws -> SharedSleepBlock {
        return try await scheduleRepository.createSleepBlock(
            schedule: schedule,
            startTime: startTime,
            endTime: endTime,
            durationMinutes: durationMinutes,
            isCore: isCore,
            syncId: syncId
        )
    }
    
    /// Belirli schedule'a ait SharedSleepBlock'ları getirir
    public func getSleepBlocks(for scheduleId: UUID) throws -> [SharedSleepBlock] {
        return try scheduleRepository.getSleepBlocks(for: scheduleId)
    }
    
    // MARK: - Sleep Entry Management (Delegated to SharedSleepEntryRepository)
    
    /// Yeni SharedSleepEntry oluşturur
    public func createSleepEntry(user: SharedUser,
                                date: Date,
                                startTime: Date,
                                endTime: Date,
                                durationMinutes: Int,
                                isCore: Bool,
                                blockId: String? = nil,
                                emoji: String? = nil,
                                rating: Int = 0,
                                syncId: String? = nil) async throws -> SharedSleepEntry {
        return try await sleepEntryRepository.createSleepEntry(
            user: user,
            date: date,
            startTime: startTime,
            endTime: endTime,
            durationMinutes: durationMinutes,
            isCore: isCore,
            blockId: blockId,
            emoji: emoji,
            rating: rating,
            syncId: syncId
        )
    }
    
    /// Belirli bir tarih için SharedSleepEntry'leri getirir
    public func getSleepEntries(for date: Date) throws -> [SharedSleepEntry] {
        return try sleepEntryRepository.getSleepEntries(for: date)
    }
    
    /// Belirli kullanıcının tüm SharedSleepEntry'lerini getirir
    public func getSleepEntriesForUser(_ userId: UUID) throws -> [SharedSleepEntry] {
        return try sleepEntryRepository.getSleepEntriesForUser(userId)
    }
    
    /// SharedSleepEntry'nin kalite puanını günceller
    public func updateSleepQuality(entryId: UUID, rating: Int, emoji: String? = nil) async throws {
        try await sleepEntryRepository.updateSleepQuality(entryId: entryId, rating: rating, emoji: emoji)
    }
    
    /// Son N gün için uyku istatistiklerini hesaplar
    public func getSleepStatistics(userId: UUID, days: Int = 7) throws -> SleepStatistics {
        return try sleepEntryRepository.getSleepStatistics(userId: userId, days: days)
    }
    
    // MARK: - Convenience Methods
    
    /// Tam sistem sağlık kontrolü (shared models için)
    public func performSystemHealthCheck() async throws -> SharedSystemHealthReport {
        let userCount = try userRepository.getAllUsers().count
        let scheduleCount = try scheduleRepository.getAllSchedules().count
        let sleepEntryCount = try sleepEntryRepository.getAllSleepEntries().count
        let hasActiveSchedule = try scheduleRepository.getActiveSchedule() != nil
        
        logger.debug("📊 Shared sistem durumu: \(userCount) kullanıcı, \(scheduleCount) program, \(sleepEntryCount) uyku kaydı")
        
        return SharedSystemHealthReport(
            userCount: userCount,
            scheduleCount: scheduleCount,
            sleepEntryCount: sleepEntryCount,
            hasActiveSchedule: hasActiveSchedule
        )
    }
    
    /// Shared ModelContainer oluşturur (deprecated - SharedModelContainer.createSharedModelContainer() kullan)
    @available(*, deprecated, message: "Use SharedModelContainer.createSharedModelContainer() instead")
    public static func createSharedModelContainer() throws -> ModelContainer {
        return try SharedModelContainer.createSharedModelContainer()
    }
    
    // MARK: - Direct Sub-Repository Access
    
    /// SharedUserRepository'ye direkt erişim
    public var user: SharedUserRepository {
        return userRepository
    }
    
    /// SharedScheduleRepository'ye direkt erişim
    public var schedule: SharedScheduleRepository {
        return scheduleRepository
    }
    
    /// SharedSleepEntryRepository'ye direkt erişim
    public var sleepEntry: SharedSleepEntryRepository {
        return sleepEntryRepository
    }
}

// MARK: - Shared System Health Report

/// Shared sistem sağlık raporu
public struct SharedSystemHealthReport {
    public let userCount: Int
    public let scheduleCount: Int
    public let sleepEntryCount: Int
    public let hasActiveSchedule: Bool
    
    public var isHealthy: Bool {
        return userCount > 0 && scheduleCount > 0
    }
} 