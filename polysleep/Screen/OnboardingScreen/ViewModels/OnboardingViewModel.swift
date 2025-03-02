import SwiftUI
import SwiftData

@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let recommender: SleepScheduleRecommender
    
    // MARK: - Published Properties
    @Published var currentPage = 0
    let totalPages = 12
    @Published var shouldNavigateToSleepSchedule = false
    @Published var showStartButton = false
    
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
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.recommender = SleepScheduleRecommender(modelContext: modelContext)
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
            saveUserPreferences()
            showStartButton = true
        }
    }
    
    func movePrevious() {
        if currentPage > 0 {
            currentPage -= 1
        }
    }
    
    // MARK: - Saving
    func saveUserPreferences() {
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
        
        // Delete previous user factor and answers
        do {
            let factorDescriptor = FetchDescriptor<UserFactor>()
            let existingFactors = try modelContext.fetch(factorDescriptor)
            print("\nFound \(existingFactors.count) existing user factors in DB. Deleting them...")
            
            for factor in existingFactors {
                modelContext.delete(factor)
            }
            
            let answerDescriptor = FetchDescriptor<OnboardingAnswer>()
            let existingAnswers = try modelContext.fetch(answerDescriptor)
            print("\nFound \(existingAnswers.count) existing answers in DB. Deleting them...")
            
            for answer in existingAnswers {
                modelContext.delete(answer)
            }
            
            if !existingFactors.isEmpty || !existingAnswers.isEmpty {
                print("Deleted \(existingFactors.count) existing user factors and \(existingAnswers.count) answers")
            }
        } catch {
            print("❌ Error deleting existing data: \(error)")
        }
        
        // Save onboarding answers
        let answers: [(String, String, String)] = [
            ("onboarding.sleepExperience", sleepExperience.localizedKey, sleepExperience.rawValue),
            ("onboarding.ageRange", ageRange.localizedKey, ageRange.rawValue),
            ("onboarding.workSchedule", workSchedule.localizedKey, workSchedule.rawValue),
            ("onboarding.napEnvironment", napEnvironment.localizedKey, napEnvironment.rawValue),
            ("onboarding.lifestyle", lifestyle.localizedKey, lifestyle.rawValue),
            ("onboarding.knowledgeLevel", knowledgeLevel.localizedKey, knowledgeLevel.rawValue),
            ("onboarding.healthStatus", healthStatus.localizedKey, healthStatus.rawValue),
            ("onboarding.motivationLevel", motivationLevel.localizedKey, motivationLevel.rawValue),
            ("onboarding.sleepGoal", sleepGoal.localizedKey, sleepGoal.rawValue),
            ("onboarding.socialObligations", socialObligations.localizedKey, socialObligations.rawValue),
            ("onboarding.disruptionTolerance", disruptionTolerance.localizedKey, disruptionTolerance.rawValue),
            ("onboarding.chronotype", chronotype.localizedKey, chronotype.rawValue)
        ]
        
        for (title, question, answer) in answers {
            let onboardingAnswer = OnboardingAnswer(
                question: NSLocalizedString(title, tableName: "Onboarding", comment: ""),
                answer: NSLocalizedString(question, tableName: "Onboarding", comment: ""),
                rawAnswer: answer
            )
            modelContext.insert(onboardingAnswer)
        }
        
        // Create a new userfactor and save it
        let userFactor = UserFactor(
            sleepExperience: sleepExperience,
            ageRange: ageRange,
            workSchedule: workSchedule,
            napEnvironment: napEnvironment,
            lifestyle: lifestyle,
            knowledgeLevel: knowledgeLevel,
            healthStatus: healthStatus,
            motivationLevel: motivationLevel,
            sleepGoal: sleepGoal,
            socialObligations: socialObligations,
            disruptionTolerance: disruptionTolerance,
            chronotype: chronotype
        )
        
        modelContext.insert(userFactor)
        
        do {
            try modelContext.save()
            print("✅ Successfully saved user factor and onboarding answers")
            
            // Get recommended schedule
            if let recommendation = recommender.recommendSchedule() {
                print("\n=== Recommended Schedule ===")
                print("Name: \(recommendation.schedule.name)")
                print("Confidence Score: \(recommendation.confidenceScore)")
                print("Adaptation Period: \(recommendation.adaptationPeriod) days")
                
                // Save schedule to SwiftData
                let scheduleStore = SleepScheduleStore(
                    scheduleId: recommendation.schedule.id,
                    name: recommendation.schedule.name,
                    totalSleepHours: recommendation.schedule.totalSleepHours,
                    schedule: recommendation.schedule.schedule
                )
                
                modelContext.insert(scheduleStore)
                try modelContext.save()
                print("✅ Successfully saved recommended schedule")
                
                // Show any warnings
                if !recommendation.warnings.isEmpty {
                    print("\nWarnings:")
                    for warning in recommendation.warnings {
                        print("- [\(warning.severity)] \(warning.messageKey)")
                    }
                }
            }
            
            shouldNavigateToSleepSchedule = true
        } catch {
            print("❌ Error saving data: \(error)")
        }
    }
    
    func startUsingApp() {
        shouldNavigateToSleepSchedule = true
    }
}
