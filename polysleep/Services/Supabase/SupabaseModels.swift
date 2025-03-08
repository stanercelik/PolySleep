import Foundation
import Supabase

/// Kimlik doğrulama hataları
enum AuthError: Error {
    case signInFailed(String)
    case signOutFailed(String)
    case userUpdateFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .signInFailed(let message):
            return "Giriş hatası: \(message)"
        case .signOutFailed(let message):
            return "Çıkış hatası: \(message)"
        case .userUpdateFailed(let message):
            return "Kullanıcı güncelleme hatası: \(message)"
        }
    }
}

/// Supabase servisi için hata tipleri
enum SupabaseError: Error {
    case userNotFound
    case syncFailed(String)
    case invalidResponse
    
    var localizedDescription: String {
        switch self {
        case .userNotFound:
            return "Kullanıcı bulunamadı"
        case .syncFailed(let message):
            return "Senkronizasyon hatası: \(message)"
        case .invalidResponse:
            return "Geçersiz yanıt"
        }
    }
}

// MARK: - Onboarding Models

/// Onboarding cevabı DTO
struct OnboardingAnswerDTO: Codable {
    let id: String
    let user_id: String
    let question: String
    let answer: String
    let date: String
}

// MARK: - Schedule Models

/// Template uyku programı
struct TemplateSchedule: Codable {
    let id: String
    let name: String
    let description_en: String
    let description_tr: String
    let total_sleep_hours: Double
    let schedule: String
    let created_at: String?
    let updated_at: String?
}
