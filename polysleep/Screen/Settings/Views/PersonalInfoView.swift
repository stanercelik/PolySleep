import SwiftUI
import SwiftData

struct PersonalInfoView: View {
    @Query private var onboardingAnswers: [OnboardingAnswerData]
    @Query private var scheduleStore: [SleepScheduleStore]
    @Environment(\.modelContext) private var modelContext
    
    var answersForDisplay: [String: String] {
        var dict: [String: String] = [:]
        for answerData in onboardingAnswers {
            dict[answerData.question] = answerData.answer
        }
        return dict
    }

    var body: some View {
        List {
            if answersForDisplay.isEmpty {
                Section {
                    Text("personalInfo.noData", tableName: "Profile")
                        .foregroundColor(.secondary)
                        .padding()
                }
            } else {
                if let schedule = scheduleStore.first {
                    Section(header: Text("personalInfo.recommendedSchedule", tableName: "Profile")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(schedule.name)
                                .font(.headline)
                            
                            Text("personalInfo.totalSleepHours \(String(format: "%.1f", schedule.totalSleepHours))", tableName: "Profile")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("personalInfo.answers", tableName: "Profile")) {
                    ForEach(getOrderedQuestions(), id: \.self) { question in
                        if let answer = answersForDisplay[question] {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(getLocalizedQuestion(for: question))
                                    .font(.headline)
                                
                                Text(getLocalizedAnswer(for: question, value: answer))
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 4)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("settings.about.personalInfo")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    private func getOrderedQuestions() -> [String] {
        let orderedQuestions = [
            "onboarding.sleepExperience", 
            "onboarding.ageRange", 
            "onboarding.workSchedule", 
            "onboarding.napEnvironment",
            "onboarding.lifestyle", 
            "onboarding.knowledgeLevel", 
            "onboarding.healthStatus", 
            "onboarding.motivationLevel",
            "onboarding.sleepGoal", 
            "onboarding.socialObligations", 
            "onboarding.disruptionTolerance", 
            "onboarding.chronotype"
        ]
        
        return orderedQuestions.filter { answersForDisplay.keys.contains($0) }
    }
    
    private func getLocalizedQuestion(for question: String) -> String {
        let key = question
        return NSLocalizedString(key, tableName: "Onboarding", comment: "")
    }
    
    private func getLocalizedAnswer(for question: String, value: String) -> String {
        let key = "\(question).\(value)"
        return NSLocalizedString(key, tableName: "Onboarding", comment: "")
    }
}

struct PersonalInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PersonalInfoView()
        }
    }
}
