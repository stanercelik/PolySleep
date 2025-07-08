import Foundation
import SwiftData
import OSLog

/// Shared kullanıcı yönetimi işlemleri için Repository
/// iOS ve watchOS platformları arasında SharedUser modeli ile çalışır
@MainActor
public final class SharedUserRepository: SharedBaseRepository {
    
    public static let shared = SharedUserRepository()
    
    private override init() {
        super.init()
        logger.debug("👤 SharedUserRepository başlatıldı")
    }
    
    // MARK: - User Management Methods
    
    /// Kullanıcı ID'si ile SharedUser nesnesini getirir
    public func getUserById(_ id: UUID) async throws -> SharedUser? {
        let context = try ensureModelContext()
        
        let userPredicate = #Predicate<SharedUser> { $0.id == id }
        let userDescriptor = FetchDescriptor(predicate: userPredicate)
        
        do {
            let users = try context.fetch(userDescriptor)
            if let user = users.first {
                logger.debug("✅ SharedUser bulundu: \(user.id.uuidString)")
            } else {
                logger.debug("📭 SharedUser bulunamadı: \(id.uuidString)")
            }
            return users.first
        } catch {
            logger.error("❌ SharedUser getirilirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.fetchFailed
        }
    }
    
    /// Yeni SharedUser oluşturur veya mevcut kullanıcıyı getirir
    public func createOrGetUser(id: UUID, 
                               email: String? = nil, 
                               displayName: String? = nil,
                               isAnonymous: Bool = false,
                               isPremium: Bool = false) async throws -> SharedUser {
        
        // Önce kullanıcıyı ara
        if let existingUser = try await getUserById(id) {
            logger.debug("📱 Mevcut SharedUser kullanılıyor: \(existingUser.id.uuidString)")
            return existingUser
        }
        
        // Kullanıcı bulunamazsa yeni oluştur
        let newUser = SharedUser(
            id: id,
            email: email,
            displayName: displayName,
            isAnonymous: isAnonymous,
            isPremium: isPremium
        )
        
        do {
            try insert(newUser)
            try save()
            logger.debug("✅ Yeni SharedUser oluşturuldu: \(newUser.id.uuidString)")
        } catch {
            logger.error("❌ SharedUser oluşturulurken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.saveFailed
        }
        
        return newUser
    }
    
    /// SharedUser bilgilerini günceller
    public func updateUser(_ user: SharedUser, 
                          email: String? = nil, 
                          displayName: String? = nil,
                          avatarUrl: String? = nil,
                          isPremium: Bool? = nil,
                          preferences: String? = nil) async throws {
        
        // Güncelleme alanları
        if let email = email {
            user.email = email
        }
        if let displayName = displayName {
            user.displayName = displayName
        }
        if let avatarUrl = avatarUrl {
            user.avatarUrl = avatarUrl
        }
        if let isPremium = isPremium {
            user.isPremium = isPremium
        }
        if let preferences = preferences {
            user.preferences = preferences
        }
        
        user.updatedAt = Date()
        
        do {
            try save()
            logger.debug("✅ SharedUser güncellendi: \(user.id.uuidString)")
        } catch {
            logger.error("❌ SharedUser güncellenirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.updateFailed
        }
    }
    
    /// Kullanıcıyı siler
    public func deleteUser(_ user: SharedUser) async throws {
        do {
            try delete(user)
            try save()
            logger.debug("🗑️ SharedUser silindi: \(user.id.uuidString)")
        } catch {
            logger.error("❌ SharedUser silinirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.deleteFailed
        }
    }
    
    /// Kullanıcının premium durumunu günceller
    public func updatePremiumStatus(userId: UUID, isPremium: Bool) async throws {
        guard let user = try await getUserById(userId) else {
            throw SharedRepositoryError.entityNotFound
        }
        
        try await updateUser(user, isPremium: isPremium)
    }
    
    /// Kullanıcının tercihlerini JSON string olarak günceller
    public func updateUserPreferences(userId: UUID, preferences: String) async throws {
        guard let user = try await getUserById(userId) else {
            throw SharedRepositoryError.entityNotFound
        }
        
        try await updateUser(user, preferences: preferences)
    }
    
    /// Tüm SharedUser'ları getirir (debugging amaçlı)
    public func getAllUsers() throws -> [SharedUser] {
        let descriptor = FetchDescriptor<SharedUser>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let users = try fetch(descriptor)
            logger.debug("🗂️ \(users.count) SharedUser getirildi")
            return users
        } catch {
            logger.error("❌ Tüm SharedUser'lar getirilirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.fetchFailed
        }
    }
} 