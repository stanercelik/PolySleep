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
        print("PolySleep Debug: SupabaseService.signInWithApple başladı")
        let nonce = randomNonceString()
        print("PolySleep Debug: Nonce oluşturuldu: \(nonce)")
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email, .fullName]
        request.nonce = nonce.sha256
        print("PolySleep Debug: Apple ID isteği oluşturuldu, nonce.sha256: \(nonce.sha256)")
        
        print("PolySleep Debug: performAppleSignIn çağrılıyor")
        let authResult = try await performAppleSignIn(request: request)
        print("PolySleep Debug: performAppleSignIn tamamlandı")
        
        guard let appleIDCredential = authResult.credential as? ASAuthorizationAppleIDCredential,
              let idToken = appleIDCredential.identityToken,
              let idTokenString = String(data: idToken, encoding: .utf8) else {
            print("PolySleep Debug: Apple ID token alınamadı")
            throw AuthError.signInFailed("Apple ID token alınamadı")
        }
        
        // Kullanıcı bilgilerini al
        let fullName = [
            appleIDCredential.fullName?.givenName,
            appleIDCredential.fullName?.familyName
        ].compactMap { $0 }.joined(separator: " ")
        
        print("PolySleep Debug: Apple ID token alındı, Supabase'e gönderiliyor")
        do {
            _ = try await client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idTokenString,
                    nonce: nonce
                )
            )
            print("PolySleep Debug: Supabase ile giriş başarılı")
            
            // Kullanıcı adını ve sağlayıcı bilgisini metadata'ya ekle
            if !fullName.isEmpty {
                // Metadata'yı güncelleyelim
                var userData: [String: AnyJSON] = [:]
                userData["full_name"] = try AnyJSON(fullName)
                userData["provider"] = try AnyJSON("apple")
                
                // Kullanıcı bilgilerini güncelle
                _ = try await client.auth.update(user: UserAttributes(data: userData))
                print("PolySleep Debug: Kullanıcı bilgileri güncellendi: \(fullName)")
            } else {
                // Sadece provider bilgisini güncelleyelim
                var userData: [String: AnyJSON] = [:]
                userData["provider"] = try AnyJSON("apple")
                
                // Kullanıcı bilgilerini güncelle
                _ = try await client.auth.update(user: UserAttributes(data: userData))
                print("PolySleep Debug: Sadece sağlayıcı bilgisi güncellendi")
            }
            
            // Güncellenmiş kullanıcı bilgilerini al
            let session = try await client.auth.session
            return session.user
        } catch {
            print("PolySleep Debug: Supabase ile giriş hatası: \(error.localizedDescription)")
            throw AuthError.signInFailed(error.localizedDescription)
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
    
    /// Anonim giriş yapar
    /// - Returns: Giriş yapan kullanıcı bilgileri
    @MainActor
    func signInAnonymously() async throws -> User {
        // Daha önce anonim kullanıcı oluşturulmuş mu kontrol et
        let userDefaults = UserDefaults.standard
        let existingAnonymousUser = userDefaults.string(forKey: "anonymousUserId")
        
        // Eğer daha önce bir anonim kullanıcı oluşturulmuşsa ve hala aktifse, 
        // mevcut oturumu kullan
        if let existingAnonymousUser = existingAnonymousUser,
           let currentUser = try? await client.auth.session.user,
           currentUser.id.uuidString == existingAnonymousUser {
            return currentUser
        }
        
        // Yeni anonim kullanıcı oluştur
        let response = try await client.auth.signInAnonymously()
        
        // Kullanıcı ID'sini kaydet
        userDefaults.set(response.user.id.uuidString, forKey: "anonymousUserId")
        
        return response.user
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
    
    private func performAppleSignIn(request: ASAuthorizationAppleIDRequest) async throws -> ASAuthorization {
        print("PolySleep Debug: performAppleSignIn başladı")
        return try await withCheckedThrowingContinuation { continuation in
            print("PolySleep Debug: withCheckedThrowingContinuation içinde")
            let controller = ASAuthorizationController(authorizationRequests: [request])
            // Delegate'i strong reference olarak tutuyoruz ki, işlem tamamlanana kadar yaşasın
            let delegate = AppleSignInContinuation(continuation: continuation)
            print("PolySleep Debug: AppleSignInContinuation oluşturuldu")
            
            // Delegate'i controller'a bağlamadan önce objemizi bir değişkende saklayalım
            // Bu şekilde ARC tarafından deallocate edilmesini önlüyoruz
            objc_setAssociatedObject(controller, &AssociatedKeys.delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN)
            
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            print("PolySleep Debug: performRequests çağrılıyor")
            controller.performRequests()
            print("PolySleep Debug: performRequests çağrıldı")
        }
    }
}

// MARK: - Associated Keys
private struct AssociatedKeys {
    static var delegateKey = "AppleSignInDelegateKey"
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
    private var isResumeCalled = false
    
    init(continuation: CheckedContinuation<ASAuthorization, Error>) {
        print("PolySleep Debug: AppleSignInContinuation init")
        self.continuation = continuation
        self.isResumeCalled = false
        super.init()
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        print("PolySleep Debug: presentationAnchor çağrıldı")
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("PolySleep Debug: didCompleteWithAuthorization çağrıldı")
        guard !isResumeCalled else {
            print("PolySleep Debug: HATA - continuation zaten resume edilmiş!")
            return
        }
        
        isResumeCalled = true
        continuation.resume(returning: authorization)
        print("PolySleep Debug: continuation.resume(returning:) çağrıldı")
        
        // Delegate referansını temizleyelim
        objc_setAssociatedObject(controller, &AssociatedKeys.delegateKey, nil, .OBJC_ASSOCIATION_RETAIN)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("PolySleep Debug: didCompleteWithError çağrıldı: \(error.localizedDescription)")
        guard !isResumeCalled else {
            print("PolySleep Debug: HATA - continuation zaten resume edilmiş!")
            return
        }
        
        isResumeCalled = true
        continuation.resume(throwing: error)
        print("PolySleep Debug: continuation.resume(throwing:) çağrıldı")
        
        // Delegate referansını temizleyelim
        objc_setAssociatedObject(controller, &AssociatedKeys.delegateKey, nil, .OBJC_ASSOCIATION_RETAIN)
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
