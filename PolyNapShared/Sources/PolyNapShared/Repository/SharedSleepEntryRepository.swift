import Foundation
import SwiftData
import OSLog

/// Shared sleep entry yönetimi işlemleri için Repository
/// iOS ve watchOS platformları arasında SharedSleepEntry modeli ile çalışır
@MainActor
public final class SharedSleepEntryRepository: SharedBaseRepository {
    
    public static let shared = SharedSleepEntryRepository()
    
    private override init() {
        super.init()
        logger.debug("💤 SharedSleepEntryRepository başlatıldı")
    }
    
    // MARK: - Sleep Entry CRUD Methods
    
    /// Yeni SharedSleepEntry oluşturur
    public func createSleepEntry(user: SharedUser,
                                date: Date,
                                startTime: Date,
                                endTime: Date,
                                durationMinutes: Int,
                                isCore: Bool,
                                blockId: String? = nil,
                                emoji: String? = nil,
                                rating: Int = 0,
                                syncId: String? = nil) async throws -> SharedSleepEntry {
        
        let sleepEntry = SharedSleepEntry(
            user: user,
            date: date,
            startTime: startTime,
            endTime: endTime,
            durationMinutes: durationMinutes,
            isCore: isCore,
            blockId: blockId,
            emoji: emoji,
            rating: rating,
            syncId: syncId
        )
        
        do {
            try insert(sleepEntry)
            try save()
            logger.debug("✅ Yeni SharedSleepEntry oluşturuldu: \(date.formatted(date: .abbreviated, time: .omitted))")
        } catch {
            logger.error("❌ SharedSleepEntry oluşturulurken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.saveFailed
        }
        
        return sleepEntry
    }
    
    /// Belirli bir tarih için SharedSleepEntry'leri getirir
    public func getSleepEntries(for date: Date) throws -> [SharedSleepEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let descriptor = FetchDescriptor<SharedSleepEntry>(
            predicate: #Predicate<SharedSleepEntry> { entry in
                entry.date >= startOfDay && entry.date < endOfDay
            },
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        
        do {
            let entries = try fetch(descriptor)
            logger.debug("🗂️ \(date.formatted(date: .abbreviated, time: .omitted)) tarihi için \(entries.count) SharedSleepEntry getirildi")
            return entries
        } catch {
            logger.error("❌ SharedSleepEntry'ler getirilirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.fetchFailed
        }
    }
    
    /// Belirli kullanıcının tüm SharedSleepEntry'lerini getirir
    public func getSleepEntriesForUser(_ userId: UUID) throws -> [SharedSleepEntry] {
        let descriptor = FetchDescriptor<SharedSleepEntry>(
            predicate: #Predicate<SharedSleepEntry> { entry in
                entry.user?.id == userId
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let entries = try fetch(descriptor)
            logger.debug("🗂️ Kullanıcı \(userId.uuidString) için \(entries.count) SharedSleepEntry getirildi")
            return entries
        } catch {
            logger.error("❌ Kullanıcı SharedSleepEntry'leri getirilirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.fetchFailed
        }
    }
    
    /// Belirli bir tarih aralığındaki SharedSleepEntry'leri getirir
    public func getSleepEntries(from startDate: Date, to endDate: Date) throws -> [SharedSleepEntry] {
        let descriptor = FetchDescriptor<SharedSleepEntry>(
            predicate: #Predicate<SharedSleepEntry> { entry in
                entry.date >= startDate && entry.date <= endDate
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            let entries = try fetch(descriptor)
            logger.debug("🗂️ \(startDate.formatted(date: .abbreviated, time: .omitted)) - \(endDate.formatted(date: .abbreviated, time: .omitted)) aralığında \(entries.count) SharedSleepEntry getirildi")
            return entries
        } catch {
            logger.error("❌ Tarih aralığındaki SharedSleepEntry'ler getirilirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.fetchFailed
        }
    }
    
    /// ID ile SharedSleepEntry getirir
    public func getSleepEntryById(_ id: UUID) throws -> SharedSleepEntry? {
        let descriptor = FetchDescriptor<SharedSleepEntry>(
            predicate: #Predicate<SharedSleepEntry> { $0.id == id }
        )
        
        do {
            let entries = try fetch(descriptor)
            return entries.first
        } catch {
            logger.error("❌ SharedSleepEntry ID'ye göre getirilirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.fetchFailed
        }
    }
    
    /// SharedSleepEntry günceller
    public func updateSleepEntry(_ entry: SharedSleepEntry,
                                emoji: String? = nil,
                                rating: Int? = nil,
                                startTime: Date? = nil,
                                endTime: Date? = nil,
                                durationMinutes: Int? = nil) async throws {
        
        if let emoji = emoji {
            entry.emoji = emoji
        }
        if let rating = rating {
            entry.rating = rating
        }
        if let startTime = startTime {
            entry.startTime = startTime
        }
        if let endTime = endTime {
            entry.endTime = endTime
        }
        if let durationMinutes = durationMinutes {
            entry.durationMinutes = durationMinutes
        }
        
        entry.updatedAt = Date()
        
        do {
            try save()
            logger.debug("✅ SharedSleepEntry güncellendi: \(entry.date.formatted(date: .abbreviated, time: .omitted))")
        } catch {
            logger.error("❌ SharedSleepEntry güncellenirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.updateFailed
        }
    }
    
    /// SharedSleepEntry'nin kalite puanını günceller
    public func updateSleepQuality(entryId: UUID, rating: Int, emoji: String? = nil) async throws {
        guard let entry = try getSleepEntryById(entryId) else {
            throw SharedRepositoryError.entityNotFound
        }
        
        try await updateSleepEntry(entry, emoji: emoji, rating: rating)
    }
    
    /// SharedSleepEntry siler
    public func deleteSleepEntry(_ entry: SharedSleepEntry) async throws {
        do {
            try delete(entry)
            try save()
            logger.debug("🗑️ SharedSleepEntry silindi: \(entry.date.formatted(date: .abbreviated, time: .omitted))")
        } catch {
            logger.error("❌ SharedSleepEntry silinirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.deleteFailed
        }
    }
    
    /// Belirli blockId'ye sahip SharedSleepEntry'leri getirir
    public func getSleepEntriesForBlock(_ blockId: String) throws -> [SharedSleepEntry] {
        let descriptor = FetchDescriptor<SharedSleepEntry>(
            predicate: #Predicate<SharedSleepEntry> { entry in
                entry.blockId == blockId
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let entries = try fetch(descriptor)
            logger.debug("🗂️ Block \(blockId) için \(entries.count) SharedSleepEntry getirildi")
            return entries
        } catch {
            logger.error("❌ Block SharedSleepEntry'leri getirilirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.fetchFailed
        }
    }
    
    /// Tüm SharedSleepEntry'leri getirir (debugging amaçlı)
    public func getAllSleepEntries() throws -> [SharedSleepEntry] {
        let descriptor = FetchDescriptor<SharedSleepEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let entries = try fetch(descriptor)
            logger.debug("🗂️ Toplam \(entries.count) SharedSleepEntry getirildi")
            return entries
        } catch {
            logger.error("❌ Tüm SharedSleepEntry'ler getirilirken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.fetchFailed
        }
    }
    
    /// Son N gün için uyku istatistiklerini hesaplar
    public func getSleepStatistics(userId: UUID, days: Int = 7) throws -> SleepStatistics {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        let descriptor = FetchDescriptor<SharedSleepEntry>(
            predicate: #Predicate<SharedSleepEntry> { entry in
                entry.user?.id == userId && entry.date >= startDate && entry.date <= endDate
            }
        )
        
        do {
            let entries = try fetch(descriptor)
            
            let totalSleepMinutes = entries.reduce(0) { $0 + $1.durationMinutes }
            let averageSleepMinutes = entries.isEmpty ? 0 : totalSleepMinutes / entries.count
            let totalSessions = entries.count
            let coreSeconds = entries.filter { $0.isCore }.reduce(0) { $0 + $1.durationMinutes }
            let napSessions = entries.filter { !$0.isCore }.count
            
            let averageRating = entries.isEmpty ? 0.0 : Double(entries.reduce(0) { $0 + $1.rating }) / Double(entries.count)
            
            logger.debug("📊 \(days) günlük istatistik: \(totalSessions) oturum, ortalama \(averageSleepMinutes) dakika")
            
            return SleepStatistics(
                totalSleepMinutes: totalSleepMinutes,
                averageSleepMinutes: averageSleepMinutes,
                totalSessions: totalSessions,
                coreSleepMinutes: coreSeconds,
                napSessions: napSessions,
                averageRating: averageRating,
                periodDays: days
            )
        } catch {
            logger.error("❌ Uyku istatistikleri hesaplanırken hata: \(error.localizedDescription)")
            throw SharedRepositoryError.fetchFailed
        }
    }
}

// MARK: - Sleep Statistics Model

/// Uyku istatistikleri için model
public struct SleepStatistics {
    public let totalSleepMinutes: Int
    public let averageSleepMinutes: Int
    public let totalSessions: Int
    public let coreSleepMinutes: Int
    public let napSessions: Int
    public let averageRating: Double
    public let periodDays: Int
    
    public var totalSleepHours: Double {
        return Double(totalSleepMinutes) / 60.0
    }
    
    public var averageSleepHours: Double {
        return Double(averageSleepMinutes) / 60.0
    }
    
    public var coreSleepHours: Double {
        return Double(coreSleepMinutes) / 60.0
    }
} 