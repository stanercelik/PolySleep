import Foundation
import SwiftData
import OSLog

/// Schedule adaptasyon ilerlemesi undo data structure
struct ScheduleChangeUndoData: Codable {
    let scheduleId: UUID // Önceki schedule'ın ID'si (referans için)
    let changeDate: Date
    let previousStreak: Int
    let previousAdaptationPhase: Int
    let previousAdaptationDate: Date
}

/// Schedule adaptasyon ilerlemesini geri alma işlemleri için service
@MainActor
final class ScheduleUndoService: BaseRepository {
    
    static let shared = ScheduleUndoService()
    
    private override init() {
        super.init()
        logger.debug("↩️ ScheduleUndoService başlatıldı")
    }
    
    // MARK: - Undo Data Management
    
    /// Schedule değişiminden önce adaptasyon ilerlemesi bilgilerini kaydeder
    func saveScheduleChangeUndoData(scheduleId: UUID) async throws {
        let undoData = ScheduleChangeUndoData(
            scheduleId: scheduleId,
            changeDate: Date(),
            previousStreak: UserDefaults.standard.integer(forKey: "currentStreak"),
            previousAdaptationPhase: getCurrentAdaptationPhase(scheduleId: scheduleId),
            previousAdaptationDate: getCurrentAdaptationStartDate(scheduleId: scheduleId)
        )
        
        // UserDefaults'a undo verisini kaydet
        if let encoded = try? JSONEncoder().encode(undoData) {
            UserDefaults.standard.set(encoded, forKey: "scheduleChangeUndoData")
            logger.debug("📝 Adaptasyon ilerlemesi undo verisi kaydedildi")
        }
    }
    
    /// Adaptasyon ilerlemesini önceki schedule'dan geri getir
    func undoScheduleChange() async throws {
        guard let data = UserDefaults.standard.data(forKey: "scheduleChangeUndoData"),
              let undoData = try? JSONDecoder().decode(ScheduleChangeUndoData.self, from: data) else {
            throw RepositoryError.noUndoDataAvailable
        }
        
        // Schedule değişimi bugün yapıldıysa geri alabilir
        let calendar = Calendar.current
        guard calendar.isDate(undoData.changeDate, inSameDayAs: Date()) else {
            throw RepositoryError.undoExpired
        }
        
        // Aktif schedule'ı bul (yeni schedule aynı kalacak)
        let activeDescriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.isActive == true }
        )
        
        do {
            guard let activeSchedule = try fetch(activeDescriptor).first else {
                throw RepositoryError.entityNotFound
            }
            
            // Sadece adaptasyon ilerlemesini önceki schedule'dan geri getir
            // Schedule kendisi değişmeyecek, sadece adaptasyon bilgileri güncellenecek
            activeSchedule.adaptationPhase = undoData.previousAdaptationPhase
            activeSchedule.updatedAt = undoData.previousAdaptationDate
            
            // Streak'i geri yükle
            UserDefaults.standard.set(undoData.previousStreak, forKey: "currentStreak")
            
            try save()
            
            // Undo verisini temizle
            UserDefaults.standard.removeObject(forKey: "scheduleChangeUndoData")
            
            // Undo başarılı olduğunda dismiss durumunu da sıfırla
            UserDefaults.standard.set(false, forKey: "undoDismissedByUser")
            
            logger.debug("✅ Adaptasyon ilerlemesi başarıyla geri getirildi")
            
        } catch {
            logger.error("❌ Adaptasyon ilerlemesi geri getirilirken hata: \(error)")
            throw RepositoryError.updateFailed
        }
    }
    
    /// Undo verisi mevcut mu kontrol et
    func hasUndoData() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: "scheduleChangeUndoData"),
              let undoData = try? JSONDecoder().decode(ScheduleChangeUndoData.self, from: data) else {
            return false
        }
        
        // Sadece bugünkü değişiklikler için undo mevcut
        let calendar = Calendar.current
        return calendar.isDate(undoData.changeDate, inSameDayAs: Date())
    }
    
    /// Undo verisini temizle (manuel cleanup)
    func clearUndoData() {
        UserDefaults.standard.removeObject(forKey: "scheduleChangeUndoData")
        
        // Undo verisi temizlendiğinde dismiss durumunu da sıfırla
        UserDefaults.standard.set(false, forKey: "undoDismissedByUser")
        
        logger.debug("🗑️ Undo verisi temizlendi")
    }
    
    // MARK: - Private Helper Methods
    
    /// Mevcut adaptasyon fazını al
    private func getCurrentAdaptationPhase(scheduleId: UUID) -> Int {
        let descriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.id == scheduleId }
        )
        
        do {
            if let schedule = try fetch(descriptor).first {
                return schedule.adaptationPhase ?? 0
            }
        } catch {
            logger.error("❌ Adaptasyon fazı alınırken hata: \(error)")
        }
        
        return 0
    }
    
    /// Mevcut adaptasyon başlangıç tarihini al
    private func getCurrentAdaptationStartDate(scheduleId: UUID) -> Date {
        let descriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.id == scheduleId }
        )
        
        do {
            if let schedule = try fetch(descriptor).first {
                return schedule.updatedAt
            }
        } catch {
            logger.error("❌ Adaptasyon başlangıç tarihi alınırken hata: \(error)")
        }
        
        return Date()
    }
} 