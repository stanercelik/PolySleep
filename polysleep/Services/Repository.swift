import Foundation
import SwiftData
import Combine
import OSLog

/// Repository pattern uygulayan sınıf
/// Tüm veritabanı işlemleri bu sınıf üzerinden yapılmalıdır.
@MainActor
class Repository: ObservableObject {
    static let shared = Repository()
    
    private let logger = Logger(subsystem: "com.polysleep.app", category: "Repository")
    
    private var _modelContext: ModelContext?
    private var localModelContainer: ModelContainer?
    
    private var authManager: AuthManager {
        AuthManager.shared
    }
    
    private init() {
        logger.debug("🗂️ Repository başlatıldı")
        // Artık burada setupLocalModelContext çağrılmıyor.
    }
    
    /// ModelContext'i ayarlar
    func setModelContext(_ context: ModelContext) {
        self._modelContext = context
        logger.debug("🗂️ ModelContext ayarlandı, Repository hazır.")
    }
    
    /// ModelContext'e erişim için ana metod
    private func ensureModelContext() throws -> ModelContext {
        guard let context = _modelContext else {
            logger.error("❌ Repository: ModelContext ayarlanmadı! Uygulama başlangıcında setModelContext çağrıldığından emin olun.")
            // Acil durum için yerel context oluşturma (test veya izole durumlar için)
            // Ana uygulama akışında bu yola düşmemesi gerekir.
            setupEmergencyLocalModelContext()
            if let emergencyContext = _modelContext {
                logger.warning("⚠️ Repository: ACİL DURUM yerel ModelContext kullanılıyor. Bu beklenmedik bir durum.")
                return emergencyContext
            }
            throw RepositoryError.modelContextNotSet
        }
        return context
    }
    
