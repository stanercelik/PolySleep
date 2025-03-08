import Foundation

/// Supabase'den alınan kullanıcı uyku bloğu modeli
struct UserSleepBlock: Codable {
    let id: UUID
    let scheduleId: UUID
    let startTime: String
    let durationMinutes: Int
    let isCore: Bool
    let createdAt: Date
    let updatedAt: Date
    let syncId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case scheduleId = "schedule_id"
        case startTime = "start_time"
        case durationMinutes = "duration_minutes"
        case isCore = "is_core"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case syncId = "sync_id"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // UUID'leri string'den dönüştür
        let idString = try container.decode(String.self, forKey: .id)
        id = UUID(uuidString: idString) ?? UUID()
        
        let scheduleIdString = try container.decode(String.self, forKey: .scheduleId)
        scheduleId = UUID(uuidString: scheduleIdString) ?? UUID()
        
        // Zaman bilgisini decode et
        startTime = try container.decode(String.self, forKey: .startTime)
        
        // Süreyi decode et
        if let durationInt = try? container.decode(Int.self, forKey: .durationMinutes) {
            durationMinutes = durationInt
        } else if let durationString = try? container.decode(String.self, forKey: .durationMinutes) {
            durationMinutes = Int(durationString) ?? 0
        } else {
            durationMinutes = 0
        }
        
        // Boolean değeri decode et
        if let isCoreBool = try? container.decode(Bool.self, forKey: .isCore) {
            isCore = isCoreBool
        } else if let isCoreString = try? container.decode(String.self, forKey: .isCore) {
            isCore = isCoreString.lowercased() == "true"
        } else {
            isCore = false
        }
        
        // Tarihleri decode et
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        // Opsiyonel sync_id'yi decode et
        syncId = try container.decodeIfPresent(String.self, forKey: .syncId)
    }
}
