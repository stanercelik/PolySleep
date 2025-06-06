import SwiftUI
import SwiftData

struct PersonalInfoView: View {
    @Query private var onboardingAnswers: [OnboardingAnswerData]
    @Query private var scheduleStore: [SleepScheduleStore]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.colorScheme) private var colorScheme
    
    var answersForDisplay: [String: String] {
        var dict: [String: String] = [:]
        for answerData in onboardingAnswers {
            dict[answerData.question] = answerData.answer
        }
        return dict
    }

    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.appBackground,
                    Color.appBackground.opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 20) {
                    // Hero Header Section
                    VStack(spacing: 16) {
                        // Icon with gradient background
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.appPrimary.opacity(0.8),
                                            Color.appAccent.opacity(0.6)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                                .shadow(
                                    color: Color.appPrimary.opacity(0.3),
                                    radius: 12,
                                    x: 0,
                                    y: 6
                                )
                            
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text(L("personalInfo.title", table: "Profile"))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.appText)
                            
                            Text(L("personalInfo.subtitle", table: "Profile"))
                                .font(.subheadline)
                                .foregroundColor(.appTextSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 24)
                    
                    if answersForDisplay.isEmpty {
                        // Enhanced Empty State
                        PersonalInfoModernCard {
                            VStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(Color.appTextSecondary.opacity(0.1))
                                        .frame(width: 56, height: 56)
                                    
                                    Image(systemName: "doc.text")
                                        .font(.title2)
                                        .foregroundColor(.appTextSecondary.opacity(0.6))
                                }
                                
                                VStack(spacing: 12) {
                                    Text(L("personalInfo.empty.title", table: "Profile"))
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.appText)
                                    
                                    Text(L("personalInfo.empty.message", table: "Profile"))
                                        .font(.subheadline)
                                        .foregroundColor(.appTextSecondary)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(2)
                                }
                            }
                        }
                    } else {
                        // Schedule Card with enhanced design
                        if let schedule = scheduleStore.first {
                            PersonalInfoModernCard {
                                VStack(spacing: 16) {
                                    // Card Header
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.appAccent.opacity(0.15))
                                                .frame(width: 40, height: 40)
                                            
                                            Image(systemName: "bed.double.fill")
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundColor(.appAccent)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(L("personalInfo.schedule.title", table: "Profile"))
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.appText)
                                            
                                            Text(L("personalInfo.schedule.subtitle", table: "Profile"))
                                                .font(.caption)
                                                .foregroundColor(.appTextSecondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    // Schedule Details
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(schedule.name)
                                                .font(.title3)
                                                .fontWeight(.medium)
                                                .foregroundColor(.appText)
                                            
                                            Text("\(String(format: "%.1f", schedule.totalSleepHours)) " + L("personalInfo.schedule.hours", table: "Profile"))
                                                .font(.subheadline)
                                                .foregroundColor(.appTextSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        // Sleep hours badge
                                        HStack(spacing: 6) {
                                            Image(systemName: "clock.fill")
                                                .font(.caption)
                                                .foregroundColor(.appSecondary)
                                            
                                            Text("\(String(format: "%.1f", schedule.totalSleepHours))h")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.appSecondary)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color.appSecondary.opacity(0.15))
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Answers Card with improved layout
                        PersonalInfoModernCard {
                            VStack(spacing: 20) {
                                // Card Header
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.appPrimary.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "person.text.rectangle.fill")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.appPrimary)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(L("personalInfo.answers.title", table: "Profile"))
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.appText)
                                        
                                        Text("\(getOrderedQuestions().count) " + L("personalInfo.answers.count", table: "Profile"))
                                            .font(.caption)
                                            .foregroundColor(.appTextSecondary)
                                    }
                                    
                                    Spacer()
                                }
                                
                                // Answers Grid
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ], spacing: 12) {
                                    ForEach(Array(getOrderedQuestions().enumerated()), id: \.element) { index, question in
                                        if let answer = answersForDisplay[question] {
                                            PersonalInfoAnswerCard(
                                                question: getLocalizedQuestion(for: question),
                                                answer: getLocalizedAnswer(for: question, value: answer),
                                                index: index
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle(L("personalInfo.title", table: "Profile"))
        .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Modern Components

// Modern card component with enhanced styling
struct PersonalInfoModernCard<Content: View>: View {
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCardBackground)
                    .overlay(
                        // Subtle border for light mode
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(colorScheme == .light ? 0.15 : 0),
                                        Color.gray.opacity(colorScheme == .light ? 0.05 : 0)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: colorScheme == .light ? 
                        Color.black.opacity(0.08) : 
                        Color.black.opacity(0.3),
                        radius: colorScheme == .light ? 12 : 16,
                        x: 0,
                        y: colorScheme == .light ? 6 : 8
                    )
            )
    }
}

// Enhanced answer card with modern design
struct PersonalInfoAnswerCard: View {
    let question: String
    let answer: String
    let index: Int
    @Environment(\.colorScheme) private var colorScheme
    
    // Define accent colors for variety
    private var accentColor: Color {
        let colors: [Color] = [.appPrimary, .appAccent, .appSecondary, .blue, .purple, .orange]
        return colors[index % colors.count]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Question with colored accent
            HStack(spacing: 8) {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 6, height: 6)
                
                Text(question)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Answer text
            Text(answer)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.appText)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            accentColor.opacity(0.03),
                            accentColor.opacity(0.01)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct PersonalInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PersonalInfoView()
        }
        .environmentObject(LanguageManager.shared)
    }
}
