//
//  SleepScheduleRecommender.swift
//  polynap
//
//  Created by Taner Çelik on 29.12.2024.
//
 
import Foundation

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
    // Basit bir başlatıcı
    private let repository: Repository
    
    init(repository: Repository = Repository.shared) {
        self.repository = repository
    }
    
    /// Ana fonksiyon: Kullanıcı faktörlerini alır, puanlama yapar ve uygun schedule önerir.
    func recommendSchedule() async throws -> SleepScheduleRecommendation? {
        print("\n=== Starting Sleep Schedule Recommendation ===")
        
        // Yerel veritabanından kullanıcı faktörlerini yükle
        guard let userAnswers = try await loadUserFactorsFromLocalDatabase() else {
            print("❌ Failed to get recommendation")
            return nil
        }
        
        // Anahtarlardan "onboarding." ön ekini kaldıralım
        var processedAnswers: [String: String] = [:]
        for (key, value) in userAnswers {
            if key.hasPrefix("onboarding.") {
                let processedKey = String(key.dropFirst("onboarding.".count))
                processedAnswers[processedKey] = value
            } else {
                processedAnswers[key] = value
            }
        }
        
        print("📋 İşlenmiş cevaplar: \(processedAnswers)")
        
        // Enum dönüşümleri - işlenmiş anahtarlarla
        let sleepExperience    = PreviousSleepExperience(rawValue: processedAnswers["sleepExperience"] ?? "")
        let ageRange           = AgeRange(rawValue: processedAnswers["ageRange"] ?? "")
        let workSchedule       = WorkSchedule(rawValue: processedAnswers["workSchedule"] ?? "")
        let napEnvironment     = NapEnvironment(rawValue: processedAnswers["napEnvironment"] ?? "")
        let lifestyle          = Lifestyle(rawValue: processedAnswers["lifestyle"] ?? "")
        let knowledgeLevel     = KnowledgeLevel(rawValue: processedAnswers["knowledgeLevel"] ?? "")
        let healthStatus       = HealthStatus(rawValue: processedAnswers["healthStatus"] ?? "")
        let motivationLevel    = MotivationLevel(rawValue: processedAnswers["motivationLevel"] ?? "")
        
        // Yeni faktörler
        let sleepGoal          = SleepGoal(rawValue: processedAnswers["sleepGoal"] ?? "")
        let socialObligations  = SocialObligations(rawValue: processedAnswers["socialObligations"] ?? "")
        let disruptionTolerance = DisruptionTolerance(rawValue: processedAnswers["disruptionTolerance"] ?? "")
        let chronotype         = Chronotype(rawValue: processedAnswers["chronotype"] ?? "")
        
        // Hangi enum dönüştürülemedi?
        if sleepExperience == nil    { print("❌ SleepExperience enum error: \(processedAnswers["sleepExperience"] ?? "")") }
        if ageRange == nil           { print("❌ AgeRange enum error: \(processedAnswers["ageRange"] ?? "")") }
        if workSchedule == nil       { print("❌ WorkSchedule enum error: \(processedAnswers["workSchedule"] ?? "")") }
        if napEnvironment == nil     { print("❌ NapEnvironment enum error: \(processedAnswers["napEnvironment"] ?? "")") }
        if lifestyle == nil          { print("❌ Lifestyle enum error: \(processedAnswers["lifestyle"] ?? "")") }
        if knowledgeLevel == nil     { print("❌ KnowledgeLevel enum error: \(processedAnswers["knowledgeLevel"] ?? "")") }
        if healthStatus == nil       { print("❌ HealthStatus enum error: \(processedAnswers["healthStatus"] ?? "")") }
        if motivationLevel == nil    { print("❌ MotivationLevel enum error: \(processedAnswers["motivationLevel"] ?? "")") }
        
        // Yeni dört faktör için kontrol
        if sleepGoal == nil          { print("❌ SleepGoal enum error: \(processedAnswers["sleepGoal"] ?? "")") }
        if socialObligations == nil  { print("❌ SocialObligations enum error: \(processedAnswers["socialObligations"] ?? "")") }
        if disruptionTolerance == nil { print("❌ DisruptionTolerance enum error: \(processedAnswers["disruptionTolerance"] ?? "")") }
        if chronotype == nil         { print("❌ Chronotype enum error: \(processedAnswers["chronotype"] ?? "")") }
        
        // Eksik enumlar için varsayılan değerler sağla
        let sleepExp  = sleepExperience    ?? .some
        let ageR      = ageRange           ?? .age25to34
        let workSch   = workSchedule       ?? .regular
        let napEnv    = napEnvironment     ?? .suitable
        let lifeS     = lifestyle          ?? .moderatelyActive
        let knowL     = knowledgeLevel     ?? .intermediate
        let healthSt  = healthStatus       ?? .healthy
        let motivL    = motivationLevel    ?? .moderate
        let sGoal     = sleepGoal          ?? .balancedLifestyle
        let sOblig    = socialObligations  ?? .moderate
        let dToler    = disruptionTolerance ?? .somewhatSensitive
        let cType     = chronotype         ?? .neutral
        
        // Programımız çalışabilmesi için kritik enum değerlerinden hiçbiri varsa
        if sleepExperience == nil || ageRange == nil || workSchedule == nil || napEnvironment == nil || 
           lifestyle == nil || knowledgeLevel == nil || healthStatus == nil || motivationLevel == nil {
            print("⚠️ Bazı kritik enum değerleri dönüştürülemedi, varsayılan değerler kullanılıyor!")
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
        
        print("\nUser Factors loaded (bazı değerler varsayılan olabilir):")
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
        
        print("\n=== Recommended Schedule: \(bestSchedule.name)")
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
    /// SwiftData'dan kullanıcı cevaplarını alır
    private func loadUserFactorsFromLocalDatabase() async throws -> [String: String]? {
        // Repository'den onboarding cevaplarını al
        do {
            // Repository'den cevapları al (artık Repository kendi ModelContext'ini yönetebiliyor)
            let onboardingAnswers = try await repository.getOnboardingAnswers()
            
            // Sonuçların boş olup olmadığını kontrol et
            print("🗂️ \(onboardingAnswers.count) onboarding cevabı getirildi")
            if onboardingAnswers.isEmpty {
                print("❌ Onboarding cevapları boş döndü")
                return nil
            }
            
            // OnboardingAnswerData'dan [String: String] sözlüğüne dönüştür
            var result: [String: String] = [:]
            for answer in onboardingAnswers {
                result[answer.question] = answer.answer
            }
            
            print("✅ Onboarding cevapları başarıyla alındı: \(result)")
            return result
        } catch {
            print("❌ Error loading user factors from local database: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// UserFactor modelini SwiftData'dan yükle - Artık kullanılmıyor
    @available(*, deprecated, message: "Bu metot artık kullanılmıyor, loadUserFactorsFromLocalDatabase kullanın")
    private func loadUserFactors() -> UserFactor? {
        print("❌ Bu metot artık kullanılmıyor!")
        return nil
    }
    
    // MARK: - Schedules JSON Yükleme
    /// Bundle içindeki SleepSchedules.json dosyasını yükler ve decode eder
    /// Sadece isPremium=false olan schedule'ları döndürür
    private func loadSleepSchedules() -> [SleepScheduleModel]? {
        guard let url = Bundle.main.url(forResource: "SleepSchedules", withExtension: "json") else {
            print("Could not find SleepSchedules.json in the main bundle")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let container = try decoder.decode(SleepSchedulesContainer.self, from: data)
            
            // Sadece isPremium=false olan schedule'ları filtrele
            let freeSchedules = container.sleepSchedules.filter { !$0.isPremium }
            
            print("Successfully loaded \(container.sleepSchedules.count) schedules from JSON")
            print("Filtered to \(freeSchedules.count) free schedules (isPremium=false)")
            
            return freeSchedules
        } catch {
            print("Error loading schedules: \(error)")
            return nil
        }
    }
    
    // MARK: - Schedule Yükleme
    /// Belirli bir ID'ye sahip uyku programını döndürür
    func getScheduleById(_ id: String) -> SleepScheduleModel? {
        // Tüm hazır programları içeren bir sözlük oluştur
        let schedules: [String: SleepScheduleModel] = [
            "monophasic": SleepScheduleModel(
                id: "monophasic",
                name: "Monofazik Uyku",
                description: LocalizedDescription(
                    en: "The Monophasic Sleep Schedule consists of a single sleep period, typically at night. This is the most common sleep pattern in modern society. It aims to consolidate all sleep into one block, usually 7-8 hours in length.",
                    tr: "Monofazik Uyku Programı, tipik olarak gece olan tek bir uyku periyodundan oluşur. Bu, modern toplumda en yaygın uyku düzenidir. Genellikle 7-8 saat uzunluğunda tüm uykuyu tek bir blokta toplamayı amaçlar."
                ),
                totalSleepHours: 7.5,
                schedule: [
                    SleepBlock(
                        startTime: "23:00",
                        duration: 450,
                        type: "core",
                        isCore: true
                    )
                ],
                isPremium: false
            ),
            "biphasic": SleepScheduleModel(
                id: "biphasic",
                name: "Bifazik Uyku",
                description: LocalizedDescription(
                    en: "The Biphasic Sleep Schedule consists of two sleep periods: a longer core sleep at night and a short nap during the day. This pattern is common in Mediterranean cultures (siesta) and may align better with our natural circadian rhythms.",
                    tr: "Bifazik Uyku Programı, iki uyku periyodundan oluşur: gece daha uzun bir ana uyku ve gündüz kısa bir şekerleme. Bu düzen, Akdeniz kültürlerinde (siesta) yaygındır ve doğal sirkadiyen ritimlerimizle daha iyi uyum sağlayabilir."
                ),
                totalSleepHours: 6.5,
                schedule: [
                    SleepBlock(
                        startTime: "23:30",
                        duration: 360,
                        type: "core",
                        isCore: true
                    ),
                    SleepBlock(
                        startTime: "14:00",
                        duration: 30,
                        type: "nap",
                        isCore: false
                    )
                ],
                isPremium: false
            ),
            "everyman": SleepScheduleModel(
                id: "everyman",
                name: "Everyman Uyku",
                description: LocalizedDescription(
                    en: "The Everyman Sleep Schedule consists of one core sleep period and multiple naps throughout the day. This schedule reduces total sleep time while maintaining cognitive function through strategic nap placement.",
                    tr: "Everyman Uyku Programı, bir ana uyku periyodu ve gün boyunca birden fazla şekerlemeden oluşur. Bu program, stratejik şekerleme yerleşimi ile bilişsel işlevi korurken toplam uyku süresini azaltır."
                ),
                totalSleepHours: 5.5,
                schedule: [
                    SleepBlock(
                        startTime: "00:00",
                        duration: 270,
                        type: "core",
                        isCore: true
                    ),
                    SleepBlock(
                        startTime: "08:30",
                        duration: 20,
                        type: "nap",
                        isCore: false
                    ),
                    SleepBlock(
                        startTime: "14:30",
                        duration: 20,
                        type: "nap",
                        isCore: false
                    ),
                    SleepBlock(
                        startTime: "20:30",
                        duration: 20,
                        type: "nap",
                        isCore: false
                    )
                ],
                isPremium: false
            ),
            "dymaxion": SleepScheduleModel(
                id: "dymaxion",
                name: "Dymaxion Uyku",
                description: LocalizedDescription(
                    en: "The Dymaxion Sleep Schedule, developed by Buckminster Fuller, consists of four 30-minute naps spread throughout the day, for a total of just 2 hours of sleep per day. This is an extreme schedule that very few people can adapt to.",
                    tr: "Buckminster Fuller tarafından geliştirilen Dymaxion Uyku Programı, günde toplam sadece 2 saat uyku için gün boyunca dağılmış dört 30 dakikalık şekerlemeden oluşur. Bu, çok az insanın uyum sağlayabileceği aşırı bir programdır."
                ),
                totalSleepHours: 2.0,
                schedule: [
                    SleepBlock(
                        startTime: "02:00",
                        duration: 30,
                        type: "nap",
                        isCore: false
                    ),
                    SleepBlock(
                        startTime: "08:00",
                        duration: 30,
                        type: "nap",
                        isCore: false
                    ),
                    SleepBlock(
                        startTime: "14:00",
                        duration: 30,
                        type: "nap",
                        isCore: false
                    ),
                    SleepBlock(
                        startTime: "20:00",
                        duration: 30,
                        type: "nap",
                        isCore: false
                    )
                ],
                isPremium: true
            ),
            "uberman": SleepScheduleModel(
                id: "uberman",
                name: "Uberman Uyku",
                description: LocalizedDescription(
                    en: "The Uberman Sleep Schedule consists of six 20-minute naps spread evenly throughout the day, for a total of 2 hours of sleep. This is one of the most difficult schedules to adapt to and maintain.",
                    tr: "Uberman Uyku Programı, günde toplam 2 saat uyku için gün boyunca eşit olarak dağılmış altı 20 dakikalık şekerlemeden oluşur. Bu, uyum sağlaması ve sürdürmesi en zor programlardan biridir."
                ),
                totalSleepHours: 2.0,
                schedule: [
                    SleepBlock(
                        startTime: "02:00",
                        duration: 20,
                        type: "nap",
                        isCore: false
                    ),
                    SleepBlock(
                        startTime: "06:00",
                        duration: 20,
                        type: "nap",
                        isCore: false
                    ),
                    SleepBlock(
                        startTime: "10:00",
                        duration: 20,
                        type: "nap",
                        isCore: false
                    ),
                    SleepBlock(
                        startTime: "14:00",
                        duration: 20,
                        type: "nap",
                        isCore: false
                    ),
                    SleepBlock(
                        startTime: "18:00",
                        duration: 20,
                        type: "nap",
                        isCore: false
                    ),
                    SleepBlock(
                        startTime: "22:00",
                        duration: 20,
                        type: "nap",
                        isCore: false
                    )
                ],
                isPremium: true
            ),
            "triphasic": SleepScheduleModel(
                id: "triphasic",
                name: "Trifazik Uyku recommender",
                description: LocalizedDescription(
                    en: "The Triphasic Sleep Schedule consists of three sleep periods spread throughout the day, aligned with natural dips in alertness. This pattern aims to maximize deep sleep and REM sleep while reducing overall sleep time.",
                    tr: "Trifazik Uyku Programı, gün boyunca dağılmış, uyanıklıktaki doğal düşüşlerle uyumlu üç uyku periyodundan oluşur. Bu düzen, toplam uyku süresini azaltırken derin uyku ve REM uykusunu en üst düzeye çıkarmayı amaçlar."
                ),
                totalSleepHours: 4.5,
                schedule: [
                    SleepBlock(
                        startTime: "22:00",
                        duration: 90,
                        type: "core",
                        isCore: true
                    ),
                    SleepBlock(
                        startTime: "06:30",
                        duration: 90,
                        type: "core",
                        isCore: true
                    ),
                    SleepBlock(
                        startTime: "14:30",
                        duration: 90,
                        type: "core",
                        isCore: true
                    )
                ],
                isPremium: true
            ),
            "dual-core": SleepScheduleModel(
                id: "dual-core",
                name: "Çift Çekirdekli Uyku",
                description: LocalizedDescription(
                    en: "The Dual Core Sleep Schedule consists of two core sleep periods and one or more naps. This schedule attempts to align with natural circadian dips and may be more sustainable than schedules with only short naps.",
                    tr: "Çift Çekirdekli Uyku Programı, iki ana uyku periyodu ve bir veya daha fazla şekerlemeden oluşur. Bu program, doğal sirkadiyen düşüşlerle uyum sağlamaya çalışır ve sadece kısa şekerlemeler içeren programlardan daha sürdürülebilir olabilir."
                ),
                totalSleepHours: 5.5,
                schedule: [
                    SleepBlock(
                        startTime: "22:00",
                        duration: 180,
                        type: "core",
                        isCore: true
                    ),
                    SleepBlock(
                        startTime: "05:30",
                        duration: 90,
                        type: "core",
                        isCore: true
                    ),
                    SleepBlock(
                        startTime: "14:00",
                        duration: 20,
                        type: "nap",
                        isCore: false
                    ),
                    SleepBlock(
                        startTime: "18:30",
                        duration: 20,
                        type: "nap",
                        isCore: false
                    )
                ],
                isPremium: true
            )
        ]
        
        // ID'ye göre programı döndür
        return schedules[id]
    }
    
    // MARK: - Score Hesaplama
    private func calculateScheduleScore(_ schedule: SleepScheduleModel, factors: UserFactors) -> Double {
        var score = 1.0
        
        print("\nPuanlama - \(schedule.name):")
        
        // 1) Sleep Experience
        switch factors.sleepExperience {
        case .none:        
            score *= 0.7
            print("- Sleep Experience (.none): 0.7 -> score: \(score)")
        case .some:        
            score *= 0.8
            print("- Sleep Experience (.some): 0.8 -> score: \(score)")
        case .moderate:    
            score *= 0.9
            print("- Sleep Experience (.moderate): 0.9 -> score: \(score)")
        case .extensive:   
            score *= 1.0
            print("- Sleep Experience (.extensive): 1.0 -> score: \(score)")
        }
        
        // 2) Age Range
        switch factors.ageRange {
        case .under18:
            // 18 yaş altıysanız, çok ekstrem düzenleri istemeyebiliriz
            score *= 0.6
            print("- Age Range (.under18): 0.6 -> score: \(score)")
        case .age18to24:
            score *= 1.0
            print("- Age Range (.age18to24): 1.0 -> score: \(score)")
        case .age25to34:
            score *= 0.9
            print("- Age Range (.age25to34): 0.9 -> score: \(score)")
        case .age35to44:
            score *= 0.8
            print("- Age Range (.age35to44): 0.8 -> score: \(score)")
        case .age45to54:
            score *= 0.7
            print("- Age Range (.age45to54): 0.7 -> score: \(score)")
        case .age55Plus:
            score *= 0.6
            print("- Age Range (.age55Plus): 0.6 -> score: \(score)")
        }
        
        // 3) Work Schedule
        switch factors.workSchedule {
        case .flexible:
            score *= 1.0
            print("- Work Schedule (.flexible): 1.0 -> score: \(score)")
        case .regular:
            score *= 0.9
            print("- Work Schedule (.regular): 0.9 -> score: \(score)")
        case .irregular:
            score *= 0.7
            print("- Work Schedule (.irregular): 0.7 -> score: \(score)")
        case .shift:
            score *= 0.6
            print("- Work Schedule (.shift): 0.6 -> score: \(score)")
        }
        
        // 4) Nap Environment (only matters if napCount>0)
        let napCount = schedule.schedule.filter { !$0.isCore }.count
        if napCount > 0 {
            switch factors.napEnvironment {
            case .ideal:
                score *= 1.0
                print("- Nap Environment (.ideal): 1.0 -> score: \(score)")
            case .suitable:
                score *= 0.9
                print("- Nap Environment (.suitable): 0.9 -> score: \(score)")
            case .limited:
                score *= 0.7
                print("- Nap Environment (.limited): 0.7 -> score: \(score)")
            case .unsuitable:
                score *= 0.5
                print("- Nap Environment (.unsuitable): 0.5 -> score: \(score)")
            }
        }
        
        // 5) Lifestyle
        switch factors.lifestyle {
        case .calm:
            score *= 1.0
            print("- Lifestyle (.calm): 1.0 -> score: \(score)")
        case .moderatelyActive:
            score *= 0.9
            print("- Lifestyle (.moderatelyActive): 0.9 -> score: \(score)")
        case .veryActive:
            score *= 0.7
            print("- Lifestyle (.veryActive): 0.7 -> score: \(score)")
        }
        
        // 6) Knowledge Level
        switch factors.knowledgeLevel {
        case .beginner:
            score *= 0.8
            print("- Knowledge Level (.beginner): 0.8 -> score: \(score)")
        case .intermediate:
            score *= 0.9
            print("- Knowledge Level (.intermediate): 0.9 -> score: \(score)")
        case .advanced:
            score *= 1.0
            print("- Knowledge Level (.advanced): 1.0 -> score: \(score)")
        }
        
        // 7) Health Status
        switch factors.healthStatus {
        case .healthy:
            score *= 1.0
            print("- Health Status (.healthy): 1.0 -> score: \(score)")
        case .managedConditions:
            score *= 0.7
            print("- Health Status (.managedConditions): 0.7 -> score: \(score)")
        case .seriousConditions:
            score *= 0.4
            print("- Health Status (.seriousConditions): 0.4 -> score: \(score)")
        }
        
        // 8) Motivation
        switch factors.motivationLevel {
        case .low:
            score *= 0.7
            print("- Motivation Level (.low): 0.7 -> score: \(score)")
        case .moderate:
            score *= 0.85
            print("- Motivation Level (.moderate): 0.85 -> score: \(score)")
        case .high:
            score *= 1.0
            print("- Motivation Level (.high): 1.0 -> score: \(score)")
        }
        
        // ----------------------------------------------
        // YENİ 4 FAKTÖR
        // 9) Sleep Goal
        switch factors.sleepGoal {
        case .moreProductivity:
            // Daha fazla üretkenlik -> daha sık (polyphasic) ufak bonus
            if napCount >= 2 {
                score *= 1.1
                print("- Sleep Goal (.moreProductivity, napCount>=2): 1.1 -> score: \(score)")
            } else {
                print("- Sleep Goal (.moreProductivity, napCount<2): Değişiklik yok -> score: \(score)")
            }
        case .balancedLifestyle:
            // Dengeli yaşam -> çok fazla nap (5+) ceza
            if napCount >= 5 {
                score *= 0.8
                print("- Sleep Goal (.balancedLifestyle, napCount>=5): 0.8 -> score: \(score)")
            } else {
                print("- Sleep Goal (.balancedLifestyle, napCount<5): Değişiklik yok -> score: \(score)")
            }
        case .improveHealth:
            // Sağlığı iyileştirme -> 4 saatin altı total sleep ceza
            if schedule.totalSleepHours < 4.0 {
                score *= 0.6
                print("- Sleep Goal (.improveHealth, totalSleepHours<4): 0.6 -> score: \(score)")
            } else {
                print("- Sleep Goal (.improveHealth, totalSleepHours>=4): Değişiklik yok -> score: \(score)")
            }
        case .curiosity:
            // Deneysellik -> 2+ nap için hafif bonus
            if napCount >= 2 {
                score *= 1.05
                print("- Sleep Goal (.curiosity, napCount>=2): 1.05 -> score: \(score)")
            } else {
                print("- Sleep Goal (.curiosity, napCount<2): Değişiklik yok -> score: \(score)")
            }
        }
        
        // 10) Social Obligations
        switch factors.socialObligations {
        case .significant:
            // Çok sosyal yükümlülük -> çok nap'li schedule ceza
            if napCount >= 3 {
                score *= 0.75
                print("- Social Obligations (.significant, napCount>=3): 0.75 -> score: \(score)")
            } else {
                print("- Social Obligations (.significant, napCount<3): Değişiklik yok -> score: \(score)")
            }
        case .moderate:
            // Orta -> 6+ naps ceza
            if napCount >= 6 {
                score *= 0.7
                print("- Social Obligations (.moderate, napCount>=6): 0.7 -> score: \(score)")
            } else {
                print("- Social Obligations (.moderate, napCount<6): Değişiklik yok -> score: \(score)")
            }
        case .minimal:
            // Az -> polifazik'e bonus
            if napCount >= 4 {
                score *= 1.1
                print("- Social Obligations (.minimal, napCount>=4): 1.1 -> score: \(score)")
            } else {
                print("- Social Obligations (.minimal, napCount<4): Değişiklik yok -> score: \(score)")
            }
        }
        
        // 11) Disruption Tolerance
        switch factors.disruptionTolerance {
        case .verySensitive:
            // Uykusu bölünmeye hassas -> 2+ nap varsa ceza
            if napCount >= 2 {
                score *= 0.75
                print("- Disruption Tolerance (.verySensitive, napCount>=2): 0.75 -> score: \(score)")
            } else {
                print("- Disruption Tolerance (.verySensitive, napCount<2): Değişiklik yok -> score: \(score)")
            }
        case .somewhatSensitive:
            // Orta hassas -> 3+ nap varsa ceza
            if napCount >= 3 {
                score *= 0.85
                print("- Disruption Tolerance (.somewhatSensitive, napCount>=3): 0.85 -> score: \(score)")
            } else {
                print("- Disruption Tolerance (.somewhatSensitive, napCount<3): Değişiklik yok -> score: \(score)")
            }
        case .notSensitive:
            // Bölünmeye tolerant -> 3+ nap'a bonus
            if napCount >= 3 {
                score *= 1.1
                print("- Disruption Tolerance (.notSensitive, napCount>=3): 1.1 -> score: \(score)")
            } else {
                print("- Disruption Tolerance (.notSensitive, napCount<3): Değişiklik yok -> score: \(score)")
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
                print("- Chronotype (.morningLark, hasLateCore): 0.8 -> score: \(score)")
            } else {
                print("- Chronotype (.morningLark, !hasLateCore): Değişiklik yok -> score: \(score)")
            }
        case .nightOwl:
            // Gece kuşu -> eğer core sleep 22:00 gibi erken başlıyorsa ceza
            let hasEarlyCore = schedule.schedule.contains { block in
                block.isCore && (TimeFormatter.time(from: block.startTime)?.hour ?? 0) < 22
            }
            if hasEarlyCore {
                score *= 0.8
                print("- Chronotype (.nightOwl, hasEarlyCore): 0.8 -> score: \(score)")
            } else {
                print("- Chronotype (.nightOwl, !hasEarlyCore): Değişiklik yok -> score: \(score)")
            }
        case .neutral:
            // Nötr -> ek bir şey yok
            print("- Chronotype (.neutral): Değişiklik yok -> score: \(score)")
            break
        }
        
        // ----------------------------------------------
        // MONOPHASIC LOGİĞİNE EK PENALTY / BONUS
        
        if schedule.id == "monophasic" {
            
            // Yetişkin, sağlıklı, motivasyonu düşük olmayanlar -> Monophasic cezası
            let isAdult       = (factors.ageRange != .under18)
            let isHealthy     = (factors.healthStatus != .seriousConditions)
            let hasMotivation = (factors.motivationLevel == .moderate || factors.motivationLevel == .high)
            
            if isAdult && isHealthy && hasMotivation {
                score *= 0.2
                print("- Monophasic (yetişkin + healthy + motivated): 0.2 -> score: \(score)")
            }
        }
        
        // Son olarak 0..1.5 aralığına clamp
        let finalScore = max(0.0, min(1.5, score))
        print("- Final (clamped) score: \(finalScore)\n")
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
        
        // Naps varsa ama ortam "unsuitable" ise
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
