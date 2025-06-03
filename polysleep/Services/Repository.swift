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
        
        // Kullanıcıyı oluştur veya getir
        let user = try await createOrGetUser()
        let userId = user.id
        
        logger.debug("🗂️ Program kaydediliyor: \(scheduleModel.name), ID: \(scheduleModel.id), UserId: \(userId)")
        
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
        
        // Mevcut aktif programları (hem ScheduleEntity hem de UserSchedule) pasifleştir
        do {
            if let activeScheduleEntity = try await getActiveScheduleEntity() {
                // Sadece kaydedilen programdan farklıysa pasifleştir
                if activeScheduleEntity.id != uuid {
                    logger.debug("🗂️ Mevcut aktif ScheduleEntity pasifleştiriliyor: \(activeScheduleEntity.name)")
                    activeScheduleEntity.isActive = false
                    activeScheduleEntity.updatedAt = Date()

                    // İlgili UserSchedule'ı da pasifleştir
                    let activeScheduleId = activeScheduleEntity.id // Değişkeni closure dışında tanımla
                    let oldUserScheduleDescriptor = FetchDescriptor<UserSchedule>(
                        predicate: #Predicate<UserSchedule> { $0.id == activeScheduleId && $0.isActive == true }
                    )
                    if let oldUserSchedule = try context.fetch(oldUserScheduleDescriptor).first {
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
        
        // Yeni programı oluştur veya mevcut programı güncelle
        let existingSchedule = findScheduleById(id: uuid.uuidString)
        
        let scheduleEntity: ScheduleEntity // Değişken adını scheduleEntity olarak değiştirdim
        
        if let existingScheduleEntity = existingSchedule { // Değişken adını existingScheduleEntity olarak değiştirdim
            // Güncelleme
            logger.debug("🗂️ Mevcut ScheduleEntity güncelleniyor: \(existingScheduleEntity.name)")
            existingScheduleEntity.name = scheduleModel.name
            existingScheduleEntity.descriptionJson = descriptionJson
            existingScheduleEntity.totalSleepHours = scheduleModel.totalSleepHours
            existingScheduleEntity.isActive = true // Yeni kaydedilen/güncellenen her zaman aktif olur
            existingScheduleEntity.updatedAt = Date()
            
            scheduleEntity = existingScheduleEntity
        } else {
            // Yeni oluştur
            logger.debug("🗂️ Yeni ScheduleEntity oluşturuluyor: \(scheduleModel.name)")
            scheduleEntity = ScheduleEntity(
                id: uuid,
                userId: userId, // UUID tipinde userId kullanılıyor
                name: scheduleModel.name,
                descriptionJson: descriptionJson,
                totalSleepHours: scheduleModel.totalSleepHours,
                isActive: true, // Yeni kaydedilen her zaman aktif olur
                syncId: syncId
            )
            
            context.insert(scheduleEntity)
        }
        
        // Eski blokları temizleyelim (sadece mevcut program güncelleniyorsa)
        if existingSchedule != nil {
            logger.debug("🗂️ \(scheduleEntity.sleepBlocks.count) eski blok temizleniyor")
            let blocksToDelete = scheduleEntity.sleepBlocks // Referansı al
            for block in blocksToDelete {
                context.delete(block) // Blokları context'ten fiziksel olarak sil
            }
            // SleepBlockEntity'ler ScheduleEntity'ye bağlı olduğu için,
            // ScheduleEntity güncellendiğinde ve save yapıldığında bu silme işlemi geçerli olur.
        }
        
        // Yeni blokları ekleyelim
        logger.debug("🗂️ \(scheduleModel.schedule.count) yeni blok ScheduleEntity'e ekleniyor")
        var newSleepBlockEntities: [SleepBlockEntity] = []
        for block in scheduleModel.schedule {
            let blockEntity = SleepBlockEntity(
                startTime: block.startTime,
                endTime: block.endTime,
                durationMinutes: block.duration,
                isCore: block.isCore,
                syncId: UUID().uuidString
            )
            // blockEntity.schedule = scheduleEntity // Bu satır yerine aşağıda toplu atama yapılıyor
            newSleepBlockEntities.append(blockEntity)
            // context.insert(blockEntity) // Toplu insert yerine ScheduleEntity üzerinden ilişki kuracağız
        }
        scheduleEntity.sleepBlocks = newSleepBlockEntities // İlişkiyi bu şekilde kurmak daha doğru
        // SwiftData, scheduleEntity kaydedildiğinde ilişkili newSleepBlockEntities'i de ekleyecektir.

        // UserSchedule entity'sini de oluştur/güncelle
        // Bu metod zaten yeni UserSchedule'ı aktif yapacak veya eskisini güncelleyip aktif yapacak.
        try await createOrUpdateUserSchedule(scheduleModel, user: user, scheduleEntity: scheduleEntity)

        do {
            try context.save() // Tüm değişiklikleri (ScheduleEntity, UserSchedule, SleepBlockEntity'ler) kaydet
            logger.debug("✅ Program ve ilişkili UserSchedule başarıyla kaydedildi/güncellendi")
        } catch {
            logger.error("❌ Program ve ilişkili UserSchedule kaydedilirken hata: \(error.localizedDescription)")
            throw RepositoryError.saveFailed
        }
        
        return scheduleEntity
    }
    
    /// UserSchedule entity'sini oluşturur veya günceller
    private func createOrUpdateUserSchedule(_ scheduleModel: UserScheduleModel, user: User, scheduleEntity: ScheduleEntity) async throws {
        guard let context = _modelContext else {
            throw RepositoryError.modelContextNotSet
        }
        
        // UUID dönüşümü
        guard let scheduleUUID = UUID(uuidString: scheduleModel.id) else {
            throw RepositoryError.invalidData
        }
        
        // Önce diğer tüm aktif UserSchedule'ları pasifleştir
        let otherActiveUserSchedulesDescriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.id != scheduleUUID && $0.isActive == true }
        )
        
        do {
            let otherActiveUserSchedules = try context.fetch(otherActiveUserSchedulesDescriptor)
            for userSchedule in otherActiveUserSchedules {
                userSchedule.isActive = false
                userSchedule.updatedAt = Date()
                logger.debug("🗂️ Önceki aktif UserSchedule pasifleştirildi: \(userSchedule.name)")
            }
        } catch {
            logger.error("❌ Diğer aktif UserSchedule'lar pasifleştirilirken hata: \(error.localizedDescription)")
            // Devam et, ancak hatayı logla
        }
        
        // Mevcut UserSchedule'ı ara
        let predicate = #Predicate<UserSchedule> { $0.id == scheduleUUID }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            if let existingUserSchedule = try context.fetch(descriptor).first {
                // Güncelle
                existingUserSchedule.user = user
                existingUserSchedule.name = scheduleModel.name
                existingUserSchedule.scheduleDescription = try encodeScheduleDescription(scheduleModel.description)
                existingUserSchedule.totalSleepHours = scheduleModel.totalSleepHours
                existingUserSchedule.isActive = true
                existingUserSchedule.updatedAt = Date()
                
                logger.debug("🗂️ UserSchedule güncellendi: \(existingUserSchedule.name)")
            } else {
                // Yeni oluştur
                let newUserSchedule = UserSchedule(
                    id: scheduleUUID,
                    user: user,
                    name: scheduleModel.name,
                    scheduleDescription: try encodeScheduleDescription(scheduleModel.description),
                    totalSleepHours: scheduleModel.totalSleepHours,
                    adaptationPhase: 0,
                    isActive: true
                )
                
                context.insert(newUserSchedule)
                logger.debug("🗂️ Yeni UserSchedule oluşturuldu: \(newUserSchedule.name)")
                
                // UserSleepBlock'ları oluştur
                for block in scheduleModel.schedule {
                    // String formatındaki saatleri Date'e dönüştür
                    let startDate = convertTimeStringToDate(block.startTime)
                    let endDate = convertTimeStringToDate(block.endTime)
                    
                    let userSleepBlock = UserSleepBlock(
                        schedule: newUserSchedule,
                        startTime: startDate,
                        endTime: endDate,
                        durationMinutes: block.duration,
                        isCore: block.isCore,
                        syncId: UUID().uuidString
                    )
                    context.insert(userSleepBlock)
                }
            }
            
            try context.save()
            logger.debug("✅ UserSchedule başarıyla kaydedildi/güncellendi")
        } catch {
            logger.error("❌ UserSchedule kaydedilirken hata: \(error.localizedDescription)")
            throw RepositoryError.saveFailed
        }
    }
    
    /// LocalizedDescription'ı JSON string'e çevirir
    private func encodeScheduleDescription(_ description: LocalizedDescription) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: [
            "en": description.en,
            "tr": description.tr
        ])
        return String(data: data, encoding: .utf8) ?? "{}"
    }
    
    /// "HH:mm" formatındaki string'i Date'e çevirir
    private func convertTimeStringToDate(_ timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        // Bugünün tarihini al ve sadece saat/dakikayı ayarla
        let today = Date()
        let calendar = Calendar.current
        
        if let time = formatter.date(from: timeString) {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(bySettingHour: timeComponents.hour ?? 0, 
                               minute: timeComponents.minute ?? 0, 
                               second: 0, 
                               of: today) ?? today
        }
        
        return today
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
    
    // MARK: - Migration Methods
    
    /// Mevcut ScheduleEntity'ler için eksik UserSchedule'ları oluşturur
    func migrateScheduleEntitiesToUserSchedules() async throws {
        let context = try ensureModelContext()
        
        logger.debug("🔄 Migration: ScheduleEntity -> UserSchedule başlatılıyor...")
        
        // Tüm ScheduleEntity'leri getir
        let scheduleDescriptor = FetchDescriptor<ScheduleEntity>(
            predicate: #Predicate<ScheduleEntity> { $0.isDeleted == false }
        )
        
        do {
            let scheduleEntities = try context.fetch(scheduleDescriptor)
            var migratedCount = 0
            
            for scheduleEntity in scheduleEntities {
                // Bu ScheduleEntity için UserSchedule var mı kontrol et
                let scheduleEntityId = scheduleEntity.id // Predicate dışında değişkene al
                let userScheduleDescriptor = FetchDescriptor<UserSchedule>(
                    predicate: #Predicate<UserSchedule> { $0.id == scheduleEntityId }
                )
                
                let existingUserSchedules = try context.fetch(userScheduleDescriptor)
                
                if existingUserSchedules.isEmpty {
                    // UserSchedule yok, oluştur
                    logger.debug("🔄 Migration: UserSchedule oluşturuluyor: \(scheduleEntity.name)")
                    
                    // Kullanıcıyı al veya oluştur
                    let user = try await createOrGetUser()
                    
                    // Açıklama JSON'ını direkt kullan
                    let descriptionJson = scheduleEntity.descriptionJson
                    
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
                    
                    context.insert(userSchedule)
                    
                    // UserSleepBlock'ları oluştur
                    for sleepBlock in scheduleEntity.sleepBlocks {
                        let userSleepBlock = UserSleepBlock(
                            schedule: userSchedule,
                            startTime: convertTimeStringToDate(sleepBlock.startTime),
                            endTime: convertTimeStringToDate(sleepBlock.endTime),
                            durationMinutes: sleepBlock.durationMinutes,
                            isCore: sleepBlock.isCore,
                            syncId: sleepBlock.syncId ?? UUID().uuidString
                        )
                        context.insert(userSleepBlock)
                    }
                    
                    migratedCount += 1
                }
            }
            
            if migratedCount > 0 {
                try context.save()
                logger.debug("✅ Migration tamamlandı: \(migratedCount) UserSchedule oluşturuldu")
            } else {
                logger.debug("ℹ️ Migration: Tüm ScheduleEntity'ler zaten UserSchedule'a sahip")
            }
            
        } catch {
            logger.error("❌ Migration hatası: \(error.localizedDescription)")
            throw RepositoryError.saveFailed
        }
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
        
        // ScheduleEntity'leri deaktive et
        let scheduleDescriptor = FetchDescriptor<ScheduleEntity>(
            predicate: #Predicate<ScheduleEntity> { $0.isActive == true && $0.isDeleted == false }
        )
        
        // UserSchedule'ları da deaktive et
        let userScheduleDescriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.isActive == true }
        )
        
        do {
            let activeSchedules = try context.fetch(scheduleDescriptor)
            let activeUserSchedules = try context.fetch(userScheduleDescriptor)
            
            if activeSchedules.isEmpty && activeUserSchedules.isEmpty {
                logger.debug("ℹ️ Deaktive edilecek aktif program bulunamadı.")
                return
            }
            
            logger.debug("🗂️ \(activeSchedules.count) ScheduleEntity ve \(activeUserSchedules.count) UserSchedule deaktive ediliyor")
            
            for schedule in activeSchedules {
                schedule.isActive = false
                schedule.updatedAt = Date()
            }
            
            for userSchedule in activeUserSchedules {
                userSchedule.isActive = false
                userSchedule.updatedAt = Date()
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
        
        guard let uuid = UUID(uuidString: id) else {
            logger.error("❌ Geçersiz UUID formatı: \(id)")
            throw RepositoryError.invalidData
        }
        
        // 1. Eğer bir programı aktif yapıyorsak, önce diğer tüm aktif programları pasifleştir.
        if isActive {
            logger.debug("🗂️ Program (ID: \(uuid.uuidString)) aktif ediliyor, diğerleri pasifleştirilecek.")
            // Diğer ScheduleEntity'leri pasifleştir
            let activeScheduleEntitiesDescriptor = FetchDescriptor<ScheduleEntity>(
                predicate: #Predicate<ScheduleEntity> { $0.id != uuid && $0.isActive == true && $0.isDeleted == false }
            )
            // Diğer UserSchedule'ları pasifleştir
            let activeUserSchedulesDescriptor = FetchDescriptor<UserSchedule>(
                predicate: #Predicate<UserSchedule> { $0.id != uuid && $0.isActive == true }
            )

            do {
                let otherActiveSchedules = try context.fetch(activeScheduleEntitiesDescriptor)
                for schedule in otherActiveSchedules {
                    schedule.isActive = false
                    schedule.updatedAt = Date()
                    logger.debug("🗂️ Önceki aktif ScheduleEntity pasifleştirildi: \(schedule.name)")
                }

                let otherActiveUserSchedules = try context.fetch(activeUserSchedulesDescriptor)
                for userSchedule in otherActiveUserSchedules {
                    userSchedule.isActive = false
                    userSchedule.updatedAt = Date()
                    logger.debug("🗂️ Önceki aktif UserSchedule pasifleştirildi: \(userSchedule.name)")
                }
            } catch {
                logger.error("❌ Diğer aktif programlar pasifleştirilirken hata: \(error.localizedDescription)")
                // Devam et, ancak hatayı logla
            }
        }

        // 2. Hedef ScheduleEntity'i güncelle
        let scheduleEntityDescriptor = FetchDescriptor<ScheduleEntity>(
            predicate: #Predicate<ScheduleEntity> { $0.id == uuid && $0.isDeleted == false }
        )
        
        do {
            guard let scheduleEntityToUpdate = try context.fetch(scheduleEntityDescriptor).first else {
                logger.error("❌ ScheduleEntity bulunamadı, ID: \(id)")
                throw RepositoryError.entityNotFound
            }
            
            scheduleEntityToUpdate.isActive = isActive
            scheduleEntityToUpdate.updatedAt = Date()
            logger.debug("✅ ScheduleEntity aktiflik durumu güncellendi: \(scheduleEntityToUpdate.name), isActive: \(isActive)")

            // 3. İlgili UserSchedule'ı güncelle
            let userScheduleDescriptor = FetchDescriptor<UserSchedule>(
                predicate: #Predicate<UserSchedule> { $0.id == uuid } // Aynı ID ile eşleştir
            )
            if let userScheduleToUpdate = try context.fetch(userScheduleDescriptor).first {
                userScheduleToUpdate.isActive = isActive
                userScheduleToUpdate.updatedAt = Date()
                
                // Eğer aktif ediliyorsa adaptasyon fazını sıfırla ve undo bilgisini kaydet
                if isActive {
                    // Undo bilgisini kaydet
                    try await saveScheduleChangeUndoData(scheduleId: uuid)
                    
                    userScheduleToUpdate.adaptationPhase = 0 // Yeniden aktivasyonda adaptasyon fazını sıfırla
                    userScheduleToUpdate.updatedAt = Date() // Adaptasyon başlangıç tarihini güncelle
                    
                    // Streak'i sıfırla
                    UserDefaults.standard.set(0, forKey: "currentStreak")
                    
                    logger.debug("🗂️ UserSchedule (ID: \(userScheduleToUpdate.id.uuidString)) aktif edildi, adaptasyon fazı ve streak sıfırlandı.")
                }
                logger.debug("✅ UserSchedule aktiflik durumu güncellendi: \(userScheduleToUpdate.name), isActive: \(isActive)")
            } else if isActive {
                // Bu durum bir tutarsızlığa işaret eder: ScheduleEntity var ama UserSchedule yok.
                // İdeal olarak bu durum saveSchedule tarafından engellenmelidir.
                logger.error("❌ TUTARSIZLIK: ScheduleEntity (ID: \(id)) için UserSchedule bulunamadı ancak aktif edilmeye çalışılıyor. Bu UserSchedule normalde saveSchedule sırasında oluşturulmalıydı.")
                // Burada eksik UserSchedule'ı oluşturmak için bir mantık eklenebilir, ancak bu daha fazla bilgi gerektirir.
                // Şimdilik bu, olası bir veri bütünlüğü sorununu vurgular.
            }
            
            try context.save()
            
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

    // MARK: - User Management Methods
    
    /// Kullanıcıyı SwiftData'da oluşturur veya mevcut kullanıcıyı getirir
    func createOrGetUser() async throws -> User {
        guard let context = _modelContext else {
            logger.error("❌ ModelContext ayarlanmamış, createOrGetUser başarısız")
            throw RepositoryError.modelContextNotSet
        }
        
        guard let currentUserIdString = authManager.currentUser?.id,
              let currentUserId = UUID(uuidString: currentUserIdString) else {
            logger.error("❌ AuthManager'dan geçerli kullanıcı ID'si alınamadı")
            throw RepositoryError.userNotAuthenticated
        }
        
        // Önce kullanıcıyı ara
        let userPredicate = #Predicate<User> { $0.id == currentUserId }
        let userDescriptor = FetchDescriptor(predicate: userPredicate)
        
        do {
            if let existingUser = try context.fetch(userDescriptor).first {
                logger.debug("✅ Mevcut kullanıcı bulundu: \(existingUser.displayName ?? "Anonim")")
                return existingUser
            } else {
                // Kullanıcı yoksa oluştur
                let newUser = User(
                    id: currentUserId,
                    email: nil, // Yerel kullanıcı için email yok
                    displayName: authManager.currentUser?.displayName,
                    isAnonymous: true, // Yerel kullanıcı anonim olarak işaretlenir
                    createdAt: Date(),
                    updatedAt: Date(),
                    isPremium: false
                )
                
                context.insert(newUser)
                try context.save()
                
                logger.debug("✅ Yeni kullanıcı oluşturuldu: \(newUser.displayName ?? "Anonim")")
                return newUser
            }
        } catch {
            logger.error("❌ Kullanıcı oluşturulurken/getirilirken hata: \(error.localizedDescription)")
            throw RepositoryError.saveFailed
        }
    }

    // MARK: - Schedule Change Undo Methods
    
    /// Schedule değişimi undo verilerini kaydeder
    private func saveScheduleChangeUndoData(scheduleId: UUID) async throws {
        let undoData = ScheduleChangeUndoData(
            scheduleId: scheduleId,
            changeDate: Date(),
            previousStreak: UserDefaults.standard.integer(forKey: "currentStreak"),
            previousAdaptationPhase: getCurrentAdaptationPhase(scheduleId: scheduleId),
            previousAdaptationDate: getCurrentAdaptationStartDate(scheduleId: scheduleId)
        )
        
        // UserDefaults'a undo verisini kaydet
        if let encoded = try? JSONEncoder().encode(undoData) {
            UserDefaults.standard.set(encoded, forKey: "scheduleChangeUndoData")
            logger.debug("📝 Schedule değişimi undo verisi kaydedildi")
        }
    }
    
    /// Mevcut adaptasyon fazını al
    private func getCurrentAdaptationPhase(scheduleId: UUID) -> Int {
        guard let context = _modelContext else { return 0 }
        
        let descriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.id == scheduleId }
        )
        
        do {
            if let schedule = try context.fetch(descriptor).first {
                return schedule.adaptationPhase ?? 0
            }
        } catch {
            logger.error("❌ Adaptasyon fazı alınırken hata: \(error)")
        }
        
        return 0
    }
    
    /// Mevcut adaptasyon başlangıç tarihini al
    private func getCurrentAdaptationStartDate(scheduleId: UUID) -> Date {
        guard let context = _modelContext else { return Date() }
        
        let descriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.id == scheduleId }
        )
        
        do {
            if let schedule = try context.fetch(descriptor).first {
                return schedule.updatedAt
            }
        } catch {
            logger.error("❌ Adaptasyon başlangıç tarihi alınırken hata: \(error)")
        }
        
        return Date()
    }
    
    /// Schedule değişimini geri al
    func undoScheduleChange() async throws {
        guard let data = UserDefaults.standard.data(forKey: "scheduleChangeUndoData"),
              let undoData = try? JSONDecoder().decode(ScheduleChangeUndoData.self, from: data) else {
            throw RepositoryError.noUndoDataAvailable
        }
        
        guard let context = _modelContext else {
            throw RepositoryError.modelContextNotSet
        }
        
        // Schedule değişimi bugün yapıldıysa geri alabilir
        let calendar = Calendar.current
        guard calendar.isDate(undoData.changeDate, inSameDayAs: Date()) else {
            throw RepositoryError.undoExpired
        }
        
        // Schedule'ı bul ve eski durumuna çevir
        let descriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.id == undoData.scheduleId }
        )
        
        do {
            guard let schedule = try context.fetch(descriptor).first else {
                throw RepositoryError.entityNotFound
            }
            
            // Eski değerleri geri yükle
            schedule.adaptationPhase = undoData.previousAdaptationPhase
            schedule.updatedAt = undoData.previousAdaptationDate
            
            // Streak'i geri yükle
            UserDefaults.standard.set(undoData.previousStreak, forKey: "currentStreak")
            
            try context.save()
            
            // Undo verisini temizle
            UserDefaults.standard.removeObject(forKey: "scheduleChangeUndoData")
            
            logger.debug("✅ Schedule değişimi başarıyla geri alındı")
            
        } catch {
            logger.error("❌ Schedule değişimi geri alınırken hata: \(error)")
            throw RepositoryError.updateFailed
        }
    }
    
    /// Undo verisi mevcut mu kontrol et
    func hasUndoData() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: "scheduleChangeUndoData"),
              let undoData = try? JSONDecoder().decode(ScheduleChangeUndoData.self, from: data) else {
            return false
        }
        
        // Sadece bugünkü değişiklikler için undo mevcut
        let calendar = Calendar.current
        return calendar.isDate(undoData.changeDate, inSameDayAs: Date())
    }
    
    /// Adaptasyon günü debug için manuel olarak ayarla
    func setAdaptationDebugDay(scheduleId: UUID, dayNumber: Int) async throws {
        guard let context = _modelContext else {
            throw RepositoryError.modelContextNotSet
        }
        
        let descriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.id == scheduleId }
        )
        
        do {
            guard let schedule = try context.fetch(descriptor).first else {
                throw RepositoryError.entityNotFound
            }
            
            // Günü adaptasyon başlangıç tarihine göre hesapla
            let calendar = Calendar.current
            let targetDate = calendar.date(byAdding: .day, value: dayNumber - 1, to: Date()) ?? Date()
            
            schedule.updatedAt = targetDate
            
            // Fazı hesapla
            let phase = calculateAdaptationPhaseForDay(dayNumber: dayNumber, schedule: schedule)
            schedule.adaptationPhase = phase
            
            try context.save()
            
            logger.debug("🐛 Adaptasyon debug günü ayarlandı: Gün \(dayNumber), Faz \(phase)")
            
        } catch {
            logger.error("❌ Adaptasyon debug günü ayarlanırken hata: \(error)")
            throw RepositoryError.updateFailed
        }
    }
    
    /// Belirli bir gün numarası için adaptasyon fazını hesapla
    private func calculateAdaptationPhaseForDay(dayNumber: Int, schedule: UserSchedule) -> Int {
        let scheduleName = schedule.name.lowercased()
        let adaptationDuration: Int
        
        if scheduleName.contains("uberman") || 
           scheduleName.contains("dymaxion") ||
           (scheduleName.contains("everyman") && scheduleName.contains("1")) {
            adaptationDuration = 28
        } else {
            adaptationDuration = 21
        }
        
        let phase: Int
        
        if adaptationDuration == 28 {
            // 28 günlük programlar için
            switch dayNumber {
            case 1:
                phase = 0  // İlk gün - Başlangıç
            case 2...7:
                phase = 1  // 2-7. günler - İlk Adaptasyon
            case 8...14:
                phase = 2  // 8-14. günler - Orta Adaptasyon
            case 15...21:
                phase = 3  // 15-21. günler - İlerlemiş Adaptasyon
            case 22...28:
                phase = 4  // 22-28. günler - İleri Adaptasyon
            default:
                phase = 5  // 28+ günler - Tamamlanmış
            }
        } else {
            // 21 günlük programlar için
            switch dayNumber {
            case 1:
                phase = 0  // İlk gün - Başlangıç
            case 2...7:
                phase = 1  // 2-7. günler - İlk Adaptasyon
            case 8...14:
                phase = 2  // 8-14. günler - Orta Adaptasyon
            case 15...21:
                phase = 3  // 15-21. günler - İlerlemiş Adaptasyon
            default:
                phase = 4  // 21+ günler - Tamamlanmış
            }
        }
        
        return phase
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
    case noUndoDataAvailable
    case undoExpired
} 
