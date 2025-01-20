//
//  SleepScheduleRecommender.swift
//  polysleep
//
//  Created by Taner Çelik on 29.12.2024.
//
 
import Foundation
import SwiftData

// MARK: - UserFactors Yapısı
/// Tüm yeni eklediğimiz alanlarla birlikte güncel yapı.
struct UserFactors {
    let sleepExperience: PreviousSleepExperience
    let ageRange: AgeRange
    let workSchedule: WorkSchedule
    let napEnvironment: NapEnvironment
    let lifestyle: Lifestyle
    let knowledgeLevel: KnowledgeLevel
    let healthStatus: HealthStatus
    let motivationLevel: MotivationLevel
    
    // Yeni eklediğimiz 4 faktör:
    let sleepGoal: SleepGoal
    let socialObligations: SocialObligations
    let disruptionTolerance: DisruptionTolerance
    let chronotype: Chronotype
}

// MARK: - SleepScheduleRecommendation Yapısı
public struct SleepScheduleRecommendation {
    let schedule: SleepScheduleModel
    let confidenceScore: Double // 0..1 veya 0..1.5 aralığında
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

// MARK: - SleepScheduleRecommender Servisi
final class SleepScheduleRecommender {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Ana fonksiyon: Veritabanındaki kullanıcı faktörlerini alır, puanlama yapar ve uygun schedule önerir.
    func recommendSchedule() -> SleepScheduleRecommendation? {
        print("\n=== Starting Sleep Schedule Recommendation ===")
        
        guard let userFactor = loadUserFactors() else {
            print("❌ Failed to load user factors from database!")
            return nil
        }
        
        // Enum dönüşümleri
        let sleepExperience    = PreviousSleepExperience(rawValue: userFactor.sleepExperience)
        let ageRange           = AgeRange(rawValue: userFactor.ageRange)
        let workSchedule       = WorkSchedule(rawValue: userFactor.workSchedule)
        let napEnvironment     = NapEnvironment(rawValue: userFactor.napEnvironment)
        let lifestyle          = Lifestyle(rawValue: userFactor.lifestyle)
        let knowledgeLevel     = KnowledgeLevel(rawValue: userFactor.knowledgeLevel)
        let healthStatus       = HealthStatus(rawValue: userFactor.healthStatus)
        let motivationLevel    = MotivationLevel(rawValue: userFactor.motivationLevel)
        
        // Yeni faktörler
        let sleepGoal          = SleepGoal(rawValue: userFactor.sleepGoal)
        let socialObligations  = SocialObligations(rawValue: userFactor.socialObligations)
        let disruptionTolerance = DisruptionTolerance(rawValue: userFactor.disruptionTolerance)
        let chronotype         = Chronotype(rawValue: userFactor.chronotype)
        
        // Hangi enum dönüştürülemedi?
        if sleepExperience == nil    { print("❌ SleepExperience enum error: \(userFactor.sleepExperience)") }
        if ageRange == nil           { print("❌ AgeRange enum error: \(userFactor.ageRange)") }
        if workSchedule == nil       { print("❌ WorkSchedule enum error: \(userFactor.workSchedule)") }
        if napEnvironment == nil     { print("❌ NapEnvironment enum error: \(userFactor.napEnvironment)") }
        if lifestyle == nil          { print("❌ Lifestyle enum error: \(userFactor.lifestyle)") }
        if knowledgeLevel == nil     { print("❌ KnowledgeLevel enum error: \(userFactor.knowledgeLevel)") }
        if healthStatus == nil       { print("❌ HealthStatus enum error: \(userFactor.healthStatus)") }
        if motivationLevel == nil    { print("❌ MotivationLevel enum error: \(userFactor.motivationLevel)") }
        
        // Yeni dört faktör için kontrol
        if sleepGoal == nil          { print("❌ SleepGoal enum error: \(userFactor.sleepGoal)") }
        if socialObligations == nil  { print("❌ SocialObligations enum error: \(userFactor.socialObligations)") }
        if disruptionTolerance == nil { print("❌ DisruptionTolerance enum error: \(userFactor.disruptionTolerance)") }
        if chronotype == nil         { print("❌ Chronotype enum error: \(userFactor.chronotype)") }
        
        // Hepsi nil değilse kullan
        guard
            let sleepExp  = sleepExperience,
            let ageR      = ageRange,
            let workSch   = workSchedule,
            let napEnv    = napEnvironment,
            let lifeS     = lifestyle,
            let knowL     = knowledgeLevel,
            let healthSt  = healthStatus,
            let motivL    = motivationLevel,
            let sGoal     = sleepGoal,
            let sOblig    = socialObligations,
            let dToler    = disruptionTolerance,
            let cType     = chronotype
        else {
            print("❌ Failed to convert one or more enums!")
            return nil
        }
        
        // Tüm faktörleri tek bir struct içine koy
        let factors = UserFactors(
            sleepExperience:    sleepExp,
            ageRange:           ageR,
            workSchedule:       workSch,
            napEnvironment:     napEnv,
            lifestyle:          lifeS,
            knowledgeLevel:     knowL,
            healthStatus:       healthSt,
            motivationLevel:    motivL,
            sleepGoal:          sGoal,
            socialObligations:  sOblig,
            disruptionTolerance:dToler,
            chronotype:         cType
        )
        
        print("\nUser Factors loaded:")
        print("- Sleep Experience:  \(sleepExp.rawValue)")
        print("- Age Range:         \(ageR.rawValue)")
        print("- Work Schedule:     \(workSch.rawValue)")
        print("- Nap Environment:   \(napEnv.rawValue)")
        print("- Lifestyle:         \(lifeS.rawValue)")
        print("- Knowledge Level:   \(knowL.rawValue)")
        print("- Health Status:     \(healthSt.rawValue)")
        print("- Motivation Level:  \(motivL.rawValue)")
        print("- Sleep Goal:        \(sGoal.rawValue)")
        print("- Social Obligations:\(sOblig.rawValue)")
        print("- Disruption Tol.:   \(dToler.rawValue)")
        print("- Chronotype:        \(cType.rawValue)")
        
        // JSON'dan schedule'ları yükle
        guard let schedules = loadSleepSchedules() else {
            print("❌ Failed to load sleep schedules from JSON!")
            return nil
        }
        
        print("\nEvaluating \(schedules.count) sleep schedules...")
        
        // Her schedule için puan hesapla
        var allScores: [(SleepScheduleModel, Double)] = []
        for schedule in schedules {
            let score = calculateScheduleScore(schedule, factors: factors)
            allScores.append((schedule, score))
        }
        
        // Skorları yüksekten düşüğe sırala
        allScores.sort { $0.1 > $1.1 }
        
        print("\n=== Sleep Schedule Scores (Sorted) ===")
        print("Format: Schedule Name (Total Sleep) - Score - Difficulty")
        print("------------------------------------------------")
        for (schedule, score) in allScores {
            print("\(schedule.name.padRight(toLength: 20)) - Score: \(String(format: "%.3f", score)) - \(schedule.difficulty.rawValue)")
        }
        print("------------------------------------------------")
        
        // En yüksek skorlu schedule
        guard let (bestSchedule, bestScore) = allScores.first else {
            print("❌ No valid schedule found!")
            return nil
        }
        
        print("\n✅ Recommended Schedule: \(bestSchedule.name)")
        print("- Total Score: \(String(format: "%.3f", bestScore))")
        print("- Difficulty:  \(bestSchedule.difficulty.rawValue)")
        
        // Warnings oluştur
        let warnings = generateWarnings(for: bestSchedule, factors: factors)
        
        // Adaptasyon süresi hesapla
        let adaptationPeriod = calculateAdaptationPeriod(experience: sleepExp, motivation: motivL)
        
        // Sonuç dön
        return SleepScheduleRecommendation(
            schedule: bestSchedule,
            confidenceScore: bestScore,
            warnings: warnings,
            adaptationPeriod: adaptationPeriod
        )
    }
    
