import SwiftUI

class SleepScheduleViewModel: ObservableObject {
    @Published var schedule: SleepScheduleModel
    @Published private(set) var recommendedSchedule: SleepScheduleModel?
    @Published private(set) var defaultSchedule: SleepScheduleModel
    
    let adaptationPeriod: Int = 14
    private let recommender = SleepScheduleRecommender()
    
    init() {
        // Initialize with default monophasic schedule
        let coreBlock = SleepBlock(
            startTime: "23:00",
            duration: 480, // 8 hours
            type: "core",
            isCore: true
        )
        
        let monophasicSchedule = SleepScheduleModel(
            id: "monophasic",
            name: "Monophasic",
            description: LocalizedDescription(en: "Traditional single sleep period during the night",
                                              tr: "Geleneksel tek parça gece uykusu"),
            totalSleepHours: 8.0,
            schedule: [coreBlock]
        )
        
        self.defaultSchedule = monophasicSchedule
        self.schedule = monophasicSchedule
        
        // Debug: Test recommendations with different settings
        testRecommendations()
    }
    
    // Debug function to test recommendations with different settings
    private func testRecommendations() {
        print("\n=== Testing Sleep Schedule Recommendations ===")
        
        // Set UserDefaults for testing
        let defaults = UserDefaults.standard
        
        // Aşağıdaki örnek değerleri istediğiniz gibi güncelleyin
        defaults.set("extensive", forKey: "onboarding.sleepExperience")
        defaults.set("age25to34", forKey: "onboarding.ageRange")
        defaults.set("flexible", forKey: "onboarding.workSchedule")
        defaults.set("ideal", forKey: "onboarding.napEnvironment")
        defaults.set("moderatelyActive", forKey: "onboarding.lifestyle")
        defaults.set("advanced", forKey: "onboarding.knowledgeLevel")
        defaults.set("healthy", forKey: "onboarding.healthStatus")
        defaults.set("high", forKey: "onboarding.motivationLevel")
        
        // Get recommendation with these settings
        if let recommendation = recommender.recommendSchedule() {
            print("\nRecommended Schedule: \(recommendation.schedule.name)")
            print("Confidence Score: \(recommendation.confidenceScore)")
            print("Adaptation Period: \(recommendation.adaptationPeriod) days")
            
            if !recommendation.warnings.isEmpty {
                print("\nWarnings:")
                recommendation.warnings.forEach { warning in
                    print("- [\(warning.severity)]: \(warning.messageKey)")
                }
            }
        }
        
        print("\n=== End of Test ===\n")
    }
    
    // Call this function after onboarding is complete
    func updateRecommendations() {
        print("\n=== Getting Sleep Schedule Recommendations ===")
        
        // Print current UserDefaults values
        let defaults = UserDefaults.standard
        print("\nCurrent User Settings:")
        print("Sleep Experience: \(defaults.string(forKey: "onboarding.sleepExperience") ?? "not set")")
        print("Age Range: \(defaults.string(forKey: "onboarding.ageRange") ?? "not set")")
        print("Work Schedule: \(defaults.string(forKey: "onboarding.workSchedule") ?? "not set")")
        print("Nap Environment: \(defaults.string(forKey: "onboarding.napEnvironment") ?? "not set")")
        print("Lifestyle: \(defaults.string(forKey: "onboarding.lifestyle") ?? "not set")")
        print("Knowledge Level: \(defaults.string(forKey: "onboarding.knowledgeLevel") ?? "not set")")
        print("Health Status: \(defaults.string(forKey: "onboarding.healthStatus") ?? "not set")")
        print("Motivation Level: \(defaults.string(forKey: "onboarding.motivationLevel") ?? "not set")")
        
        // Get recommendation based on user settings
        if let recommendation = recommender.recommendSchedule() {
            print("\nRecommended Schedule: \(recommendation.schedule.name)")
            print("Confidence Score: \(recommendation.confidenceScore)")
            print("Adaptation Period: \(recommendation.adaptationPeriod) days")
            
            if !recommendation.warnings.isEmpty {
                print("\nWarnings:")
                recommendation.warnings.forEach { warning in
                    print("- [\(warning.severity)]: \(warning.messageKey)")
                }
            }
            
            self.recommendedSchedule = recommendation.schedule
            self.schedule = recommendation.schedule
        } else {
            print("\nNo recommendation available, using default schedule")
            self.schedule = defaultSchedule
        }
        
        print("\n=== End of Recommendations ===\n")
    }
    
    func updateToRecommendedSchedule() {
        if let recommended = recommendedSchedule {
            schedule = recommended
        }
    }
    
    func shareSchedule() {
        let scheduleText = """
        Sleep Schedule: \(schedule.name)
        Total Sleep: \(schedule.totalSleepHours) hours
        
        Schedule Details:
        \(schedule.schedule.map { "• \($0.startTime) - \(String(format: "%02d:00", $0.endHour)) (\($0.type))" }.joined(separator: "\n"))
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [scheduleText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
