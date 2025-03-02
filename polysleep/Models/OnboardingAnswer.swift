import Foundation
import SwiftData

@Model
final class OnboardingAnswer {
    var id: UUID
    var question: String
    var answer: String
    var rawAnswer: String
    var date: Date
    
    init(id: UUID = UUID(), question: String, answer: String, rawAnswer: String, date: Date = Date()) {
        self.id = id
        self.question = question
        self.answer = answer
        self.rawAnswer = rawAnswer
        self.date = date
    }
}
