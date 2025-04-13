import Foundation
import Supabase
import Combine
import SwiftUI

/// Kullanıcı kimlik doğrulama işlemlerini yöneten sınıf
class AuthManager: ObservableObject {
    // Singleton instance
    static let shared = AuthManager()
    
    // Supabase servisi
    private let supabaseService = SupabaseService.shared
    
    // Yayınlanan özellikler
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var authError: String?
    
    // Abonelikler
    private var cancellables = Set<AnyCancellable>()
    
    // Private initializer for singleton pattern
    private init() {
        // Auth durumunu dinle
        setupAuthStateListener()
        
        // Mevcut kullanıcıyı kontrol et
        Task {
            await checkCurrentUser()
        }
    }
    
    /// Auth durumu değişikliklerini dinler
    private func setupAuthStateListener() {
        Task {
            for await authState in supabaseService.client.auth.authStateChanges {
                await MainActor.run {
                    let previousAuthState = self.isAuthenticated
                    switch authState.event {
                    case .initialSession, .signedIn:
                        self.currentUser = authState.session?.user
                        self.isAuthenticated = true
                        // Eğer önceki durum false ise ve şimdi true olduysa (giriş yapıldı)
                        if !previousAuthState && self.isAuthenticated {
                            print("AuthManager: Kullanıcı doğrulandı (authStateChanges). ScheduleManager yükleniyor.")
                            ScheduleManager.shared.loadActiveSchedule()
                        }
                    case .signedOut, .userDeleted:
                        self.currentUser = nil
                        self.isAuthenticated = false
                        // Kullanıcı çıkış yaptıysa, schedule manager'ı temizle/güncelle
                        if previousAuthState && !self.isAuthenticated {
                             print("AuthManager: Kullanıcı çıkış yaptı. ScheduleManager güncelleniyor.")
                            ScheduleManager.shared.activeSchedule = nil
                            ScheduleManager.shared.updateNotificationsForActiveSchedule() // Temiz bildirimler
                        }
                    default:
                        break
                    }
                }
            }
        }
    }
    
    /// Mevcut kullanıcıyı kontrol eder
    @MainActor
    private func checkCurrentUser() async {
        do {
            self.currentUser = try await supabaseService.getCurrentUser()
            let previousAuthState = self.isAuthenticated
            self.isAuthenticated = self.currentUser != nil
            // Eğer uygulama başlarken kullanıcı zaten varsa
            if !previousAuthState && self.isAuthenticated {
                 print("AuthManager: Mevcut kullanıcı kontrol edildi, doğrulandı. ScheduleManager yükleniyor.")
                 ScheduleManager.shared.loadActiveSchedule()
            }
        } catch {
            print("PolySleep Debug: Kullanıcı bilgisi alınamadı: \(error.localizedDescription)")
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    /// Apple ID ile giriş yapar
    @MainActor
    func signInWithApple() async {
        print("PolySleep Debug: AuthManager.signInWithApple başladı")
        isLoading = true
        authError = nil
        
        defer {
            isLoading = false
        }
        
        do {
            print("PolySleep Debug: supabaseService.signInWithApple çağrılıyor")
            if let user = try await SupabaseAuthService.shared.signInWithApple() {
                print("PolySleep Debug: Apple ID ile giriş başarılı: \(user.email ?? "email yok")")
            } else {
                print("PolySleep Debug: Apple ID ile giriş başarısız: kullanıcı bilgileri alınamadı")
                authError = "Kullanıcı bilgileri alınamadı"
            }
        } catch {
            print("PolySleep Debug: Apple ID ile giriş hatası: \(error.localizedDescription)")
            authError = error.localizedDescription
        }
    }
    
    /// Çıkış yapar
    @MainActor
    func signOut() async {
        isLoading = true
        authError = nil
        
        do {
            try await SupabaseAuthService.shared.signOut()
        } catch {
            authError = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Anonim giriş yapar
    @MainActor
    func signInAnonymously() async throws {
        _ = UserDefaults.standard
        
        do {
            let user = try await SupabaseAuthService.shared.signInAnonymously()

        } catch {
            throw error
        }
    }
    
    // Bu fonksiyona artık gerek yok, authStateChanges dinleyici yeterli
    // @MainActor
    // private func refreshAuthState() async {
    //     self.isAuthenticated = self.currentUser != nil
    // }
}
