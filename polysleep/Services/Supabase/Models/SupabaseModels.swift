import Foundation

/// Uyku kaydı veri transfer nesnesi
struct SleepEntryDTO: Codable, Identifiable {
    let id: String
    let userId: String
    let date: Date
    let blockId: String
    let rating: Int
    let emoji: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case blockId = "block_id"
        case rating
        case emoji
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Uyku bloğu veri transfer nesnesi
struct BlockDTO: Codable, Identifiable {
    let id: String
    let scheduleId: String
    let startTime: Int // dakika cinsinden (00:00'dan itibaren)
    let endTime: Int // dakika cinsinden (00:00'dan itibaren)
    let type: String // "core" veya "nap"
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case scheduleId = "schedule_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case type
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Uyku programı veri transfer nesnesi
struct ScheduleDTO: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let type: String // "monophasic", "biphasic", "everyman", "dymaxion", "uberman", "custom"
    let createdAt: Date
    let updatedAt: Date
    let blocks: [BlockDTO]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case type
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case blocks
    }
}
