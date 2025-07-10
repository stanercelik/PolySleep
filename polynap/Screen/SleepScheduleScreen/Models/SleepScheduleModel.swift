import Foundation

/// Time formatter helper for consistent time string handling
public enum TimeFormatter {
    static func time(from string: String) -> (hour: Int, minute: Int)? {
        let components = string.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return nil
        }
        return (hour, minute)
    }
    
    static func formatTime(_ hour: Int, _ minute: Int) -> String {
        return String(format: "%02d:%02d", hour % 24, minute % 60)
    }
    
    static func addMinutes(_ minutes: Int, to timeString: String) -> String {
        guard let (startHour, startMinute) = time(from: timeString) else { return "00:00" }
        let totalMinutes = startHour * 60 + startMinute + minutes
        let hour = (totalMinutes / 60) % 24
        let minute = totalMinutes % 60
        return formatTime(hour, minute)
    }
    
    static func formattedString(from timeString: String) -> String {
        guard let (hour, minute) = time(from: timeString) else { return timeString }
        return formatTime(hour, minute)
    }
}

/// Represents a sleep block within a schedule (either core sleep or nap)
public struct SleepBlock: Codable, Identifiable, Equatable {
    public var id = UUID()
    public let startTime: String
    public let duration: Int
    public let type: String
    public let isCore: Bool
    
    public var startTimeComponents: (hour: Int, minute: Int) {
        TimeFormatter.time(from: startTime) ?? (0, 0)
    }
    
    public var endTime: String {
        TimeFormatter.addMinutes(duration, to: startTime)
    }
    
    public var endTimeComponents: (hour: Int, minute: Int) {
        TimeFormatter.time(from: endTime) ?? (0, 0)
    }
    
    public var endHour: Int {
        guard let (hour, _) = TimeFormatter.time(from: endTime) else { return 0 }
        return hour
    }
    
    public init(startTime: String, duration: Int, type: String, isCore: Bool) {
        self.startTime = startTime
        self.duration = duration
        self.type = type
        self.isCore = isCore
    }
    
    public init(id: UUID, startTime: String, duration: Int, type: String, isCore: Bool) {
        self.id = id
        self.startTime = startTime
        self.duration = duration
        self.type = type
        self.isCore = isCore
    }
    
    private enum CodingKeys: String, CodingKey {
        case startTime, duration, type, isCore
    }
}

/// Represents a localized description
public struct LocalizedDescription: Codable, Equatable {
    public let en: String
    public let tr: String

     public init(en: String, tr: String) {
        self.en = en
        self.tr = tr
    }
    
    public func localized() -> String {
        // For now, just return English. In a real app, this would use the system language
        return en
    }
}

/// Represents a complete sleep schedule with all its properties
public struct SleepScheduleModel: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let description: LocalizedDescription
    public let totalSleepHours: Double
    public let schedule: [SleepBlock]
    public let isPremium: Bool
    
    public init(
        id: String,
        name: String,
        description: LocalizedDescription,
        totalSleepHours: Double,
        schedule: [SleepBlock],
        isPremium: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.totalSleepHours = totalSleepHours
        self.schedule = schedule
        self.isPremium = isPremium
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, totalSleepHours, schedule, isPremium
    }
}

// MARK: - Schedule Analysis
extension SleepScheduleModel {
    /// Check if schedule has naps during typical work hours (9-17)
    var hasNapsInWorkHours: Bool {
        let workStart = 9
        let workEnd = 17
        
        return schedule.contains { block in
            guard !block.isCore,
                  let (blockHour, _) = TimeFormatter.time(from: block.startTime) else {
                return false
            }
            return blockHour >= workStart && blockHour <= workEnd
        }
    }
    
    /// Calculate difficulty level based on schedule characteristics
    var difficulty: DifficultyLevel {
        let napCount = schedule.filter { !$0.isCore }.count
        let totalSleepTime = totalSleepHours
        
        switch (napCount, totalSleepTime) {
        case (0, 6...8):
            return .beginner
        case (1, 5...7):
            return .intermediate
        case (2, 4...6):
            return .advanced
        default:
            return .extreme
        }
    }
    
    /// Converts SleepScheduleModel to UserScheduleModel
    var toUserScheduleModel: UserScheduleModel {
        // String ID'yi UUID formatına dönüştür
        let uuidString = generateDeterministicUUID(from: id).uuidString
        
        return UserScheduleModel(
            id: uuidString,
            name: name,
            description: description,
            totalSleepHours: totalSleepHours,
            schedule: schedule,
            isPremium: isPremium
        )
    }
    
    /// String ID'den deterministik UUID oluşturur
    private func generateDeterministicUUID(from stringId: String) -> UUID {
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
}

/// Container for multiple sleep schedules
public struct SleepSchedulesContainer: Codable {
    public let sleepSchedules: [SleepScheduleModel]
    
    public init(sleepSchedules: [SleepScheduleModel]) {
        self.sleepSchedules = sleepSchedules
    }
}
