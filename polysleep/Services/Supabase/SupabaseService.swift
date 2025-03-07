import Foundation
import Supabase
import AuthenticationServices
import UIKit
import CommonCrypto

/// Supabase servisi için hata tipleri
enum SupabaseError: Error {
    case userNotFound
    case syncFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .userNotFound:
            return "Kullanıcı bulunamadı"
        case .syncFailed(let message):
            return "Senkronizasyon hatası: \(message)"
        }
    }
}

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
    public func getCurrentUser() async throws -> User? {
        return try await client.auth.session.user
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
           let currentUser = try? await getCurrentUser(),
           currentUser.id.uuidString == existingAnonymousUser {
            
            // Bu kullanıcı için public.users tablosunda kayıt var mı kontrol et
            // ve yoksa oluştur
            try? await ensureUserInPublicTable(userId: currentUser.id)
            return currentUser
        }
        
        // Yeni anonim kullanıcı oluştur
        let response = try await client.auth.signInAnonymously()
        
        // Kullanıcı ID'sini kaydet
        userDefaults.set(response.user.id.uuidString, forKey: "anonymousUserId")
        
        // Kullanıcıyı public.users tablosuna ekle
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
    
    // MARK: - Onboarding Methods
    
    /// Kullanıcının onboarding cevaplarını Supabase'e senkronize eder
    /// - Parameter answers: Kullanıcının cevapları
    /// - Returns: Başarılı olup olmadığı
    @MainActor
    func syncOnboardingAnswersToSupabase(answers: [OnboardingAnswer]) async throws -> Bool {
        // Mevcut kullanıcı bilgisini al
        guard let user = try await getCurrentUser() else {
            print("PolySleep Debug: Kullanıcı bulunamadı, onboarding cevapları senkronize edilemiyor")
            throw SupabaseError.userNotFound
        }
        
        var success = true
        
        // Her bir cevap için kaydetme işlemi yap
        for answer in answers {
            do {
                _ = try await saveOnboardingAnswer(userId: user.id.uuidString, onboardingAnswer: answer)
            } catch {
                print("PolySleep Debug: Onboarding cevabı senkronize edilemedi: \(error.localizedDescription)")
                success = false
            }
        }
        
        return success
    }
    
    /// Bir onboarding cevabını Supabase'e kaydeder
    /// - Parameters:
    ///   - userId: Kullanıcı ID'si
    ///   - answer: Onboarding cevabı
    /// - Returns: Sunucudan gelen cevap
    @MainActor
    private func saveOnboardingAnswer(userId: String, onboardingAnswer: OnboardingAnswer) async throws -> PostgrestResponse<Void> {
        let dto = OnboardingAnswerDTO(
            id: onboardingAnswer.id.uuidString,
            user_id: userId,
            question: onboardingAnswer.question,
            answer: onboardingAnswer.answer,
            date: ISO8601DateFormatter().string(from: onboardingAnswer.date)
        )
        
        // Önce bu soru için mevcut bir kayıt var mı kontrol edelim
        // Supabase LIKE yerine ILIKE kullanarak case-insensitive arama yapar
        let response: Void = try await client
            .from("onboarding_answers")
            .select()
            .eq("user_id", value: userId)
            .like("question", pattern: onboardingAnswer.question)
            .execute()
            .value
        
        // Yanıtı kontrol et
        if let rows = response as? [[String: Any]], !rows.isEmpty {
            // Mevcut kayıt var, güncelle
            print("PolySleep Debug: Mevcut onboarding cevabı güncelleniyor")
            if let existingId = rows.first?["id"] as? String {
                return try await client
                    .from("onboarding_answers")
                    .update(dto)
                    .eq("id", value: existingId)
                    .execute()
            }
        }
        
        // Yeni kayıt oluştur
        print("PolySleep Debug: Yeni onboarding cevabı kaydediliyor")
        return try await client
            .from("onboarding_answers")
            .insert(dto)
            .execute()
    }
    
    /// Onboarding cevaplarını Supabase'den getirir
    /// - Returns: Kullanıcının onboarding cevapları
    @MainActor
    func getOnboardingAnswers() async throws -> [OnboardingAnswerDTO] {
        // Mevcut kullanıcı bilgisini al
        guard let user = try await getCurrentUser() else {
            print("PolySleep Debug: Kullanıcı bulunamadı, onboarding cevapları alınamıyor")
            throw SupabaseError.userNotFound
        }
        
        do {
            let response: Void = try await client
                .from("onboarding_answers")
                .select()
                .eq("user_id", value: user.id.uuidString)
                .order("date", ascending: false)
                .execute()
                .value
            
            let decoder = JSONDecoder()
            let jsonData = try JSONSerialization.data(withJSONObject: response, options: [])
            return try decoder.decode([OnboardingAnswerDTO].self, from: jsonData)
        } catch {
            print("PolySleep Debug: Onboarding cevapları alınamadı: \(error.localizedDescription)")
            throw SupabaseError.syncFailed(error.localizedDescription)
        }
    }
    
    /// Kullanıcının bir onboarding sorusuna verdiği en son cevabı alır
    /// - Parameter question: Sorunun değeri (örn. "onboarding.sleepExperience")
    /// - Returns: Soruya verilen cevap
    @MainActor
    func getOnboardingAnswer(for question: String) async throws -> String? {
        // Mevcut kullanıcı bilgisini al
        guard let user = try await getCurrentUser() else {
            print("PolySleep Debug: Kullanıcı bulunamadı, onboarding cevabı alınamıyor")
            throw SupabaseError.userNotFound
        }
        
        print("PolySleep Debug: '\(question)' sorusu için cevap aranıyor...")
        
        do {
            let response: Void = try await client
                .from("onboarding_answers")
                .select()
                .eq("user_id", value: user.id.uuidString)
                .eq("question", value: question)
                .order("date", ascending: false)
                .limit(1)
                .execute()
                .value
            
            if let rows = response as? [[String: Any]], !rows.isEmpty,
               let answer = rows.first?["answer"] as? String {
                print("PolySleep Debug: '\(question)' sorusu için cevap bulundu: \(answer)")
                return answer
            } else {
                print("PolySleep Debug: '\(question)' sorusu için cevap bulunamadı")
                return nil
            }
        } catch {
            print("PolySleep Debug: Onboarding cevabı alınamadı: \(error.localizedDescription)")
            throw SupabaseError.syncFailed(error.localizedDescription)
        }
    }
    
    /// Tüm onboarding cevaplarını answer değerleriyle birlikte getirir
    /// - Returns: Cevaplar dictionary formatında (soru: cevap)
    @MainActor
    func getAllOnboardingAnswersRaw() async throws -> [String: String] {
        // Mevcut kullanıcı bilgisini al
        guard let user = try await getCurrentUser() else {
            print("PolySleep Debug: Kullanıcı bulunamadı, onboarding cevapları alınamıyor")
            throw SupabaseError.userNotFound
        }
        
        // Kullanıcı ID'sini küçük harfe çeviriyoruz
        let userId = user.id.uuidString.lowercased()
        print("PolySleep Debug: Kullanıcı ID: \(userId)")
        
        do {
            print("PolySleep Debug: Dokümentasyona göre güncellenmiş sorgu metodu kullanılıyor...")
            
            // Onboarding cevapları için decodable model
            struct OnboardingAnswerDTO: Decodable {
                let question: String
                let answer: String
                let date: String // Cevap tarihi
            }
            
            // Supabase dokümantasyonuna göre decode edilebilir veri çekimi
            let onboardingAnswers: [OnboardingAnswerDTO] = try await client
                .from("onboarding_answers")
                .select("question, answer, date")
                .eq("user_id", value: userId)
                .order("date", ascending: false)
                .execute()
                .value
            
            print("PolySleep Debug: Decode edilmiş yanıt alındı, eleman sayısı: \(onboardingAnswers.count)")
            
            // Aynı oturumdaki cevapları gruplamak için:
            // 1. Önce tüm cevapları tarihe göre grupla
            // (Bir oturumda yapılan onboarding cevapları aynı tarih/saat'e sahip olacak veya çok yakın olacak)
            var answersByDate: [String: [OnboardingAnswerDTO]] = [:]
            
            // En son oturumu bulmak için
            var latestSessionDate: String? = nil
            
            // Tüm cevapları tarihe göre grupla
            for answer in onboardingAnswers {
                // Eğer ilk işlenen cevapsa, bu en son cevap oturumunun tarihidir
                if latestSessionDate == nil {
                    latestSessionDate = answer.date
                }
                
                // Tarihi dakika hassasiyetine indir (saniye kısmını sil)
                let dateMinute = String(answer.date.prefix(16)) // "2025-03-07T23:41" formatına getir
                
                if answersByDate[dateMinute] != nil {
                    answersByDate[dateMinute]!.append(answer)
                } else {
                    answersByDate[dateMinute] = [answer]
                }
            }
            
            // En çok soru yanıtlanan oturumu bul (en son tam onboarding oturumu)
            var mostCompleteSessionKey = ""
            var maxAnswerCount = 0
            
            for (dateKey, answers) in answersByDate {
                if answers.count > maxAnswerCount {
                    maxAnswerCount = answers.count
                    mostCompleteSessionKey = dateKey
                }
            }
            
            print("PolySleep Debug: En son tam oturum tarihi: \(mostCompleteSessionKey), soru sayısı: \(maxAnswerCount)")
            
            // Dictionary formatına çevirme - sadece en son tam oturumdaki cevapları kullan
            var result: [String: String] = [:]
            
            if let latestSessionAnswers = answersByDate[mostCompleteSessionKey] {
                for answer in latestSessionAnswers {
                    result[answer.question] = answer.answer
                    print("PolySleep Debug: Eklendi - Soru: \(answer.question), Cevap: \(answer.answer)")
                }
            } else {
                // Tam bir oturum bulunamazsa en son cevapları kullan
                for answer in onboardingAnswers {
                    if !result.keys.contains(answer.question) {
                        result[answer.question] = answer.answer
                        print("PolySleep Debug: Eklendi - Soru: \(answer.question), Cevap: \(answer.answer)")
                    }
                }
            }
            
            print("PolySleep Debug: Standart sorgu sonucu: \(result)")
            return result
            
        } catch {
            print("PolySleep Debug: Onboarding cevapları alınamadı: \(error.localizedDescription)")
            print("PolySleep Debug: Hata detayı: \(error)")
            throw SupabaseError.syncFailed(error.localizedDescription)
        }
    }
    
    /// Hata ayıklama için onboarding answer raw değerlerini yazdırır
    @MainActor
    func testGetAllOnboardingAnswersRaw() async throws {
        do {
            let results = try await getAllOnboardingAnswersRaw()
            print("\n=== Test: getAllOnboardingAnswersRaw ===")
            print("Sonuç sayısı: \(results.count)")
            for (key, value) in results {
                print("\(key): \(value)")
            }
            print("=== Test Tamamlandı ===\n")
        } catch {
            print("\n=== Test Hatası: getAllOnboardingAnswersRaw ===")
            print("Hata: \(error.localizedDescription)")
            print("=== Test Tamamlandı ===\n")
        }
    }
    
    /// Önerilen uyku programını Supabase'e kaydeder
    /// - Parameters:
    ///   - schedule: Kaydedilecek uyku programı
    ///   - adaptationPeriod: Adaptasyon süresi (gün cinsinden)
    /// - Returns: İşlemin başarılı olup olmadığı
    @MainActor
    func saveRecommendedSchedule(
        schedule: SleepScheduleModel,
        adaptationPeriod: Int
    ) async throws -> Bool {
        // Mevcut kullanıcı bilgisini al
        guard let user = try await getCurrentUser() else {
            print("PolySleep Debug: Kullanıcı bulunamadı, önerilen program kaydedilemiyor")
            throw SupabaseError.userNotFound
        }
        
        // Uyku bloklarını JSON formatına dönüştür
        let encoder = JSONEncoder()
        let scheduleJSON = try encoder.encode(schedule.schedule)
        let scheduleString = String(data: scheduleJSON, encoding: .utf8) ?? "{}"
        
        do {
            // Önce mevcut aktif programı pasif yap
            try await client
                .from("schedules")
                .update(["is_active": false])
                .eq("user_id", value: user.id.uuidString)
                .eq("is_active", value: true)
                .execute()
            
            // Yeni programı JSON string olarak kaydet
            let query = """
            INSERT INTO schedules (
                user_id, schedule_id, name, description_en, description_tr, 
                total_sleep_hours, schedule, is_customized, adaptation_phase, 
                is_active, sync_id
            ) VALUES (
                '\(user.id.uuidString)',
                '\(schedule.id)',
                '\(schedule.name)',
                '\(schedule.description.en)',
                '\(schedule.description.tr)',
                \(schedule.totalSleepHours),
                '\(scheduleString)'::jsonb,
                false,
                \(adaptationPeriod),
                true,
                '\(UUID().uuidString)'
            )
            """
            
            try await client.rpc("execute_sql", params: ["sql": query]).execute()
            
            return true
        } catch {
            print("PolySleep Debug: Önerilen program kaydedilemedi: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Onboarding DTO
struct OnboardingAnswerDTO: Codable {
    let id: String
    let user_id: String
    let question: String
    let answer: String
    let date: String
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
