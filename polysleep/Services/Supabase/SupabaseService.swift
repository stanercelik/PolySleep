import Foundation
import Supabase

/// Ana Supabase servisi, diğer tüm modül servislerine erişim sağlar
class SupabaseService {
    // Singleton instance
    static let shared = SupabaseService()
    
    // Supabase istemcisi
    lazy var client = SupabaseClient(
        supabaseURL: URL(string: SupabaseConfig.supabaseUrl)!,
        supabaseKey: SupabaseConfig.supabaseKey
    )
    
    // Private initializer for singleton pattern
    private init() {}
    
    // MARK: - Servis Erişim Metodları
    
    /// Kimlik doğrulama servisi
    var auth: SupabaseAuthService {
        return SupabaseAuthService.shared
    }
    
    /// Onboarding servisi
    var onboarding: SupabaseOnboardingService {
        return SupabaseOnboardingService.shared
    }
    
    /// Uyku programları servisi
    var schedule: SupabaseScheduleService {
        return SupabaseScheduleService.shared
    }
    
    // MARK: - Yardımcı Metodlar
    
    /// Mevcut kullanıcıyı döndürür (auth servisinden)
    @MainActor
    public func getCurrentUser() async throws -> User? {
        return try await auth.getCurrentUser()
    }
    
    /// JSON verisini kodlar
    /// - Parameter value: Kodlanacak değer
    /// - Returns: JSON string
    func encodeToJson<T: Encodable>(_ value: T) -> String? {
        do {
            let jsonData = try JSONEncoder().encode(value)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("PolySleep Debug: JSON kodlama hatası: \(error)")
            return nil
        }
    }
}
