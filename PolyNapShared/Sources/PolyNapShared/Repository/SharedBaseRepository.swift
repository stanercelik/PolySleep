import Foundation
import SwiftData
import Combine
import OSLog

/// Shared temel Repository işlevlerini sağlayan base class
/// iOS ve watchOS platformları arasında ortak ModelContext yönetimi ve CRUD operasyonları
@available(iOS 17.0, watchOS 10.0, macOS 14.0, *)
@MainActor
public class SharedBaseRepository: ObservableObject {
    
    // MARK: - Properties
    
    public let logger = Logger(subsystem: "com.tanercelik.polynap.shared", category: "SharedRepository")
    
    private var _modelContext: ModelContext?
    private var localModelContainer: ModelContainer?
    
    // MARK: - Initialization
    
    public init() {
        logger.debug("🗂️ SharedBaseRepository başlatıldı")
    }
    
    // MARK: - ModelContext Management
    
    /// ModelContext'i ayarlar (iOS ve watchOS için ortak)
    public func setModelContext(_ context: ModelContext) {
        self._modelContext = context
        logger.debug("🗂️ Shared ModelContext ayarlandı")
    }
    
    /// Diğer servislerin merkezi ModelContext'e erişmesini sağlar
    public func getModelContext() -> ModelContext? {
        return self._modelContext
    }
    
    /// ModelContext'e erişim için ana metod
    /// Eğer context ayarlanmamışsa shared emergency context'i oluşturur
    public func ensureModelContext() throws -> ModelContext {
        guard let context = _modelContext else {
            logger.error("❌ SharedBaseRepository: ModelContext ayarlanmadı!")
            
            // Shared emergency context oluşturma denemesi
            do {
                try setupSharedEmergencyModelContext()
                if let emergencyContext = _modelContext {
                    logger.warning("⚠️ SharedBaseRepository: ACİL DURUM shared ModelContext kullanılıyor")
                    return emergencyContext
                } else {
                    logger.error("❌ SharedBaseRepository: ACİL DURUM ModelContext oluşturulamadı")
                    throw SharedRepositoryError.modelContextNotSet
                }
            } catch {
                logger.error("❌ SharedBaseRepository: ACİL DURUM ModelContext kurulum hatası: \(error.localizedDescription)")
                throw SharedRepositoryError.modelContextNotSet
            }
        }
        return context
    }
    
    // MARK: - Private Helper Methods
    
    /// Shared models için acil durum ModelContext'i oluşturur
    private func setupSharedEmergencyModelContext() throws {
        if _modelContext != nil { 
            logger.debug("🔍 SharedBaseRepository: ModelContext zaten mevcut, emergency setup atlanıyor")
            return 
        }
        
        logger.warning("🚨 SharedBaseRepository: Acil durum shared ModelContext oluşturuluyor")
        
        // Availability check
        guard #available(iOS 17.0, macOS 14.0, watchOS 10.0, *) else {
            logger.error("❌ SharedBaseRepository: SwiftData bu platform versiyonunda desteklenmiyor")
            throw SharedRepositoryError.platformNotSupported
        }
        
        do {
            // In-memory fallback container oluştur
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let emergencyContainer = try ModelContainer(
                for: SharedUser.self, SharedUserSchedule.self, SharedSleepBlock.self, SharedSleepEntry.self,
                configurations: config
            )
            
            _modelContext = emergencyContainer.mainContext
            logger.info("✅ SharedBaseRepository: ACİL DURUM in-memory ModelContext oluşturuldu")
            
        } catch {
            logger.error("❌ SharedBaseRepository: ACİL DURUM shared ModelContext oluşturulamadı: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Common CRUD Operations
    
    /// Genel amaçlı veri getirme metodu
    public func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> [T] {
        let context = try ensureModelContext()
        return try context.fetch(descriptor)
    }
    
    /// Genel amaçlı kaydetme metodu
    public func save() throws {
        let context = try ensureModelContext()
        try context.save()
    }
    
    /// Genel amaçlı silme metodu
    public func delete<T: PersistentModel>(_ entity: T) throws {
        let context = try ensureModelContext()
        context.delete(entity)
    }
    
    /// Genel amaçlı insert metodu
    public func insert<T: PersistentModel>(_ entity: T) throws {
        let context = try ensureModelContext()
        context.insert(entity)
    }
}

// MARK: - Shared Repository Error Types

/// Shared Repository işlemleri için hata türleri
public enum SharedRepositoryError: Error {
    case modelContextNotSet
    case userNotAuthenticated
    case invalidData
    case saveFailed
    case deleteFailed
    case fetchFailed
    case updateFailed
    case entityNotFound
    case platformNotSupported
}

/// SharedRepositoryError için yerelleştirilmiş açıklamalar
extension SharedRepositoryError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .modelContextNotSet:
            return "Model context ayarlanmamış"
        case .userNotAuthenticated:
            return "Kullanıcı kimlik doğrulaması yapılmamış"
        case .invalidData:
            return "Geçersiz veri"
        case .saveFailed:
            return "Kaydetme işlemi başarısız"
        case .deleteFailed:
            return "Silme işlemi başarısız"
        case .fetchFailed:
            return "Veri getirme işlemi başarısız"
        case .updateFailed:
            return "Güncelleme işlemi başarısız"
        case .entityNotFound:
            return "Varlık bulunamadı"
        case .platformNotSupported:
            return "Platform desteklenmiyor"
        }
    }
} 