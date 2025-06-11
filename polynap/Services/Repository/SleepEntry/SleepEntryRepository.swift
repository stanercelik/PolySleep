import Foundation
import SwiftData
import OSLog

/// Sleep entry işlemleri için Repository
@MainActor
final class SleepEntryRepository: BaseRepository {
    
    static let shared = SleepEntryRepository()
    
    private override init() {
        super.init()
        logger.debug("💤 SleepEntryRepository başlatıldı")
    }
    
    // MARK: - Sleep Entry CRUD Methods
    
    /// Uyku girdisi ekler
    func addSleepEntry(blockId: String, emoji: String, rating: Int, date: Date) async throws -> SleepEntryEntity {
        // Kullanıcı kimliğini yerel kullanıcı modeline göre al ve UUID'ye dönüştür
        let userIdString = authManager.currentUser?.id ?? "unknown" 
        let userId = UUID(uuidString: userIdString) ?? UUID() // Geçerli değilse yeni UUID oluştur
        
        let syncId = UUID().uuidString
        logger.debug("🗂️ Yeni uyku girdisi ekleniyor, blockId: \(blockId), syncId: \(syncId)")
        
        let entry = SleepEntryEntity(
            userId: userId,
            date: date,
            blockId: blockId,
            emoji: emoji,
            rating: rating,
            syncId: syncId
        )
        
        do {
            try insert(entry)
            try save()
            logger.debug("✅ Uyku girdisi başarıyla kaydedildi, ID: \(entry.id.uuidString)")
        } catch {
            logger.error("❌ Uyku girdisi kaydedilirken hata: \(error.localizedDescription)")
            throw RepositoryError.saveFailed
        }
        
        return entry
    }
    
    /// Belirli bir tarih için uyku girdilerini getirir
    func getSleepEntries(for date: Date) throws -> [SleepEntryEntity] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let descriptor = FetchDescriptor<SleepEntryEntity>(
            predicate: #Predicate<SleepEntryEntity> { entry in
                entry.date >= startOfDay && entry.date < endOfDay
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            let entries = try fetch(descriptor)
            logger.debug("🗂️ \(date.formatted(date: .abbreviated, time: .omitted)) tarihi için \(entries.count) uyku girdisi getirildi")
            return entries
        } catch {
            logger.error("❌ Uyku girdileri getirilirken hata: \(error.localizedDescription)")
            throw RepositoryError.fetchFailed
        }
    }
    
    /// Belirli bir kullanıcının tüm uyku girdilerini getirir
    func getAllSleepEntries(for userId: UUID) throws -> [SleepEntryEntity] {
        let descriptor = FetchDescriptor<SleepEntryEntity>(
            predicate: #Predicate<SleepEntryEntity> { entry in
                entry.userId == userId
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let entries = try fetch(descriptor)
            logger.debug("🗂️ Kullanıcı \(userId.uuidString) için \(entries.count) uyku girdisi getirildi")
            return entries
        } catch {
            logger.error("❌ Kullanıcı uyku girdileri getirilirken hata: \(error.localizedDescription)")
            throw RepositoryError.fetchFailed
        }
    }
    
    /// Uyku girdisini günceller
    func updateSleepEntry(_ entry: SleepEntryEntity, emoji: String? = nil, rating: Int? = nil) throws {
        if let emoji = emoji {
            entry.emoji = emoji
        }
        
        if let rating = rating {
            entry.rating = rating
        }
        
        entry.updatedAt = Date()
        
        do {
            try save()
            logger.debug("✅ Uyku girdisi güncellendi: \(entry.id.uuidString)")
        } catch {
            logger.error("❌ Uyku girdisi güncellenirken hata: \(error.localizedDescription)")
            throw RepositoryError.updateFailed
        }
    }
    
    /// Uyku girdisini siler
    func deleteSleepEntry(_ entry: SleepEntryEntity) throws {
        do {
            try delete(entry)
            try save()
            logger.debug("✅ Uyku girdisi silindi: \(entry.id.uuidString)")
        } catch {
            logger.error("❌ Uyku girdisi silinirken hata: \(error.localizedDescription)")
            throw RepositoryError.deleteFailed
        }
    }
    
    /// Belirli bir tarih aralığı için uyku girdilerini getirir
    func getSleepEntries(from startDate: Date, to endDate: Date) throws -> [SleepEntryEntity] {
        let descriptor = FetchDescriptor<SleepEntryEntity>(
            predicate: #Predicate<SleepEntryEntity> { entry in
                entry.date >= startDate && entry.date <= endDate
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            let entries = try fetch(descriptor)
            logger.debug("🗂️ \(startDate.formatted(date: .abbreviated, time: .omitted)) - \(endDate.formatted(date: .abbreviated, time: .omitted)) aralığı için \(entries.count) uyku girdisi getirildi")
            return entries
        } catch {
            logger.error("❌ Tarih aralığı uyku girdileri getirilirken hata: \(error.localizedDescription)")
            throw RepositoryError.fetchFailed
        }
    }
    
    /// Belirli bir blok ID için uyku girdilerini getirir
    func getSleepEntries(for blockId: String) throws -> [SleepEntryEntity] {
        let descriptor = FetchDescriptor<SleepEntryEntity>(
            predicate: #Predicate<SleepEntryEntity> { entry in
                entry.blockId == blockId
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let entries = try fetch(descriptor)
            logger.debug("🗂️ Blok \(blockId) için \(entries.count) uyku girdisi getirildi")
            return entries
        } catch {
            logger.error("❌ Blok uyku girdileri getirilirken hata: \(error.localizedDescription)")
            throw RepositoryError.fetchFailed
        }
    }
    
    /// Son N gün için uyku girdilerini getirir
    func getRecentSleepEntries(dayCount: Int) throws -> [SleepEntryEntity] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -dayCount, to: endDate) ?? endDate
        
        return try getSleepEntries(from: startDate, to: endDate)
    }
    
    /// Uyku girdisi istatistiklerini hesaplar
    func calculateSleepEntryStats(for userId: UUID, dayCount: Int = 30) throws -> SleepEntryStats {
        let entries = try getRecentSleepEntries(dayCount: dayCount)
        let userEntries = entries.filter { $0.userId == userId }
        
        guard !userEntries.isEmpty else {
            return SleepEntryStats(totalEntries: 0, averageRating: 0.0, mostUsedEmoji: "", entryCount: 0)
        }
        
        let totalEntries = userEntries.count
        let averageRating = Double(userEntries.map { $0.rating }.reduce(0, +)) / Double(totalEntries)
        
        // En çok kullanılan emoji
        let emojiCounts = Dictionary(grouping: userEntries) { $0.emoji }
            .mapValues { $0.count }
        let mostUsedEmoji = emojiCounts.max(by: { $0.value < $1.value })?.key ?? ""
        
        logger.debug("📊 Kullanıcı \(userId.uuidString) için son \(dayCount) gün istatistikleri: \(totalEntries) girdi, ortalama rating: \(averageRating)")
        
        return SleepEntryStats(
            totalEntries: totalEntries,
            averageRating: averageRating,
            mostUsedEmoji: mostUsedEmoji,
            entryCount: totalEntries
        )
    }
}

/// Uyku girdisi istatistikleri için model
struct SleepEntryStats {
    let totalEntries: Int
    let averageRating: Double
    let mostUsedEmoji: String
    let entryCount: Int
} 