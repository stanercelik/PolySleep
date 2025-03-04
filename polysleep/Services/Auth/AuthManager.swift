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
                    switch authState.event {
                    case .initialSession, .signedIn:
                        self.currentUser = authState.session?.user
                        self.isAuthenticated = true
                    case .signedOut, .userDeleted:
                        self.currentUser = nil
                        self.isAuthenticated = false
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
        self.currentUser = await supabaseService.getCurrentUser()
        self.isAuthenticated = self.currentUser != nil
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
            if let user = try await supabaseService.signInWithApple() {
                print("PolySleep Debug: Apple ID ile giriş başarılı: \(user.email ?? "email yok")")
                currentUser = user
                isAuthenticated = true
            } else {
                print("PolySleep Debug: Apple ID ile giriş başarısız: kullanıcı bilgileri alınamadı")
                authError = "Kullanıcı bilgileri alınamadı"
            }
        } catch {
            print("PolySleep Debug: Apple ID ile giriş hatası: \(error.localizedDescription)")
            authError = error.localizedDescription
        }
    }
    
    /// Google ile giriş yapar
    @MainActor
    func signInWithGoogle() async {
        isLoading = true
        authError = nil
        
        do {
            if let user = try await supabaseService.signInWithGoogle() {
                currentUser = user
                isAuthenticated = true
            } else {
                authError = "Kullanıcı bilgileri alınamadı"
            }
        } catch {
            authError = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Çıkış yapar
    @MainActor
    func signOut() async {
        isLoading = true
        authError = nil
        
        do {
            try await supabaseService.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            authError = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Anonim giriş yapar
    @MainActor
    func signInAnonymously() async throws {
        // UserDefaults'tan anonim giriş yapıldı mı kontrol et
        let userDefaults = UserDefaults.standard
        
        do {
            // SupabaseService'deki signInAnonymously metodunu çağır
            // Bu metot zaten UserDefaults kontrolü yapar
            let user = try await supabaseService.signInAnonymously()
            self.currentUser = user
            await refreshAuthState()
        } catch {
            throw error
        }
    }
    
    @MainActor
    private func refreshAuthState() async {
        self.isAuthenticated = self.currentUser != nil
    }
}
