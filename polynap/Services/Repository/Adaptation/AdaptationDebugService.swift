import Foundation
import SwiftData
import OSLog

/// Adaptasyon debug işlemleri için service
@MainActor
final class AdaptationDebugService: BaseRepository {
    
    static let shared = AdaptationDebugService()
    
    private override init() {
        super.init()
        logger.debug("🐛 AdaptationDebugService başlatıldı")
    }
    
    // MARK: - Debug Methods
    
    /// Adaptasyon günü debug için manuel olarak ayarla
    func setAdaptationDebugDay(scheduleId: UUID, dayNumber: Int) async throws {
        let descriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.id == scheduleId }
        )
        
        do {
            guard let schedule = try fetch(descriptor).first else {
                throw RepositoryError.entityNotFound
            }
            
            // Debug için istenen günü simüle etmek üzere başlangıç tarihini ayarla
            // dayNumber = 1 ise bugün başlangıç olmalı
            // dayNumber = 8 ise 7 gün önce başlamalı
            let calendar = Calendar.current
            let currentDate = Date()
            let daysToSubtract = dayNumber - 1 // 1. gün için 0, 8. gün için 7 gün çıkar
            
            guard let targetStartDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: currentDate) else {
                throw RepositoryError.updateFailed
            }
            
            schedule.updatedAt = targetStartDate
            
            // Fazı hesapla
            let phase = RepositoryUtils.calculateAdaptationPhaseForDay(dayNumber: dayNumber, schedule: schedule)
            schedule.adaptationPhase = phase
            
            try save()
            
            logger.debug("🐛 Adaptasyon debug günü ayarlandı: Gün \(dayNumber), Faz \(phase), Başlangıç tarihi: \(targetStartDate)")
            
        } catch {
            logger.error("❌ Adaptasyon debug günü ayarlanırken hata: \(error)")
            throw RepositoryError.updateFailed
        }
    }
    
    /// Debug bilgilerini al
    func getDebugInfo(scheduleId: UUID) -> AdaptationDebugInfo {
        let descriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.id == scheduleId }
        )
        
        do {
            guard let schedule = try fetch(descriptor).first else {
                return AdaptationDebugInfo(
                    scheduleId: scheduleId,
                    scheduleName: "Bulunamadı",
                    currentPhase: 0,
                    startDate: Date(),
                    daysSinceStart: 0,
                    adaptationType: "Bilinmiyor"
                )
            }
            
            let calendar = Calendar.current
            let daysSinceStart = calendar.dateComponents([.day], from: schedule.updatedAt, to: Date()).day ?? 0
            
            let scheduleName = schedule.name.lowercased()
            let adaptationType: String
            
            if scheduleName.contains("uberman") || 
               scheduleName.contains("dymaxion") ||
               (scheduleName.contains("everyman") && scheduleName.contains("1")) {
                adaptationType = "28 günlük"
            } else {
                adaptationType = "21 günlük"
            }
            
            return AdaptationDebugInfo(
                scheduleId: scheduleId,
                scheduleName: schedule.name,
                currentPhase: schedule.adaptationPhase ?? 0,
                startDate: schedule.updatedAt,
                daysSinceStart: daysSinceStart,
                adaptationType: adaptationType
            )
            
        } catch {
            logger.error("❌ Debug bilgileri alınırken hata: \(error)")
            return AdaptationDebugInfo(
                scheduleId: scheduleId,
                scheduleName: "Hata",
                currentPhase: 0,
                startDate: Date(),
                daysSinceStart: 0,
                adaptationType: "Hata"
            )
        }
    }
    
    /// Adaptasyon fazını manuel olarak ayarla
    func setAdaptationPhase(scheduleId: UUID, phase: Int) async throws {
        let descriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.id == scheduleId }
        )
        
        do {
            guard let schedule = try fetch(descriptor).first else {
                throw RepositoryError.entityNotFound
            }
            
            schedule.adaptationPhase = phase
            schedule.updatedAt = Date()
            
            try save()
            
            logger.debug("🐛 Adaptasyon fazı manuel olarak ayarlandı: Faz \(phase)")
            
        } catch {
            logger.error("❌ Adaptasyon fazı manuel olarak ayarlanırken hata: \(error)")
            throw RepositoryError.updateFailed
        }
    }
    
    /// Adaptasyon başlangıç tarihini manuel olarak ayarla
    func setAdaptationStartDate(scheduleId: UUID, startDate: Date) async throws {
        let descriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.id == scheduleId }
        )
        
        do {
            guard let schedule = try fetch(descriptor).first else {
                throw RepositoryError.entityNotFound
            }
            
            schedule.updatedAt = startDate
            
            // Yeni tarihe göre fazı yeniden hesapla
            let calendar = Calendar.current
            let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
            let newPhase = RepositoryUtils.calculateAdaptationPhaseForDay(dayNumber: daysSinceStart + 1, schedule: schedule)
            schedule.adaptationPhase = newPhase
            
            try save()
            
            logger.debug("🐛 Adaptasyon başlangıç tarihi manuel olarak ayarlandı: \(startDate), Yeni faz: \(newPhase)")
            
        } catch {
            logger.error("❌ Adaptasyon başlangıç tarihi manuel olarak ayarlanırken hata: \(error)")
            throw RepositoryError.updateFailed
        }
    }
    
    /// Debug ayarlarını sıfırla
    func resetAdaptationDebug(scheduleId: UUID) async throws {
        let descriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.id == scheduleId }
        )
        
        do {
            guard let schedule = try fetch(descriptor).first else {
                throw RepositoryError.entityNotFound
            }
            
            schedule.adaptationPhase = 0
            schedule.updatedAt = Date()
            
            try save()
            
            logger.debug("🐛 Adaptasyon debug ayarları sıfırlandı")
            
        } catch {
            logger.error("❌ Adaptasyon debug ayarları sıfırlanırken hata: \(error)")
            throw RepositoryError.updateFailed
        }
    }
    
    /// Tüm debug verilerini al
    func getAllDebugInfo() -> [AdaptationDebugInfo] {
        let descriptor = FetchDescriptor<UserSchedule>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let schedules = try fetch(descriptor)
            return schedules.map { schedule in
                let calendar = Calendar.current
                let daysSinceStart = calendar.dateComponents([.day], from: schedule.updatedAt, to: Date()).day ?? 0
                
                let scheduleName = schedule.name.lowercased()
                let adaptationType: String
                
                if scheduleName.contains("uberman") || 
                   scheduleName.contains("dymaxion") ||
                   (scheduleName.contains("everyman") && scheduleName.contains("1")) {
                    adaptationType = "28 günlük"
                } else {
                    adaptationType = "21 günlük"
                }
                
                return AdaptationDebugInfo(
                    scheduleId: schedule.id,
                    scheduleName: schedule.name,
                    currentPhase: schedule.adaptationPhase ?? 0,
                    startDate: schedule.updatedAt,
                    daysSinceStart: daysSinceStart,
                    adaptationType: adaptationType
                )
            }
        } catch {
            logger.error("❌ Tüm debug bilgileri alınırken hata: \(error)")
            return []
        }
    }
}

/// Adaptasyon debug bilgileri için model
struct AdaptationDebugInfo {
    let scheduleId: UUID
    let scheduleName: String
    let currentPhase: Int
    let startDate: Date
    let daysSinceStart: Int
    let adaptationType: String
    
    /// Görüntüleme için formatlanmış bilgi
    var formattedInfo: String {
        """
        Program: \(scheduleName)
        Faz: \(currentPhase) (\(adaptationType))
        Başlangıç: \(startDate.formatted(date: .abbreviated, time: .omitted))
        Gün: \(daysSinceStart + 1)
        """
    }
} 