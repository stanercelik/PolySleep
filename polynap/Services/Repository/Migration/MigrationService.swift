import Foundation
import SwiftData
import OSLog

/// Veri migrasyonu işlemleri için service
@MainActor
final class MigrationService: BaseRepository {
    
    static let shared = MigrationService()
    
    private var userRepository: UserRepository {
        UserRepository.shared
    }
    
    private override init() {
        super.init()
        logger.debug("🔄 MigrationService başlatıldı")
    }
    
    // MARK: - Migration Methods
    
    /// Mevcut ScheduleEntity'ler için eksik UserSchedule'ları oluşturur
    func migrateScheduleEntitiesToUserSchedules() async throws {
        logger.debug("🔄 Migration: ScheduleEntity -> UserSchedule başlatılıyor...")
        
        // Tüm ScheduleEntity'leri getir
        let scheduleDescriptor = FetchDescriptor<ScheduleEntity>(
            predicate: #Predicate<ScheduleEntity> { $0.isDeleted == false }
        )
        
        do {
            let scheduleEntities = try fetch(scheduleDescriptor)
            var migratedCount = 0
            
            for scheduleEntity in scheduleEntities {
                // Bu ScheduleEntity için UserSchedule var mı kontrol et
                let scheduleEntityId = scheduleEntity.id
                let userScheduleDescriptor = FetchDescriptor<UserSchedule>(
                    predicate: #Predicate<UserSchedule> { $0.id == scheduleEntityId }
                )
                
                let existingUserSchedules = try fetch(userScheduleDescriptor)
                
                if existingUserSchedules.isEmpty {
                    // UserSchedule yok, oluştur
                    logger.debug("🔄 Migration: UserSchedule oluşturuluyor: \(scheduleEntity.name)")
                    
                    // Kullanıcıyı al veya oluştur
                    let user = try await userRepository.createOrGetUser()
                    
                    // UserSchedule oluştur
                    let userSchedule = UserSchedule(
                        id: scheduleEntity.id, // Aynı ID'yi kullan
                        user: user,
                        name: scheduleEntity.name,
                        scheduleDescription: scheduleEntity.descriptionJson,
                        totalSleepHours: scheduleEntity.totalSleepHours,
                        adaptationPhase: 0,
                        isActive: scheduleEntity.isActive
                    )
                    
                    try insert(userSchedule)
                    
                    // UserSleepBlock'ları oluştur
                    for sleepBlock in scheduleEntity.sleepBlocks {
                        let userSleepBlock = UserSleepBlock(
                            schedule: userSchedule,
                            startTime: RepositoryUtils.convertTimeStringToDate(sleepBlock.startTime),
                            endTime: RepositoryUtils.convertTimeStringToDate(sleepBlock.endTime),
                            durationMinutes: sleepBlock.durationMinutes,
                            isCore: sleepBlock.isCore,
                            syncId: sleepBlock.syncId ?? UUID().uuidString
                        )
                        try insert(userSleepBlock)
                    }
                    
                    migratedCount += 1
                }
            }
            
            if migratedCount > 0 {
                try save()
                logger.debug("✅ Migration tamamlandı: \(migratedCount) UserSchedule oluşturuldu")
            } else {
                logger.debug("ℹ️ Migration: Tüm ScheduleEntity'ler zaten UserSchedule'a sahip")
            }
            
        } catch {
            logger.error("❌ Migration hatası: \(error.localizedDescription)")
            throw RepositoryError.saveFailed
        }
    }
    
