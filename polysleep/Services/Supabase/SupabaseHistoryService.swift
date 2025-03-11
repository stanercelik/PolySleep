import Foundation
import Supabase

/// Uyku kayıtları için Supabase servisi
class SupabaseHistoryService {
    // Singleton instance
    static let shared = SupabaseHistoryService()
    
    // Supabase client
    private var client: SupabaseClient {
        return SupabaseService.shared.client
    }
    
    // Tablo adı
    private let tableName = "sleep_entries"
    
    // Private initializer for singleton pattern
    private init() {}
    
    // MARK: - Veri Transfer Nesnesi
    
    /// Supabase ile veri alışverişi için DTO
    struct SleepEntryDTO: Codable, Sendable {
        let id: UUID
        let user_id: UUID?
        let date: Date
        let block_id: String
        let emoji: String
        let rating: Int
        let sync_id: String
        var created_at: Date?
        var updated_at: Date?
        
        enum CodingKeys: String, CodingKey {
            case id, user_id, date, block_id, emoji, rating, sync_id, created_at, updated_at
        }
        
        // Özel init decoder için
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            id = try container.decode(UUID.self, forKey: .id)
            user_id = try container.decodeIfPresent(UUID.self, forKey: .user_id)
            block_id = try container.decode(String.self, forKey: .block_id)
            emoji = try container.decode(String.self, forKey: .emoji)
            rating = try container.decode(Int.self, forKey: .rating)
            sync_id = try container.decode(String.self, forKey: .sync_id)
            
            // Date alanı için özel çözme stratejisi
            if let dateString = try? container.decode(String.self, forKey: .date) {
                date = try Self.parseDate(dateString)
            } else if let dateDouble = try? container.decode(Double.self, forKey: .date) {
                date = Date(timeIntervalSince1970: dateDouble)
            } else {
                throw DecodingError.typeMismatch(Date.self, DecodingError.Context(codingPath: [CodingKeys.date], debugDescription: "Expected date string or timestamp", underlyingError: nil))
            }
            
            // created_at ve updated_at için benzer strateji
            if let createdAtString = try? container.decode(String.self, forKey: .created_at) {
                created_at = try? Self.parseDate(createdAtString)
            } else {
                created_at = try container.decodeIfPresent(Date.self, forKey: .created_at)
            }
            
            if let updatedAtString = try? container.decode(String.self, forKey: .updated_at) {
                updated_at = try? Self.parseDate(updatedAtString)
            } else {
                updated_at = try container.decodeIfPresent(Date.self, forKey: .updated_at)
            }
        }
        
        // Özel encode metodu
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(id, forKey: .id)
            try container.encodeIfPresent(user_id, forKey: .user_id)
            try container.encode(block_id, forKey: .block_id)
            try container.encode(emoji, forKey: .emoji)
            try container.encode(rating, forKey: .rating)
            try container.encode(sync_id, forKey: .sync_id)
            
            // Tarihleri ISO8601 formatında kodlama
            try container.encode(Self.formatDateForSupabase(date), forKey: .date)
            
            if let createdAt = created_at {
                try container.encode(Self.formatDateForSupabase(createdAt), forKey: .created_at)
            }
            
