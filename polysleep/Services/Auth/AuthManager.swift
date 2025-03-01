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
        isLoading = true
        authError = nil
        
        do {
            if let user = try await supabaseService.signInWithApple() {
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
}
