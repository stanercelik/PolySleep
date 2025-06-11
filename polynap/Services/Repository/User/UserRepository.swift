import Foundation
import SwiftData
import OSLog

/// Kullanıcı yönetimi işlemleri için Repository
@MainActor
final class UserRepository: BaseRepository {
    
    static let shared = UserRepository()
    
    private override init() {
        super.init()
        logger.debug("👤 UserRepository başlatıldı")
    }
    
    // MARK: - User Management Methods
    
    /// Kullanıcıyı SwiftData'da oluşturur veya mevcut kullanıcıyı getirir
    func createOrGetUser() async throws -> User {
        let context = try ensureModelContext()
        
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
                
                try insert(newUser)
                try save()
                
                logger.debug("✅ Yeni kullanıcı oluşturuldu: \(newUser.displayName ?? "Anonim")")
                return newUser
            }
        } catch {
            logger.error("❌ Kullanıcı oluşturulurken/getirilirken hata: \(error.localizedDescription)")
            throw RepositoryError.saveFailed
        }
    }
    
    /// Kullanıcının premium durumunu günceller
    func updateUserPremiumStatus(isPremium: Bool) async throws {
        let user = try await createOrGetUser()
        user.isPremium = isPremium
        user.updatedAt = Date()
        
        do {
            try save()
            logger.debug("✅ Kullanıcı premium durumu güncellendi: \(isPremium)")
        } catch {
            logger.error("❌ Kullanıcı premium durumu güncellenirken hata: \(error.localizedDescription)")
            throw RepositoryError.updateFailed
        }
    }
    
    /// Kullanıcının görüntü adını günceller
    func updateUserDisplayName(_ displayName: String) async throws {
        let user = try await createOrGetUser()
        user.displayName = displayName
        user.updatedAt = Date()
        
        do {
            try save()
            logger.debug("✅ Kullanıcı görüntü adı güncellendi: \(displayName)")
        } catch {
            logger.error("❌ Kullanıcı görüntü adı güncellenirken hata: \(error.localizedDescription)")
            throw RepositoryError.updateFailed
        }
    }
    
    /// Kullanıcının email adresini günceller
    func updateUserEmail(_ email: String?) async throws {
        let user = try await createOrGetUser()
        user.email = email
        user.updatedAt = Date()
        
        if email != nil {
            user.isAnonymous = false // Email varsa artık anonim değil
        }
        
        do {
            try save()
            logger.debug("✅ Kullanıcı email adresi güncellendi")
        } catch {
            logger.error("❌ Kullanıcı email adresi güncellenirken hata: \(error.localizedDescription)")
            throw RepositoryError.updateFailed
        }
    }
    
    /// Kullanıcı verilerini siler (hesap silme)
    func deleteUser() async throws {
        let user = try await createOrGetUser()
        
        do {
            try delete(user)
            try save()
            logger.debug("✅ Kullanıcı verisi silindi")
        } catch {
            logger.error("❌ Kullanıcı verisi silinirken hata: \(error.localizedDescription)")
            throw RepositoryError.deleteFailed
        }
    }
    
    /// Kullanıcının premium durumunu kontrol eder
    func checkUserPremiumStatus() async throws -> Bool {
        do {
            let user = try await createOrGetUser()
            return user.isPremium
        } catch {
            logger.warning("⚠️ Premium durum kontrolü yapılırken hata, varsayılan olarak false dönülüyor: \(error.localizedDescription)")
            return false
        }
    }
} 