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
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header Card
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.appPrimary)
                            .padding(.top, 8)
                        
                        Text("Kişisel Bilgilerim")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.appText)
                        
                        Text("Profil bilgileriniz ve tercihleriniz")
                            .font(.subheadline)
                            .foregroundColor(.appSecondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.appCardBackground)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    
                    if answersForDisplay.isEmpty {
                        // Empty State
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 50))
                                .foregroundColor(.appSecondaryText.opacity(0.6))
                            
                            Text("Henüz kişisel bilgi bulunamadı")
                                .font(.headline)
                                .foregroundColor(.appText)
                            
                            Text("Onboarding sürecini tamamlayarak kişisel bilgilerinizi ekleyebilirsiniz")
                                .font(.subheadline)
                                .foregroundColor(.appSecondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.appCardBackground)
                                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                        )
                    } else {
                        // Recommended Schedule Section
                        if let schedule = scheduleStore.first {
                            PersonalInfoSection(
                                title: "Önerilen Uyku Programı",
                                icon: "bed.double.fill",
                                iconColor: .appAccent
                            ) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text(schedule.name)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.appText)
                                        
                                        Spacer()
                                        
                                        Text("\(String(format: "%.1f", schedule.totalSleepHours)) saat")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.appSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(Color.appSecondary.opacity(0.15))
                                            )
                                    }
                                    
                                    Text("Toplam günlük uyku süresi")
                                        .font(.caption)
                                        .foregroundColor(.appSecondaryText)
                                }
                            }
                        }
                        
                        // Personal Answers Section
                        PersonalInfoSection(
                            title: "Onboarding Cevaplarım",
                            icon: "questionmark.bubble.fill",
                            iconColor: .appPrimary
                        ) {
                            VStack(spacing: 16) {
                                ForEach(getOrderedQuestions(), id: \.self) { question in
                                    if let answer = answersForDisplay[question] {
                                        PersonalInfoAnswerCard(
                                            question: getLocalizedQuestion(for: question),
                                            answer: getLocalizedAnswer(for: question, value: answer)
                                        )
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
        .navigationTitle("Kişisel Bilgiler")
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

// MARK: - Custom Components

struct PersonalInfoSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
            }
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }
}

struct PersonalInfoAnswerCard: View {
    let question: String
    let answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.appText)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(answer)
                .font(.body)
                .foregroundColor(.appSecondaryText)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appSecondaryText.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct PersonalInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PersonalInfoView()
        }
    }
}
