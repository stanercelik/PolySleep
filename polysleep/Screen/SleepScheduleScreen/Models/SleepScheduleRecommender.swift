import Foundation

struct SleepScheduleRecommendation {
    let schedule: SleepScheduleModel
    let confidenceScore: Double // between 0 and 1
    let warnings: [Warning]
    let adaptationPeriod: Int // in days
    
    struct Warning {
        let severity: Severity
        let messageKey: String
        
        enum Severity {
            case info
            case warning
            case critical
        }
    }
}

class SleepScheduleRecommender {
    private let userDefaults = UserDefaults.standard
    
    // Factors that influence schedule recommendation based on the 8 questions
    private struct UserFactors {
        let sleepExperience: PreviousSleepExperience
        let ageRange: AgeRange
        let workSchedule: WorkSchedule
        let napEnvironment: NapEnvironment
        let lifestyle: Lifestyle
        let knowledgeLevel: KnowledgeLevel
        let healthStatus: HealthStatus
        let motivationLevel: MotivationLevel
        
        init(from userDefaults: UserDefaults) {
            self.sleepExperience = PreviousSleepExperience(rawValue: userDefaults.string(forKey: "onboarding.sleepExperience") ?? "") ?? .none
            self.ageRange = AgeRange(rawValue: userDefaults.string(forKey: "onboarding.ageRange") ?? "") ?? .age25to34
            self.workSchedule = WorkSchedule(rawValue: userDefaults.string(forKey: "onboarding.workSchedule") ?? "") ?? .regular
            self.napEnvironment = NapEnvironment(rawValue: userDefaults.string(forKey: "onboarding.napEnvironment") ?? "") ?? .unsuitable
            self.lifestyle = Lifestyle(rawValue: userDefaults.string(forKey: "onboarding.lifestyle") ?? "") ?? .moderatelyActive
            self.knowledgeLevel = KnowledgeLevel(rawValue: userDefaults.string(forKey: "onboarding.knowledgeLevel") ?? "") ?? .beginner
            self.healthStatus = HealthStatus(rawValue: userDefaults.string(forKey: "onboarding.healthStatus") ?? "") ?? .healthy
            self.motivationLevel = MotivationLevel(rawValue: userDefaults.string(forKey: "onboarding.motivationLevel") ?? "") ?? .moderate
        }
    }
    
    func recommendSchedule() -> SleepScheduleRecommendation? {
        let factors = UserFactors(from: userDefaults)
        
        // Load available schedules
        guard let schedules = loadSleepSchedules() else { return nil }
        
        // Score each schedule based on user factors
        let scoredSchedules = schedules.map { schedule -> (SleepScheduleModel, Double) in
            let score = calculateScheduleScore(schedule, factors: factors)
            return (schedule, score)
        }
        
        // Get the highest scoring schedule
        guard let (bestSchedule, score) = scoredSchedules.max(by: { $0.1 < $1.1 }) else { return nil }
        
        // Generate warnings based on the selected schedule and user factors
        let warnings = generateWarnings(for: bestSchedule, factors: factors)
        
        // Calculate adaptation period
        let adaptationPeriod = calculateAdaptationPeriod(for: bestSchedule, factors: factors)
        
        return SleepScheduleRecommendation(
            schedule: bestSchedule,
            confidenceScore: score,
            warnings: warnings,
            adaptationPeriod: adaptationPeriod
        )
    }
    
