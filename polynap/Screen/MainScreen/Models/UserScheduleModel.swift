import Foundation
import SwiftUI

struct UserScheduleModel {
    var id: String
    var name: String
    var description: LocalizedDescription
    var totalSleepHours: Double
    var schedule: [SleepBlock]
    var isPremium: Bool
    
    /// Schedule'daki bloklardan hesaplanan gerçek toplam uyku saati
    var calculatedTotalSleepHours: Double {
        return schedule.reduce(0.0) { total, block in
            total + (Double(block.duration) / 60.0) // dakikayı saate çevir
        }
    }
    
    /// UI'da gösterilecek toplam uyku saati - hesaplanan değer öncelikli
    var displayTotalSleepHours: Double {
        let calculated = calculatedTotalSleepHours
        // Eğer hesaplanan değer ile mevcut değer arasında fark varsa, hesaplanan değeri kullan
        return calculated > 0 ? calculated : totalSleepHours
    }
    
    private func sortBlocks(_ blocks: [SleepBlock]) -> [SleepBlock] {
        return blocks.sorted { block1, block2 in
            let time1 = TimeFormatter.time(from: block1.startTime)!
            let time2 = TimeFormatter.time(from: block2.startTime)!
            let minutes1 = time1.hour * 60 + time1.minute
            let minutes2 = time2.hour * 60 + time2.minute
            return minutes1 < minutes2
        }
    }

    init(id: String, name: String, description: LocalizedDescription, totalSleepHours: Double, schedule: [SleepBlock], isPremium: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.totalSleepHours = totalSleepHours
        self.schedule = schedule
        self.isPremium = isPremium
        self.schedule = sortBlocks(self.schedule)
        
        // Eğer totalSleepHours ile hesaplanan değer farklıysa, güncelle
        let calculated = self.calculatedTotalSleepHours
        if calculated > 0 && abs(calculated - totalSleepHours) > 0.1 {
            self.totalSleepHours = calculated
        }
    }
    
    static var defaultSchedule: UserScheduleModel {
        let schedule = [
            SleepBlock(
                startTime: "23:00",
                duration: 120,
                type: "core",
                isCore: true
            ),
            SleepBlock(
                startTime: "04:00",
                duration: 30,
                type: "nap",
                isCore: false
            ),
            SleepBlock(
                startTime: "08:00",
                duration: 30,
                type: "nap",
                isCore: false
            ),
            SleepBlock(
                startTime: "12:00",
                duration: 30,
                type: "nap",
                isCore: false
            ),
            SleepBlock(
                startTime: "19:00",
                duration: 120,
                type: "core",
                isCore: true
            )
        ]
        
        let defaultUUID = generateDeterministicUUID(from: "default")
        
        let currentLang = LanguageManager.shared.currentLanguage
        let nameKey = currentLang == "tr" ? "schedule.default.name" : "schedule.default.name"
        let descEnKey = currentLang == "tr" ? "schedule.default.description.en" : "schedule.default.description.en"
        let descTrKey = currentLang == "tr" ? "schedule.default.description.tr" : "schedule.default.description.tr"
        
        return UserScheduleModel(
            id: defaultUUID.uuidString,
            name: L(nameKey, table: "MainScreen"),
            description: LocalizedDescription(
                en: L(descEnKey, table: "MainScreen"),
                tr: L(descTrKey, table: "MainScreen")
            ),
            totalSleepHours: 8.0,
            schedule: schedule,
            isPremium: false
        )
    }
    
    /// String ID'den deterministik UUID oluşturur
    private static func generateDeterministicUUID(from stringId: String) -> UUID {
        // PolySleep namespace UUID'si (sabit bir UUID) - MainScreenViewModel ile aynı
        let namespace = UUID(uuidString: "6BA7B810-9DAD-11D1-80B4-00C04FD430C8") ?? UUID()
        
        // String'i Data'ya dönüştür
        let data = stringId.data(using: .utf8) ?? Data()
        
        // MD5 hash ile deterministik UUID oluştur
        var digest = [UInt8](repeating: 0, count: 16)
        
        // Basit hash algoritması
        let namespaceBytes = withUnsafeBytes(of: namespace.uuid) { Array($0) }
        let stringBytes = Array(data)
        
        for (index, byte) in (namespaceBytes + stringBytes).enumerated() {
            digest[index % 16] ^= byte
        }
        
        // UUID'nin version ve variant bitlerini ayarla (version 5 için)
        digest[6] = (digest[6] & 0x0F) | 0x50  // Version 5
        digest[8] = (digest[8] & 0x3F) | 0x80  // Variant 10
        
        // UUID oluştur
        let uuid = NSUUID(uuidBytes: digest) as UUID
        return uuid
    }
    
    var nextBlock: SleepBlock? {
        guard !schedule.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = currentTime.hour! * 60 + currentTime.minute!
        
        for block in schedule {
            let startComponents = TimeFormatter.time(from: block.startTime)!
            let startMinutes = startComponents.hour * 60 + startComponents.minute
            
            if startMinutes > currentMinutes {
                return block
            }
        }
        
        return schedule.first
    }
    
    var currentBlock: SleepBlock? {
        guard !schedule.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = currentTime.hour! * 60 + currentTime.minute!
        
        for block in schedule {
            let startComponents = TimeFormatter.time(from: block.startTime)!
            let startMinutes = startComponents.hour * 60 + startComponents.minute
            
            let endComponents = TimeFormatter.time(from: block.endTime)!
            let endMinutes = endComponents.hour * 60 + endComponents.minute
            
            if endMinutes < startMinutes {
                if currentMinutes >= startMinutes || currentMinutes <= endMinutes {
                    return block
                }
            } else {
                if currentMinutes >= startMinutes && currentMinutes <= endMinutes {
                    return block
                }
            }
        }
        
        return nil
    }
    
    var remainingTimeToNextBlock: Int {
        guard let next = nextBlock else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = currentTime.hour! * 60 + currentTime.minute!
        
        let startComponents = TimeFormatter.time(from: next.startTime)!
        let startMinutes = startComponents.hour * 60 + startComponents.minute
        
        if startMinutes <= currentMinutes {
            return (24 * 60 - currentMinutes) + startMinutes
        } else {
            return startMinutes - currentMinutes
        }
    }
}

extension UserScheduleModel {
    var toSleepScheduleModel: SleepScheduleModel {
        SleepScheduleModel(
            id: id,
            name: name,
            description: description,
            totalSleepHours: totalSleepHours,
            schedule: schedule,
            isPremium: isPremium
        )
    }
}
