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
        
        // Hard-coded descriptions for consistency with JSON schedules
        let descriptions = LocalizedDescription(
            en: "The Triphasic Sleep Schedule consists of three sleep periods spread throughout the day: two 30-minute naps and one core sleep period of 4.5 hours. This pattern aims to maximize deep sleep and REM sleep while reducing overall sleep time. It's designed for those who want to experiment with polyphasic sleep and need to maintain high cognitive performance.",
            tr: "Trifazik Uyku Programı, gün boyunca dağılmış üç uyku periyodundan oluşur: iki 30 dakikalık şekerleme ve bir 4.5 saatlik ana uyku dönemi. Bu düzen, toplam uyku süresini azaltırken derin uyku ve REM uykusunu en üst düzeye çıkarmayı amaçlar. Polifazik uyku denemek ve yüksek bilişsel performans sürdürmek isteyenler için tasarlanmıştır.",
            ja: "三相性睡眠スケジュールは、1日を通して3つの睡眠期間で構成されます：2回の30分の仮眠と、1回の4.5時間の主睡眠期間。このパターンは、総睡眠時間を短縮しながら、深い睡眠とレム睡眠を最大化することを目的としています。多相睡眠を試してみたい、そして高い認知能力を維持したい人向けに設計されています。",
            de: "Der triphasische Schlafplan besteht aus drei Schlafperioden, die über den Tag verteilt sind: zwei 30-minütige Nickerchen und eine Kernschlafperiode von 4,5 Stunden. Dieses Muster zielt darauf ab, den Tiefschlaf und den REM-Schlaf zu maximieren und gleichzeitig die Gesamtschlafzeit zu reduzieren. Es ist für diejenigen konzipiert, die mit polyphasischem Schlaf experimentieren und eine hohe kognitive Leistungsfähigkeit beibehalten möchten.",
            ms: "Jadual Tidur Trifasa terdiri daripada tiga tempoh tidur yang tersebar sepanjang hari: dua tidur sebentar selama 30 minit dan satu tempoh tidur teras selama 4.5 jam. Corak ini bertujuan untuk memaksimumkan tidur nyenyak dan tidur REM sambil mengurangkan masa tidur keseluruhan. Ia direka untuk mereka yang ingin bereksperimen dengan tidur polifasa dan perlu mengekalkan prestasi kognitif yang tinggi.",
            th: "ตารางการนอนหลับแบบสามเฟสประกอบด้วยการนอนหลับสามช่วงกระจายอยู่ตลอดทั้งวัน: การงีบ 30 นาทีสองครั้งและการนอนหลัก 4.5 ชั่วโมง รูปแบบนี้มีเป้าหมายเพื่อเพิ่มการนอนหลับลึกและการนอนหลับ REM ให้สูงสุดในขณะที่ลดเวลาการนอนหลับโดยรวม เหมาะสำหรับผู้ที่ต้องการทดลองการนอนหลับแบบหลายเฟสและต้องการรักษาประสิทธิภาพการรับรู้ในระดับสูง"
        )
        
        return UserScheduleModel(
            id: defaultUUID.uuidString,
            name: L("schedule.default.name", table: "MainScreen"),
            description: descriptions,
            totalSleepHours: 8.0,
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
