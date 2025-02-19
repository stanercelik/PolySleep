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
        
        // Delete previous user factor
        do {
            let descriptor = FetchDescriptor<UserFactor>()
            let existingFactors = try modelContext.fetch(descriptor)
            print("\nFound \(existingFactors.count) existing user factors in DB. Deleting them...")
            
            for factor in existingFactors {
                modelContext.delete(factor)
            }
            
            if !existingFactors.isEmpty {
                print("Deleted \(existingFactors.count) existing user factors")
            }
        } catch {
            print("❌ Error deleting existing user factors: \(error)")
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
            print("✅ Successfully saved user factor")
            
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
