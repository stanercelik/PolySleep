import Foundation
import SwiftData
import OSLog

/// Adaptasyon fazı yönetimi için service
@MainActor
final class AdaptationManager: BaseRepository {
    
    static let shared = AdaptationManager()
    
    private override init() {
        super.init()
        logger.debug("🔄 AdaptationManager başlatıldı")
    }
    
    // MARK: - Adaptation Phase Management
    
    /// Mevcut adaptasyon fazını al
    func getCurrentAdaptationPhase(scheduleId: UUID) -> Int {
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
    func getCurrentAdaptationStartDate(scheduleId: UUID) -> Date {
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
    
    /// Adaptasyon fazını güncelle
    func updateAdaptationPhase(scheduleId: UUID, newPhase: Int) throws {
        let descriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.id == scheduleId }
        )
        
        do {
            guard let schedule = try fetch(descriptor).first else {
                logger.error("❌ Adaptasyon fazı güncellenecek UserSchedule (ID: \(scheduleId.uuidString)) bulunamadı.")
                throw RepositoryError.entityNotFound
            }
            
            schedule.adaptationPhase = newPhase
            schedule.updatedAt = Date()
            
            try save()
            logger.debug("✅ UserSchedule (ID: \(scheduleId.uuidString)) adaptasyon fazı başarıyla güncellendi: \(newPhase)")
        } catch {
            logger.error("❌ UserSchedule adaptasyon fazı güncellenirken hata: \(error.localizedDescription)")
            throw RepositoryError.updateFailed
        }
    }
    
    /// Adaptasyon ilerlemesini hesapla
    func calculateAdaptationProgress(scheduleId: UUID) -> AdaptationProgress {
        let currentPhase = getCurrentAdaptationPhase(scheduleId: scheduleId)
        let startDate = getCurrentAdaptationStartDate(scheduleId: scheduleId)
        
        // Schedule'ı bul
        let descriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.id == scheduleId }
        )
        
        do {
            guard let schedule = try fetch(descriptor).first else {
                return AdaptationProgress(
                    currentPhase: 0,
                    totalPhases: 4,
                    daysSinceStart: 0,
                    estimatedTotalDays: 21,
                    progressPercentage: 0.0,
                    isCompleted: false
                )
            }
            
            let scheduleName = schedule.name.lowercased()
            let totalPhases: Int
            let estimatedTotalDays: Int
            
            // Program tipine göre adaptasyon süresi
            if scheduleName.contains("uberman") || 
               scheduleName.contains("dymaxion") ||
               (scheduleName.contains("everyman") && scheduleName.contains("1")) {
                totalPhases = 5
                estimatedTotalDays = 28
            } else {
                totalPhases = 4
                estimatedTotalDays = 21
            }
            
            // Başlangıçtan bu yana geçen gün sayısı
            let calendar = Calendar.current
            let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
            
            // İlerleme yüzdesi
            let progressPercentage = min(Double(daysSinceStart) / Double(estimatedTotalDays), 1.0)
            
            // Tamamlanmış mı kontrolü
            let isCompleted = currentPhase >= totalPhases || daysSinceStart >= estimatedTotalDays
            
            logger.debug("📊 Adaptasyon ilerlemesi - Faz: \(currentPhase)/\(totalPhases), Gün: \(daysSinceStart)/\(estimatedTotalDays), İlerleme: %\(Int(progressPercentage * 100))")
            
            return AdaptationProgress(
                currentPhase: currentPhase,
                totalPhases: totalPhases,
                daysSinceStart: daysSinceStart,
                estimatedTotalDays: estimatedTotalDays,
                progressPercentage: progressPercentage,
                isCompleted: isCompleted
            )
            
        } catch {
            logger.error("❌ Adaptasyon ilerlemesi hesaplanırken hata: \(error)")
            return AdaptationProgress(
                currentPhase: 0,
                totalPhases: 4,
                daysSinceStart: 0,
                estimatedTotalDays: 21,
                progressPercentage: 0.0,
                isCompleted: false
            )
        }
    }
    
    /// Otomatik adaptasyon fazı güncellemesi
    func autoUpdateAdaptationPhase(scheduleId: UUID) throws {
        let progress = calculateAdaptationProgress(scheduleId: scheduleId)
        
        // Eğer ilerleme varsa ve henüz tamamlanmamışsa fazı güncelle
        if !progress.isCompleted && progress.daysSinceStart > 0 {
            let newPhase = calculatePhaseForDay(
                dayNumber: progress.daysSinceStart + 1,
                totalDays: progress.estimatedTotalDays
            )
            
            if newPhase > progress.currentPhase {
                try updateAdaptationPhase(scheduleId: scheduleId, newPhase: newPhase)
                logger.debug("🔄 Otomatik adaptasyon fazı güncellendi: \(progress.currentPhase) → \(newPhase)")
            }
        }
    }
    
    /// Adaptasyon fazını sıfırla (yeni program başlangıcı)
    func resetAdaptationPhase(scheduleId: UUID) throws {
        try updateAdaptationPhase(scheduleId: scheduleId, newPhase: 0)
        logger.debug("🔄 Adaptasyon fazı sıfırlandı: \(scheduleId.uuidString)")
    }
    
    // MARK: - Private Helper Methods
    
    /// Gün numarasına göre adaptasyon fazını hesapla
    private func calculatePhaseForDay(dayNumber: Int, totalDays: Int) -> Int {
        if totalDays == 28 {
            // 28 günlük programlar için (Uberman, Dymaxion, Everyman E1)
            switch dayNumber {
            case 1:
                return 0  // İlk gün - Başlangıç
            case 2...7:
                return 1  // 2-7. günler - İlk Adaptasyon
            case 8...14:
                return 2  // 8-14. günler - Orta Adaptasyon
            case 15...21:
                return 3  // 15-21. günler - İlerlemiş Adaptasyon
            case 22...28:
                return 4  // 22-28. günler - İleri Adaptasyon
            default:
                return 5  // 28+ günler - Tamamlanmış
            }
        } else {
            // 21 günlük programlar için (Diğer Everyman türevleri)
            switch dayNumber {
            case 1:
                return 0  // İlk gün - Başlangıç
            case 2...7:
                return 1  // 2-7. günler - İlk Adaptasyon
            case 8...14:
                return 2  // 8-14. günler - Orta Adaptasyon
            case 15...21:
                return 3  // 15-21. günler - İlerlemiş Adaptasyon
            default:
                return 4  // 21+ günler - Tamamlanmış
            }
        }
    }
}

/// Adaptasyon ilerlemesi için model
struct AdaptationProgress {
    let currentPhase: Int
    let totalPhases: Int
    let daysSinceStart: Int
    let estimatedTotalDays: Int
    let progressPercentage: Double
    let isCompleted: Bool
    
    /// Kalan gün sayısı
    var remainingDays: Int {
        max(0, estimatedTotalDays - daysSinceStart)
    }
    
    /// Faz ismi
    var phaseName: String {
        switch currentPhase {
        case 0:
            return "Başlangıç"
        case 1:
            return "İlk Adaptasyon"
        case 2:
            return "Orta Adaptasyon"
        case 3:
            return "İlerlemiş Adaptasyon"
        case 4:
            return "İleri Adaptasyon"
        case 5:
            return "Tamamlanmış"
        default:
            return "Tamamlanmış"
        }
    }
} 