    /// Silinmiş olarak işaretlenmiş blokları fiziksel olarak siler
    func cleanupDeletedBlocks() throws {
        let deletedBlocksDescriptor = FetchDescriptor<SleepBlockEntity>(
            predicate: #Predicate<SleepBlockEntity> { $0.isDeleted == true }
        )
        
        do {
            let deletedBlocks = try fetch(deletedBlocksDescriptor)
            if !deletedBlocks.isEmpty {
                logger.debug("🧹 \(deletedBlocks.count) silinmiş olarak işaretlenmiş blok temizleniyor")
                for block in deletedBlocks {
                    // İlişkiyi kaldır, böylece cascade silme esnasında sorun çıkmasını önle
                    block.schedule = nil
                    try delete(block)
                }
                try save()
                logger.debug("✅ Silinmiş bloklar başarıyla temizlendi")
            }
        } catch {
            logger.error("❌ Silinmiş bloklar temizlenirken hata: \(error.localizedDescription)")
            throw RepositoryError.deleteFailed
        }
    }
    
    /// Orphaned (sahipsiz) UserSleepBlock'ları temizle
    func cleanupOrphanedUserSleepBlocks() throws {
        let allUserSleepBlocksDescriptor = FetchDescriptor<UserSleepBlock>()
        
        do {
            let allBlocks = try fetch(allUserSleepBlocksDescriptor)
            var orphanedCount = 0
            
            for block in allBlocks {
                if block.schedule == nil {
                    try delete(block)
                    orphanedCount += 1
                }
            }
            
            if orphanedCount > 0 {
                try save()
                logger.debug("✅ \(orphanedCount) sahipsiz UserSleepBlock temizlendi")
            } else {
                logger.debug("ℹ️ Sahipsiz UserSleepBlock bulunamadı")
            }
            
        } catch {
            logger.error("❌ Sahipsiz UserSleepBlock'lar temizlenirken hata: \(error.localizedDescription)")
            throw RepositoryError.deleteFailed
        }
    }
    
    /// Veri tutarlılığı kontrolü yapar
    func validateDataConsistency() throws -> DataConsistencyReport {
        logger.debug("🔍 Veri tutarlılığı kontrolü başlatılıyor...")
        
        var report = DataConsistencyReport()
        
        do {
            // ScheduleEntity sayısı
            let scheduleDescriptor = FetchDescriptor<ScheduleEntity>(
                predicate: #Predicate<ScheduleEntity> { $0.isDeleted == false }
            )
            let scheduleEntities = try fetch(scheduleDescriptor)
            report.totalScheduleEntities = scheduleEntities.count
            
            // UserSchedule sayısı
            let userScheduleDescriptor = FetchDescriptor<UserSchedule>()
            let userSchedules = try fetch(userScheduleDescriptor)
            report.totalUserSchedules = userSchedules.count
            
            // Aktif ScheduleEntity sayısı
            let activeScheduleDescriptor = FetchDescriptor<ScheduleEntity>(
                predicate: #Predicate<ScheduleEntity> { $0.isActive == true && $0.isDeleted == false }
            )
            let activeSchedules = try fetch(activeScheduleDescriptor)
            report.activeScheduleEntities = activeSchedules.count
            
            // Aktif UserSchedule sayısı
            let activeUserScheduleDescriptor = FetchDescriptor<UserSchedule>(
                predicate: #Predicate<UserSchedule> { $0.isActive == true }
            )
            let activeUserSchedules = try fetch(activeUserScheduleDescriptor)
            report.activeUserSchedules = activeUserSchedules.count
            
            // Orphaned UserSleepBlock sayısı
            let allUserSleepBlocksDescriptor = FetchDescriptor<UserSleepBlock>()
            let allBlocks = try fetch(allUserSleepBlocksDescriptor)
            report.orphanedUserSleepBlocks = allBlocks.filter { $0.schedule == nil }.count
            
            // Silinmiş SleepBlockEntity sayısı
            let deletedBlocksDescriptor = FetchDescriptor<SleepBlockEntity>(
                predicate: #Predicate<SleepBlockEntity> { $0.isDeleted == true }
            )
            let deletedBlocks = try fetch(deletedBlocksDescriptor)
            report.deletedSleepBlockEntities = deletedBlocks.count
            
            // ScheduleEntity'si olmayan UserSchedule'ları bul
            for userSchedule in userSchedules {
                let userScheduleId = userSchedule.id
                let matchingScheduleDescriptor = FetchDescriptor<ScheduleEntity>(
                    predicate: #Predicate<ScheduleEntity> { $0.id == userScheduleId && $0.isDeleted == false }
                )
                let matchingSchedules = try fetch(matchingScheduleDescriptor)
                if matchingSchedules.isEmpty {
                    report.unmatchedUserSchedules += 1
                }
            }
            
            // UserSchedule'ı olmayan ScheduleEntity'leri bul
            for scheduleEntity in scheduleEntities {
                let scheduleEntityId = scheduleEntity.id
                let matchingUserScheduleDescriptor = FetchDescriptor<UserSchedule>(
                    predicate: #Predicate<UserSchedule> { $0.id == scheduleEntityId }
                )
                let matchingUserSchedules = try fetch(matchingUserScheduleDescriptor)
                if matchingUserSchedules.isEmpty {
                    report.unmatchedScheduleEntities += 1
                }
            }
            
            logger.debug("✅ Veri tutarlılığı kontrolü tamamlandı")
            return report
            
        } catch {
            logger.error("❌ Veri tutarlılığı kontrolünde hata: \(error.localizedDescription)")
            throw RepositoryError.fetchFailed
        }
    }
    
