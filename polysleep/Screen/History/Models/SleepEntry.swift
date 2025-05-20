import SwiftData
import Foundation

// Eğer global olarak tanımlanmadıysa SleepType enum'ı
enum SleepTypeEnum: String, Codable, CaseIterable {
    case core = "Core"
    case powerNap = "Power Nap"
    // Gerekirse diğer türler eklenebilir
}

@Model
final class SleepEntry {
    @Attribute(.unique) var id: UUID
    var user: User? // User ile ilişki (Supabase: user_id)
    
    var date: Date // Genellikle uyku bloğunun başladığı gün/tarih
    
    var blockId: String? // Hangi schedule block'una ait olduğu (opsiyonel)
    var emoji: String?
    var rating: Int // 1-5 arası

    // Supabase'deki user_sleep_blocks tablosundan gelen alanlar:
    var startTime: Date // Bloğun kesin başlangıç zamanı (saat ve dakika dahil)
    var endTime: Date   // Bloğun kesin bitiş zamanı
    var durationMinutes: Int // Dakika cinsinden süre
    var isCore: Bool    // Ana uyku mu, şekerleme mi?

    var type: SleepType { // isCore'a göre hesaplanır
        isCore ? .core : .powerNap
    }
    
    var duration: TimeInterval { // Saniye cinsinden süre (hesaplanmış)
        Double(durationMinutes * 60)
    }

    var createdAt: Date
    var updatedAt: Date
    var syncId: String?

    // HistoryModel ile ters ilişki (bir uyku kaydı bir günlük geçmişe ait olabilir)
    var historyDay: HistoryModel?

    init(id: UUID = UUID(),
         user: User? = nil,
         date: Date, // Bloğun ait olduğu gün
         startTime: Date,
         endTime: Date,
         durationMinutes: Int,
         isCore: Bool,
         blockId: String? = nil,
         emoji: String? = nil,
         rating: Int = 0,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         syncId: String? = UUID().uuidString,
         historyDay: HistoryModel? = nil) {
        self.id = id
        self.user = user
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.isCore = isCore
        self.blockId = blockId
        self.emoji = emoji
        self.rating = rating
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncId = syncId
        self.historyDay = historyDay
    }
} 
