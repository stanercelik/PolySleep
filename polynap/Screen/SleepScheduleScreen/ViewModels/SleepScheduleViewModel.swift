import SwiftUI
import SwiftData

class SleepScheduleViewModel: ObservableObject {
    @Published var schedule: SleepScheduleModel
    @Published private(set) var recommendedSchedule: SleepScheduleModel?
    @Published private(set) var defaultSchedule: SleepScheduleModel
    
    private var recommender: SleepScheduleRecommender?
    private let analyticsManager = AnalyticsManager.shared
    
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
        self.recommender = SleepScheduleRecommender()
        Task {
            await updateRecommendations()
        }
    }
    
    func updateRecommendations() async {
        print("\n=== Getting Sleep Schedule Recommendations ===")
        
        guard let recommender = recommender else {
            print("No recommender available")
            return
        }
        
        do {
            guard let recommendation = try await recommender.recommendSchedule() else {
                print("No recommendation available, using default schedule")
                return
            }
            
            self.recommendedSchedule = recommendation.schedule
            
            // İsterseniz warnings'leri yazdırabilirsiniz
            for warning in recommendation.warnings {
                print("Warning (\(warning.severity)): \(warning.messageKey)")
            }
            
            print("Confidence Score: \(recommendation.confidenceScore)")
            print("Adaptation Period: \(recommendation.adaptationPeriod) days")
            
            // İsterseniz otomatik olarak schedule'ı güncelleyebilirsiniz:
            schedule = recommendation.schedule
        } catch {
            print("Error getting recommendations: \(error.localizedDescription)")
        }
    }
    
    func shareSchedule() {
        // TO-DO: Share function
    }
    
    func updateToRecommendedSchedule() {
        if let recommended = recommendedSchedule {
            let previousScheduleName = schedule.name
            schedule = recommended
            
            // 📊 Analytics: Schedule seçimi/değişikliği tracking
            if previousScheduleName != recommended.name {
                analyticsManager.logScheduleChanged(
                    fromSchedule: previousScheduleName,
                    toSchedule: recommended.name,
                    reason: "recommended_schedule_selected"
                )
            }
            
            analyticsManager.logScheduleSelected(
                scheduleName: recommended.name,
                difficulty: determineDifficultyLevel(recommended)
            )
        }
    }
    
    // 📊 Analytics: Schedule zorluk seviyesi belirleme helper
    private func determineDifficultyLevel(_ schedule: SleepScheduleModel) -> String {
        switch schedule.name.lowercased() {
        case "monophasic", "siesta", "biphasic":
            return "easy"
        case "everyman", "triphasic":
            return "medium"
        case "uberman", "dymaxion":
            return "hard"
        default:
            return "unknown"
        }
    }
}
