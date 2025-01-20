import Foundation

// 1. Previous Sleep Experience
public enum PreviousSleepExperience: String, CaseIterable, Identifiable, LocalizableEnum {
    case none = "none"
    case some = "some"
    case moderate = "moderate"
    case extensive = "extensive"
    
    public var id: String { rawValue }
    
    public var localizedKey: String {
        "onboarding.sleepExperience.\(rawValue)"
    }
}

// 2. Age Range
public enum AgeRange: String, CaseIterable, Identifiable, LocalizableEnum {
    case under18 = "under18"
    case age18to24 = "18to24"
    case age25to34 = "25to34"
    case age35to44 = "35to44"
    case age45to54 = "45to54"
    case age55Plus = "55plus"
    
    public var id: String { rawValue }
    
    public var localizedKey: String {
        "onboarding.ageRange.\(rawValue)"
    }
}

// 3. Work Schedule
public enum WorkSchedule: String, CaseIterable, Identifiable, LocalizableEnum {
    case flexible = "flexible"
    case regular = "regular"
    case shift = "shift"
    case irregular = "irregular"
    
    public var id: String { rawValue }
    
    public var localizedKey: String {
        "onboarding.workSchedule.\(rawValue)"
    }
}

// 4. Nap Environment
public enum NapEnvironment: String, CaseIterable, Identifiable, LocalizableEnum {
    case ideal = "ideal"
    case suitable = "suitable"
    case limited = "limited"
    case unsuitable = "unsuitable"
    
    public var id: String { rawValue }
    
    public var localizedKey: String {
        "onboarding.napEnvironment.\(rawValue)"
    }
}

// 5. Lifestyle
public enum Lifestyle: String, CaseIterable, Identifiable, LocalizableEnum {
    case veryActive = "veryActive"
    case moderatelyActive = "moderatelyActive"
    case calm = "calm"
    
    public var id: String { rawValue }
    
    public var localizedKey: String {
        "onboarding.lifestyle.\(rawValue)"
    }
}

// 6. Knowledge Level
public enum KnowledgeLevel: String, CaseIterable, Identifiable, LocalizableEnum {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    
    public var id: String { rawValue }
    
    public var localizedKey: String {
        "onboarding.knowledgeLevel.\(rawValue)"
    }
}

// 7. Health Status
public enum HealthStatus: String, CaseIterable, Identifiable, LocalizableEnum {
    case healthy = "healthy"
    case managedConditions = "managedConditions"
    case seriousConditions = "seriousConditions"
    
    public var id: String { rawValue }
    
    public var localizedKey: String {
        "onboarding.healthStatus.\(rawValue)"
    }
}

// 8. Motivation Level
public enum MotivationLevel: String, CaseIterable, Identifiable, LocalizableEnum {
    case high = "high"
    case moderate = "moderate"
    case low = "low"
    
    public var id: String { rawValue }
    
    public var localizedKey: String {
        "onboarding.motivationLevel.\(rawValue)"
    }
}

// 9. Sleep Goal
public enum SleepGoal: String, CaseIterable, Identifiable, LocalizableEnum {
    case moreProductivity = "moreProductivity"
    case balancedLifestyle = "balancedLifestyle"
    case improveHealth = "improveHealth"
    case curiosity = "curiosity"
    
    public var id: String { rawValue }
    
    public var localizedKey: String {
        // örn: "onboarding.sleepGoal.moreProductivity"
        "onboarding.sleepGoal.\(rawValue)"
    }
}

// 10. Social Obligations
public enum SocialObligations: String, CaseIterable, Identifiable, LocalizableEnum {
    case significant = "significant"
    case moderate = "moderate"
    case minimal = "minimal"
    
    public var id: String { rawValue }
    
    public var localizedKey: String {
        "onboarding.socialObligations.\(rawValue)"
    }
}

// 11. DisruptionTolerance
public enum DisruptionTolerance: String, CaseIterable, Identifiable, LocalizableEnum {
    case verySensitive = "verySensitive"
    case somewhatSensitive = "somewhatSensitive"
    case notSensitive = "notSensitive"
    
    public var id: String { rawValue }
    
    public var localizedKey: String {
        "onboarding.disruptionTolerance.\(rawValue)"
    }
}

// 12. Chronotype
public enum Chronotype: String, CaseIterable, Identifiable, LocalizableEnum {
    case morningLark = "morningLark"
    case nightOwl = "nightOwl"
    case neutral = "neutral"
    
    public var id: String { rawValue }
    
    public var localizedKey: String {
        "onboarding.chronotype.\(rawValue)"
    }
    
}
