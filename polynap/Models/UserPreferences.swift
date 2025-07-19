import SwiftUI
import SwiftData

@Model
final class UserPreferences {
    var hasCompletedOnboarding: Bool
    var hasCompletedQuestions: Bool
    var hasSkippedOnboarding: Bool
    var reminderLeadTimeInMinutes: Int
    
    init(hasCompletedOnboarding: Bool = false, hasCompletedQuestions: Bool = false, hasSkippedOnboarding: Bool = false, reminderLeadTimeInMinutes: Int = 15) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasCompletedQuestions = hasCompletedQuestions
        self.hasSkippedOnboarding = hasSkippedOnboarding
        self.reminderLeadTimeInMinutes = reminderLeadTimeInMinutes
    }
    
    /// Kullanıcı tercihlerini sıfırlar
    func resetPreferences() {
        self.hasCompletedOnboarding = false
        self.hasCompletedQuestions = false
        self.hasSkippedOnboarding = false
        self.reminderLeadTimeInMinutes = 15
    }
}
