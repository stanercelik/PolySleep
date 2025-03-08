import SwiftUI
import SwiftData

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
                await saveUserPreferences()
            }
            showStartButton = true
        }
    }
    
    func movePrevious() {
        if currentPage > 0 {
            currentPage -= 1
        }
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
        
        // Supabase'e senkronize et
        do {
            let success = try await SupabaseOnboardingService.shared.syncOnboardingAnswersToSupabase(answers: savedAnswers)
            if success {
                print("✅ Successfully synced onboarding answers to Supabase")
                
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
        }
    }
    
    func getRecommendedSchedule() async {
        await MainActor.run {
            isLoadingRecommendation = true
        }
        
        do {
            if let recommendation = try await recommender.recommendSchedule() {
                print("\n=== Recommended Schedule ===")
                print("Name: \(recommendation.schedule.name)")
                print("Confidence Score: \(recommendation.confidenceScore)")
                
                // Önerilen programı schedules tablosuna kaydet
                let success = try await SupabaseScheduleService.shared.saveRecommendedSchedule(
                    schedule: recommendation.schedule,
                    adaptationPeriod: recommendation.adaptationPeriod
                )
                
                if success {
                    print("✅ Successfully saved recommended schedule to Supabase")
                } else {
                    print("⚠️ Failed to save recommended schedule to Supabase")
                }
            } else {
                print("❌ Failed to get recommendation")
                await showErrorMessage("Uyku programı önerisi oluşturulamadı.")
            }
        } catch {
            print("❌ Error getting recommendation: \(error.localizedDescription)")
            await showErrorMessage("Uyku programı önerisi alınamadı: \(error.localizedDescription)")
        }
        
        await MainActor.run {
            isLoadingRecommendation = false
        }
    }
    
    func startUsingApp() {
        shouldNavigateToSleepSchedule = true
    }
}
