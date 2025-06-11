import Foundation
import SwiftData
import OSLog

/// Schedule CRUD işlemleri için Repository
@MainActor
final class ScheduleRepository: BaseRepository {
    
    static let shared = ScheduleRepository()
    
    private var userRepository: UserRepository {
        UserRepository.shared
    }
    
    private override init() {
        super.init()
        logger.debug("📅 ScheduleRepository başlatıldı")
    }
    
    // MARK: - Schedule CRUD Methods
    
    /// Tüm uyku programlarını yerel veritabanından getirir
    func getAllSchedules() throws -> [ScheduleEntity] {
        let descriptor = FetchDescriptor<ScheduleEntity>(
            predicate: #Predicate<ScheduleEntity> { $0.isDeleted == false }
        )
        
        do {
            let schedules = try fetch(descriptor)
            logger.debug("🗂️ Yerel veritabanından \(schedules.count) program getirildi")
            return schedules
        } catch {
            logger.error("❌ Programlar getirilirken hata: \(error.localizedDescription)")
            throw RepositoryError.fetchFailed
        }
    }
    
    /// Aktif olan uyku programını getirir
    func getActiveSchedule() async throws -> UserScheduleModel? {
        logger.debug("🗂️ ScheduleRepository.getActiveSchedule() çağrıldı")
        
        let predicate = #Predicate<UserSchedule> { $0.isActive == true }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            guard let activeUserSchedule = try fetch(descriptor).first else {
                logger.debug("ℹ️ ScheduleRepository: Aktif UserSchedule bulunamadı.")
                return nil
            }
            
