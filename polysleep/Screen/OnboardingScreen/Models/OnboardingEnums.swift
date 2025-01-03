import Foundation

public enum SleepQuality: String, CaseIterable, Identifiable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case veryPoor = "Very Poor"
    
    public var id: String { rawValue }
}

public enum SleepScheduleType: String, CaseIterable, Identifiable {
    case monophasic = "Monophasic"
    case biphasic = "Biphasic"
    case polyphasic = "Polyphasic"
    case flexible = "Flexible"
    
    public var id: String { rawValue }
}

public enum WorkSchedule: String, CaseIterable, Identifiable {
    case regular = "Regular (9-5)"
    case flexible = "Flexible Hours"
    case shift = "Shift Work"
    case remote = "Remote Work"
    case irregular = "Irregular Schedule"
    
    public var id: String { rawValue }
}

public enum Lifestyle: String, CaseIterable, Identifiable {
    case active = "Active"
    case moderate = "Moderate"
    case sedentary = "Sedentary"
    case athletic = "Athletic"
    case variable = "Variable"
    
    public var id: String { rawValue }
}

public enum SleepEnvironment: String, CaseIterable, Identifiable {
    case quiet = "Quiet"
    case noisy = "Noisy"
    case variable = "Variable"
    case controlled = "Controlled"
    
    public var id: String { rawValue }
}

public enum NapEnvironment: String, CaseIterable, Identifiable {
    case ideal = "Ideal"
    case suitable = "Suitable"
    case limited = "Limited"
    case unsuitable = "Unsuitable"
    
    public var id: String { rawValue }
}

public enum PreviousSleepExperience: String, CaseIterable, Identifiable {
    case none = "No Experience"
    case some = "Some Experience"
    case moderate = "Moderate Experience"
    case extensive = "Extensive Experience"
    
    public var id: String { rawValue }
}

public enum KnowledgeLevel: String, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
    
    public var id: String { rawValue }
}

public enum AgeRange: String, CaseIterable, Identifiable {
    case under18 = "Under 18"
    case age18to24 = "18-24"
    case age25to34 = "25-34"
    case age35to44 = "35-44"
    case age45to54 = "45-54"
    case age55Plus = "55+"
    
    public var id: String { rawValue }
}

public enum SleepDuration: String, CaseIterable, Identifiable {
    case lessThan4Hours = "Less than 4 hours"
    case hours4to6 = "4-6 hours"
    case hours6to8 = "6-8 hours"
    case moreThan8Hours = "More than 8 hours"
    
    public var id: String { rawValue }
}
