import SwiftUI
import SwiftData

// Enum dönüşüm hatası için özel hata tipi
struct EnumConversionError: Error, LocalizedError {
    let enumType: String
    let value: String
    
    var errorDescription: String? {
        return "'\(value)' değeri '\(enumType)' enum tipine dönüştürülemedi."
    }
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Dependencies
    private let recommender: SleepScheduleRecommender
    
    // MARK: - Published Properties
    @Published var currentPage = 0
    let totalPages = 12
    @Published var shouldNavigateToSleepSchedule = false
    @Published var showStartButton = false
    @Published var isLoadingRecommendation = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    // Yükleme ekranı için yeni değişkenler
    @Published var recommendationProgress: Double = 0.0
    @Published var recommendationStatusMessage: String = ""
    @Published var recommendationComplete: Bool = false
    @Published var showLoadingView: Bool = false
    @Published var navigateToMainScreen: Bool = false
    
    // Ana ekrana geçiş için NavigationLink değişkeni
    @Published var goToMainScreen: Bool = false
    
    // User selections
    @Published var previousSleepExperience: PreviousSleepExperience?
    @Published var ageRange: AgeRange?
    @Published var workSchedule: WorkSchedule?
    @Published var napEnvironment: NapEnvironment?
    @Published var lifestyle: Lifestyle?
    @Published var knowledgeLevel: KnowledgeLevel?
    @Published var healthStatus: HealthStatus?
    @Published var motivationLevel: MotivationLevel?
    @Published var sleepGoal: SleepGoal?
    @Published var socialObligations: SocialObligations?
    @Published var disruptionTolerance: DisruptionTolerance?
    @Published var chronotype: Chronotype?
    
    // MARK: - Initialization
    init() {
        self.recommender = SleepScheduleRecommender()
    }
    
    // Geriye dönük uyumluluk için eski başlatıcıyı da saklıyoruz
    @available(*, deprecated, message: "SwiftData kullanımı kaldırıldı, boş başlatıcıyı kullanın")
    init(modelContext: ModelContext) {
        self.recommender = SleepScheduleRecommender()
    }
    
    // MARK: - Computed Properties
    var canMoveNext: Bool {
        switch currentPage {
        case 0: return previousSleepExperience != nil
        case 1: return ageRange != nil
        case 2: return workSchedule != nil
        case 3: return napEnvironment != nil
        case 4: return lifestyle != nil
        case 5: return knowledgeLevel != nil
        case 6: return healthStatus != nil
        case 7: return motivationLevel != nil
        case 8: return sleepGoal != nil
        case 9: return socialObligations != nil
        case 10: return disruptionTolerance != nil
        case 11: return chronotype != nil
        default: return false
        }
    }
    
