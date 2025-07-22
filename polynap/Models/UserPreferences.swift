import SwiftUI
import SwiftData

@Model
final class UserPreferences {
    var hasCompletedOnboarding: Bool
    var hasCompletedQuestions: Bool
    var hasSkippedOnboarding: Bool
    var reminderLeadTimeInMinutes: Int
    var onboardingRestartCount: Int
    var hasSeenSkippedOnboardingCard: Bool
    
    init(hasCompletedOnboarding: Bool = false, hasCompletedQuestions: Bool = false, hasSkippedOnboarding: Bool = false, reminderLeadTimeInMinutes: Int = 15, onboardingRestartCount: Int = 0, hasSeenSkippedOnboardingCard: Bool = false) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasCompletedQuestions = hasCompletedQuestions
        self.hasSkippedOnboarding = hasSkippedOnboarding
        self.reminderLeadTimeInMinutes = reminderLeadTimeInMinutes
        self.onboardingRestartCount = onboardingRestartCount
        self.hasSeenSkippedOnboardingCard = hasSeenSkippedOnboardingCard
    }
    
    /// Kullanıcı tercihlerini sıfırlar
    func resetPreferences() {
        self.hasCompletedOnboarding = false
        self.hasCompletedQuestions = false
        self.hasSkippedOnboarding = false
        self.reminderLeadTimeInMinutes = 15
        self.hasSeenSkippedOnboardingCard = false
        // onboardingRestartCount'ı sıfırlamıyoruz çünkü bu kullanıcının geçmişi
    }
}