    // MARK: - UserFactors Yükleme
    /// Veritabanından (SwiftData) son girilen `UserFactor` kaydını alır
    private func loadUserFactors() -> UserFactor? {
        print("\n=== Loading User Factors ===")
        let descriptor = FetchDescriptor<UserFactor>()
        
        do {
            let factors = try modelContext.fetch(descriptor)
            print("Found \(factors.count) user factors in database")
            
            if let factor = factors.first {
                print("User Factor Values:")
                print("- Sleep Experience:  \(factor.sleepExperience)")
                print("- Age Range:         \(factor.ageRange)")
                print("- Work Schedule:     \(factor.workSchedule)")
                print("- Nap Environment:   \(factor.napEnvironment)")
                print("- Lifestyle:         \(factor.lifestyle)")
                print("- Knowledge Level:   \(factor.knowledgeLevel)")
                print("- Health Status:     \(factor.healthStatus)")
                print("- Motivation Level:  \(factor.motivationLevel)")
                print("- Sleep Goal:        \(factor.sleepGoal)")
                print("- Social Obligations:\(factor.socialObligations)")
                print("- Disruption Tol.:   \(factor.disruptionTolerance)")
                print("- Chronotype:        \(factor.chronotype)")
                
                return factor
            } else {
                print("❌ No user factors found in database")
                return nil
            }
        } catch {
            print("❌ Error fetching user factors: \(error)")
            return nil
        }
    }
    
