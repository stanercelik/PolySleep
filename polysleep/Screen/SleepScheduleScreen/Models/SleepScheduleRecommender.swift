import Foundation
import SwiftUI

// MARK: - SleepScheduleRecommendation Structure
public struct SleepScheduleRecommendation {
    let schedule: SleepScheduleModel
    let confidenceScore: Double // 0..1
    let warnings: [Warning]
    let adaptationPeriod: Int // days
    
    public struct Warning {
        let severity: Severity
        let messageKey: String
        
        public enum Severity {
            case info
            case warning
            case critical
        }
    }
}

// MARK: - SleepScheduleRecommender Service

final class SleepScheduleRecommender {
    private let userDefaults: UserDefaults
    
    // User factors struct for loading from UserDefaults
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
            self.sleepExperience = PreviousSleepExperience(
                rawValue: userDefaults.string(forKey: "onboarding.sleepExperience") ?? ""
            ) ?? .none
            
            self.ageRange = AgeRange(
                rawValue: userDefaults.string(forKey: "onboarding.ageRange") ?? ""
            ) ?? .age25to34
            
            self.workSchedule = WorkSchedule(
                rawValue: userDefaults.string(forKey: "onboarding.workSchedule") ?? ""
            ) ?? .regular
            
            self.napEnvironment = NapEnvironment(
                rawValue: userDefaults.string(forKey: "onboarding.napEnvironment") ?? ""
            ) ?? .unsuitable
            
            self.lifestyle = Lifestyle(
                rawValue: userDefaults.string(forKey: "onboarding.lifestyle") ?? ""
            ) ?? .moderatelyActive
            
            self.knowledgeLevel = KnowledgeLevel(
                rawValue: userDefaults.string(forKey: "onboarding.knowledgeLevel") ?? ""
            ) ?? .beginner
            
            self.healthStatus = HealthStatus(
                rawValue: userDefaults.string(forKey: "onboarding.healthStatus") ?? ""
            ) ?? .healthy
            