            if let updatedAt = updated_at {
                try container.encode(Self.formatDateForSupabase(updatedAt), forKey: .updated_at)
            }
        }
        
        // Standart init
        init(id: UUID, user_id: UUID?, date: Date, block_id: String, emoji: String, rating: Int, sync_id: String, created_at: Date? = nil, updated_at: Date? = nil) {
            self.id = id
            self.user_id = user_id
            self.date = date
            self.block_id = block_id
            self.emoji = emoji
            self.rating = rating
            self.sync_id = sync_id
            self.created_at = created_at
            self.updated_at = updated_at
        }
        
        // Tarih çözümleme yardımcı metodu
        private static func parseDate(_ dateString: String) throws -> Date {
            // Farklı tarih formatlarını deneyelim
            let formatters: [(DateFormatter, String)] = [
                // ISO8601 formatları
                createDateFormatter(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ", description: "ISO8601 with milliseconds"),
                createDateFormatter(format: "yyyy-MM-dd'T'HH:mm:ssZ", description: "ISO8601 without milliseconds"),
                createDateFormatter(format: "yyyy-MM-dd'T'HH:mm:ss.SSS", description: "ISO8601 without timezone"),
                createDateFormatter(format: "yyyy-MM-dd'T'HH:mm:ss", description: "ISO8601 basic"),
                
                // PostgreSQL formatları
                createDateFormatter(format: "yyyy-MM-dd HH:mm:ss.SSSZ", description: "PostgreSQL with timezone"),
                createDateFormatter(format: "yyyy-MM-dd HH:mm:ssZ", description: "PostgreSQL with timezone"),
                createDateFormatter(format: "yyyy-MM-dd HH:mm:ss", description: "PostgreSQL basic"),
                
                // Basit formatlar
                createDateFormatter(format: "yyyy-MM-dd", description: "Simple date")
            ]
            
            // ISO8601DateFormatter da deneyelim
            let iso8601Formatters = [
                createISO8601Formatter(options: [.withInternetDateTime, .withFractionalSeconds], description: "Full ISO8601"),
                createISO8601Formatter(options: [.withInternetDateTime], description: "ISO8601 without fractions"),
                createISO8601Formatter(options: [.withFullDate, .withTime, .withTimeZone], description: "ISO8601 with timezone"),
                createISO8601Formatter(options: [.withFullDate, .withTime], description: "ISO8601 without timezone")
            ]
            
            // DateFormatter'ları deneyelim
            for (formatter, description) in formatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            // ISO8601DateFormatter'ları deneyelim
            for (formatter, description) in iso8601Formatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            // Hiçbir format uymadıysa hata fırlat
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: [CodingKeys.date],
                debugDescription: "Date string does not match any known format: \(dateString)",
                underlyingError: nil
            ))
        }
        
        // DateFormatter oluşturma yardımcı metodu
        private static func createDateFormatter(format: String, description: String) -> (DateFormatter, String) {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return (formatter, description)
        }
        
        // ISO8601DateFormatter oluşturma yardımcı metodu
        private static func createISO8601Formatter(options: ISO8601DateFormatter.Options, description: String) -> (ISO8601DateFormatter, String) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = options
            return (formatter, description)
        }
        
        // Supabase için tarih formatlama
        private static func formatDateForSupabase(_ date: Date) -> String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter.string(from: date)
        }
    }
    
    // MARK: - CRUD İşlemleri
    
    /// Tüm uyku kayıtlarını getirir
    /// - Returns: Uyku kayıtları listesi
    @MainActor
    func fetchAllSleepEntries() async throws -> [SleepEntryDTO] {
        do {
            let response = try await client
                .from(tableName)
                .select()
                .execute()
            
            let data = response.data
            let entries = try JSONDecoder().decode([SleepEntryDTO].self, from: data)
            return entries
        } catch {
            print("PolySleep Debug: Uyku kayıtları getirilirken hata oluştu: \(error)")
            throw error
        }
    }
    
    /// Belirli bir tarihe ait uyku kayıtlarını getirir
    /// - Parameter date: Tarih
    /// - Returns: Uyku kayıtları listesi
    @MainActor
    func fetchSleepEntries(for date: Date) async throws -> [SleepEntryDTO] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let startDateString = dateFormatter.string(from: startOfDay)
        let endDateString = dateFormatter.string(from: endOfDay)
        
        do {
            let response = try await client
                .from(tableName)
                .select()
                .gte("date", value: startDateString)
                .lt("date", value: endDateString)
                .execute()
            
            let data = response.data
            let entries = try JSONDecoder().decode([SleepEntryDTO].self, from: data)
            return entries
        } catch {
            print("PolySleep Debug: Belirli tarih için uyku kayıtları getirilirken hata oluştu: \(error)")
            throw error
        }
    }
    
    /// Yeni bir uyku kaydı ekler
    /// - Parameter entry: Eklenecek uyku kaydı
    /// - Returns: Eklenen uyku kaydı
    @MainActor
    func addSleepEntry(_ entry: SleepEntryDTO) async throws -> SleepEntryDTO {
        do {
            let response = try await client
                .from(tableName)
                .insert(entry)
                .select()
                .single()
                .execute()
            
            let data = response.data
            let addedEntry = try JSONDecoder().decode(SleepEntryDTO.self, from: data)
            return addedEntry
        } catch {
            print("PolySleep Debug: Uyku kaydı eklenirken hata oluştu: \(error)")
            throw error
        }
    }
    
    /// Bir uyku kaydını günceller
    /// - Parameter entry: Güncellenecek uyku kaydı
    /// - Returns: Güncellenen uyku kaydı
    @MainActor
    func updateSleepEntry(_ entry: SleepEntryDTO) async throws -> SleepEntryDTO {
        do {
            let response = try await client
                .from(tableName)
                .update(entry)
                .eq("id", value: entry.id.uuidString)
                .select()
                .single()
                .execute()
            
            let data = response.data
            let updatedEntry = try JSONDecoder().decode(SleepEntryDTO.self, from: data)
            return updatedEntry
        } catch {
            print("PolySleep Debug: Uyku kaydı güncellenirken hata oluştu: \(error)")
            throw error
        }
    }
    
    /// Bir uyku kaydını siler
    /// - Parameter id: Silinecek uyku kaydının ID'si
    @MainActor
    func deleteSleepEntry(id: UUID) async throws {
        do {
            _ = try await client
                .from(tableName)
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        } catch {
            print("PolySleep Debug: Uyku kaydı silinirken hata oluştu: \(error)")
            throw error
        }
    }
    
    /// Belirli bir sync_id'ye sahip uyku kaydını kontrol eder
    /// - Parameter syncId: Kontrol edilecek sync_id
    /// - Returns: Uyku kaydı varsa true, yoksa false
    @MainActor
    func checkSleepEntryExists(syncId: String) async throws -> Bool {
        do {
            let response = try await client
                .from(tableName)
                .select("id")
                .eq("sync_id", value: syncId)
                .execute()
            
            let data = response.data
            let entries = try JSONDecoder().decode([SleepEntryDTO].self, from: data)
            return !entries.isEmpty
        } catch {
            print("PolySleep Debug: Uyku kaydı kontrolü sırasında hata oluştu: \(error)")
            throw error
        }
    }
}
