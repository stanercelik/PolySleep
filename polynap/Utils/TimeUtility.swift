import Foundation

enum TimeUtility {
    /// 24 saatlik formatı için merkezi DateFormatter
    static var standardTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_GB") // 24 saatlik format için zorla
        return formatter
    }
    
    /// Date'i HH:mm formatında string'e çevirir (her zaman 24 saatlik)
    static func formatTime(_ date: Date) -> String {
        return standardTimeFormatter.string(from: date)
    }
    
    /// HH:mm formatındaki string'i Date'e çevirir
    static func parseTime(_ timeString: String) -> Date? {
        return standardTimeFormatter.date(from: timeString)
    }
    
    static func adjustTime(_ timeString: String, byMinutes minutes: Int) -> String? {
        let formatter = standardTimeFormatter
        
        guard let date = formatter.date(from: timeString) else { return nil }
        let adjustedDate = Calendar.current.date(byAdding: .minute, value: minutes, to: date)
        
        return adjustedDate.map { formatter.string(from: $0) }
    }
}
