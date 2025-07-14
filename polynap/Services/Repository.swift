import Foundation
import SwiftData
import Combine
import OSLog

/// Ana Repository hub'ı - Tüm repository modüllerini koordine eder
/// Bu sınıf artık sadece modüller arası koordinasyon ve legacy API uyumluluğu sağlar
@MainActor
class Repository: ObservableObject {
    static let shared = Repository()
    
    
    // MARK: - Sub-Repository References
    
    private let baseRepository = BaseRepository()
    private let userRepository = UserRepository.shared
    private let scheduleRepository = ScheduleRepository.shared
    private let scheduleStateManager = ScheduleStateManager.shared
    private let scheduleUndoService = ScheduleUndoService.shared
    private let sleepEntryRepository = SleepEntryRepository.shared
    private let adaptationManager = AdaptationManager.shared

    private let migrationService = MigrationService.shared
    
    // MARK: - ModelContext Management (Delegated to BaseRepository)
    
    /// ModelContext'i tüm modüllerde ayarlar
    func setModelContext(_ context: ModelContext) {
        baseRepository.setModelContext(context)
        userRepository.setModelContext(context)
        scheduleRepository.setModelContext(context)
        scheduleStateManager.setModelContext(context)
        scheduleUndoService.setModelContext(context)
        sleepEntryRepository.setModelContext(context)
        adaptationManager.setModelContext(context)

        migrationService.setModelContext(context)
    }
    
    /// Merkezi ModelContext'e erişim
    func getModelContext() -> ModelContext? {
        return baseRepository.getModelContext()
    }
    
    // MARK: - Legacy API Compatibility
    
    /// Bildirim hatırlatma süresini getirir
    func getReminderLeadTime() -> Int {
        return baseRepository.getReminderLeadTime()
    }
    
    /// Güncel kullanıcı tercihlerini OnboardingAnswer türünde döner
    func getOnboardingAnswers() async throws -> [OnboardingAnswerData] {
        return try await baseRepository.getOnboardingAnswers()
    }
    
    // MARK: - Schedule Methods (Delegated to ScheduleRepository)
    
    /// Aktif olan uyku programını getirir
    func getActiveSchedule() async throws -> UserScheduleModel? {
        return try await scheduleRepository.getActiveSchedule()
    }
    
    /// Tüm uyku programlarını yerel veritabanından getirir
    func getAllSchedules() throws -> [ScheduleEntity] {
        return try scheduleRepository.getAllSchedules()
    }
    
    /// Belirtilen kullanıcı için aktif UserSchedule @Model nesnesini getirir
    func getActiveUserSchedule(userId: UUID, context: ModelContext) throws -> UserSchedule? {
        return try scheduleRepository.getActiveUserSchedule(userId: userId)
    }
    
    /// UserScheduleModel'i yerel olarak kaydeder
    func saveSchedule(_ scheduleModel: UserScheduleModel) async throws -> ScheduleEntity {
        return try await scheduleRepository.saveSchedule(scheduleModel)
    }
    
    // MARK: - Schedule State Management (Delegated to ScheduleStateManager)
    
    /// Tüm programları deaktive eder
    func deactivateAllSchedules() async throws {
        try await scheduleStateManager.deactivateAllSchedules()
    }
    
    /// Belirli bir programı aktif veya pasif yapar
    func setScheduleActive(id: String, isActive: Bool) async throws {
        try await scheduleStateManager.setScheduleActive(id: id, isActive: isActive)
    }
    
    /// Bir UserSchedule'ın adaptasyon fazını günceller
    func updateUserScheduleAdaptationPhase(scheduleId: UUID, newPhase: Int, context: ModelContext) throws {
        try scheduleStateManager.updateUserScheduleAdaptationPhase(scheduleId: scheduleId, newPhase: newPhase)
    }
    
    // MARK: - Sleep Entry Methods (Delegated to SleepEntryRepository)
    
    /// Uyku girdisi ekler
    func addSleepEntry(blockId: String, emoji: String, rating: Int, date: Date) async throws -> SleepEntryEntity {
        return try await sleepEntryRepository.addSleepEntry(blockId: blockId, emoji: emoji, rating: rating, date: date)
    }
    
