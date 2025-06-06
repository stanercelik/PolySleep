import SwiftUI
import SwiftData

@Model
final class UserPreferences {
    var hasCompletedOnboarding: Bool
    var hasCompletedQuestions: Bool
    var reminderLeadTimeInMinutes: Int
    
    init(hasCompletedOnboarding: Bool = false, hasCompletedQuestions: Bool = false, reminderLeadTimeInMinutes: Int = 15) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasCompletedQuestions = hasCompletedQuestions
        self.reminderLeadTimeInMinutes = reminderLeadTimeInMinutes
    }
    
    /// Kullanıcı tercihlerini sıfırlar
    func resetPreferences() {
        self.hasCompletedOnboarding = false
        self.hasCompletedQuestions = false
        self.reminderLeadTimeInMinutes = 15
    }
}