            let userScheduleModel = RepositoryUtils.convertUserScheduleToModel(activeUserSchedule)
            logger.debug("✅ ScheduleRepository: Aktif UserSchedule bulundu ve modele dönüştürüldü: \(userScheduleModel.name)")
            return userScheduleModel
        } catch {
            logger.error("❌ Aktif schedule getirilirken hata: \(error.localizedDescription)")
            throw RepositoryError.fetchFailed
        }
    }
    
    /// Belirtilen kullanıcı için aktif UserSchedule @Model nesnesini getirir
    func getActiveUserSchedule(userId: UUID) throws -> UserSchedule? {
        logger.debug("🗂️ Kullanıcı (ID: \(userId.uuidString)) için aktif UserSchedule getiriliyor...")
        
        let descriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { schedule in
                schedule.user?.id == userId && schedule.isActive == true
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let schedules = try fetch(descriptor)
            if let activeSchedule = schedules.first {
                logger.debug("✅ Aktif UserSchedule bulundu: \(activeSchedule.name)")
                return activeSchedule
            } else {
                logger.debug("ℹ️ Kullanıcı (ID: \(userId.uuidString)) için aktif UserSchedule bulunamadı.")
                return nil
            }
        } catch {
            logger.error("❌ Aktif UserSchedule getirilirken hata: \(error.localizedDescription)")
            throw RepositoryError.fetchFailed
        }
    }
    
    /// UserScheduleModel'i yerel olarak kaydeder
    func saveSchedule(_ scheduleModel: UserScheduleModel) async throws -> ScheduleEntity {
        // Kullanıcıyı oluştur veya getir
        let user = try await userRepository.createOrGetUser()
        let userId = user.id
        
        logger.debug("🗂️ Program kaydediliyor: \(scheduleModel.name), ID: \(scheduleModel.id), UserId: \(userId)")
        
        // Açıklamaları JSON'a dönüştür
        let descriptionJson = try RepositoryUtils.encodeScheduleDescription(scheduleModel.description)
        
        // Güvenli UUID dönüştürme
        let uuid = RepositoryUtils.safeUUID(from: scheduleModel.id)
        let syncId = UUID().uuidString
        
        logger.debug("🗂️ Program verileri hazırlandı, UUID: \(uuid.uuidString), syncId: \(syncId)")
        
        // ÖNEMLİ: Mevcut aktif program bilgilerini undo için kaydet (pasifleştirmeden ÖNCE)
        try await saveCurrentActiveScheduleForUndoIfNeeded()
        
        // Mevcut aktif programları pasifleştir
        try await deactivateOtherSchedules(exceptId: uuid)
        
        // Yeni programı oluştur veya mevcut programı güncelle
        let existingSchedule = findScheduleById(id: scheduleModel.id)
        
        let scheduleEntity: ScheduleEntity
        
        if let existingScheduleEntity = existingSchedule {
            // Güncelleme
            logger.debug("🗂️ Mevcut ScheduleEntity güncelleniyor: \(existingScheduleEntity.name)")
            existingScheduleEntity.name = scheduleModel.name
            existingScheduleEntity.descriptionJson = descriptionJson
            existingScheduleEntity.totalSleepHours = scheduleModel.totalSleepHours
            existingScheduleEntity.isActive = true
            existingScheduleEntity.updatedAt = Date()
            
            scheduleEntity = existingScheduleEntity
        } else {
            // Yeni oluştur
            logger.debug("🗂️ Yeni ScheduleEntity oluşturuluyor: \(scheduleModel.name)")
            scheduleEntity = ScheduleEntity(
                id: uuid,
                userId: userId,
                name: scheduleModel.name,
                descriptionJson: descriptionJson,
                totalSleepHours: scheduleModel.totalSleepHours,
                isActive: true,
                syncId: syncId
            )
            
            try insert(scheduleEntity)
        }
        
        // Eski blokları temizle ve yeni blokları ekle
        try updateSleepBlocks(for: scheduleEntity, with: scheduleModel.schedule)
        
        // UserSchedule entity'sini de oluştur/güncelle
        try await createOrUpdateUserSchedule(scheduleModel, user: user, scheduleEntity: scheduleEntity)

        do {
            try save()
            logger.debug("✅ Program ve ilişkili UserSchedule başarıyla kaydedildi/güncellendi")
        } catch {
            logger.error("❌ Program ve ilişkili UserSchedule kaydedilirken hata: \(error.localizedDescription)")
            throw RepositoryError.saveFailed
        }
        
        return scheduleEntity
    }
    
    /// Program ID'sine göre veri getirir
    func fetchScheduleById(id: String) throws -> ScheduleEntity? {
        guard let uuid = UUID(uuidString: id) else {
            logger.error("❌ Geçersiz UUID: \(id)")
            throw RepositoryError.invalidData
        }
        
        let descriptor = FetchDescriptor<ScheduleEntity>(
            predicate: #Predicate<ScheduleEntity> { $0.id == uuid && $0.isDeleted == false }
        )
        
        do {
            let schedules = try fetch(descriptor)
            if let schedule = schedules.first {
                logger.debug("🗂️ Program bulundu, ID: \(id), Ad: \(schedule.name)")
            } else {
                logger.debug("🗂️ Program bulunamadı, ID: \(id)")
            }
            return schedules.first
        } catch {
            logger.error("❌ Program ID'ye göre getirilirken hata: \(error.localizedDescription)")
            throw RepositoryError.fetchFailed
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Mevcut aktif schedule'ın bilgilerini undo için kaydeder (eğer varsa)
    private func saveCurrentActiveScheduleForUndoIfNeeded() async throws {
        // Şu anda aktif olan UserSchedule'ı bul
        let activeUserScheduleDescriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.isActive == true }
        )
        
        do {
            if let currentActiveUserSchedule = try fetch(activeUserScheduleDescriptor).first {
                // Mevcut aktif schedule'ın bilgilerini kaydet
                try await ScheduleUndoService.shared.saveScheduleChangeUndoData(scheduleId: currentActiveUserSchedule.id)
                logger.debug("📝 Undo için kaydedilen schedule: \(currentActiveUserSchedule.name), Faz: \(currentActiveUserSchedule.adaptationPhase ?? 0)")
            } else {
                logger.debug("ℹ️ Undo için kaydedilecek aktif UserSchedule bulunamadı")
            }
        } catch {
            logger.error("❌ Aktif schedule undo bilgileri kaydedilirken hata: \(error)")
            // Bu hata kritik değil, işleme devam et
        }
    }
    
    /// Try? ile çağırdığımız yerler için daha açıklayıcı bir metot
    private func findScheduleById(id: String) -> ScheduleEntity? {
        do {
            return try fetchScheduleById(id: id)
        } catch {
            logger.warning("⚠️ findScheduleById ile program aranırken hata: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Diğer aktif programları pasifleştir
    private func deactivateOtherSchedules(exceptId: UUID) async throws {
        do {
            if let activeScheduleEntity = try await getActiveScheduleEntity() {
                if activeScheduleEntity.id != exceptId {
                    logger.debug("🗂️ Mevcut aktif ScheduleEntity pasifleştiriliyor: \(activeScheduleEntity.name)")
                    activeScheduleEntity.isActive = false
                    activeScheduleEntity.updatedAt = Date()

                    // İlgili UserSchedule'ı da pasifleştir
                    let activeScheduleId = activeScheduleEntity.id
                    let oldUserScheduleDescriptor = FetchDescriptor<UserSchedule>(
                        predicate: #Predicate<UserSchedule> { $0.id == activeScheduleId && $0.isActive == true }
                    )
                    if let oldUserSchedule = try fetch(oldUserScheduleDescriptor).first {
                        oldUserSchedule.isActive = false
                        oldUserSchedule.updatedAt = Date()
                        logger.debug("🗂️ Mevcut aktif UserSchedule pasifleştirildi: \(oldUserSchedule.name)")
                    }
                }
            }
        } catch {
            logger.warning("⚠️ Aktif program kontrol edilirken/pasifleştirilirken hata: \(error.localizedDescription)")
            // İşleme devam et, kritik bir hata değil
        }
    }
    
    /// Schedule için sleep block'ları günceller
    private func updateSleepBlocks(for scheduleEntity: ScheduleEntity, with blocks: [SleepBlock]) throws {
        // Eski blokları temizle
        if !scheduleEntity.sleepBlocks.isEmpty {
            logger.debug("🗂️ \(scheduleEntity.sleepBlocks.count) eski blok temizleniyor")
            let blocksToDelete = scheduleEntity.sleepBlocks
            for block in blocksToDelete {
                try delete(block)
            }
        }
        
        // Yeni blokları ekle
        logger.debug("🗂️ \(blocks.count) yeni blok ScheduleEntity'e ekleniyor")
        var newSleepBlockEntities: [SleepBlockEntity] = []
        for block in blocks {
            let blockEntity = SleepBlockEntity(
                startTime: block.startTime,
                endTime: block.endTime,
                durationMinutes: block.duration,
                isCore: block.isCore,
                syncId: UUID().uuidString
            )
            newSleepBlockEntities.append(blockEntity)
        }
        scheduleEntity.sleepBlocks = newSleepBlockEntities
    }
    
    /// UserSchedule entity'sini oluşturur veya günceller
    private func createOrUpdateUserSchedule(_ scheduleModel: UserScheduleModel, user: User, scheduleEntity: ScheduleEntity) async throws {
        // UUID dönüşümü
        guard let scheduleUUID = UUID(uuidString: scheduleModel.id) else {
            throw RepositoryError.invalidData
        }
        
        // Önce diğer tüm aktif UserSchedule'ları pasifleştir
        let otherActiveUserSchedulesDescriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.id != scheduleUUID && $0.isActive == true }
        )
        
        do {
            let otherActiveUserSchedules = try fetch(otherActiveUserSchedulesDescriptor)
            for userSchedule in otherActiveUserSchedules {
                userSchedule.isActive = false
                userSchedule.updatedAt = Date()
                logger.debug("🗂️ Önceki aktif UserSchedule pasifleştirildi: \(userSchedule.name)")
            }
        } catch {
            logger.error("❌ Diğer aktif UserSchedule'lar pasifleştirilirken hata: \(error.localizedDescription)")
        }
        
        // Mevcut UserSchedule'ı ara
        let predicate = #Predicate<UserSchedule> { $0.id == scheduleUUID }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            if let existingUserSchedule = try fetch(descriptor).first {
                // Güncelle
                existingUserSchedule.user = user
                existingUserSchedule.name = scheduleModel.name
                existingUserSchedule.scheduleDescription = try RepositoryUtils.encodeScheduleDescription(scheduleModel.description)
                existingUserSchedule.totalSleepHours = scheduleModel.totalSleepHours
                existingUserSchedule.isActive = true
                existingUserSchedule.updatedAt = Date()
                
                // Mevcut UserSleepBlock'ları temizle
                if let existingBlocks = existingUserSchedule.sleepBlocks {
                    for block in existingBlocks {
                        try delete(block)
                    }
                }
                
                // Yeni UserSleepBlock'ları oluştur
                for block in scheduleModel.schedule {
                    let startDate = RepositoryUtils.convertTimeStringToDate(block.startTime)
                    let endDate = RepositoryUtils.convertTimeStringToDate(block.endTime)
                    
                    let userSleepBlock = UserSleepBlock(
                        schedule: existingUserSchedule,
                        startTime: startDate,
                        endTime: endDate,
                        durationMinutes: block.duration,
                        isCore: block.isCore,
                        syncId: UUID().uuidString
                    )
                    try insert(userSleepBlock)
                }
                
                logger.debug("🗂️ UserSchedule ve UserSleepBlock'ları güncellendi: \(existingUserSchedule.name)")
            } else {
                // Yeni oluştur
                let newUserSchedule = UserSchedule(
                    id: scheduleUUID,
                    user: user,
                    name: scheduleModel.name,
                    scheduleDescription: try RepositoryUtils.encodeScheduleDescription(scheduleModel.description),
                    totalSleepHours: scheduleModel.totalSleepHours,
                    adaptationPhase: 0,
                    isActive: true
                )
                
                try insert(newUserSchedule)
                logger.debug("🗂️ Yeni UserSchedule oluşturuldu: \(newUserSchedule.name)")
                
                // UserSleepBlock'ları oluştur
                for block in scheduleModel.schedule {
                    let startDate = RepositoryUtils.convertTimeStringToDate(block.startTime)
                    let endDate = RepositoryUtils.convertTimeStringToDate(block.endTime)
                    
                    let userSleepBlock = UserSleepBlock(
                        schedule: newUserSchedule,
                        startTime: startDate,
                        endTime: endDate,
                        durationMinutes: block.duration,
                        isCore: block.isCore,
                        syncId: UUID().uuidString
                    )
                    try insert(userSleepBlock)
                }
            }
            
            logger.debug("✅ UserSchedule başarıyla hazırlandı")
        } catch {
            logger.error("❌ UserSchedule hazırlanırken hata: \(error.localizedDescription)")
            throw RepositoryError.saveFailed
        }
    }
    
    /// Sadece entity olarak aktif programı getiren yardımcı metot
    private func getActiveScheduleEntity() async throws -> ScheduleEntity? {
        let descriptor = FetchDescriptor<ScheduleEntity>(
            predicate: #Predicate<ScheduleEntity> { $0.isActive == true && $0.isDeleted == false }
        )
        
        do {
            let schedules = try fetch(descriptor)
            return schedules.first
        } catch {
            logger.error("❌ Aktif program entity getirilirken hata: \(error.localizedDescription)")
            throw RepositoryError.fetchFailed
        }
    }
} 