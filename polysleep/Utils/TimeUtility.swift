import Foundation

enum TimeUtility {
    static func adjustTime(_ timeString: String, byMinutes minutes: Int) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let date = formatter.date(from: timeString) else { return nil }
        let adjustedDate = Calendar.current.date(byAdding: .minute, value: minutes, to: date)
        
        return adjustedDate.map { formatter.string(from: $0) }
    }
}
