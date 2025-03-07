import Foundation
import SwiftData

@Model
final class OnboardingAnswer {
    var id: UUID
    var question: String
    var answer: String
    var date: Date
    
    init(id: UUID = UUID(), question: String, answer: String, date: Date = Date()) {
        self.id = id
        self.question = question
        self.answer = answer
        self.date = date
    }
}
