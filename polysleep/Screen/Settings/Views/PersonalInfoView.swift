import SwiftUI
import SwiftData

struct PersonalInfoView: View {
    @Query private var onboardingAnswers: [OnboardingAnswer]
    @Query private var scheduleStore: [SleepScheduleStore]
    @Environment(\.modelContext) private var modelContext
    @State private var supabaseAnswers: [String: String] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        List {
            if isLoading {
                Section {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            } else if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            } else if supabaseAnswers.isEmpty {
                Section {
                    Text("personalInfo.noData", tableName: "Profile")
                        .foregroundColor(.secondary)
                        .padding()
                }
            } else {
                // Önerilen Program
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
                
                // Kişisel Bilgiler - Onboarding Cevapları
                Section(header: Text("personalInfo.answers", tableName: "Profile")) {
                    ForEach(getOrderedQuestions(), id: \.self) { question in
                        if let answer = supabaseAnswers[question] {
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
        .task {
            await loadOnboardingAnswers()
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    private func loadOnboardingAnswers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            supabaseAnswers = try await SupabaseOnboardingService.shared.getAllOnboardingAnswersRaw()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Onboarding cevaplarınız yüklenemedi. Lütfen internet bağlantınızı kontrol edin."
            print("Onboarding cevapları yüklenirken hata oluştu: \(error)")
        }
    }
    
    private func getOrderedQuestions() -> [String] {
        // Soruları istenen sırayla göstermek için
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
        
        // Sadece kullanıcının cevapladığı soruları filtrele
        return orderedQuestions.filter { supabaseAnswers.keys.contains($0) }
    }
    
    private func getLocalizedQuestion(for question: String) -> String {
        let key = question // örn: "onboarding.sleepExperience"
        return NSLocalizedString(key, tableName: "Onboarding", comment: "")
    }
    
    private func getLocalizedAnswer(for question: String, value: String) -> String {
        // Cevabın localize edilmiş halini getir 
        // Örneğin: onboarding.sleepExperience.low -> "Düşük"
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
