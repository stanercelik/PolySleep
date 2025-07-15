import Foundation

/// Adaptasyon verilerini temsil eden model
struct AdaptationData: Codable, Equatable {
    let adaptationPhase: Int
    let adaptationPercentage: Int
    let averageRating: Double
    let totalEntries: Int
    let last7DaysEntries: Int
    let lastUpdated: Date
    
    init(
        adaptationPhase: Int = 1,
        adaptationPercentage: Int = 0,
        averageRating: Double = 0.0,
        totalEntries: Int = 0,
        last7DaysEntries: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.adaptationPhase = adaptationPhase
        self.adaptationPercentage = adaptationPercentage
        self.averageRating = averageRating
        self.totalEntries = totalEntries
        self.last7DaysEntries = last7DaysEntries
        self.lastUpdated = lastUpdated
    }
    
    /// Dictionary'den AdaptationData oluşturur
    init?(from dictionary: [String: Any]) {
        guard let adaptationPhase = dictionary["adaptationPhase"] as? Int,
              let adaptationPercentage = dictionary["adaptationPercentage"] as? Int,
              let averageRating = dictionary["averageRating"] as? Double,
              let totalEntries = dictionary["totalEntries"] as? Int,
              let last7DaysEntries = dictionary["last7DaysEntries"] as? Int else {
            return nil
        }
        
        self.adaptationPhase = adaptationPhase
        self.adaptationPercentage = adaptationPercentage
        self.averageRating = averageRating
        self.totalEntries = totalEntries
        self.last7DaysEntries = last7DaysEntries
        self.lastUpdated = Date()
    }
    
    /// Dictionary'ye çevirir
    var dictionary: [String: Any] {
        return [
            "adaptationPhase": adaptationPhase,
            "adaptationPercentage": adaptationPercentage,
            "averageRating": averageRating,
            "totalEntries": totalEntries,
            "last7DaysEntries": last7DaysEntries,
            "lastUpdated": lastUpdated.timeIntervalSince1970
        ]
    }
    
    /// Adaptasyon durumu açıklaması
    var phaseDescription: String {
        switch adaptationPhase {
        case 1:
            return "Başlangıç"
        case 2:
            return "Uyum"
        case 3:
            return "İlerleme"
        case 4:
            return "Uzman"
        default:
            return "Bilinmiyor"
        }
    }
    
    /// Adaptasyon başarı durumu
    var isAdaptationSuccessful: Bool {
        return adaptationPercentage >= 70 && averageRating >= 3.5
    }
    
    /// Haftalık hedef karşılanma durumu
    var weeklyGoalMet: Bool {
        return last7DaysEntries >= 5 // Haftada en az 5 uyku girişi
    }
}

/// Default/empty adaptasyon verisi
extension AdaptationData {
    static let empty = AdaptationData()
}