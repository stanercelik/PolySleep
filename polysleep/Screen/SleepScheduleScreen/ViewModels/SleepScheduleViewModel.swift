import Foundation
import SwiftUI
import Combine

class SleepScheduleViewModel: ObservableObject {
    @Published private(set) var schedule: SleepScheduleModel
    @Published var currentQuality: Int = 0
    @Published var sleepAnalysis: String?
    @Published private(set) var warnings: [SleepScheduleRecommendation.Warning] = []
    @Published private(set) var adaptationPeriod: Int = 14
    @Published private(set) var confidenceScore: Double = 1.0
    
    private let userDefaults = UserDefaults.standard
    private let recommender = SleepScheduleRecommender()
    
    init() {
        // Initialize with a default schedule first
        self.schedule = SleepScheduleModel(
            id: "monophasic",
            name: "Monophasic",
            description: .init(
                en: "Traditional single sleep period during the night",
                tr: "Geleneksel tek parça gece uykusu"
            ),
            totalSleepHours: 8.0,
            schedule: [
                .init(type: "core", startTime: "23:00", duration: 480)
            ]
        )
        
        // Then load the recommended schedule
        loadRecommendedSchedule()
        updateSleepAnalysis()
    }
    
    private func loadRecommendedSchedule() {
        if let recommendation = recommender.recommendSchedule() {
            self.schedule = recommendation.schedule
            self.warnings = recommendation.warnings
            self.adaptationPeriod = recommendation.adaptationPeriod
            self.confidenceScore = recommendation.confidenceScore
        }
    }
    
    func updateSleepQuality(_ rating: Int) {
        currentQuality = rating
        updateSleepAnalysis()
    }
    
    private func determineRecommendedSchedule() -> String {
        let sleepExperience = userDefaults.integer(forKey: "onboarding.sleepExperience")
        let napEnvironment = userDefaults.bool(forKey: "onboarding.napEnvironment")
        let energyLevel = userDefaults.integer(forKey: "onboarding.energyLevel")
        
        // Conservative recommendation for beginners or those without nap environment
        if sleepExperience < 3 || !napEnvironment {
            return "monophasic"
        }
        
        // For experienced users with nap environment
        if sleepExperience >= 4 && napEnvironment {
            return energyLevel >= 4 ? "everyman" : "biphasic"
        }
        
        // Default to biphasic for moderate experience
        return "biphasic"
    }
    
    private func updateSleepAnalysis() {
        var analysis = [String]()
        
        if currentQuality > 0 {
            analysis.append(String(format: String(localized: "sleepSchedule.analysis.quality"), currentQuality))
        }
        
        analysis.append(String(format: String(localized: "sleepSchedule.analysis.schedule"), schedule.name))
        analysis.append(String(format: String(localized: "sleepSchedule.analysis.duration"), schedule.totalSleepHours))
        
        let napCount = schedule.schedule.filter { $0.type != "core" }.count
        if napCount > 0 {
            analysis.append(String(format: String(localized: "sleepSchedule.analysis.naps"), napCount))
        }
        
        analysis.append(String(format: String(localized: "sleepSchedule.analysis.adaptation"), adaptationPeriod))
        
        sleepAnalysis = analysis.joined(separator: "\n")
    }
}
