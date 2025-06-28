import Foundation
import StoreKit
import SwiftUI

@MainActor
final class RatingManager: ObservableObject {
    static let shared = RatingManager()
    
    private let hasRequestedReviewKey = "has_requested_review"
    private let lastReviewRequestDateKey = "last_review_request_date"
    private let minimumDaysBetweenRequests: Double = 30
    
    private init() {}
    
    /// Rating request'ini tetikler - sadece native StoreKit kullanır
    func requestRating(completion: @escaping () -> Void) {
        print("📝 RatingManager: Native rating request başlatılıyor...")
        
        // Sadece StoreKit'in native rating'ini kullan
        if canRequestNativeReview() {
            requestNativeReview { [weak self] _ in
                print("✅ RatingManager: Native review tetiklendi")
                self?.markReviewAsRequested()
                completion()
            }
        } else {
            print("ℹ️ RatingManager: Native review şartları karşılanmadı, atlıyor")
            completion()
        }
    }
    
    /// StoreKit'in native rating sistemini tetikler
    private func requestNativeReview(completion: @escaping (Bool) -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            print("❌ RatingManager: WindowScene bulunamadı")
            completion(false)
            return
        }
        
        print("📝 RatingManager: StoreKit native review tetikleniyor...")
        
        // StoreKit'in native rating'ini tetikle
        SKStoreReviewController.requestReview(in: windowScene)
        
        // Native rating tetiklendi, completion'ı hemen çağır
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion(true)
        }
    }
    

    
    /// Native review'ın yapılıp yapılamayacağını kontrol eder
    private func canRequestNativeReview() -> Bool {
        // Daha önce review request yapıldı mı kontrol et
        if hasRequestedReviewBefore() {
            print("ℹ️ RatingManager: Daha önce review request yapıldı")
            return false
        }
        
        return true
    }
    
    /// Daha önce review request yapılıp yapılmadığını kontrol eder
    private func hasRequestedReviewBefore() -> Bool {
        let hasRequested = UserDefaults.standard.bool(forKey: hasRequestedReviewKey)
        
        if hasRequested {
            if let lastRequestDate = UserDefaults.standard.object(forKey: lastReviewRequestDateKey) as? Date {
                let daysSinceLastRequest = Date().timeIntervalSince(lastRequestDate) / (24 * 60 * 60)
                return daysSinceLastRequest < minimumDaysBetweenRequests
            }
        }
        
        return hasRequested
    }
    
    /// Review request'ini kaydeder
    private func markReviewAsRequested() {
        UserDefaults.standard.set(true, forKey: hasRequestedReviewKey)
        UserDefaults.standard.set(Date(), forKey: lastReviewRequestDateKey)
        print("✅ RatingManager: Review request kaydedildi")
    }
    
    /// App Store'a yönlendirme yapar
    func openAppStore() {
        let appStoreURL = "https://apps.apple.com/us/app/polynap-sleep-optimizer/id6746938552"
        
        if let url = URL(string: appStoreURL) {
            UIApplication.shared.open(url)
            markReviewAsRequested()
            print("📱 RatingManager: App Store açıldı")
        }
    }
    

    
    /// Test amaçlı rating geçmişini sıfırlar
    func resetRatingHistory() {
        UserDefaults.standard.removeObject(forKey: hasRequestedReviewKey)
        UserDefaults.standard.removeObject(forKey: lastReviewRequestDateKey)
        print("🔄 RatingManager: Rating geçmişi sıfırlandı")
    }
    
    /// Test amaçlı rating'i zorla tetikler (cooldown'u ignore eder)
    func testRating() {
        print("🧪 RatingManager: Test rating tetikleniyor...")
        
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            print("❌ RatingManager: WindowScene bulunamadı")
            return
        }
        
        // Test için direkt native rating'i tetikle
        SKStoreReviewController.requestReview(in: windowScene)
        print("✅ RatingManager: Test rating tetiklendi")
    }
} 