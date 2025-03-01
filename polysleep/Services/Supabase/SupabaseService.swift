import Foundation
import Supabase
import AuthenticationServices
import UIKit
import CommonCrypto

/// Supabase servisi
class SupabaseService {
    // Singleton instance
    static let shared = SupabaseService()
    
    // Supabase istemcisi
    private(set) lazy var client = SupabaseClient(
        supabaseURL: URL(string: SupabaseConfig.supabaseUrl)!,
        supabaseKey: SupabaseConfig.supabaseKey
    )
    
    // Private initializer for singleton pattern
    private init() {}
    
    // MARK: - Auth Methods
    
    /// Mevcut kullanıcıyı döndürür
    @MainActor
    func getCurrentUser() async -> User? {
        return try? await client.auth.session.user
    }
    
    /// Apple ID ile giriş yapar
    /// - Returns: Giriş yapan kullanıcı bilgileri
    @MainActor
    func signInWithApple() async throws -> User? {
        let nonce = randomNonceString()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email, .fullName]
        request.nonce = nonce.sha256
        
        let authResult = try await performAppleSignIn(request: request)
        
        guard let appleIDCredential = authResult.credential as? ASAuthorizationAppleIDCredential,
              let idToken = appleIDCredential.identityToken,
              let idTokenString = String(data: idToken, encoding: .utf8) else {
            throw AuthError.signInFailed("Apple ID token alınamadı")
        }
        
        do {
            let authResponse = try await client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idTokenString,
                    nonce: nonce
                )
            )
            return authResponse.user
        } catch {
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }
    
    private func performAppleSignIn(request: ASAuthorizationAppleIDRequest) async throws -> ASAuthorization {
        return try await withCheckedThrowingContinuation { continuation in
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AppleSignInContinuation(continuation: continuation)
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            controller.performRequests()
        }
    }
    
    /// Google ile giriş yapar
    /// - Returns: Giriş yapan kullanıcı bilgileri
    @MainActor
    func signInWithGoogle() async throws -> User? {
        // NOT: Google OAuth istemcisi bulunamadı hatası alıyorsanız, aşağıdaki adımları izleyin:
        // 1. Supabase Dashboard'a gidin
        // 2. Authentication -> Providers -> Google'ı etkinleştirin
        // 3. Google Cloud Console'dan Client ID ve Client Secret alın
        // 4. Bu bilgileri Supabase Dashboard'a ekleyin
        // 5. Authorized redirect URI olarak https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback ekleyin
        
        // Google OAuth URL'sini oluştur
        let redirectURL = URL(string: "\(SupabaseConfig.supabaseUrl)/auth/v1/callback")!
        let authURL = try await client.auth.getOAuthSignInURL(
            provider: .google,
            redirectTo: redirectURL
        )
        
        // URL'yi aç
        await UIApplication.shared.open(authURL)
        
        // Bu noktada kullanıcı tarayıcıda Google ile giriş yapacak
        // ve uygulama URL scheme ile geri çağrılacak
        // Bu işlemi AppDelegate veya SceneDelegate'de ele almanız gerekiyor
        
        // Şimdilik dummy bir hata fırlatalım
        throw AuthError.signInFailed("Google ile giriş yapma işlemi henüz tamamlanmadı. Lütfen URL callback işlemini AppDelegate veya SceneDelegate'de ele alın.")
    }
    
    /// Mevcut oturumu kapatır
    @MainActor
    func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch {
            throw AuthError.signOutFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Rastgele bir nonce string oluşturur
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
}

// MARK: - Auth Errors

enum AuthError: Error, LocalizedError {
    case signInFailed(String)
    case signOutFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .signInFailed(let message):
            return "Giriş yapılamadı: \(message)"
        case .signOutFailed(let message):
            return "Çıkış yapılamadı: \(message)"
        }
    }
}

// MARK: - Apple Sign In Continuation

class AppleSignInContinuation: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let continuation: CheckedContinuation<ASAuthorization, Error>
    
    init(continuation: CheckedContinuation<ASAuthorization, Error>) {
        self.continuation = continuation
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation.resume(returning: authorization)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
}

// MARK: - String Extension

extension String {
    var sha256: String {
        let data = Data(self.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
