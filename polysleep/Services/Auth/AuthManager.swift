import Foundation
import Combine
import SwiftUI

// AuthError tanımı basitleştirildi
enum AuthError: Error {
    case noCurrentUser
    case unknownError(Error? = nil)
    // Apple Sign In ile ilgili hatalar kaldırıldı
}

/// Kullanıcı kimlik doğrulama işlemlerini yöneten sınıf - Tamamen Offline versiyon
class AuthManager: ObservableObject {
    // Singleton instance
    static let shared = AuthManager()
    
    // Yayınlanan özellikler
    @Published var isAuthenticated = true // Offline modda her zaman kimlik doğrulanmış kabul edilir
    @Published var currentUser: LocalUser?
    @Published var isLoading = false
    @Published var authError: String? // Artık çok fazla kullanılmayabilir
    
    // Private initializer for singleton pattern
    private init() {
        // Yerel kullanıcı oluştur veya getir
        currentUser = createOrGetLocalUser()
        print("AuthManager: Yerel kullanıcı ile başlatıldı: ID \(currentUser?.id ?? "N/A")")
        
        // Program yöneticisini asenkron olarak başlat
        Task {
            await ScheduleManager.shared.loadActiveSchedule()
        }
    }
    
    /// Yerel kullanıcı oluşturur veya varsa getirir
    private func createOrGetLocalUser() -> LocalUser {
        let userIdKey = "localUserId"
        let displayNameKey = "localUserDisplayName" // DisplayName'i de saklayalım
        
        var userId = UserDefaults.standard.string(forKey: userIdKey)
        if userId == nil {
            userId = UUID().uuidString
            UserDefaults.standard.set(userId, forKey: userIdKey)
            // Yeni kullanıcı için varsayılan isim
            UserDefaults.standard.removeObject(forKey: displayNameKey)
            print("AuthManager: Yeni yerel kullanıcı ID'si oluşturuldu: \(userId!)")
        }
        
        let displayName = UserDefaults.standard.string(forKey: displayNameKey) ?? NSLocalizedString("localUser.defaultName", tableName: "Auth", comment: "Default local user name")
        
        return LocalUser(id: userId!, displayName: displayName)
    }
    
    /// Profile isim güncelleme
    @MainActor
    func updateDisplayName(_ name: String) {
        guard var user = currentUser else {
            // Bu durumda yeni bir kullanıcı oluşturabilir veya hata verebiliriz.
            // Şimdilik sadece mevcut kullanıcıyı güncelliyoruz.
            print("AuthManager: Display name güncellenemedi, mevcut kullanıcı yok.")
            return
        }
        user.displayName = name
        self.currentUser = user
        UserDefaults.standard.set(name, forKey: "localUserDisplayName")
        print("AuthManager: Display name güncellendi: \(name)")
    }
    
    /// Kullanıcı çıkış işlemi (Offline modda: kullanıcı bilgilerini sıfırlar)
    @MainActor
    func signOut() async {
        isLoading = true
        authError = nil
        
        // Çıkış işlemi için kısa gecikme (isteğe bağlı)
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 saniye
        
        // UserDefaults'tan displayName'i kaldırıp yeni bir kullanıcı oluşturuyoruz
        // Böylece "AppFirstLaunch" ve "onboardingCompleted" etkilenmez ama kullanıcı adı "sıfırlanır".
        UserDefaults.standard.removeObject(forKey: "localUserDisplayName")
        // UserId'yi sıfırlamıyoruz, aynı cihazda aynı "anonim" kullanıcı devam eder.
        
        self.currentUser = createOrGetLocalUser() // Kullanıcıyı yeniden yükle (varsayılan isimle gelir)
        
        isLoading = false
        isAuthenticated = true // Offline modda her zaman true
        print("AuthManager: Kullanıcı 'çıkış yaptı' (bilgiler sıfırlandı). Yeni/Varsayılan kullanıcı: \(currentUser?.displayName ?? "N/A")")
    }
    
    // Apple ile giriş ve ilgili tüm yardımcı metodlar kaldırıldı
}

/// Offline-first mod için basit kullanıcı modeli
struct LocalUser {
    let id: String
    var displayName: String = ""
    var email: String = "" // Artık pek kullanılmayacak
    var photoURL: String = "" // Artık pek kullanılmayacak
    var isPremium: Bool = false // Yerel olarak yönetilebilir veya her zaman false
    var authProvider: String = "local"
}