    private func calculateScheduleScore(_ schedule: SleepScheduleModel, factors: UserFactors) -> Double {
        var score = 1.0
        
        // Base score adjustment based on schedule difficulty
        switch schedule.difficultyLevel {
        case .beginner:
            score *= 1.2  // Favor beginner-friendly schedules
        case .intermediate:
            score *= 1.0  // Neutral score
        case .advanced:
            score *= 0.8  // Slight penalty for advanced schedules
        case .extreme:
            score *= 0.6  // Significant penalty for extreme schedules
        }
        
        // 1. Previous Sleep Experience
        switch factors.sleepExperience {
        case .none:
            switch schedule.difficultyLevel {
            case .beginner: break
            case .intermediate: score *= 0.8
            case .advanced: score *= 0.5
            case .extreme: score *= 0.3
            }
        case .some:
            switch schedule.difficultyLevel {
            case .beginner, .intermediate: break
            case .advanced: score *= 0.7
            case .extreme: score *= 0.5
            }
        case .moderate:
            switch schedule.difficultyLevel {
            case .beginner, .intermediate, .advanced: break
            case .extreme: score *= 0.8
            }
        case .extensive:
            // No penalty for experienced users
            break
        }
        
        // 2. Age Range Considerations
        switch factors.ageRange {
        case .under18:
            score *= 0.7 // Generally not recommended for under 18
            if schedule.difficultyLevel == .extreme {
                score *= 0.5
            }
        case .age18to24, .age25to34:
            // Prime age for adaptation, no penalty
            break
        case .age35to44:
            if schedule.difficultyLevel == .extreme {
                score *= 0.8
            }
        case .age45to54:
            if schedule.difficultyLevel == .advanced || schedule.difficultyLevel == .extreme {
                score *= 0.7
            }
        case .age55Plus:
            if schedule.difficultyLevel == .advanced || schedule.difficultyLevel == .extreme {
                score *= 0.5
            }
        }
        
        // 3. Work Schedule Compatibility
        switch factors.workSchedule {
        case .flexible:
            // Ideal for any schedule
            score *= 1.2
        case .regular:
            if schedule.hasNapsInWorkHours {
                score *= 0.4
            }
        case .shift:
            score *= 0.7 // Any schedule is challenging with shift work
        case .irregular:
            score *= 0.6 // Irregular schedule makes consistency difficult
        }
        
        // 4. Nap Environment
        let napCount = schedule.schedule.filter { !$0.isCore }.count
        if napCount > 0 {
            switch factors.napEnvironment {
            case .ideal:
                // No penalty
                break
            case .suitable:
                score *= pow(0.9, Double(napCount))
            case .limited:
                score *= pow(0.7, Double(napCount))
            case .unsuitable:
                score *= pow(0.4, Double(napCount))
            }
        }
        
        // 5. Lifestyle Considerations
        switch factors.lifestyle {
        case .veryActive:
            switch schedule.difficultyLevel {
            case .beginner: break
            case .intermediate: score *= 0.9
            case .advanced, .extreme: score *= 0.7
            }
        case .moderatelyActive:
            switch schedule.difficultyLevel {
            case .beginner, .intermediate: break
            case .advanced: score *= 0.9
            case .extreme: score *= 0.8
            }
        case .calm:
            // No penalty for calm lifestyle
            break
        }
        
        // 6. Knowledge Level Impact
        switch factors.knowledgeLevel {
        case .beginner:
            switch schedule.difficultyLevel {
            case .beginner: break
            case .intermediate: score *= 0.8
            case .advanced: score *= 0.6
            case .extreme: score *= 0.4
            }
        case .intermediate:
            switch schedule.difficultyLevel {
            case .beginner, .intermediate: break
            case .advanced: score *= 0.8
            case .extreme: score *= 0.6
            }
        case .advanced:
            // No penalty for advanced users
            break
        }
        
        // 7. Health Status Considerations
        switch factors.healthStatus {
        case .healthy:
            // No penalty
            break
        case .managedConditions:
            switch schedule.difficultyLevel {
            case .beginner: break
            case .intermediate: score *= 0.8
            case .advanced: score *= 0.6
            case .extreme: score *= 0.4
            }
        case .seriousConditions:
            switch schedule.difficultyLevel {
            case .beginner: score *= 0.8
            case .intermediate: score *= 0.6
            case .advanced: score *= 0.4
            case .extreme: score *= 0.2
            }
        }
        
        // 8. Motivation Level Impact
        switch factors.motivationLevel {
        case .high:
            score *= 1.2 // Bonus for high motivation
        case .moderate:
            switch schedule.difficultyLevel {
            case .beginner, .intermediate: break
            case .advanced: score *= 0.8
            case .extreme: score *= 0.7
            }
        case .low:
            switch schedule.difficultyLevel {
            case .beginner: score *= 0.9
            case .intermediate: score *= 0.8
            case .advanced: score *= 0.6
            case .extreme: score *= 0.4
            }
        }
        
        return score
    }
    