    // MARK: - Methods
    func moveNext() {
        if currentPage < totalPages - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            Task {
                await startRecommendationProcess()
            }
        }
    }
    
    func movePrevious() {
        if currentPage > 0 {
            currentPage -= 1
        }
    }
    
    // MARK: - Recommendation Process
    func startRecommendationProcess() async {
        showLoadingView = true
        recommendationProgress = 0.0
        recommendationStatusMessage = "Bilgiler alınıyor..."
        recommendationComplete = false
        
        // Bilgileri kaydet
        await saveUserPreferences()
    }
    
    // MARK: - Saving
    func saveUserPreferences() async {
        print("\n=== Saving User Preferences ===")
        
        guard let sleepExperience = previousSleepExperience,
              let ageRange = ageRange,
              let workSchedule = workSchedule,
              let napEnvironment = napEnvironment,
              let lifestyle = lifestyle,
              let knowledgeLevel = knowledgeLevel,
              let healthStatus = healthStatus,
              let motivationLevel = motivationLevel,
              let sleepGoal = sleepGoal,
              let socialObligations = socialObligations,
              let disruptionTolerance = disruptionTolerance,
              let chronotype = chronotype
        else {
            print("❌ Error: Some user preferences are not set")
            await showErrorMessage("Bazı tercihler belirlenmemiş. Lütfen tüm soruları yanıtlayın.")
            return
        }
        
        updateProgress(0.15, "Tercihleriniz kaydediliyor...")
        
        print("\nSaving values:")
        print("- Sleep Experience: \(sleepExperience.rawValue)")
        print("- Age Range: \(ageRange.rawValue)")
        print("- Work Schedule: \(workSchedule.rawValue)")
        print("- Nap Environment: \(napEnvironment.rawValue)")
        print("- Lifestyle: \(lifestyle.rawValue)")
        print("- Knowledge Level: \(knowledgeLevel.rawValue)")
        print("- Health Status: \(healthStatus.rawValue)")
        print("- Motivation Level: \(motivationLevel.rawValue)")
        print("- Sleep Goal: \(sleepGoal.rawValue)")
        print("- Social Obligations: \(socialObligations.rawValue)")
        print("- Disruption Tolerance: \(disruptionTolerance.rawValue)")
        print("- Chronotype: \(chronotype.rawValue)")
        
        // Supabase'e kaydet
        // Onboarding cevaplarını hazırla
        let answers: [(String, String)] = [
            ("onboarding.sleepExperience", sleepExperience.rawValue),
            ("onboarding.ageRange", ageRange.rawValue),
            ("onboarding.workSchedule", workSchedule.rawValue),
            ("onboarding.napEnvironment", napEnvironment.rawValue),
            ("onboarding.lifestyle", lifestyle.rawValue),
            ("onboarding.knowledgeLevel", knowledgeLevel.rawValue),
            ("onboarding.healthStatus", healthStatus.rawValue),
            ("onboarding.motivationLevel", motivationLevel.rawValue),
            ("onboarding.sleepGoal", sleepGoal.rawValue),
            ("onboarding.socialObligations", socialObligations.rawValue),
            ("onboarding.disruptionTolerance", disruptionTolerance.rawValue),
            ("onboarding.chronotype", chronotype.rawValue)
        ]
        
        var savedAnswers: [OnboardingAnswer] = []
        
        for (question, answer) in answers {
            let onboardingAnswer = OnboardingAnswer(
                question: question,
                answer: answer
            )
            savedAnswers.append(onboardingAnswer)
        }
        
        updateProgress(0.30, "Veriler senkronize ediliyor...")
        
        // Supabase'e senkronize et
        do {
            let success = try await SupabaseOnboardingService.shared.syncOnboardingAnswersToSupabase(answers: savedAnswers)
            if success {
                print("✅ Successfully synced onboarding answers to Supabase")
                updateProgress(0.45, "Uyku programınız hesaplanıyor...")
                // Recommend Schedule kısmında async/await kullanmak için
                await getRecommendedSchedule()
            } else {
                print("⚠️ Some onboarding answers failed to sync with Supabase")
                await showErrorMessage("Bazı tercihler kaydedilemedi. Lütfen internet bağlantınızı kontrol edin.")
            }
        } catch {
            print("❌ Error syncing onboarding answers to Supabase: \(error.localizedDescription)")
            await showErrorMessage("Tercihler kaydedilemedi: \(error.localizedDescription)")
        }
    }
    
    private func showErrorMessage(_ message: String) async {
        await MainActor.run {
            errorMessage = message
            showError = true
            showLoadingView = false
        }
    }
    
    private func updateProgress(_ targetProgress: Double, _ message: String) {
        // Animasyon için başlangıç değeri
        let startProgress = recommendationProgress
        let totalSteps = 20
        let animationDuration = 1.0 // Toplam animasyon süresi (saniye)
        
        for step in 0...totalSteps {
            let delayForStep = animationDuration * Double(step) / Double(totalSteps)
            let progressForStep = startProgress + (targetProgress - startProgress) * Double(step) / Double(totalSteps)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delayForStep) {
                withAnimation(.easeInOut(duration: animationDuration / Double(totalSteps))) {
                    self.recommendationProgress = progressForStep
                    
                    // Sadece son adımda mesajı güncelle
                    if step == totalSteps {
                        self.recommendationStatusMessage = message
                    }
                }
            }
        }
    }
    
    func getRecommendedSchedule() async {
        updateProgress(0.6, "Programınız analiz ediliyor...")
        
        // Yapay bir gecikme ekleyelim ki kullanıcı hesaplamanın yapıldığını görsün
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 saniye
        
        updateProgress(0.75, "Çok az kaldı...")
        
        do {
            if let recommendation = try await recommender.recommendSchedule() {
                print("\n=== Recommended Schedule ===")
                print("Name: \(recommendation.schedule.name)")
                print("Confidence Score: \(recommendation.confidenceScore)")
                
                // Yapay bir gecikme ekleyelim ki kullanıcı hesaplamanın yapıldığını görsün
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 saniye
                
                updateProgress(0.9, "Programınız kaydediliyor...")
                
                // Önerilen programı schedules tablosuna kaydet
                let success = try await SupabaseScheduleService.shared.saveRecommendedSchedule(
                    schedule: recommendation.schedule,
                    adaptationPeriod: recommendation.adaptationPeriod
                )
                
                if success {
                    print("✅ Successfully saved recommended schedule to Supabase")
                    
                    // Yapay bir gecikme ekleyelim ki kullanıcı hesaplamanın yapıldığını görsün
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 saniye
                    
                    updateProgress(1.0, "Hazır!")
                    recommendationComplete = true
                } else {
                    print("⚠️ Failed to save recommended schedule to Supabase")
                    
                    // Hata olsa bile kullanıcıya yükleme tamamlandı gösterelim
                    handleErrorButContinue("Veriler kaydedilemedi ancak yine de devam edebilirsiniz.")
                }
            } else {
                print("❌ Failed to get recommendation")
                
                // Önerilen program oluşturulamasa bile kullanıcıya yükleme tamamlandı gösterelim
                handleErrorButContinue("Varsayılan program oluşturuldu.")
            }
        } catch let error as EnumConversionError {
            print("❌ Enum conversion error: \(error.localizedDescription)")
            handleErrorButContinue("Verileriniz işlenirken bir sorun oluştu, varsayılan program oluşturuldu.")
        } catch {
            print("❌ Error getting recommendation: \(error.localizedDescription)")
            handleErrorButContinue("Beklenmeyen bir hata oluştu, varsayılan program oluşturuldu.")
        }
    }
    
    // Hata durumlarında yükleme ekranını tamamlamak için yardımcı fonksiyon
    private func handleErrorButContinue(_ message: String) {
        // Bir uyarı göster ama yine de yükleme animasyonunu tamamla
        updateProgress(0.9, message)
        
        // 1 saniye sonra tamamlanmış olarak göster
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                self.recommendationProgress = 1.0
                self.recommendationStatusMessage = "Hazır!"
                self.recommendationComplete = true
            }
        }
    }
    
    func startUsingApp() {
        // Ana ekrana geçmeden önce Onboarding tamamlandı bildirimini gönder
        NotificationCenter.default.post(name: NSNotification.Name("OnboardingCompleted"), object: nil)
        
        // Ana ekrana geçiş yap
        navigateToMainScreen = true
    }
    
    // Ana ekrana geçiş işlemini yönetir
    func handleNavigationToMainScreen() {
        // FullScreenCover'ı kapattıktan sonra NavigationLink ile ana ekrana geçiş yapar
        withAnimation {
            goToMainScreen = true
        }
    }
}