            self.motivationLevel = MotivationLevel(
                rawValue: userDefaults.string(forKey: "onboarding.motivationLevel") ?? ""
            ) ?? .moderate
        }
    }
    
    // MARK: - Init
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Public Method
    func recommendSchedule() -> SleepScheduleRecommendation? {
        print("\n=== Starting Sleep Schedule Recommendation ===")
        
        let factors = UserFactors(from: userDefaults)
        print("\nUser Factors loaded:")
        print("- Sleep Experience: \(factors.sleepExperience.rawValue)")
        print("- Age Range: \(factors.ageRange.rawValue)")
        print("- Work Schedule: \(factors.workSchedule.rawValue)")
        print("- Nap Environment: \(factors.napEnvironment.rawValue)")
        print("- Lifestyle: \(factors.lifestyle.rawValue)")
        print("- Knowledge Level: \(factors.knowledgeLevel.rawValue)")
        print("- Health Status: \(factors.healthStatus.rawValue)")
        print("- Motivation Level: \(factors.motivationLevel.rawValue)")
        
        guard let schedules = loadSleepSchedules() else {
            print("❌ Failed to load sleep schedules!")
            return nil
        }
        
        print("\nEvaluating \(schedules.count) sleep schedules...")
        
        var allScores: [(id: String, score: Double)] = []
        
        // Calculate score for each schedule
        let scoredSchedules = schedules.map { schedule -> (SleepScheduleModel, Double) in
            let score = calculateScheduleScore(schedule, factors: factors)
            allScores.append((schedule.id, score))
            return (schedule, score)
        }
        
        // Print scores in descending order
        print("\nAll Schedule Scores (sorted):")
        allScores.sorted { $0.score > $1.score }.forEach { score in
            print("\(score.id): \(String(format: "%.3f", score.score))")
        }
        
        // Select the schedule with the highest score
        guard let (bestSchedule, score) = scoredSchedules.max(by: { $0.1 < $1.1 }) else {
            print("❌ No valid schedule found!")
            return nil
        }
        
        print("\n✅ Best Schedule Selected:")
        print("- Schedule: \(bestSchedule.id)")
        print("- Score: \(String(format: "%.3f", score))")
        print("- Total Sleep: \(bestSchedule.totalSleepHours) hours")
        print("- Number of Naps: \(bestSchedule.schedule.filter { !$0.isCore }.count)")
        
        let warnings = generateWarnings(for: bestSchedule, factors: factors)
        if !warnings.isEmpty {
            print("\nWarnings Generated:")
            warnings.forEach { warning in
                print("- [\(warning.severity)]: \(warning.messageKey)")
            }
        }
        
        let adaptationPeriod = calculateAdaptationPeriod(for: bestSchedule, factors: factors)
        print("\nAdaptation Period: \(adaptationPeriod) days")
        
        print("\n=== Recommendation Complete ===\n")
        
        return SleepScheduleRecommendation(
            schedule: bestSchedule,
            confidenceScore: score,
            warnings: warnings,
            adaptationPeriod: adaptationPeriod
        )
    }
    
    /// Calculate the score for a given schedule
    private func calculateScheduleScore(_ schedule: SleepScheduleModel, factors: UserFactors) -> Double {
        var score = 1.0
        print("\n=== Calculating score for \(schedule.id) ===")
        print("Initial score: \(score)")
        
        let napCount = schedule.schedule.filter { !$0.isCore }.count
        print("Number of naps: \(napCount)")
        
        // 1. Initial scoring (daha belirgin ayrımlar)
        switch schedule.id {
        case "monophasic":
            // Geleneksel / basit => en düşük baz
            score = 0.6
            print("Base schedule initial score (monophasic): \(score)")
            
        case "segmented", "segmented-alt":
            // Orta seviye => biraz daha yüksek
            score = 0.7
            print("Base schedule initial score (segmented): \(score)")
            
        case "biphasic", "biphasic-extended":
            // Daha popüler/kolay çoklu => biraz daha yüksek
            score = 0.8
            print("Base schedule initial score (biphasic): \(score)")
            
        case "triphasic", "triphasic-alt":
            // Üç parçaya ayrılmış => biraz daha "ileri"
            score = 0.9
            print("Base schedule initial score (triphasic): \(score)")
            
        case "everyman", "everyman-e2", "everyman-e3", "everyman-e4":
            // Orta-ileri polifazik => yüksek baz
            score = 1.0
            print("Base schedule initial score (everyman): \(score)")
            
        case "dymaxion", "dymaxion-alt":
            // Daha ekstrem => bazda biraz daha düşük
            score = 0.5
            print("Base schedule initial score (dymaxion): \(score)")
            
        case "uberman":
            // En ekstrem => düşük baz
            score = 0.4
            print("Base schedule initial score (uberman): \(score)")
            
        default:
            print("Default schedule initial score: \(score)")
        }

        // 2. Experience-based adjustments
        switch factors.sleepExperience {
        case .none:
            // Yeni başlayanlar: fazla nap varsa biraz ceza
            if napCount > 1 {
                score *= 0.9
                print("Penalty for no experience with multiple naps: \(score)")
            }
        case .some:
            // Biraz denemiş, ama çok uzun sürmemiş
            if napCount > 2 {
                score *= 0.95
                print("Minor penalty for some experience with many naps: \(score)")
            }
        case .moderate:
            // Bir süre kullanmış
            if napCount >= 2 {
                score *= 1.1
                print("Bonus for moderate experience with multiple naps: \(score)")
            }
        case .extensive:
            // Uzun süre kullanmış
            // Naps = multiple => +%20
            if napCount >= 2 {
                score *= 1.2
                print("Major bonus for extensive experience with multiple naps: \(score)")
            }
        }

        // 3. Knowledge level + schedule complexity
        switch schedule.id {
        case "uberman", "dymaxion", "dymaxion-alt":
            // Bu planlar çok ekstrem; advanced knowledge + high motivation varsa büyük bonus
            if factors.knowledgeLevel == .advanced && factors.motivationLevel == .high {
                score *= 1.5  // Yüksek bonus
                print("Extreme schedule with advanced knowledge & high motivation: \(score)")
            } else {
                // Yoksa bir miktar ceza
                score *= 0.8
                print("Penalty for extreme schedule without advanced knowledge: \(score)")
            }
            
        case "everyman", "everyman-e2", "everyman-e3", "everyman-e4":
            // Knowledge seviyesi advanced değilse çok hafif ceza
            if factors.knowledgeLevel != .advanced {
                score *= 0.9
                print("Slight penalty for Everyman if not advanced knowledge: \(score)")
            }
            
        case "triphasic", "triphasic-alt":
            // Intermediate veya advanced ise hafif bonus
            if factors.knowledgeLevel == .advanced || factors.knowledgeLevel == .intermediate {
                score *= 1.1
                print("Triphasic knowledge bonus: \(score)")
            }
            
        default:
            // Monophasic, biphasic, segmented gibi planlar
            // Knowledge level farkı büyük etki etmesin
            print("No specific knowledge adjustment for this schedule type.")
        }

        // 4. Environment and schedule compatibility
        if napCount > 0 {
            // Daha çok nap => environment önemli
            switch factors.napEnvironment {
            case .ideal:
                score *= 1.2
                print("Ideal nap environment bonus: \(score)")
            case .suitable:
                score *= 1.1
                print("Suitable nap environment bonus: \(score)")
            case .unsuitable:
                score *= 0.85
                print("Unsuitable nap environment penalty: \(score)")
            case .limited:
                score *= 0.9
                print("Limited nap environment penalty: \(score)")
            }
        } else {
            // Nap yok (monophasic, segmented, vb.)
            // Ortamın etkisi az
            print("No naps => environment less critical here.")
        }

        // 5. Work schedule compatibility
        switch factors.workSchedule {
        case .flexible:
            // Flexible + naps => büyük bonus
            if napCount > 1 {
                score *= 1.3
                print("Flexible schedule big bonus for multiple naps: \(score)")
            } else if napCount == 1 {
                score *= 1.1
                print("Flexible schedule minor bonus for single nap: \(score)")
            }
        case .irregular:
            // Irregular => bazen polyphasic işleyebilir
            if napCount >= 3 {
                score *= 1.1
                print("Irregular schedule minor bonus for many naps: \(score)")
            }
        case .regular:
            // Regular => multiple naps ceza
            if napCount > 1 {
                score *= 0.85
                print("Regular work schedule penalty for multiple naps: \(score)")
            }
        case .shift:
            // Shift => polyphasic bazen avantajlı
            if napCount > 0 {
                score *= 1.1
                print("Shift work schedule bonus for naps: \(score)")
            }
        }

        // 6. Polyphasic suitability (yaş + lifestyle)
        let suitability = calculatePolyphasicSuitability(for: schedule, napCount: napCount, factors: factors)
        score *= suitability
        print("Polyphasic suitability: \(suitability), New score: \(score)")
        
        // 7. Knowledge adjustment (daha genel)
        let knowledgeScore = calculateKnowledgeAdjustment(napCount: napCount, level: factors.knowledgeLevel)
        score *= knowledgeScore
        print("Knowledge adjustment: \(knowledgeScore), New score: \(score)")
        
        // 8. Motivation adjustment
        let motivationScore = calculateMotivationAdjustment(napCount: napCount, level: factors.motivationLevel)
        score *= motivationScore
        print("Motivation adjustment: \(motivationScore), New score: \(score)")
        
        // 9. Nap environment quality (second pass, if schedule has naps)
        if napCount > 0 {
            let envScore = calculateNapEnvironmentScore(environment: factors.napEnvironment)
            score *= envScore
            print("Nap environment second pass: \(envScore), New score: \(score)")
        }
        
        // 10. Penalty for NO naps if environment is good (some subtle effect)
        if napCount == 0 {
            switch factors.napEnvironment {
            case .ideal:
                score *= 0.95
                print("Penalty for no naps despite ideal environment: \(score)")
            case .suitable:
                score *= 0.97
                print("Penalty for no naps despite suitable environment: \(score)")
            default:
                break
            }
        }
        
        // 11. Global push for polyphasic under perfect conditions
        if napCount >= 2 &&
           (factors.workSchedule == .flexible || factors.workSchedule == .irregular) &&
           factors.napEnvironment == .ideal &&
           factors.motivationLevel == .high {
            
            score *= 1.2
            print("Bonus for perfect polyphasic conditions: \(score)")
        }
        
        print("Final score for \(schedule.id): \(String(format: "%.3f", score))")
        print("=====================================")
        
        return score
    }
    
    // MARK: - Helper Score Functions
    
    private func calculatePolyphasicSuitability(for schedule: SleepScheduleModel,
                                                napCount: Int,
                                                factors: UserFactors) -> Double {
        var suitability = 1.0
        
        // Yaş
        switch factors.ageRange {
        case .under18:
            // Çok genç => belki polyphasic ~ risky
            if napCount > 2 { suitability *= 0.7 }
        case .age18to24:
            // Gençler polyphasic’e genelde daha uygun
            if napCount > 2 { suitability *= 1.05 }
        case .age25to34:
            if napCount > 2 { suitability *= 1.0 }
        case .age35to44:
            if napCount > 2 { suitability *= 0.95 }
        case .age45to54:
            if napCount > 2 { suitability *= 0.85 }
        case .age55Plus:
            if napCount > 1 { suitability *= 0.8 }
        }
        
        // Yaşam tarzı
        switch factors.lifestyle {
        case .calm:
            // Sakin yaşam => az nap = normal
            if napCount >= 3 { suitability *= 0.9 }
        case .moderatelyActive:
            suitability *= 1.0
        case .veryActive:
            // Çok aktif => belki 2+ nap avantaj
            if napCount >= 2 { suitability *= 1.1 }
        }
        
        return suitability
    }
    
    private func calculateKnowledgeAdjustment(napCount: Int, level: KnowledgeLevel) -> Double {
        // Varsayılan: Çok naps = zor => advanced knowledge bonus
        var factor = 1.0
        
        switch level {
        case .beginner:
            // NapCount 2+ ise penalty
            if napCount >= 2 {
                factor = 0.85
            }
        case .intermediate:
            if napCount >= 3 {
                factor = 0.9
            }
        case .advanced:
            // NapCount fazla ise bonus
            if napCount >= 3 {
                factor = 1.1
            }
        }
        
        return factor
    }
    
    private func calculateMotivationAdjustment(napCount: Int, level: MotivationLevel) -> Double {
        // Yüksek motivasyon => çoklu naps'a artı
        var factor = 1.0
        switch level {
        case .low:
            // Fazla nap => ceza
            if napCount >= 2 {
                factor = 0.8
            }
        case .moderate:
            if napCount >= 3 {
                factor = 0.9
            }
        case .high:
            if napCount >= 3 {
                factor = 1.15
            }
        }
        
        return factor
    }
    
    private func calculateNapEnvironmentScore(environment: NapEnvironment) -> Double {
        // Tek sefer daha küçük, çok naps > environment critical (handled above)
        switch environment {
        case .unsuitable:
            return 0.9
        case .limited:
            return 0.95
        case .suitable:
            return 1.0
        case .ideal:
            return 1.05
        }
    }
    
    // MARK: - Warning and Adaptation
    
    private func generateWarnings(for schedule: SleepScheduleModel,
                                  factors: UserFactors) -> [SleepScheduleRecommendation.Warning] {
        var warnings: [SleepScheduleRecommendation.Warning] = []
        
        if schedule.difficulty == .extreme {
            switch factors.sleepExperience {
            case .none, .some:
                warnings.append(
                    .init(severity: .critical, messageKey: "warning.experienceTooLow")
                )
            case .moderate:
                warnings.append(
                    .init(severity: .warning, messageKey: "warning.moderateExperience")
                )
            case .extensive:
                warnings.append(
                    .init(severity: .info, messageKey: "warning.challengingSchedule")
                )
            }
        }
        
        if schedule.difficulty == .extreme && factors.healthStatus != .healthy {
            warnings.append(
                .init(severity: .critical, messageKey: "warning.healthConcerns")
            )
        }
        
        let hasNaps = schedule.schedule.contains { !$0.isCore }
        if hasNaps && factors.napEnvironment == .unsuitable {
            warnings.append(
                .init(severity: .warning, messageKey: "warning.unsuitableNapEnvironment")
            )
        }
        
        if schedule.hasNapsInWorkHours && factors.workSchedule == .regular {
            warnings.append(
                .init(severity: .warning, messageKey: "warning.workScheduleConflict")
            )
        }
        
        return warnings
    }
    
    private func calculateAdaptationPeriod(for schedule: SleepScheduleModel,
                                           factors: UserFactors) -> Int {
        let basePeriod: Int = {
            switch schedule.difficulty {
            case .extreme:      return 28
            case .advanced:     return 21
            case .intermediate: return 14
            case .beginner:     return 7
            }
        }()
        
        let experienceMultiplier: Double = {
            switch factors.sleepExperience {
            case .extensive: return 0.7
            case .moderate:  return 0.8
            case .some:      return 0.9
            case .none:      return 1.0
            }
        }()
        
        let motivationMultiplier: Double = {
            switch factors.motivationLevel {
            case .high:     return 0.8
            case .moderate: return 0.9
            case .low:      return 1.0
            }
        }()
        
        return Int(Double(basePeriod) * experienceMultiplier * motivationMultiplier)
    }
    
    // MARK: - JSON Loading
    
    private func loadSleepSchedules() -> [SleepScheduleModel]? {
        print("\nAttempting to load sleep schedules...")
        guard let url = Bundle.main.url(forResource: "SleepSchedules", withExtension: "json") else {
            print("Could not find SleepSchedules.json in bundle")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let container = try decoder.decode(SleepSchedulesContainer.self, from: data)
            print("Successfully loaded \(container.sleepSchedules.count) schedules")
            return container.sleepSchedules
        } catch {
            print("Error loading sleep schedules: \(error)")
            return nil
        }
    }
}
