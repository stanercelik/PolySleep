import Foundation
import Supabase
import AuthenticationServices
import UIKit
import CommonCrypto

/// Supabase kimlik doğrulama servisi
class SupabaseAuthService {
    // Singleton instance
    static let shared = SupabaseAuthService()
    
    // Supabase istemcisi referansı
    private var client: SupabaseClient {
        return SupabaseService.shared.client
    }
    
    // Private initializer for singleton pattern
    private init() {}
    
    /// Mevcut kullanıcıyı döndürür
    @MainActor
    public func getCurrentUser() async throws -> User? {
        return try await client.auth.session.user
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
            throw AuthError.signInFailed("Cannot find Apple ID")
        }
        
        // Kullanıcı bilgilerini al
        let fullName = [
            appleIDCredential.fullName?.givenName,
            appleIDCredential.fullName?.familyName
        ].compactMap { $0 }.joined(separator: " ")
        do {
            _ = try await client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idTokenString,
                    nonce: nonce
                )
            )
            
            // Kullanıcı adını ve sağlayıcı bilgisini metadata'ya ekle
            if !fullName.isEmpty {
                // Metadata'yı güncelleyelim
                var userData: [String: AnyJSON] = [:]
                userData["full_name"] = try AnyJSON(fullName)
                userData["provider"] = try AnyJSON("apple")
                
                // Kullanıcı bilgilerini güncelle
                _ = try await client.auth.update(user: UserAttributes(data: userData))
            } else {
                // Sadece provider bilgisini güncelleyelim
                var userData: [String: AnyJSON] = [:]
                userData["provider"] = try AnyJSON("apple")
                
                // Kullanıcı bilgilerini güncelle
                _ = try await client.auth.update(user: UserAttributes(data: userData))
            }
            
            // Güncellenmiş kullanıcı bilgilerini al
            let session = try await client.auth.session
            return session.user
        } catch {
            print("PolySleep Debug: Supabase ile giriş hatası: \(error.localizedDescription)")
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }
    
    /// Anonim giriş yapar
    /// - Returns: Giriş yapan kullanıcı bilgileri
    @MainActor
    func signInAnonymously() async throws -> User {
        // Daha önce anonim kullanıcı oluşturulmuş mu kontrol et
        let userDefaults = UserDefaults.standard
        let existingAnonymousUser = userDefaults.string(forKey: "anonymousUserId")

        if let existingAnonymousUser = existingAnonymousUser,
           let currentUser = try? await getCurrentUser(),
           currentUser.id.uuidString == existingAnonymousUser {

            try? await ensureUserInPublicTable(userId: currentUser.id)
            return currentUser
        }
        
        let response = try await client.auth.signInAnonymously()
        
        userDefaults.set(response.user.id.uuidString, forKey: "anonymousUserId")
        
        try await ensureUserInPublicTable(userId: response.user.id)
        
        return response.user
    }
    
    /// Kullanıcının public.users tablosunda kaydı olduğundan emin olur
    /// - Parameter userId: Kullanıcı ID'si
    @MainActor
    private func ensureUserInPublicTable(userId: UUID) async throws {
        // Kullanıcının public.users tablosunda kaydı var mı kontrol et
        let response: Void = try await client
            .from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .execute()
            .value
        
        // Kayıt yoksa oluştur
        if let rows = response as? [[String: Any]], rows.isEmpty {
            print("PolySleep Debug: Kullanıcı public.users tablosuna ekleniyor: \(userId.uuidString)")
            try await client
                .from("users")
                .insert([
                    "id": userId.uuidString,
                    "created_at": ISO8601DateFormatter().string(from: Date()),
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .execute()
            print("PolySleep Debug: Kullanıcı public.users tablosuna eklendi")
        }
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
    
    // MARK: - Apple Sign In Helper Methods
    
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

// MARK: - Apple Sign In Continuation

/// Apple oturum açma işlemi için continuation sınıfı
class AppleSignInContinuation: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let continuation: CheckedContinuation<ASAuthorization, Error>
    private var isResumeCalled = false
    
    init(continuation: CheckedContinuation<ASAuthorization, Error>) {
        self.continuation = continuation
        self.isResumeCalled = false
        super.init()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("PolySleep Debug: didCompleteWithAuthorization çağrıldı")
        guard !isResumeCalled else { return }
        isResumeCalled = true
        continuation.resume(returning: authorization)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("PolySleep Debug: didCompleteWithError çağrıldı: \(error.localizedDescription)")
        guard !isResumeCalled else { return }
        isResumeCalled = true
        if let error = error as? ASAuthorizationError {
            continuation.resume(throwing: AuthError.signInFailed("ASAuthorization Error: \(error.localizedDescription)"))
        } else {
            continuation.resume(throwing: error)
        }
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        print("PolySleep Debug: presentationAnchor çağrıldı")
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("Window yok")
        }
        return window
    }
}

/// Apple auth için associated key
private enum AssociatedKeys {
    static var delegateKey = "AppleSignInDelegate"
}
