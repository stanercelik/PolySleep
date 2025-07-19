import Foundation
import SwiftData
import OSLog

/// Shared schedule yönetimi işlemleri için Repository
/// iOS ve watchOS platformları arasında SharedUserSchedule ve SharedSleepBlock modelleri ile çalışır
@available(iOS 17.0, watchOS 10.0, macOS 14.0, *)
@MainActor
public final class SharedScheduleRepository: SharedBaseRepository {
    
    public static let shared = SharedScheduleRepository()
    
    private override init() {
        super.init()
        logger.debug("📅 SharedScheduleRepository başlatıldı")
    }
    
    // MARK: - Schedule CRUD Methods
    
    /// Tüm SharedUserSchedule'ları getirir
    public func getAllSchedules() throws -> [SharedUserSchedule] {
        let descriptor = FetchDescriptor<SharedUserSchedule>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let schedules = try fetch(descriptor)
            logger.debug("🗂️ \(schedules.count) SharedUserSchedule getirildi")
            return schedules
        } catch {
            logger.error("❌ SharedUserSchedule'lar getirilirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.fetchFailed
        }
    }
    
    /// Aktif olan SharedUserSchedule'ı getirir
    public func getActiveSchedule() throws -> SharedUserSchedule? {
        let descriptor = FetchDescriptor<SharedUserSchedule>(
            predicate: #Predicate<SharedUserSchedule> { $0.isActive == true },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        do {
            let schedules = try fetch(descriptor)
            if let activeSchedule = schedules.first {
                logger.debug("✅ Aktif SharedUserSchedule bulundu: \(activeSchedule.name)")
            } else {
                logger.debug("📭 Aktif SharedUserSchedule bulunamadı")
            }
            return schedules.first
        } catch {
            logger.error("❌ Aktif SharedUserSchedule getirilirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.fetchFailed
        }
    }
    
    /// Belirli kullanıcının SharedUserSchedule'larını getirir
    public func getSchedulesForUser(_ userId: UUID) throws -> [SharedUserSchedule] {
        let descriptor = FetchDescriptor<SharedUserSchedule>(
            predicate: #Predicate<SharedUserSchedule> { schedule in
                schedule.user?.id == userId
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let schedules = try fetch(descriptor)
            logger.debug("🗂️ Kullanıcı \(userId.uuidString) için \(schedules.count) SharedUserSchedule getirildi")
            return schedules
        } catch {
            logger.error("❌ Kullanıcı SharedUserSchedule'ları getirilirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.fetchFailed
        }
    }
    
    /// ID ile SharedUserSchedule getirir
    public func getScheduleById(_ id: UUID) throws -> SharedUserSchedule? {
        let descriptor = FetchDescriptor<SharedUserSchedule>(
            predicate: #Predicate<SharedUserSchedule> { $0.id == id }
        )
        
        do {
            let schedules = try fetch(descriptor)
            return schedules.first
        } catch {
            logger.error("❌ SharedUserSchedule ID'ye göre getirilirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.fetchFailed
        }
    }
    
    /// Yeni SharedUserSchedule oluşturur
    public func createSchedule(user: SharedUser,
                              name: String,
                              description: String? = nil,
                              totalSleepHours: Double? = nil,
                              adaptationPhase: Int? = nil,
                              isActive: Bool = false) async throws -> SharedUserSchedule {
        
        let schedule = SharedUserSchedule(
            user: user,
            name: name,
            scheduleDescription: description,
            totalSleepHours: totalSleepHours,
            adaptationPhase: adaptationPhase,
            adaptationStartDate: Date(), // Yeni schedule için adaptasyon başlangıç tarihi
            isActive: isActive
        )
        
        do {
            try insert(schedule)
            try save()
            logger.debug("✅ Yeni SharedUserSchedule oluşturuldu: \(schedule.name)")
        } catch {
            logger.error("❌ SharedUserSchedule oluşturulurken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.saveFailed
        }
        
        return schedule
    }
    
    /// SharedUserSchedule günceller
    public func updateSchedule(_ schedule: SharedUserSchedule,
                              name: String? = nil,
                              description: String? = nil,
                              totalSleepHours: Double? = nil,
                              adaptationPhase: Int? = nil,
                              isActive: Bool? = nil) async throws {
        
        if let name = name {
            schedule.name = name
        }
        if let description = description {
            schedule.scheduleDescription = description
        }
        if let totalSleepHours = totalSleepHours {
            schedule.totalSleepHours = totalSleepHours
        }
        if let adaptationPhase = adaptationPhase {
            schedule.adaptationPhase = adaptationPhase
        }
        if let isActive = isActive {
            schedule.isActive = isActive
        }
        
        schedule.updatedAt = Date()
        
        do {
            try save()
            logger.debug("✅ SharedUserSchedule güncellendi: \(schedule.name)")
        } catch {
            logger.error("❌ SharedUserSchedule güncellenirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.updateFailed
        }
    }
    
    /// SharedUserSchedule siler
    public func deleteSchedule(_ schedule: SharedUserSchedule) async throws {
        do {
            try delete(schedule)
            try save()
            logger.debug("🗑️ SharedUserSchedule silindi: \(schedule.name)")
        } catch {
            logger.error("❌ SharedUserSchedule silinirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.deleteFailed
        }
    }
    
    /// Tüm schedule'ları deaktive eder
    public func deactivateAllSchedules() async throws {
        let schedules = try getAllSchedules()
        
        for schedule in schedules where schedule.isActive {
            try await updateSchedule(schedule, isActive: false)
        }
        
        logger.debug("🔄 Tüm SharedUserSchedule'lar deaktive edildi")
    }

    /// Belirli schedule'ı aktive eder, diğerlerini deaktive eder
    public func setActiveSchedule(id: UUID) async throws {
        try await deactivateAllSchedules()
        if let scheduleToActivate = try getScheduleById(id) {
            try await updateSchedule(scheduleToActivate, isActive: true)
            logger.debug("✅ Schedule aktive edildi: \(scheduleToActivate.name)")
        } else {
            logger.error("❌ Aktive edilecek schedule bulunamadı: \(id.uuidString)")
            throw SharedRepositoryError.entityNotFound
        }
    }
    
    /// Belirli schedule'ı deaktive eder
    public func deactivateSchedule(id: UUID) async throws {
        if let schedule = try getScheduleById(id) {
            try await updateSchedule(schedule, isActive: false)
        }
    }

    /// WSSchedulePayload'dan bir schedule oluşturur veya günceller
    public func createOrUpdateSchedule(from payload: WSSchedulePayload) async throws -> SharedUserSchedule {
        let schedule: SharedUserSchedule
        
        // Mevcut schedule'ı ID ile bul
        if let existingSchedule = try getScheduleById(payload.id) {
            schedule = existingSchedule
            logger.debug("🔄 Mevcut schedule güncelleniyor: \(payload.name)")
            
            // Özellikleri güncelle
            let wasInactive = !schedule.isActive
            schedule.name = payload.name
            schedule.scheduleDescription = payload.description
            schedule.totalSleepHours = payload.totalSleepHours
            schedule.isActive = payload.isActive
            schedule.adaptationPhase = payload.adaptationPhase
            schedule.updatedAt = Date()
            
            // Eğer schedule daha önce inaktif idi veya adaptationStartDate yoksa, yeni adaptasyon başlat
            if wasInactive || schedule.adaptationStartDate == nil {
                schedule.adaptationStartDate = Date()
                schedule.adaptationPhase = 0
            }
            
            // Mevcut sleep block'ları sil
            if let existingBlocks = schedule.sleepBlocks {
                for block in existingBlocks {
                    try delete(block)
                }
                schedule.sleepBlocks?.removeAll()
            }
            
        } else {
            // Yeni schedule oluştur
            logger.debug("✨ Yeni schedule oluşturuluyor: \(payload.name)")
            // Geçici olarak varsayılan bir kullanıcı al/oluştur.
            // TODO: Kullanıcı senkronizasyonunu daha sağlam hale getir.
            let user = try await SharedUserRepository.shared.createOrGetUser(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, displayName: "Watch User")

            schedule = SharedUserSchedule(
                id: payload.id,
                user: user,
                name: payload.name,
                scheduleDescription: payload.description,
                totalSleepHours: payload.totalSleepHours,
                adaptationPhase: payload.adaptationPhase,
                adaptationStartDate: Date(), // Yeni schedule için adaptasyon başlangıç tarihi
                isActive: payload.isActive
            )
            try insert(schedule)
        }
        
        // Yeni sleep block'ları ekle
        var newBlocks: [SharedSleepBlock] = []
        for blockPayload in payload.sleepBlocks {
            let newBlock = SharedSleepBlock(
                id: blockPayload.id,
                schedule: schedule,
                startTime: blockPayload.startTime,
                endTime: blockPayload.endTime,
                durationMinutes: blockPayload.durationMinutes,
                isCore: blockPayload.isCore,
                syncId: blockPayload.id.uuidString
            )
            newBlocks.append(newBlock)
            try insert(newBlock)
        }
        schedule.sleepBlocks = newBlocks
        
        try save()
        logger.debug("✅ Schedule başarıyla kaydedildi: \(schedule.name)")
        
        return schedule
    }
    
    // MARK: - Sleep Block Methods
    
    /// SharedSleepBlock oluşturur
    public func createSleepBlock(schedule: SharedUserSchedule,
                                startTime: String,
                                endTime: String,
                                durationMinutes: Int,
                                isCore: Bool = false,
                                syncId: String? = nil) async throws -> SharedSleepBlock {
        
        let sleepBlock = SharedSleepBlock(
            schedule: schedule,
            startTime: startTime,
            endTime: endTime,
            durationMinutes: durationMinutes,
            isCore: isCore,
            syncId: syncId
        )
        
        do {
            try insert(sleepBlock)
            try save()
            logger.debug("✅ Yeni SharedSleepBlock oluşturuldu: \(startTime)-\(endTime)")
        } catch {
            logger.error("❌ SharedSleepBlock oluşturulurken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.saveFailed
        }
        
        return sleepBlock
    }
    
    /// Belirli schedule'a ait SharedSleepBlock'ları getirir
    public func getSleepBlocks(for scheduleId: UUID) throws -> [SharedSleepBlock] {
        let descriptor = FetchDescriptor<SharedSleepBlock>(
            predicate: #Predicate<SharedSleepBlock> { block in
                block.schedule?.id == scheduleId
            },
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        
        do {
            let blocks = try fetch(descriptor)
            logger.debug("🗂️ Schedule \(scheduleId.uuidString) için \(blocks.count) SharedSleepBlock getirildi")
            return blocks
        } catch {
            logger.error("❌ SharedSleepBlock'lar getirilirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.fetchFailed
        }
    }
    
    /// SharedSleepBlock günceller
    public func updateSleepBlock(_ block: SharedSleepBlock,
                                startTime: String? = nil,
                                endTime: String? = nil,
                                durationMinutes: Int? = nil,
                                isCore: Bool? = nil) async throws {
        
        if let startTime = startTime {
            block.startTime = startTime
        }
        if let endTime = endTime {
            block.endTime = endTime
        }
        if let durationMinutes = durationMinutes {
            block.durationMinutes = durationMinutes
        }
        if let isCore = isCore {
            block.isCore = isCore
        }
        
        block.updatedAt = Date()
        
        do {
            try save()
            logger.debug("✅ SharedSleepBlock güncellendi: \(block.startTime)-\(block.endTime)")
        } catch {
            logger.error("❌ SharedSleepBlock güncellenirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.updateFailed
        }
    }
    
    /// SharedSleepBlock siler
    public func deleteSleepBlock(_ block: SharedSleepBlock) async throws {
        do {
            try delete(block)
            try save()
            logger.debug("🗑️ SharedSleepBlock silindi: \(block.startTime)-\(block.endTime)")
        } catch {
            logger.error("❌ SharedSleepBlock silinirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.deleteFailed
        }
    }
} 