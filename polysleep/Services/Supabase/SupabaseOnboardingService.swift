import Foundation
import Supabase

/// Onboarding işlemleri için servis sınıfı
class SupabaseOnboardingService {
    // Singleton instance
    static let shared = SupabaseOnboardingService()
    
    // Supabase istemcisi referansı
    private var client: SupabaseClient {
        return SupabaseService.shared.client
    }
    
    // Auth servisi referansı
    private var authService: SupabaseAuthService {
        return SupabaseAuthService.shared
    }
    
    // Private initializer for singleton pattern
    private init() {}
    
    /// Kullanıcının onboarding cevaplarını Supabase'e senkronize eder
    /// - Parameter answers: Kullanıcının cevapları
    /// - Returns: Başarılı olup olmadığı
    @MainActor
    func syncOnboardingAnswersToSupabase(answers: [OnboardingAnswer]) async throws -> Bool {
        // Mevcut kullanıcı bilgisini al
        guard let user = try await authService.getCurrentUser() else {
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
    
    @MainActor
    private func saveOnboardingAnswer(userId: String, onboardingAnswer: OnboardingAnswer) async throws -> PostgrestResponse<Void> {
        let dto = OnboardingAnswerDTO(
            id: onboardingAnswer.id.uuidString,
            user_id: userId,
            question: onboardingAnswer.question,
            answer: onboardingAnswer.answer,
            date: ISO8601DateFormatter().string(from: onboardingAnswer.date)
        )
        
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
            if let existingId = rows.first?["id"] as? String {
                return try await client
                    .from("onboarding_answers")
                    .update(dto)
                    .eq("id", value: existingId)
                    .execute()
            }
        }
        
        // Yeni kayıt oluştur
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
        guard let user = try await authService.getCurrentUser() else {
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
        guard let user = try await authService.getCurrentUser() else {
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
        guard let user = try await authService.getCurrentUser() else {
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
    ///   - recommendation: Önerilen uyku programı
    /// - Returns: İşlemin başarılı olup olmadığı
    @MainActor
    func saveRecommendedSchedule(recommendation: SleepScheduleRecommendation) async throws -> Bool {
        return try await SupabaseScheduleService.shared.saveRecommendedSchedule(
            schedule: recommendation.schedule,
            adaptationPeriod: recommendation.adaptationPeriod
        )
    }
}
