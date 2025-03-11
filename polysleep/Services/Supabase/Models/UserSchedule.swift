import Foundation

/// Supabase'den alınan kullanıcı uyku programı modeli
struct UserSchedule: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let description: String // JSON formatında LocalizedDescription
    let totalSleepHours: Double
    let adaptationPhase: Int
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case description
        case totalSleepHours = "total_sleep_hours"
        case adaptationPhase = "adaptation_phase"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // UUID'leri string'den dönüştür
        let idString = try container.decode(String.self, forKey: .id)
        id = UUID(uuidString: idString) ?? UUID()
        
        let userIdString = try container.decode(String.self, forKey: .userId)
        userId = UUID(uuidString: userIdString) ?? UUID()
        
        // Diğer alanları decode et
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        
        // Sayısal değerleri decode et
        if let totalSleepHoursDouble = try? container.decode(Double.self, forKey: .totalSleepHours) {
            totalSleepHours = totalSleepHoursDouble
        } else if let totalSleepHoursString = try? container.decode(String.self, forKey: .totalSleepHours) {
            totalSleepHours = Double(totalSleepHoursString) ?? 0.0
        } else {
            totalSleepHours = 0.0
        }
        
        if let isActiveBool = try? container.decode(Bool.self, forKey: .isActive) {
            isActive = isActiveBool
        } else if let isActiveString = try? container.decode(String.self, forKey: .isActive) {
            isActive = isActiveString.lowercased() == "true"
        } else {
            isActive = false
        }
        
        // Adaptasyon fazını decode et
        if let adaptationPhaseInt = try? container.decode(Int.self, forKey: .adaptationPhase) {
            adaptationPhase = adaptationPhaseInt
        } else if let adaptationPhaseString = try? container.decode(String.self, forKey: .adaptationPhase) {
            adaptationPhase = Int(adaptationPhaseString) ?? 0
        } else {
            adaptationPhase = 0
        }
        
        // Tarihleri decode et
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    /// UserScheduleModel'e dönüştürme
    func toUserScheduleModel(with blocks: [UserSleepBlock]) -> UserScheduleModel {
        // JSON'dan LocalizedDescription oluştur
        let localizedDescription = parseDescription(from: description)
        
        // SleepBlock listesi oluştur
        let sleepBlocks = blocks.map { block in
            SleepBlock(
                startTime: block.startTime.replacingOccurrences(of: ":00$", with: "", options: .regularExpression),
                duration: block.durationMinutes,
                type: block.isCore ? "core" : "nap",
                isCore: block.isCore
            )
        }
        
        return UserScheduleModel(
            id: id.uuidString,
            name: name,
            description: localizedDescription,
            totalSleepHours: totalSleepHours,
            schedule: sleepBlocks,
            isPremium: false
        )
    }
    
    /// JSON formatındaki açıklamayı LocalizedDescription'a dönüştürür
    private func parseDescription(from jsonString: String) -> LocalizedDescription {
        let decoder = JSONDecoder()
        
        do {
            guard let jsonData = jsonString.data(using: .utf8) else {
                return LocalizedDescription(en: "", tr: "")
            }
            
            let descDict = try decoder.decode([String: String].self, from: jsonData)
            return LocalizedDescription(
                en: descDict["en"] ?? "",
                tr: descDict["tr"] ?? ""
            )
        } catch {
            print("PolySleep Debug: Açıklama JSON parse hatası: \(error)")
            return LocalizedDescription(en: "", tr: "")
        }
    }
}
