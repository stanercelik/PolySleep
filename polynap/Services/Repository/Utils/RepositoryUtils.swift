import Foundation
import SwiftData

/// Repository için yardımcı fonksiyonlar ve veri dönüştürücüler
struct RepositoryUtils {
    
    // MARK: - Data Conversion Methods
    
    /// LocalizedDescription'ı JSON string'e çevirir
    static func encodeScheduleDescription(_ description: LocalizedDescription) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: [
            "en": description.en,
            "tr": description.tr,
            "ja": description.ja,
            "de": description.de,
            "ms": description.ms,
            "th": description.th
        ])
        return String(data: data, encoding: .utf8) ?? "{}"
    }
    
    /// "HH:mm" formatındaki string'i Date'e çevirir
    static func convertTimeStringToDate(_ timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_GB") // 24 saatlik format için zorla
        
        // Bugünün tarihini al ve sadece saat/dakikayı ayarla
        let today = Date()
        let calendar = Calendar.current
        
        if let time = formatter.date(from: timeString) {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(bySettingHour: timeComponents.hour ?? 0, 
                               minute: timeComponents.minute ?? 0, 
                               second: 0, 
                               of: today) ?? today
        }
        
        return today
    }
    
    // MARK: - Entity Conversion Methods
    
    /// ScheduleEntity'i UserScheduleModel'e dönüştüren yardımcı metot
    static func convertEntityToUserScheduleModel(_ entity: ScheduleEntity) -> UserScheduleModel {
        // Açıklama JSON verisini çöz
        var description = LocalizedDescription(en: "", tr: "", ja: "", de: "", ms: "", th: "")
        if let jsonData = entity.descriptionJson.data(using: .utf8) {
            if let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                if let en = dict["en"] as? String, let tr = dict["tr"] as? String,let ja = dict["ja"] as? String,let de = dict["de"] as? String,let ms = dict["ms"] as? String,let th = dict["th"] as? String {
                    description = LocalizedDescription(en: en, tr: tr, ja: ja, de: de, ms: ms, th: th)
                }
            }
        }
        
        // Uyku bloklarını dönüştür
        let sleepBlocks = entity.sleepBlocks.map { blockEntity -> SleepBlock in
            return SleepBlock(
                startTime: blockEntity.startTime,
                duration: blockEntity.durationMinutes,
                type: blockEntity.isCore ? "core" : "nap",
                isCore: blockEntity.isCore
            )
        }
        
        // UserScheduleModel oluştur
        return UserScheduleModel(
            id: entity.id.uuidString,
            name: entity.name,
            description: description,
            totalSleepHours: entity.totalSleepHours,
            schedule: sleepBlocks,
            isPremium: false // ScheduleEntity'de bu özellik olmadığı için varsayılan değer
        )
    }
    
    /// UserSchedule entity'sini UserScheduleModel'e dönüştürür
    static func convertUserScheduleToModel(_ schedule: UserSchedule) -> UserScheduleModel {
        let description: LocalizedDescription
        if let descData = schedule.scheduleDescription?.data(using: .utf8),
           let json = try? JSONDecoder().decode([String: String].self, from: descData) {
            
            // Tüm dillerin mevcut olup olmadığını kontrol et
            let hasAllLanguages = json["en"] != nil && json["tr"] != nil && 
                                 json["ja"] != nil && json["de"] != nil && 
                                 json["ms"] != nil && json["th"] != nil
            
            if hasAllLanguages {
                // Tam JSON mevcut, direkt kullan
                description = LocalizedDescription(
                    en: json["en"] ?? "", 
                    tr: json["tr"] ?? "", 
                    ja: json["ja"] ?? "", 
                    de: json["de"] ?? "", 
                    ms: json["ms"] ?? "", 
                    th: json["th"] ?? ""
                )
            } else {
                // Eksik diller var, JSON'dan fallback yap
                description = createDescriptionWithJSONFallback(
                    existingJson: json, 
                    scheduleName: schedule.name
                )
            }
        } else {
            // JSON decode edilemedi, fallback kullan
            description = createDescriptionWithJSONFallback(
                existingJson: [:], 
                scheduleName: schedule.name
            )
        }

        let sleepBlocks = (schedule.sleepBlocks ?? []).map { block in
            // 24 saatlik format için DateFormatter kullan
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            formatter.locale = Locale(identifier: "en_GB")
            
            return SleepBlock(
                startTime: formatter.string(from: block.startTime),
                duration: block.durationMinutes,
                type: block.isCore ? "core" : "nap",
                isCore: block.isCore
            )
        }
        
        return UserScheduleModel(
            id: schedule.id.uuidString,
            name: schedule.name,
            description: description,
            totalSleepHours: schedule.totalSleepHours ?? 0,
            schedule: sleepBlocks,
            isPremium: false // Gerekirse bu bilgiyi de UserSchedule'a ekleyin
        )
    }
    
    // MARK: - Adaptation Phase Calculation
    
    /// Belirli bir gün numarası için adaptasyon fazını hesapla
    static func calculateAdaptationPhaseForDay(dayNumber: Int, schedule: UserSchedule) -> Int {
        let scheduleName = schedule.name.lowercased()
        let adaptationDuration: Int
        
        if scheduleName.contains("uberman") || 
           scheduleName.contains("dymaxion") ||
           (scheduleName.contains("everyman") && scheduleName.contains("1")) {
            adaptationDuration = 28
        } else {
            adaptationDuration = 21
        }
        
        let phase: Int
        
        if adaptationDuration == 28 {
            // 28 günlük programlar için
            switch dayNumber {
            case 1:
                phase = 0  // İlk gün - Başlangıç
            case 2...7:
                phase = 1  // 2-7. günler - İlk Adaptasyon
            case 8...14:
                phase = 2  // 8-14. günler - Orta Adaptasyon
            case 15...21:
                phase = 3  // 15-21. günler - İlerlemiş Adaptasyon
            case 22...28:
                phase = 4  // 22-28. günler - İleri Adaptasyon
            default:
                phase = 5  // 28+ günler - Tamamlanmış
            }
        } else {
            // 21 günlük programlar için
            switch dayNumber {
            case 1:
                phase = 0  // İlk gün - Başlangıç
            case 2...7:
                phase = 1  // 2-7. günler - İlk Adaptasyon
            case 8...14:
                phase = 2  // 8-14. günler - Orta Adaptasyon
            case 15...21:
                phase = 3  // 15-21. günler - İlerlemiş Adaptasyon
            default:
                phase = 4  // 21+ günler - Tamamlanmış
            }
        }
        
        return phase
    }
    
    // MARK: - UUID Validation
    
    /// String'i güvenli bir şekilde UUID'ye çevirir
    static func safeUUID(from string: String) -> UUID {
        return UUID(uuidString: string) ?? UUID()
    }
    
    // MARK: - Fallback Description Helper
    
    /// Eksik dil açıklamaları için JSON'dan fallback yapan helper metot
    private static func createDescriptionWithJSONFallback(existingJson: [String: String], scheduleName: String) -> LocalizedDescription {
        print("🔍 DEBUG - createDescriptionWithJSONFallback: scheduleName='\(scheduleName)'")
        
        // JSON schedule'ları yükle
        guard let jsonSchedules = loadSchedulesFromJSONFile(),
              let matchingSchedule = findMatchingJSONSchedule(scheduleName: scheduleName, in: jsonSchedules) else {
            print("❌ JSON'dan eşleşen schedule bulunamadı: '\(scheduleName)'")
            // JSON'dan da bulunamazsa varsayılan açıklamaları kullan
            return LocalizedDescription(
                en: existingJson["en"] ?? "Sleep schedule description",
                tr: existingJson["tr"] ?? "Uyku programı açıklaması", 
                ja: existingJson["ja"] ?? "睡眠スケジュールの説明",
                de: existingJson["de"] ?? "Beschreibung des Schlafplans",
                ms: existingJson["ms"] ?? "Huraian jadual tidur",
                th: existingJson["th"] ?? "คำอธิบายตารางการนอน"
            )
        }
        
        print("✅ JSON'dan eşleşen schedule bulundu: '\(matchingSchedule.id)'")
        print("🔍 JSON Description - EN: '\(matchingSchedule.description.en.prefix(50))...'")
        print("🔍 JSON Description - TR: '\(matchingSchedule.description.tr.prefix(50))...'")
        print("🔍 JSON Description - MS: '\(matchingSchedule.description.ms.prefix(50))...'")
        
        // Database'de stored JSON'u tamamen yok say ve her zaman JSON'dan al
        return LocalizedDescription(
            en: matchingSchedule.description.en,
            tr: matchingSchedule.description.tr,
            ja: matchingSchedule.description.ja,
            de: matchingSchedule.description.de,
            ms: matchingSchedule.description.ms,
            th: matchingSchedule.description.th
        )
    }
    
    /// JSON dosyasından schedule'ları yükler (static metot)
    private static func loadSchedulesFromJSONFile() -> [SleepScheduleModel]? {
        guard let url = Bundle.main.url(forResource: "SleepSchedules", withExtension: "json") else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let response = try JSONDecoder().decode(SleepSchedulesContainer.self, from: data)
            return response.sleepSchedules
        } catch {
            return nil
        }
    }
    
    /// UserSchedule name'ini JSON schedule'ları arasında eşleştiren helper
    private static func findMatchingJSONSchedule(scheduleName: String, in schedules: [SleepScheduleModel]) -> SleepScheduleModel? {
        print("🔍 DEBUG - findMatchingJSONSchedule: scheduleName='\(scheduleName)'")
        print("🔍 DEBUG - Available JSON schedules: \(schedules.map { $0.id }.joined(separator: ", "))")
        // UserSchedule name'lerini JSON ID'lerine map et
        let nameMapping: [String: String] = [
            "Biphasic Sleep": "biphasic",
            "Extended Biphasic Sleep": "biphasic-extended",
            "Everyman": "everyman",
            "Everyman 2 (E2)": "everyman-e2",
            "Everyman 3 (E3)": "everyman-e3",
            "Everyman 4 (E4)": "everyman-e4",
            "Everyman E2 (Extended)": "everyman-e2-extended",
            "Everyman E3 (Extended)": "everyman-e3-extended",
            "Everyman E4 (Extended)": "everyman-e4-extended",
            "Everyman E5": "everyman-e5",
            "Everyman Sevarny": "everyman-sevarny",
            "Everyman Trimaxion": "everyman-trimaxion",
            "Biphasic E1 (Extended)": "biphasic-e1",
            "Biphasic (Siesta)": "biphasic-siesta",
            "Biphasic (Segmented)": "biphasic-segmented",
            "Biphasic X": "biphasic-x",
            "Dual Core Sleep": "dual-core",
            "Dual Core DC1": "dual-core-dc1",
            "Dual Core DC1 (Extended)": "dual-core-dc1-extended",
            "Dual Core DC2 (Extended)": "dual-core-dc2-extended",
            "Dual Core DC3": "dual-core-dc3",
            "Dual Core DAB": "dual-core-dab",
            "Dual Core Bimaxion": "dual-core-bimaxion",
            "Tri Core TC1": "tri-core-tc1",
            "Tri Core TC2": "tri-core-tc2",
            "Triphasic": "triphasic",
            "Triphasic (Alternative)": "triphasic-alt",
            "Segmented Sleep": "segmented",
            "Segmented Sleep (Late-Wake)": "segmented-alt",
            "Uberman": "uberman",
            "Dymaxion": "dymaxion",
            "Dymaxion (Alternative)": "dymaxion-alt",
            "Tesla": "nap-only-tesla",
            "Spamayl": "nap-only-spamayl"
        ]
        
        // Önce direkt mapping'den kontrol et
        if let mappedId = nameMapping[scheduleName] {
            return schedules.first { $0.id == mappedId }
        }
        
        // Alternatif olarak name'i normalize ederek ara
        let normalizedName = scheduleName.lowercased()
        for (mappingName, mappingId) in nameMapping {
            if mappingName.lowercased() == normalizedName {
                return schedules.first { $0.id == mappingId }
            }
        }
        
        return nil
    }
} 
