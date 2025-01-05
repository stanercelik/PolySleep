import Foundation

// 1. Previous Sleep Experience
public enum PreviousSleepExperience: String, CaseIterable, Identifiable {
    case none = "No Experience"
    case some = "Tried Briefly"
    case moderate = "Several Months Experience"
    case extensive = "Long Term Experience"
    
    public var id: String { rawValue }
}

// 2. Age Range
public enum AgeRange: String, CaseIterable, Identifiable {
    case under18 = "Under 18"
    case age18to24 = "18-24"
    case age25to34 = "25-34"
    case age35to44 = "35-44"
    case age45to54 = "45-54"
    case age55Plus = "55+"
    
    public var id: String { rawValue }
}

// 3. Work Schedule
public enum WorkSchedule: String, CaseIterable, Identifiable {
    case flexible = "Flexible"
    case regular = "Regular"
    case shift = "Shift Work"
    case irregular = "Irregular"
    
    public var id: String { rawValue }
}

// 4. Nap Environment
public enum NapEnvironment: String, CaseIterable, Identifiable {
    case ideal = "Ideal"
    case suitable = "Suitable"
    case limited = "Limited"
    case unsuitable = "Unsuitable"
    
    public var id: String { rawValue }
}

// 5. Lifestyle
public enum Lifestyle: String, CaseIterable, Identifiable {
    case veryActive = "Very Active"
    case moderatelyActive = "Moderately Active"
    case calm = "Calm"
    
    public var id: String { rawValue }
}

// 6. Knowledge Level
public enum KnowledgeLevel: String, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    public var id: String { rawValue }
}

// 7. Health Status
public enum HealthStatus: String, CaseIterable, Identifiable {
    case healthy = "No Health Issues"
    case managedConditions = "Managed Conditions"
    case seriousConditions = "Serious Conditions"
    
    public var id: String { rawValue }
}

// 8. Motivation Level
public enum MotivationLevel: String, CaseIterable, Identifiable {
    case high = "High Motivation"
    case moderate = "Moderate Motivation"
    case low = "Low Motivation"
    
    public var id: String { rawValue }
}