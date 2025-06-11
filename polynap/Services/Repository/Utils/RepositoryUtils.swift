import Foundation

/// Repository için yardımcı fonksiyonlar ve veri dönüştürücüler
struct RepositoryUtils {
    
    // MARK: - Data Conversion Methods
    
    /// LocalizedDescription'ı JSON string'e çevirir
    static func encodeScheduleDescription(_ description: LocalizedDescription) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: [
            "en": description.en,
            "tr": description.tr
        ])
        return String(data: data, encoding: .utf8) ?? "{}"
    }
    
    /// "HH:mm" formatındaki string'i Date'e çevirir
    static func convertTimeStringToDate(_ timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        // Bugünün tarihini al ve sadece saat/dakikayı ayarla
        let today = Date()
        let calendar = Calendar.current
        
        if let time = formatter.date(from: timeString) {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(bySettingHour: timeComponents.hour ?? 0, 
                               minute: timeComponents.minute ?? 0, 
                               second: 0, 
                               of: today) ?? today
        }
        
        return today
    }
    
    // MARK: - Entity Conversion Methods
    
    /// ScheduleEntity'i UserScheduleModel'e dönüştüren yardımcı metot
    static func convertEntityToUserScheduleModel(_ entity: ScheduleEntity) -> UserScheduleModel {
        // Açıklama JSON verisini çöz
        var description = LocalizedDescription(en: "", tr: "")
        if let jsonData = entity.descriptionJson.data(using: .utf8) {
            if let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                if let en = dict["en"] as? String, let tr = dict["tr"] as? String {
                    description = LocalizedDescription(en: en, tr: tr)
                }
            }
        }
        
        // Uyku bloklarını dönüştür
        let sleepBlocks = entity.sleepBlocks.map { blockEntity -> SleepBlock in
            return SleepBlock(
                startTime: blockEntity.startTime,
                duration: blockEntity.durationMinutes,
                type: blockEntity.isCore ? "core" : "nap",
                isCore: blockEntity.isCore
            )
        }
        
        // UserScheduleModel oluştur
        return UserScheduleModel(
            id: entity.id.uuidString,
            name: entity.name,
            description: description,
            totalSleepHours: entity.totalSleepHours,
            schedule: sleepBlocks,
            isPremium: false // ScheduleEntity'de bu özellik olmadığı için varsayılan değer
        )
    }
    
    /// UserSchedule entity'sini UserScheduleModel'e dönüştürür
    static func convertUserScheduleToModel(_ schedule: UserSchedule) -> UserScheduleModel {
        let description: LocalizedDescription
        if let descData = schedule.scheduleDescription?.data(using: .utf8),
           let json = try? JSONDecoder().decode([String: String].self, from: descData) {
            description = LocalizedDescription(en: json["en"] ?? "", tr: json["tr"] ?? "")
        } else {
            description = LocalizedDescription(en: "Açıklama yok", tr: "No description")
        }

        let sleepBlocks = (schedule.sleepBlocks ?? []).map { block in
            SleepBlock(
                startTime: block.startTime.formatted(date: .omitted, time: .shortened),
                duration: block.durationMinutes,
                type: block.isCore ? "core" : "nap",
                isCore: block.isCore
            )
        }
        
        return UserScheduleModel(
            id: schedule.id.uuidString,
            name: schedule.name,
            description: description,
            totalSleepHours: schedule.totalSleepHours ?? 0,
            schedule: sleepBlocks,
            isPremium: false // Gerekirse bu bilgiyi de UserSchedule'a ekleyin
        )
    }
    
    // MARK: - Adaptation Phase Calculation
    
    /// Belirli bir gün numarası için adaptasyon fazını hesapla
    static func calculateAdaptationPhaseForDay(dayNumber: Int, schedule: UserSchedule) -> Int {
        let scheduleName = schedule.name.lowercased()
        let adaptationDuration: Int
        
        if scheduleName.contains("uberman") || 
           scheduleName.contains("dymaxion") ||
           (scheduleName.contains("everyman") && scheduleName.contains("1")) {
            adaptationDuration = 28
        } else {
            adaptationDuration = 21
        }
        
        let phase: Int
        
        if adaptationDuration == 28 {
            // 28 günlük programlar için
            switch dayNumber {
            case 1:
                phase = 0  // İlk gün - Başlangıç
            case 2...7:
                phase = 1  // 2-7. günler - İlk Adaptasyon
            case 8...14:
                phase = 2  // 8-14. günler - Orta Adaptasyon
            case 15...21:
                phase = 3  // 15-21. günler - İlerlemiş Adaptasyon
            case 22...28:
                phase = 4  // 22-28. günler - İleri Adaptasyon
            default:
                phase = 5  // 28+ günler - Tamamlanmış
            }
        } else {
            // 21 günlük programlar için
            switch dayNumber {
            case 1:
                phase = 0  // İlk gün - Başlangıç
            case 2...7:
                phase = 1  // 2-7. günler - İlk Adaptasyon
            case 8...14:
                phase = 2  // 8-14. günler - Orta Adaptasyon
            case 15...21:
                phase = 3  // 15-21. günler - İlerlemiş Adaptasyon
            default:
                phase = 4  // 21+ günler - Tamamlanmış
            }
        }
        
        return phase
    }
    
    // MARK: - UUID Validation
    
    /// String'i güvenli bir şekilde UUID'ye çevirir
    static func safeUUID(from string: String) -> UUID {
        return UUID(uuidString: string) ?? UUID()
    }
} 