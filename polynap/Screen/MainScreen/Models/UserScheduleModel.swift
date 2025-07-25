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
            guard let time1 = TimeFormatter.time(from: block1.startTime),
                  let time2 = TimeFormatter.time(from: block2.startTime) else {
                print("⚠️ UserScheduleModel: Geçersiz zaman formatı - block1: \(block1.startTime), block2: \(block2.startTime)")
                return false
            }
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
    
    static var placeholder: UserScheduleModel {
        // Shimmer efekti için boş bir yer tutucu model.
        // Adı boşluktan oluşur ki metin alanı için yer ayrılsın ama görünmesin.
        return UserScheduleModel(
            id: "placeholder_id",
            name: " ",
            description: LocalizedDescription(en: " ", tr: " ", ja: " ", de: " ", ms: " ", th: " "),
            totalSleepHours: 8, // Ortalama bir değer, grafiğin çizilmesi için
            schedule: [
                // Shimmer'ın doğru görünmesi için birkaç boş blok ekleyelim.
                // Bu blokların süresi vs. önemli değil, sadece var olmaları yeterli.
                SleepBlock(startTime: "00:00", duration: 60, type: "core", isCore: true),
                SleepBlock(startTime: "00:00", duration: 60, type: "nap", isCore: false),
                SleepBlock(startTime: "00:00", duration: 60, type: "nap", isCore: false)
            ],
            isPremium: false
        )
    }

    static var defaultSchedule: UserScheduleModel {
        let schedule = [
            SleepBlock(
                startTime: "23:00",
                duration: 360, // 6 hours core sleep
                type: "core",
                isCore: true
            ),
            SleepBlock(
                startTime: "14:00",
                duration: 30, // 30 minutes nap
                type: "nap",
                isCore: false
            )
        ]
        
        let defaultUUID = generateDeterministicUUID(from: "default")
        
        // Hard-coded descriptions for consistency with JSON schedules
        let descriptions = LocalizedDescription(
            en: "A sleep pattern with one core sleep period and one short nap during the day, often practiced in some cultures as an afternoon siesta.",
            tr: "Bir ana uyku dönemi ve gün içinde kısa bir şekerlemeden oluşan uyku düzeni. Özellikle bazı kültürlerde öğleden sonra yapılan siesta şeklinde uygulanabilir.",
            ja: "夜にまとめて寝る時間のほかに、日中に短いお昼寝を1回とる睡眠スタイル。スペインのシエスタみたいに、文化として根付いている地域もありますよ。",
            de: "Ein Schlafmuster mit einer Kernschlafphase und einem kurzen Nickerchen während des Tages, das in einigen Kulturen oft als Nachmittagssiesta praktiziert wird.",
            ms: "Corak tidur dengan satu tempoh tidur teras dan satu tidur sebentar pendek pada siang hari, sering diamalkan dalam sesetengah budaya sebagai siesta petang.",
            th: "รูปแบบการนอนที่มีช่วงการนอนหลักหนึ่งครั้งและการหลับสั้นๆ ในช่วงกลางวัน มักพบในบางวัฒนธรรมเป็นการนอนบ่าย"
        )
        
        return UserScheduleModel(
            id: defaultUUID.uuidString,
            name: "Biphasic Sleep",
            description: descriptions,
            totalSleepHours: 6.5,
            schedule: schedule,
            isPremium: false
        )
    }
    
    /// String ID'den deterministik UUID oluşturur
    private static func generateDeterministicUUID(from stringId: String) -> UUID {
        // PolyNap namespace UUID'si (sabit bir UUID) - MainScreenViewModel ile aynı
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
            guard let startComponents = TimeFormatter.time(from: block.startTime) else {
                print("⚠️ UserScheduleModel.nextBlock: Geçersiz zaman formatı - \(block.startTime)")
                continue
            }
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
            guard let startComponents = TimeFormatter.time(from: block.startTime),
                  let endComponents = TimeFormatter.time(from: block.endTime) else {
                print("⚠️ UserScheduleModel.currentBlock: Geçersiz zaman formatı - start: \(block.startTime), end: \(block.endTime)")
                continue
            }
            let startMinutes = startComponents.hour * 60 + startComponents.minute
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
        
        guard let startComponents = TimeFormatter.time(from: next.startTime) else {
            print("⚠️ UserScheduleModel.remainingTimeToNextBlock: Geçersiz zaman formatı - \(next.startTime)")
            return 0
        }
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
