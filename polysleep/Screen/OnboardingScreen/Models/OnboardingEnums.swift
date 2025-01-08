import Foundation

// 1. Previous Sleep Experience
public enum PreviousSleepExperience: String, CaseIterable, Identifiable {
    case none = "onboarding.sleepExperience.none"
    case some = "onboarding.sleepExperience.some"
    case moderate = "onboarding.sleepExperience.moderate"
    case extensive = "onboarding.sleepExperience.extensive"
    
    public var id: String { rawValue }
}

// 2. Age Range
public enum AgeRange: String, CaseIterable, Identifiable {
    case under18 = "onboarding.ageRange.under18"
    case age18to24 = "onboarding.ageRange.18to24"
    case age25to34 = "onboarding.ageRange.25to34"
    case age35to44 = "onboarding.ageRange.35to44"
    case age45to54 = "onboarding.ageRange.45to54"
    case age55Plus = "onboarding.ageRange.55plus"
    
    public var id: String { rawValue }
}

// 3. Work Schedule
public enum WorkSchedule: String, CaseIterable, Identifiable {
    case flexible = "onboarding.workSchedule.flexible"
    case regular = "onboarding.workSchedule.regular"
    case shift = "onboarding.workSchedule.shift"
    case irregular = "onboarding.workSchedule.irregular"
    
    public var id: String { rawValue }
}

// 4. Nap Environment
public enum NapEnvironment: String, CaseIterable, Identifiable {
    case ideal = "onboarding.napEnvironment.ideal"
    case suitable = "onboarding.napEnvironment.suitable"
    case limited = "onboarding.napEnvironment.limited"
    case unsuitable = "onboarding.napEnvironment.unsuitable"
    
    public var id: String { rawValue }
}

// 5. Lifestyle
public enum Lifestyle: String, CaseIterable, Identifiable {
    case veryActive = "onboarding.lifestyle.veryActive"
    case moderatelyActive = "onboarding.lifestyle.moderatelyActive"
    case calm = "onboarding.lifestyle.calm"
    
    public var id: String { rawValue }
}

// 6. Knowledge Level
public enum KnowledgeLevel: String, CaseIterable, Identifiable {
    case beginner = "onboarding.knowledgeLevel.beginner"
    case intermediate = "onboarding.knowledgeLevel.intermediate"
    case advanced = "onboarding.knowledgeLevel.advanced"
    
    public var id: String { rawValue }
}

// 7. Health Status
public enum HealthStatus: String, CaseIterable, Identifiable {
    case healthy = "onboarding.healthStatus.healthy"
    case managedConditions = "onboarding.healthStatus.managedConditions"
    case seriousConditions = "onboarding.healthStatus.seriousConditions"
    
    public var id: String { rawValue }
}

// 8. Motivation Level
public enum MotivationLevel: String, CaseIterable, Identifiable {
    case high = "onboarding.motivationLevel.high"
    case moderate = "onboarding.motivationLevel.moderate"
    case low = "onboarding.motivationLevel.low"
    
    public var id: String { rawValue }
}