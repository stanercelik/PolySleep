import Foundation
import SwiftData

@Model
final class OnboardingAnswerData {
    @Attribute(.unique) var id: UUID
    var user: User? // User modeline ilişki eklendi
    var question: String
    var answer: String
    var date: Date
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), user: User? = nil, question: String, answer: String, date: Date = Date(), createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.user = user // init güncellendi
        self.question = question
        self.answer = answer
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
} 