    // MARK: - Schedules JSON Yükleme
    /// Bundle içindeki SleepSchedules.json dosyasını yükler ve decode eder
    private func loadSleepSchedules() -> [SleepScheduleModel]? {
        guard let url = Bundle.main.url(forResource: "SleepSchedules", withExtension: "json") else {
            print("Could not find SleepSchedules.json in the main bundle")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let container = try decoder.decode(SleepSchedulesContainer.self, from: data)
            print("Successfully loaded \(container.sleepSchedules.count) schedules from JSON")
            return container.sleepSchedules
        } catch {
            print("Error loading schedules: \(error)")
            return nil
        }
    }
    
    // MARK: - Score Hesaplama
    private func calculateScheduleScore(_ schedule: SleepScheduleModel, factors: UserFactors) -> Double {
        var score = 1.0
        
        // 1) Sleep Experience
        switch factors.sleepExperience {
        case .none:        score *= 0.7
        case .some:        score *= 0.8
        case .moderate:    score *= 0.9
        case .extensive:   score *= 1.0
        }
        
        // 2) Age Range
        switch factors.ageRange {
        case .under18:
            // 18 yaş altıysanız, çok ekstrem düzenleri istemeyebiliriz
            score *= 0.6
        case .age18to24:
            score *= 1.0
        case .age25to34:
            score *= 0.9
        case .age35to44:
            score *= 0.8
        case .age45to54:
            score *= 0.7
        case .age55Plus:
            score *= 0.6
        }
        
        // 3) Work Schedule
        switch factors.workSchedule {
        case .flexible:
            score *= 1.0
        case .regular:
            score *= 0.9
        case .irregular:
            score *= 0.7
        case .shift:
            score *= 0.6
        }
        
        // 4) Nap Environment (only matters if napCount>0)
        let napCount = schedule.schedule.filter { !$0.isCore }.count
        if napCount > 0 {
            switch factors.napEnvironment {
            case .ideal:      score *= 1.0
            case .suitable:   score *= 0.9
            case .limited:    score *= 0.7
            case .unsuitable: score *= 0.5
            }
        }
        
        // 5) Lifestyle
        switch factors.lifestyle {
        case .calm:
            score *= 1.0
        case .moderatelyActive:
            score *= 0.9
        case .veryActive:
            score *= 0.7
        }
        
        // 6) Knowledge Level
        switch factors.knowledgeLevel {
        case .beginner:
            score *= 0.8
        case .intermediate:
            score *= 0.9
        case .advanced:
            score *= 1.0
        }
        
        // 7) Health Status
        switch factors.healthStatus {
        case .healthy:
            score *= 1.0
        case .managedConditions:
            score *= 0.7
        case .seriousConditions:
            score *= 0.4
        }
        
        // 8) Motivation
        switch factors.motivationLevel {
        case .low:
            score *= 0.7
        case .moderate:
            score *= 0.85
        case .high:
            score *= 1.0
        }
        
        // ----------------------------------------------
        // YENİ 4 FAKTÖR
        // 9) Sleep Goal
        switch factors.sleepGoal {
        case .moreProductivity:
            // Daha fazla üretkenlik -> daha sık (polyphasic) ufak bonus
            if napCount >= 2 {
                score *= 1.1
            }
        case .balancedLifestyle:
            // Dengeli yaşam -> çok fazla nap (5+) ceza
            if napCount >= 5 {
                score *= 0.8
            }
        case .improveHealth:
            // Sağlığı iyileştirme -> 4 saatin altı total sleep ceza
            if schedule.totalSleepHours < 4.0 {
                score *= 0.6
            }
        case .curiosity:
            // Deneysellik -> 2+ nap için hafif bonus
            if napCount >= 2 {
                score *= 1.05
            }
        }
        
        // 10) Social Obligations
        switch factors.socialObligations {
        case .significant:
            // Çok sosyal yükümlülük -> çok nap'li schedule ceza
            if napCount >= 3 {
                score *= 0.75
            }
        case .moderate:
            // Orta -> 6+ naps ceza
            if napCount >= 6 {
                score *= 0.7
            }
        case .minimal:
            // Az -> polifazik'e bonus
            if napCount >= 4 {
                score *= 1.1
            }
        }
        
        // 11) Disruption Tolerance
        switch factors.disruptionTolerance {
        case .verySensitive:
            // Uykusu bölünmeye hassas -> 2+ nap varsa ceza
            if napCount >= 2 {
                score *= 0.75
            }
        case .somewhatSensitive:
            // Orta hassas -> 3+ nap varsa ceza
            if napCount >= 3 {
                score *= 0.85
            }
        case .notSensitive:
            // Bölünmeye tolerant -> 3+ nap'a bonus
            if napCount >= 3 {
                score *= 1.1
            }
        }
        
        // 12) Chronotype
        switch factors.chronotype {
        case .morningLark:
            // Sabahçı -> eğer core sleep çok geç başlıyorsa biraz ceza
            let hasLateCore = schedule.schedule.contains { block in
                block.isCore && (TimeFormatter.time(from: block.startTime)?.hour ?? 0) >= 2
            }
            if hasLateCore {
                score *= 0.8
            }
        case .nightOwl:
            // Gece kuşu -> eğer core sleep 22:00 gibi erken başlıyorsa ceza
            let hasEarlyCore = schedule.schedule.contains { block in
                block.isCore && (TimeFormatter.time(from: block.startTime)?.hour ?? 0) < 22
            }
            if hasEarlyCore {
                score *= 0.8
            }
        case .neutral:
            // Nötr -> ek bir şey yok
            break
        }
        
        // ----------------------------------------------
        // MONOPHASIC LOGİĞİNE EK PENALTY / BONUS
        
        if schedule.id == "monophasic" {
            // 18 yaş altı veya ciddi sağlık problemi varsa -> Monophasic bonus
            if (factors.ageRange == .under18) || (factors.healthStatus == .seriousConditions) {
                score *= 1.3
            }
            
            // Yetişkin, sağlıklı, motivasyonu düşük olmayanlar -> Monophasic cezası
            let isAdult       = (factors.ageRange != .under18)
            let isHealthy     = (factors.healthStatus == .healthy)
            let hasMotivation = (factors.motivationLevel == .moderate || factors.motivationLevel == .high)
            
            if isAdult && isHealthy && hasMotivation {
                score *= 0.3
            }
        }
        
        // Son olarak 0..1.5 aralığına clamp
        let finalScore = max(0.0, min(1.5, score))
        return finalScore
    }
    
