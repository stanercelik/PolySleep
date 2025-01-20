import SwiftUI
import SwiftData

class SleepScheduleViewModel: ObservableObject {
    @Published var schedule: SleepScheduleModel
    @Published private(set) var recommendedSchedule: SleepScheduleModel?
    @Published private(set) var defaultSchedule: SleepScheduleModel
    
    private var recommender: SleepScheduleRecommender?
    
    init() {
        // Monophasic varsayılan
        let coreBlock = SleepBlock(
            startTime: "23:00",
            duration: 480,
            type: "core",
            isCore: true
        )
        
        let monophasicSchedule = SleepScheduleModel(
            id: "monophasic",
            name: "Monophasic",
            description: LocalizedDescription(
                en: "Traditional single sleep period during the night",
                tr: "Geleneksel tek parça gece uykusu"
            ),
            totalSleepHours: 8.0,
            schedule: [coreBlock]
        )
        
        self.defaultSchedule = monophasicSchedule
        self.schedule = monophasicSchedule
    }
    
    func setModelContext(_ context: ModelContext) {
        self.recommender = SleepScheduleRecommender(modelContext: context)
        updateRecommendations()
    }
    
    func updateRecommendations() {
        print("\n=== Getting Sleep Schedule Recommendations ===")
        
        guard let recommender = recommender,
              let recommendation = recommender.recommendSchedule()
        else {
            print("No recommendation available, using default schedule")
            return
        }
        
        self.recommendedSchedule = recommendation.schedule
        
        // İsterseniz warnings’leri yazdırabilirsiniz
        for warning in recommendation.warnings {
            print("Warning (\(warning.severity)): \(warning.messageKey)")
        }
        
        print("Confidence Score: \(recommendation.confidenceScore)")
        print("Adaptation Period: \(recommendation.adaptationPeriod) days")
        
        // İsterseniz otomatik olarak schedule'ı güncelleyebilirsiniz:
        schedule = recommendation.schedule
    }
    
    func shareSchedule() {
        let scheduleText = """
        Sleep Schedule: \(schedule.name)
        Total Sleep: \(schedule.totalSleepHours) hours
        
        Schedule Details:
        \(schedule.schedule.map {
            "• \($0.startTime) - \($0.endTime) (\($0.type))"
        }.joined(separator: "\n"))
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [scheduleText],
            applicationActivities: nil
        )
        
        // Sunum için:
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    func updateToRecommendedSchedule() {
        if let recommended = recommendedSchedule {
            schedule = recommended
        }
    }
}
