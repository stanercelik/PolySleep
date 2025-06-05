import Foundation
import SwiftData
import SwiftUI

enum SortOption: String, CaseIterable {
    case newestFirst = "Newest First"
    case oldestFirst = "Oldest First"
    case highestRated = "Highest Rated"
    case lowestRated = "Lowest Rated"
}

enum CompletionStatus: Int, Codable {
    case completed
    case partial
    case missed
    
    var color: Color {
        switch self {
        case .completed:
            return .appSuccess
        case .partial:
            return .appWarning
        case .missed:
            return .appError
        }
    }
    
    var localizedTitle: String {
        switch self {
        case .completed:
            return NSLocalizedString("history.status.completed", tableName: "History", comment: "")
        case .partial:
            return NSLocalizedString("history.status.partial", tableName: "History", comment: "")
        case .missed:
            return NSLocalizedString("history.status.missed", tableName: "History", comment: "")
        }
    }
}

@Model
final class HistoryModel {
    @Attribute(.unique) var id: UUID // Günlük grup için benzersiz ID
    var date: Date // Bu geçmiş modelinin temsil ettiği tarih (günün başlangıcı)

    // Bu güne ait uyku girişleri ile ilişki
    @Relationship(deleteRule: .cascade, inverse: \SleepEntry.historyDay)
    var sleepEntries: [SleepEntry]? = []

    var averageRating: Double {
        guard let entries = sleepEntries, !entries.isEmpty else { return 0 }
        let totalRating = entries.reduce(0) { $0 + $1.rating }
        return Double(totalRating) / Double(entries.count)
    }

    var totalSleepDuration: TimeInterval { // Saniye cinsinden
        guard let entries = sleepEntries else { return 0 }
        return entries.reduce(0.0) { $0 + $1.duration }
    }
    
    // Bu gün için tamamlama durumu (örnek mantık)
    var completionStatus: CompletionStatus {
        guard let entries = sleepEntries, !entries.isEmpty else { return .missed }
        // Basit bir mantık: Eğer herhangi bir uyku girişi varsa ve toplam süre 0'dan büyükse tamamlanmış say.
        // Daha karmaşık bir mantık için aktif programla karşılaştırma gerekebilir.
        return totalSleepDuration > 0 ? .completed : .missed 
    }

    init(id: UUID = UUID(), date: Date, sleepEntries: [SleepEntry]? = []) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date) // Her zaman günün başlangıcını sakla
        self.sleepEntries = sleepEntries
    }
}