    // MARK: - Warnings
    /// Ek uyarı mekanizması
    private func generateWarnings(for schedule: SleepScheduleModel, factors: UserFactors) -> [SleepScheduleRecommendation.Warning] {
        var warnings: [SleepScheduleRecommendation.Warning] = []
        
        // Difficulty = .extreme ve deneyim düşükse
        if schedule.difficulty == .extreme {
            switch factors.sleepExperience {
            case .none, .some:
                warnings.append(.init(severity: .critical, messageKey: "warning.experienceTooLow"))
            case .moderate:
                warnings.append(.init(severity: .warning, messageKey: "warning.moderateExperience"))
            case .extensive:
                warnings.append(.init(severity: .info, messageKey: "warning.challengingSchedule"))
            }
        }
        
        // Health durumunu da ek bir kontrol
        if schedule.difficulty == .extreme && factors.healthStatus != .healthy {
            warnings.append(.init(severity: .critical, messageKey: "warning.healthConcerns"))
        }
        
        // Naps varsa ama ortam “unsuitable” ise
        let hasNaps = schedule.schedule.contains { !$0.isCore }
        if hasNaps && factors.napEnvironment == .unsuitable {
            warnings.append(.init(severity: .warning, messageKey: "warning.unsuitableNapEnvironment"))
        }
        
        // Work hours (09:00-17:00) ile çakışma
        if schedule.hasNapsInWorkHours && factors.workSchedule == .regular {
            warnings.append(.init(severity: .warning, messageKey: "warning.workScheduleConflict"))
        }
        
        return warnings
    }
    
    // MARK: - Adaptation Period
    /// Deneyim ve motivasyona göre adaptasyon süresi (basit örnek)
    private func calculateAdaptationPeriod(experience: PreviousSleepExperience, motivation: MotivationLevel) -> Int {
        let basePeriod = 14
        let expMult: Double
        switch experience {
        case .none:      expMult = 1.2
        case .some:      expMult = 1.0
        case .moderate:  expMult = 0.8
        case .extensive: expMult = 0.6
        }
        
        let motMult: Double
        switch motivation {
        case .low:       motMult = 1.2
        case .moderate:  motMult = 1.0
        case .high:      motMult = 0.8
        }
        
        return Int(Double(basePeriod) * expMult * motMult)
    }
}

// MARK: - String Helpers
fileprivate extension String {
    /// Sağ tarafı belirli bir uzunluğa kadar boşlukla doldurmak için
    func padRight(toLength length: Int) -> String {
        if self.count >= length {
            return String(self.prefix(length))
        }
        return self + String(repeating: " ", count: length - self.count)
    }
}
