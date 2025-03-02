import SwiftUI
import SwiftData

struct PersonalInfoView: View {
    @Query private var onboardingAnswers: [OnboardingAnswer]
    @Query private var scheduleStore: [SleepScheduleStore]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        List {
            if onboardingAnswers.isEmpty {
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
                
                // Kişisel Bilgiler
                Section(header: Text("personalInfo.answers", tableName: "Profile")) {
                    ForEach(onboardingAnswers.sorted { $0.date > $1.date }) { answer in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(answer.question)
                                .font(.headline)
                            
                            Text(answer.answer)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 4)
                            
                            Text(dateFormatter.string(from: answer.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
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
}

struct PersonalInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PersonalInfoView()
        }
    }
}