    /// Sadece kesinlikle başka bir context yoksa çağrılacak acil durum metodu
    private func setupEmergencyLocalModelContext() {
        if _modelContext != nil { return } // Zaten varsa bir şey yapma
        logger.warning("🚨 Repository: Acil durum yerel ModelContext oluşturuluyor. Bu genellikle bir yapılandırma sorunudur.")
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: false) // Veya test için true
            let emergencyContainer = try ModelContainer(
                for: // TÜM MODELLER
                SleepScheduleStore.self, UserPreferences.self, UserFactor.self, HistoryModel.self, SleepEntry.self,
                OnboardingAnswerData.self, User.self, UserSchedule.self, UserSleepBlock.self,
                ScheduleEntity.self, SleepBlockEntity.self, SleepEntryEntity.self, PendingChange.self,
                configurations: config
            )
            _modelContext = emergencyContainer.mainContext
        } catch {
            logger.error("❌ Repository: ACİL DURUM yerel ModelContext oluşturulamadı: \(error.localizedDescription)")
        }
    }

    // MARK: - Repository metodları
    
    /// Bildirim hatırlatma süresini getirir
    func getReminderLeadTime() -> Int {
        do {
            let context = try ensureModelContext()
            
            let descriptor = FetchDescriptor<UserPreferences>()
            guard let userPrefs = try context.fetch(descriptor).first else {
                logger.debug("🗂️ UserPreferences bulunamadı, varsayılan değer kullanılıyor (15)")
                return 15
            }
            
            return userPrefs.reminderLeadTimeInMinutes
        } catch {
            logger.error("❌ getReminderLeadTime hatası: \(error.localizedDescription)")
            return 15 // Varsayılan değer
        }
    }

    // ... Diğer metodlar - bunları "modelContext?" yerine "try ensureModelContext()" kullanacak şekilde güncellemelisiniz.
    
    // Örnek olarak bir metod:
    
    /// Aktif olan uyku programını getirir
    func getActiveSchedule() async throws -> UserScheduleModel? {
        let context = try ensureModelContext()
        
        let entity = try await getActiveScheduleEntity()
        guard let scheduleEntity = entity else {
            logger.debug("🗂️ Aktif program bulunamadı")
            return nil
        }
        
        logger.debug("🗂️ Aktif program bulundu: \(scheduleEntity.name), \(scheduleEntity.sleepBlocks.count) blok içeriyor")
        return convertEntityToUserScheduleModel(scheduleEntity)
    }
    
    /// Güncel kullanıcı tercihlerini OnboardingAnswer türünde döner
    func getOnboardingAnswers() async throws -> [OnboardingAnswerData] {
        return try await MainActor.run {
            let context = try ensureModelContext()
            
            let descriptor = FetchDescriptor<OnboardingAnswerData>(sortBy: [SortDescriptor(\OnboardingAnswerData.date, order: .reverse)])
            
            do {
                let answers = try context.fetch(descriptor)
                logger.debug("🗂️ \(answers.count) onboarding cevabı getirildi")
                return answers
            } catch {
                logger.error("❌ Onboarding cevapları getirilirken hata: \(error.localizedDescription)")
                throw RepositoryError.fetchFailed
            }
        }
    }
    
    // MARK: - Schedule Methods
    
    /// Tüm uyku programlarını yerel veritabanından getirir
    func getAllSchedules() throws -> [ScheduleEntity] {
        guard let context = _modelContext else {
            logger.error("❌ ModelContext ayarlanmamış, getAllSchedules başarısız")
            throw RepositoryError.modelContextNotSet
        }
        
        let descriptor = FetchDescriptor<ScheduleEntity>(
            predicate: #Predicate<ScheduleEntity> { $0.isDeleted == false }
        )
        
        do {
            let schedules = try context.fetch(descriptor)
            logger.debug("🗂️ Yerel veritabanından \(schedules.count) program getirildi")
            return schedules
        } catch {
            logger.error("❌ Programlar getirilirken hata: \(error.localizedDescription)")
            throw RepositoryError.fetchFailed
        }
    }
    
    /// Belirtilen kullanıcı için aktif UserSchedule @Model nesnesini getirir.
    func getActiveUserSchedule(userId: UUID, context: ModelContext) throws -> UserSchedule? {
        logger.debug("🗂️ Kullanıcı (ID: \(userId.uuidString)) için aktif UserSchedule getiriliyor...")
        let descriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { schedule in
                schedule.user?.id == userId && schedule.isActive == true
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)] // En son oluşturulan aktif programı al
        )
        
        do {
            let schedules = try context.fetch(descriptor)
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

    /// Bir UserSchedule'ın adaptasyon fazını ve güncellenme tarihini günceller.
    func updateUserScheduleAdaptationPhase(scheduleId: UUID, newPhase: Int, context: ModelContext) throws {
        logger.debug("🗂️ UserSchedule (ID: \(scheduleId.uuidString)) adaptasyon fazı güncelleniyor: \(newPhase)")
        let descriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.id == scheduleId }
        )
        
        do {
            guard let scheduleToUpdate = try context.fetch(descriptor).first else {
                logger.error("❌ Adaptasyon fazı güncellenecek UserSchedule (ID: \(scheduleId.uuidString)) bulunamadı.")
                throw RepositoryError.entityNotFound
            }
            
            scheduleToUpdate.adaptationPhase = newPhase
            scheduleToUpdate.updatedAt = Date()
            
            try context.save()
            logger.debug("✅ UserSchedule (ID: \(scheduleId.uuidString)) adaptasyon fazı başarıyla güncellendi.")
        } catch {
            logger.error("❌ UserSchedule adaptasyon fazı güncellenirken hata: \(error.localizedDescription)")
            throw RepositoryError.updateFailed
        }
    }
    
    /// ScheduleEntity'i UserScheduleModel'e dönüştüren yardımcı metot
    private func convertEntityToUserScheduleModel(_ entity: ScheduleEntity) -> UserScheduleModel {
        // Açıklama JSON verisini çöz
        var description = LocalizedDescription(en: "", tr: "")
        if let jsonData = entity.descriptionJson.data(using: .utf8) {
            if let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                if let en = dict["en"] as? String, let tr = dict["tr"] as? String {
                    description = LocalizedDescription(en: en, tr: tr)
                }
            }
        }
        
        // Uyku bloklarını dönüştür
        let sleepBlocks = entity.sleepBlocks.map { blockEntity -> SleepBlock in
            return SleepBlock(
                startTime: blockEntity.startTime,
                duration: blockEntity.durationMinutes,
                type: blockEntity.isCore ? "core" : "nap",
                isCore: blockEntity.isCore
            )
        }
        
        // UserScheduleModel oluştur
        return UserScheduleModel(
            id: entity.id.uuidString,
            name: entity.name,
            description: description,
            totalSleepHours: entity.totalSleepHours,
            schedule: sleepBlocks,
            isPremium: false // ScheduleEntity'de bu özellik olmadığı için varsayılan değer kullanıyoruz
        )
    }
    
    /// UserScheduleModel'i yerel olarak kaydeder
    func saveSchedule(_ scheduleModel: UserScheduleModel) async throws -> ScheduleEntity {
        guard let context = _modelContext else {
            logger.error("❌ ModelContext ayarlanmamış, saveSchedule başarısız")
            throw RepositoryError.modelContextNotSet
        }
        
        // Kullanıcı kimliğini yerel kullanıcı modeline göre al ve UUID'ye dönüştür
        let userIdString = authManager.currentUser?.id ?? "unknown"
        let userId = UUID(uuidString: userIdString) ?? UUID() // Geçerli değilse yeni UUID oluştur
        
        logger.debug("🗂️ Program kaydediliyor: \(scheduleModel.name), ID: \(scheduleModel.id)")
        
        // Açıklamaları JSON'a dönüştür
        let descriptionData = try JSONSerialization.data(withJSONObject: [
            "en": scheduleModel.description.en,
            "tr": scheduleModel.description.tr
        ])
        let descriptionJson = String(data: descriptionData, encoding: .utf8) ?? "{}"
        
        // Güvenli UUID dönüştürme
        let uuid = UUID(uuidString: scheduleModel.id) ?? UUID()
        let syncId = UUID().uuidString
        
        logger.debug("🗂️ Program verileri hazırlandı, UUID: \(uuid.uuidString), syncId: \(syncId)")
        
        // Mevcut aktif programı pasifleştir
        do {
            if let activeScheduleEntity = try await getActiveScheduleEntity() {
                logger.debug("🗂️ Mevcut aktif program pasifleştiriliyor: \(activeScheduleEntity.name)")
                activeScheduleEntity.isActive = false
                activeScheduleEntity.updatedAt = Date()
            }
        } catch {
            logger.warning("⚠️ Aktif program kontrol edilirken hata: \(error.localizedDescription)")
            // İşleme devam et, kritik bir hata değil
        }
        
        // Yeni programı oluştur veya mevcut programı güncelle
        let existingSchedule = findScheduleById(id: uuid.uuidString)
        
        let schedule: ScheduleEntity
        
        if let existingSchedule = existingSchedule {
            // Güncelleme
            logger.debug("🗂️ Mevcut program güncelleniyor: \(existingSchedule.name)")
            existingSchedule.name = scheduleModel.name
            existingSchedule.descriptionJson = descriptionJson
            existingSchedule.totalSleepHours = scheduleModel.totalSleepHours
            existingSchedule.isActive = true
            existingSchedule.updatedAt = Date()
            
            schedule = existingSchedule
        } else {
            // Yeni oluştur
            logger.debug("🗂️ Yeni program oluşturuluyor: \(scheduleModel.name)")
            schedule = ScheduleEntity(
                id: uuid,
                userId: userId, // UUID tipinde userId kullanılıyor
                name: scheduleModel.name,
                descriptionJson: descriptionJson,
                totalSleepHours: scheduleModel.totalSleepHours,
                isActive: true,
                syncId: syncId
            )
            
            context.insert(schedule)
        }
        
        // Eski blokları temizleyelim
        if let existingSchedule = existingSchedule {
            logger.debug("🗂️ \(existingSchedule.sleepBlocks.count) eski blok temizleniyor")
            let blocksToDelete = existingSchedule.sleepBlocks // Referansı al
            for block in blocksToDelete {
                context.delete(block) // Blokları context'ten fiziksel olarak sil
            }
        }
        
        // Yeni blokları ekleyelim
        logger.debug("🗂️ \(scheduleModel.schedule.count) yeni blok ekleniyor")
        for block in scheduleModel.schedule {
            let blockEntity = SleepBlockEntity(
                startTime: block.startTime,
                endTime: block.endTime,
                durationMinutes: block.duration,
                isCore: block.isCore,
                syncId: UUID().uuidString
            )
            
            blockEntity.schedule = schedule
            context.insert(blockEntity)
        }
        
        do {
            try context.save()
            logger.debug("✅ Program başarıyla kaydedildi")
        } catch {
            logger.error("❌ Program kaydedilirken hata: \(error.localizedDescription)")
            throw RepositoryError.saveFailed
        }
        
        return schedule
    }
    
    /// Program ID'sine göre veri getirir
    private func fetchScheduleById(id: String) throws -> ScheduleEntity? {
        guard let context = _modelContext else {
            logger.error("❌ ModelContext ayarlanmamış, fetchScheduleById başarısız")
            throw RepositoryError.modelContextNotSet
        }
        
        guard let uuid = UUID(uuidString: id) else {
            logger.error("❌ Geçersiz UUID: \(id)")
            throw RepositoryError.invalidData
        }
        
        let descriptor = FetchDescriptor<ScheduleEntity>(
            predicate: #Predicate<ScheduleEntity> { $0.id == uuid && $0.isDeleted == false }
        )
        
        do {
            let schedules = try context.fetch(descriptor)
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
    
    // Try? ile çağırdığımız yerler için daha açıklayıcı bir metot
    private func findScheduleById(id: String) -> ScheduleEntity? {
        do {
            return try fetchScheduleById(id: id)
        } catch {
            logger.warning("⚠️ findScheduleById ile program aranırken hata: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Sleep Entry Methods
    
    /// Uyku girdisi ekler
    func addSleepEntry(blockId: String, emoji: String, rating: Int, date: Date) async throws -> SleepEntryEntity {
        guard let context = _modelContext else {
            logger.error("❌ ModelContext ayarlanmamış, addSleepEntry başarısız")
            throw RepositoryError.modelContextNotSet
        }
        
        // Kullanıcı kimliğini yerel kullanıcı modeline göre al ve UUID'ye dönüştür
        let userIdString = authManager.currentUser?.id ?? "unknown" 
        let userId = UUID(uuidString: userIdString) ?? UUID() // Geçerli değilse yeni UUID oluştur
        
        let syncId = UUID().uuidString
        logger.debug("🗂️ Yeni uyku girdisi ekleniyor, blockId: \(blockId), syncId: \(syncId)")
        
        let entry = SleepEntryEntity(
            userId: userId, // UUID tipinde userId kullanılıyor
            date: date,
            blockId: blockId,
            emoji: emoji,
            rating: rating,
            syncId: syncId
        )
        
        context.insert(entry)
        
        do {
            try context.save()
            logger.debug("✅ Uyku girdisi başarıyla kaydedildi, ID: \(entry.id.uuidString)")
        } catch {
            logger.error("❌ Uyku girdisi kaydedilirken hata: \(error.localizedDescription)")
            throw RepositoryError.saveFailed
        }
        
        return entry
    }
    
    // MARK: - Cleanup Methods
    
    /// Silinmiş olarak işaretlenmiş blokları fiziksel olarak siler
    func cleanupDeletedBlocks() throws {
        guard let context = _modelContext else {
            logger.error("❌ ModelContext ayarlanmamış, cleanupDeletedBlocks başarısız")
            throw RepositoryError.modelContextNotSet
        }
        
        let deletedBlocksDescriptor = FetchDescriptor<SleepBlockEntity>(
            predicate: #Predicate<SleepBlockEntity> { $0.isDeleted == true }
        )
        
        do {
            let deletedBlocks = try context.fetch(deletedBlocksDescriptor)
            if !deletedBlocks.isEmpty {
                logger.debug("🧹 \(deletedBlocks.count) silinmiş olarak işaretlenmiş blok temizleniyor")
                for block in deletedBlocks {
                    // İlişkiyi kaldır, böylece cascade silme esnasında sorun çıkmasını önle
                    block.schedule = nil
                    context.delete(block)
                }
                try context.save()
                logger.debug("✅ Silinmiş bloklar başarıyla temizlendi")
            }
        } catch {
            logger.error("❌ Silinmiş bloklar temizlenirken hata: \(error.localizedDescription)")
            throw RepositoryError.deleteFailed
        }
    }
    
    /// Tüm programları deaktive eder
    func deactivateAllSchedules() async throws {
        guard let context = _modelContext else {
            logger.error("❌ ModelContext ayarlanmamış, deactivateAllSchedules başarısız")
            throw RepositoryError.modelContextNotSet
        }
        
        let descriptor = FetchDescriptor<ScheduleEntity>(
            predicate: #Predicate<ScheduleEntity> { $0.isActive == true && $0.isDeleted == false }
        )
        
        do {
            let activeSchedules = try context.fetch(descriptor)
            logger.debug("🗂️ \(activeSchedules.count) aktif program deaktive ediliyor")
            
            for schedule in activeSchedules {
                schedule.isActive = false
                schedule.updatedAt = Date()
            }
            
            try context.save()
            logger.debug("✅ Tüm programlar başarıyla deaktive edildi")
        } catch {
            logger.error("❌ Programlar deaktive edilirken hata: \(error.localizedDescription)")
            throw RepositoryError.updateFailed
        }
    }
    
    /// Belirli bir programı aktif veya pasif yapar
    func setScheduleActive(id: String, isActive: Bool) async throws {
        guard let context = _modelContext else {
            logger.error("❌ ModelContext ayarlanmamış, setScheduleActive başarısız")
            throw RepositoryError.modelContextNotSet
        }
        
        // UUID dönüşümünü yap
        guard let uuid = UUID(uuidString: id) else {
            logger.error("❌ Geçersiz UUID formatı: \(id)")
            throw RepositoryError.invalidData
        }
        
        // Predicate ile direkt UUID kullanarak ara
        let descriptor = FetchDescriptor<ScheduleEntity>(
            predicate: #Predicate<ScheduleEntity> { $0.id == uuid && $0.isDeleted == false }
        )
        
        do {
            let schedules = try context.fetch(descriptor)
            guard let schedule = schedules.first else {
                logger.error("❌ Program bulunamadı, ID: \(id)")
                throw RepositoryError.entityNotFound
            }
            
            // Programı güncelle
            schedule.isActive = isActive
            schedule.updatedAt = Date()
            
            try context.save()
            logger.debug("✅ Program aktiflik durumu güncellendi: \(schedule.name), isActive: \(isActive)")
        } catch {
            logger.error("❌ Program aktiflik durumu güncellenirken hata: \(error.localizedDescription)")
            throw RepositoryError.updateFailed
        }
    }
    
    /// Sadece entity olarak aktif programı getiren yardımcı metot
    private func getActiveScheduleEntity() async throws -> ScheduleEntity? {
        guard let context = _modelContext else {
            logger.error("❌ ModelContext ayarlanmamış, getActiveScheduleEntity başarısız")
            throw RepositoryError.modelContextNotSet
        }
        
        let descriptor = FetchDescriptor<ScheduleEntity>(
            predicate: #Predicate<ScheduleEntity> { $0.isActive == true && $0.isDeleted == false }
        )
        
        do {
            let schedules = try context.fetch(descriptor)
            return schedules.first
        } catch {
            logger.error("❌ Aktif program entity getirilirken hata: \(error.localizedDescription)")
            throw RepositoryError.fetchFailed
        }
    }
}

enum RepositoryError: Error {
    case modelContextNotSet
    case userNotAuthenticated
    case invalidData
    case saveFailed
    case deleteFailed
    case fetchFailed
    case updateFailed
    case entityNotFound
} 
