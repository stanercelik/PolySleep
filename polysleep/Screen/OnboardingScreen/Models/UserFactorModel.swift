import Foundation
import SwiftData
import SwiftUI

// MARK: - Dependencies
@_exported import struct Supabase.User

@Model
final class UserFactor {
    // MARK: - Onboarding Error
    enum OnboardingError: Error, LocalizedError {
        case userNotFound
        case scheduleNotFound
        
        var errorDescription: String? {
            switch self {
            case .userNotFound:
                return "Kullanıcı bulunamadı"
            case .scheduleNotFound:
                return "Program bulunamadı"
            }
        }
    }
    
    // MARK: - Properties
    var sleepExperience: String
    var ageRange: String
    var workSchedule: String
    var napEnvironment: String
    var lifestyle: String
    var knowledgeLevel: String
    var healthStatus: String
    var motivationLevel: String
    var createdAt: Date
    var sleepGoal: String
    var socialObligations: String
    var disruptionTolerance: String
    var chronotype: String
    
    // MARK: - Initialization
    init(
        sleepExperience: PreviousSleepExperience,
        ageRange: AgeRange,
        workSchedule: WorkSchedule,
        napEnvironment: NapEnvironment,
        lifestyle: Lifestyle,
        knowledgeLevel: KnowledgeLevel,
        healthStatus: HealthStatus,
        motivationLevel: MotivationLevel,
        sleepGoal: SleepGoal,
        socialObligations: SocialObligations,
        disruptionTolerance: DisruptionTolerance,
        chronotype: Chronotype 
    ) {
        self.sleepExperience = sleepExperience.rawValue
        self.ageRange = ageRange.rawValue
        self.workSchedule = workSchedule.rawValue
        self.napEnvironment = napEnvironment.rawValue
        self.lifestyle = lifestyle.rawValue
        self.knowledgeLevel = knowledgeLevel.rawValue
        self.healthStatus = healthStatus.rawValue
        self.motivationLevel = motivationLevel.rawValue
        self.sleepGoal = sleepGoal.rawValue
        self.socialObligations = socialObligations.rawValue
        self.disruptionTolerance = disruptionTolerance.rawValue
        self.chronotype = chronotype.rawValue
        self.createdAt = Date()
    }
    
    // MARK: - Convenience getters (String -> Enum)
    var sleepExperienceEnum: PreviousSleepExperience? {
        PreviousSleepExperience(rawValue: sleepExperience)
    }
    
    var ageRangeEnum: AgeRange? {
        AgeRange(rawValue: ageRange)
    }
    
    var workScheduleEnum: WorkSchedule? {
        WorkSchedule(rawValue: workSchedule)
    }
    
    var napEnvironmentEnum: NapEnvironment? {
        NapEnvironment(rawValue: napEnvironment)
    }
    
    var lifestyleEnum: Lifestyle? {
        Lifestyle(rawValue: lifestyle)
    }
    
    var knowledgeLevelEnum: KnowledgeLevel? {
        KnowledgeLevel(rawValue: knowledgeLevel)
    }
    
    var healthStatusEnum: HealthStatus? {
        HealthStatus(rawValue: healthStatus)
    }
    
    var motivationLevelEnum: MotivationLevel? {
        MotivationLevel(rawValue: motivationLevel)
    }

    var sleepGoalEnum: SleepGoal? {
        SleepGoal(rawValue: sleepGoal)
    }
    
    var socialObligationsEnum: SocialObligations? {
        SocialObligations(rawValue: socialObligations)
    }
    
    var disruptionToleranceEnum: DisruptionTolerance? {
        DisruptionTolerance(rawValue: disruptionTolerance)
    }
    
    var chronotypeEnum: Chronotype? {
        Chronotype(rawValue: chronotype)
    }
    
    // MARK: - Schedule Management
    func saveSelectedSchedule(templateId: String) async throws {
        guard let userId = AuthManager.shared.currentUser?.id else {
            throw OnboardingError.userNotFound
        }
        
        // SleepScheduleRecommender kullanarak programı oluştur
        let recommender = SleepScheduleRecommender()
        guard let schedule = recommender.getScheduleById(templateId) else {
            throw OnboardingError.scheduleNotFound
        }
        
        // Programı Supabase'e kaydet
        _ = try await SupabaseScheduleService.shared.saveRecommendedSchedule(
            schedule: schedule,
            adaptationPeriod: 0
        )
    }
}