    /// Tüm migration ve cleanup işlemlerini sırayla çalıştır
    func runFullMigrationAndCleanup() async throws {
        logger.debug("🔄 Tam migration ve cleanup başlatılıyor...")
        
        // 1. Schedule migration
        try await migrateScheduleEntitiesToUserSchedules()
        
        // 2. Orphaned blocks cleanup
        try cleanupOrphanedUserSleepBlocks()
        
        // 3. Deleted blocks cleanup
        try cleanupDeletedBlocks()
        
        // 4. Consistency validation
        let report = try validateDataConsistency()
        logger.debug("📊 Migration sonrası rapor: \(report.summary)")
        
        logger.debug("✅ Tam migration ve cleanup tamamlandı")
    }
    
    /// UserDefaults temizliği
    func cleanupUserDefaults() {
        let keysToClean = [
            "scheduleChangeUndoData",
            "lastMigrationVersion",
            "temporaryData"
        ]
        
        for key in keysToClean {
            if UserDefaults.standard.object(forKey: key) != nil {
                UserDefaults.standard.removeObject(forKey: key)
                logger.debug("🧹 UserDefaults temizlendi: \(key)")
            }
        }
        
        logger.debug("✅ UserDefaults temizliği tamamlandı")
    }
}

/// Veri tutarlılığı raporu
struct DataConsistencyReport {
    var totalScheduleEntities: Int = 0
    var totalUserSchedules: Int = 0
    var activeScheduleEntities: Int = 0
    var activeUserSchedules: Int = 0
    var unmatchedScheduleEntities: Int = 0
    var unmatchedUserSchedules: Int = 0
    var orphanedUserSleepBlocks: Int = 0
    var deletedSleepBlockEntities: Int = 0
    
    /// Rapor özeti
    var summary: String {
        """
        📊 Veri Tutarlılığı Raporu:
        - ScheduleEntity: \(totalScheduleEntities) (Aktif: \(activeScheduleEntities))
        - UserSchedule: \(totalUserSchedules) (Aktif: \(activeUserSchedules))
        - Eşleşmeyen ScheduleEntity: \(unmatchedScheduleEntities)
        - Eşleşmeyen UserSchedule: \(unmatchedUserSchedules)
        - Sahipsiz UserSleepBlock: \(orphanedUserSleepBlocks)
        - Silinmiş SleepBlockEntity: \(deletedSleepBlockEntities)
        """
    }
    
    /// Sorun var mı?
    var hasIssues: Bool {
        return unmatchedScheduleEntities > 0 ||
               unmatchedUserSchedules > 0 ||
               orphanedUserSleepBlocks > 0 ||
               deletedSleepBlockEntities > 0 ||
               activeScheduleEntities > 1 ||
               activeUserSchedules > 1
    }
} 