import SwiftUI
import SwiftData

@Model
final class UserPreferences {
    var hasCompletedOnboarding: Bool
    var hasCompletedQuestions: Bool
    
    init(hasCompletedOnboarding: Bool = false, hasCompletedQuestions: Bool  = false) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasCompletedQuestions = hasCompletedQuestions
    }
}