    private func generateWarnings(for schedule: SleepScheduleModel, factors: UserFactors) -> [SleepScheduleRecommendation.Warning] {
        var warnings: [SleepScheduleRecommendation.Warning] = []
        
        // Health warnings
        if factors.healthStatus != .healthy {
            warnings.append(.init(
                severity: .critical,
                messageKey: "sleepSchedule.warning.healthStatus"
            ))
        }
        
        // Experience warnings
        if schedule.difficultyLevel == .extreme && factors.sleepExperience == .none {
            warnings.append(.init(
                severity: .warning,
                messageKey: "sleepSchedule.warning.noExperience"
            ))
        }
        
        // Nap environment warnings
        if schedule.schedule.filter({ !$0.isCore }).count > 0 && factors.napEnvironment == .unsuitable {
            warnings.append(.init(
                severity: .warning,
                messageKey: "sleepSchedule.warning.napEnvironment"
            ))
        }
        
        // Work schedule warnings
        if factors.workSchedule == .regular && schedule.hasNapsInWorkHours {
            warnings.append(.init(
                severity: .warning,
                messageKey: "sleepSchedule.warning.workSchedule"
            ))
        }
        
        // Motivation warnings
        if schedule.difficultyLevel == .extreme && factors.motivationLevel == .low {
            warnings.append(.init(
                severity: .warning,
                messageKey: "sleepSchedule.warning.lowMotivation"
            ))
        }
        
        return warnings
    }
    
    private func calculateAdaptationPeriod(for schedule: SleepScheduleModel, factors: UserFactors) -> Int {
        var basePeriod: Int
        
        // Base adaptation period based on schedule type
        if schedule.difficultyLevel == .extreme {
            basePeriod = 28 // 4 weeks for extreme schedules
        } else if schedule.schedule.filter({ !$0.isCore }).count > 2 {
            basePeriod = 21 // 3 weeks for schedules with many naps
        } else {
            basePeriod = 14 // 2 weeks for simpler schedules
        }
        
        // Adjust based on experience
        switch factors.sleepExperience {
        case .extensive:
            basePeriod = Int(Double(basePeriod) * 0.7)
        case .moderate:
            basePeriod = Int(Double(basePeriod) * 0.85)
        case .some:
            // No adjustment
            break
        case .none:
            basePeriod = Int(Double(basePeriod) * 1.3)
        }
        
        // Adjust based on motivation
        switch factors.motivationLevel {
        case .high:
            basePeriod = Int(Double(basePeriod) * 0.9)
        case .moderate:
            // No adjustment
            break
        case .low:
            basePeriod = Int(Double(basePeriod) * 1.2)
        }
        
        return basePeriod
    }
    
    private func loadSleepSchedules() -> [SleepScheduleModel]? {
        guard let url = Bundle.main.url(forResource: "SleepSchedules", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let response = try? JSONDecoder().decode(SleepSchedulesResponse.self, from: data) else {
            return nil
        }
        return response.sleepSchedules
    }
}

// Helper extensions for SleepScheduleModel
extension SleepScheduleModel {
    var isExtreme: Bool {
        // Consider a schedule extreme if:
        // 1. It's Dymaxion or Uberman
        // 2. Total sleep is less than 4.5 hours
        // 3. Has more than 3 naps
        return id == "dymaxion" || id == "uberman" ||
               totalSleepHours < 4.5 ||
               schedule.filter { !$0.isCore }.count > 3
    }
    
    var difficultyLevel: DifficultyLevel {
        if isExtreme {
            return .extreme
        } else if totalSleepHours < 6.0 || schedule.filter { !$0.isCore }.count > 2 {
            return .advanced
        } else if schedule.filter { !$0.isCore }.count > 1 {
            return .intermediate
        } else {
            return .beginner
        }
    }
    
    var hasNapsInWorkHours: Bool {
        return schedule.filter { !$0.isCore }.contains { block in
            if let time = TimeFormatter.time(from: block.startTime) {
                return time >= 9 && time <= 17
            }
            return false
        }
    }
}

enum DifficultyLevel {
    case beginner
    case intermediate
    case advanced
    case extreme
}

private enum TimeFormatter {
    static func time(from string: String) -> Int? {
        let components = string.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]) else {
            return nil
        }
        return hour
    }
}