    /// Son sleep entries'leri getirir (Watch sync için)
    func getRecentSleepEntries(limit: Int = 10) async throws -> [SleepEntryEntity] {
        return try sleepEntryRepository.getRecentSleepEntries(dayCount: 30).prefix(limit).map { $0 }
    }
    
    // MARK: - User Management (Delegated to UserRepository)
    
    /// Kullanıcıyı SwiftData'da oluşturur veya mevcut kullanıcıyı getirir
    func createOrGetUser() async throws -> User {
        return try await userRepository.createOrGetUser()
    }
    
    // MARK: - Migration Methods (Delegated to MigrationService)
    
    /// Mevcut ScheduleEntity'ler için eksik UserSchedule'ları oluşturur
    func migrateScheduleEntitiesToUserSchedules() async throws {
        try await migrationService.migrateScheduleEntitiesToUserSchedules()
    }
    
    /// Silinmiş olarak işaretlenmiş blokları fiziksel olarak siler
    func cleanupDeletedBlocks() throws {
        try migrationService.cleanupDeletedBlocks()
    }
    
    // MARK: - Schedule Undo Methods (Delegated to ScheduleUndoService)
    
    /// Adaptasyon ilerlemesini önceki schedule'dan geri getir
    func undoScheduleChange() async throws {
        try await scheduleUndoService.undoScheduleChange()
    }
    
    /// Undo verisi mevcut mu kontrol et
    func hasUndoData() -> Bool {
        return scheduleUndoService.hasUndoData()
    }
    

    
    // MARK: - Direct Sub-Repository Access
    
    /// UserRepository'ye direkt erişim
    var user: UserRepository {
        return userRepository
    }
    
    /// ScheduleRepository'ye direkt erişim
    var schedule: ScheduleRepository {
        return scheduleRepository
    }
    
    /// ScheduleStateManager'a direkt erişim
    var scheduleState: ScheduleStateManager {
        return scheduleStateManager
    }
    
    /// ScheduleUndoService'e direkt erişim
    var scheduleUndo: ScheduleUndoService {
        return scheduleUndoService
    }
    
    /// SleepEntryRepository'ye direkt erişim
    var sleepEntry: SleepEntryRepository {
        return sleepEntryRepository
    }
    
    /// AdaptationManager'a direkt erişim
    var adaptation: AdaptationManager {
        return adaptationManager
    }
    

    
    /// MigrationService'e direkt erişim
    var migration: MigrationService {
        return migrationService
    }
    
    // MARK: - Convenience Methods
    
    /// Tam sistem sağlık kontrolü
    func performSystemHealthCheck() async throws -> SystemHealthReport {
        
        let consistencyReport = try migrationService.validateDataConsistency()
        let hasActiveSchedule = try await scheduleRepository.getActiveSchedule() != nil
        let hasUndoAvailable = scheduleUndoService.hasUndoData()
        
        let healthReport = SystemHealthReport(
            dataConsistency: consistencyReport,
            hasActiveSchedule: hasActiveSchedule,
            hasUndoDataAvailable: hasUndoAvailable
        )
        return healthReport
    }
    
    /// Tam sistem temizliği
    func performSystemCleanup() async throws {
        
        try await migrationService.runFullMigrationAndCleanup()
        migrationService.cleanupUserDefaults()
        
    }
}

// MARK: - System Health Report

/// Sistem sağlık raporu
struct SystemHealthReport {
    let dataConsistency: DataConsistencyReport
    let hasActiveSchedule: Bool
    let hasUndoDataAvailable: Bool
    
    /// Genel sistem durumu
    var overallStatus: String {
        if dataConsistency.hasIssues {
            return "⚠️ Veri tutarsızlığı mevcut"
        } else if !hasActiveSchedule {
            return "ℹ️ Aktif program yok"
        } else {
            return "✅ Sistem sağlıklı"
        }
    }
    
    /// Detaylı rapor
    var detailedReport: String {
        """
        🏥 Sistem Sağlık Raporu:
        
        \(dataConsistency.summary)
        
        🎯 Durum:
        - Aktif Program: \(hasActiveSchedule ? "✅" : "❌")
        - Undo Mevcut: \(hasUndoDataAvailable ? "✅" : "❌")
        
        📊 Genel Durum: \(overallStatus)
        """
    }
} 
