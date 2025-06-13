import Foundation
import SwiftData
import Combine
import OSLog

/// Temel Repository işlevlerini sağlayan base class
/// ModelContext yönetimi ve ortak CRUD operasyonları burada yapılır
@MainActor
class BaseRepository: ObservableObject {
    
    // MARK: - Properties
    
    internal let logger = Logger(subsystem: "com.tanercelik.polynap", category: "Repository")
    
    private var _modelContext: ModelContext?
    private var localModelContainer: ModelContainer?
    
    internal var authManager: AuthManager {
        AuthManager.shared
    }
    
    // MARK: - Initialization
    
    init() {
        logger.debug("🗂️ BaseRepository başlatıldı")
    }
    
    // MARK: - ModelContext Management
    
    /// ModelContext'i ayarlar
    func setModelContext(_ context: ModelContext) {
        self._modelContext = context
        logger.debug("🗂️ ModelContext ayarlandı, Repository hazır.")
    }
    
    /// Diğer servislerin merkezi ModelContext'e erişmesini sağlar
    /// Bu, `ScheduleManager` gibi singleton'ların context'e ihtiyaç duyduğu durumu çözer
    func getModelContext() -> ModelContext? {
        return self._modelContext
    }
    
    /// ModelContext'e erişim için ana metod
    /// Eğer context ayarlanmamışsa acil durum context'i oluşturur
    func ensureModelContext() throws -> ModelContext {
        guard let context = _modelContext else {
            logger.error("❌ BaseRepository: ModelContext ayarlanmadı! Uygulama başlangıcında setModelContext çağrıldığından emin olun.")
            
            // Acil durum için yerel context oluşturma (test veya izole durumlar için)
            setupEmergencyLocalModelContext()
            if let emergencyContext = _modelContext {
                logger.warning("⚠️ BaseRepository: ACİL DURUM yerel ModelContext kullanılıyor. Bu beklenmedik bir durum.")
                return emergencyContext
            }
            throw RepositoryError.modelContextNotSet
        }
        return context
    }
    
    // MARK: - Private Helper Methods
    
    /// Sadece kesinlikle başka bir context yoksa çağrılacak acil durum metodu
    private func setupEmergencyLocalModelContext() {
        if _modelContext != nil { return } // Zaten varsa bir şey yapma
        
        logger.warning("🚨 BaseRepository: Acil durum yerel ModelContext oluşturuluyor. Bu genellikle bir yapılandırma sorunudur.")
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            let emergencyContainer = try ModelContainer(
                for: // TÜM MODELLER
                SleepScheduleStore.self, UserPreferences.self, UserFactor.self, HistoryModel.self, SleepEntry.self,
                OnboardingAnswerData.self, User.self, UserSchedule.self, UserSleepBlock.self,
                ScheduleEntity.self, SleepBlockEntity.self, SleepEntryEntity.self, PendingChange.self,
                configurations: config
            )
            _modelContext = emergencyContainer.mainContext
        } catch {
            logger.error("❌ BaseRepository: ACİL DURUM yerel ModelContext oluşturulamadı: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Common CRUD Operations
    
    /// Genel amaçlı veri getirme metodu
    func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> [T] {
        let context = try ensureModelContext()
        return try context.fetch(descriptor)
    }
    
    /// Genel amaçlı kaydetme metodu
    func save() throws {
        let context = try ensureModelContext()
        try context.save()
    }
    
    /// Genel amaçlı silme metodu
    func delete<T: PersistentModel>(_ entity: T) throws {
        let context = try ensureModelContext()
        context.delete(entity)
    }
    
    /// Genel amaçlı insert metodu
    func insert<T: PersistentModel>(_ entity: T) throws {
        let context = try ensureModelContext()
        context.insert(entity)
    }
    
    // MARK: - Common Data Operations
    
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
    
    /// Güncel kullanıcı tercihlerini OnboardingAnswer türünde döner
    func getOnboardingAnswers() async throws -> [OnboardingAnswerData] {
        return try await MainActor.run {
            let context = try ensureModelContext()
            
            let descriptor = FetchDescriptor<OnboardingAnswerData>(
                sortBy: [SortDescriptor(\OnboardingAnswerData.date, order: .reverse)]
            )
            
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
} 
