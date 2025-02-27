//
//  OnboardingView.swift
//  polysleep
//
//  Created by Taner Çelik on 29.12.2024.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    let modelContext: ModelContext
    @StateObject private var viewModel: OnboardingViewModel
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // ProgressView -> 11 Pages
                    ProgressView(value: Double(viewModel.currentPage), total: Double(viewModel.totalPages))
                        .tint(Color.appPrimary)
                        .padding(.horizontal)
                        .accessibilityValue("\(viewModel.currentPage + 1) of \(viewModel.totalPages) pages")
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            switch viewModel.currentPage {
                            case 0:
                                OnboardingSelectionView(
                                    title: LocalizedStringKey("onboarding.sleepExperience"),
                                    description: LocalizedStringKey("onboarding.sleepExperienceQuestion"),
                                    options: PreviousSleepExperience.allCases,
                                    selectedOption: $viewModel.previousSleepExperience
                                )
                            case 1:
                                OnboardingSelectionView(
                                    title: LocalizedStringKey("onboarding.ageRange"),
                                    description: LocalizedStringKey("onboarding.ageRangeDescription"),
                                    options: AgeRange.allCases,
                                    selectedOption: $viewModel.ageRange
                                )
                            case 2:
                                OnboardingSelectionView(
                                    title: LocalizedStringKey("onboarding.workSchedule"),
                                    description: LocalizedStringKey("onboarding.workScheduleQuestion"),
                                    options: WorkSchedule.allCases,
                                    selectedOption: $viewModel.workSchedule
                                )
                            case 3:
                                OnboardingSelectionView(
                                    title: LocalizedStringKey("onboarding.napEnvironment"),
                                    description: LocalizedStringKey("onboarding.napEnvironmentDescription"),
                                    options: NapEnvironment.allCases,
                                    selectedOption: $viewModel.napEnvironment
                                )
                            case 4:
                                OnboardingSelectionView(
                                    title: LocalizedStringKey("onboarding.lifestyle"),
                                    description: LocalizedStringKey("onboarding.lifestyleDescription"),
                                    options: Lifestyle.allCases,
                                    selectedOption: $viewModel.lifestyle
                                )
                            case 5:
                                OnboardingSelectionView(
                                    title: LocalizedStringKey("onboarding.knowledgeLevel"),
                                    description: LocalizedStringKey("onboarding.knowledgeLevelDescription"),
                                    options: KnowledgeLevel.allCases,
                                    selectedOption: $viewModel.knowledgeLevel
                                )
                            case 6:
                                OnboardingSelectionView(
                                    title: LocalizedStringKey("onboarding.healthStatus"),
                                    description: LocalizedStringKey("onboarding.healthStatusDescription"),
                                    options: HealthStatus.allCases,
                                    selectedOption: $viewModel.healthStatus
                                )
                            case 7:
                                OnboardingSelectionView(
                                    title: LocalizedStringKey("onboarding.motivationLevel"),
                                    description: LocalizedStringKey("onboarding.motivationLevelQuestion"),
                                    options: MotivationLevel.allCases,
                                    selectedOption: $viewModel.motivationLevel
                                )
                            case 8:
                                OnboardingSelectionView(
                                    title: LocalizedStringKey("onboarding.sleepGoal"),
                                    description: LocalizedStringKey("onboarding.sleepGoalDescription"),
                                    options: SleepGoal.allCases,
                                    selectedOption: $viewModel.sleepGoal
                                )
                            case 9:
                                OnboardingSelectionView(
                                    title: LocalizedStringKey("onboarding.socialObligations"),
                                    description: LocalizedStringKey("onboarding.socialObligationsDescription"),
                                    options: SocialObligations.allCases,
                                    selectedOption: $viewModel.socialObligations
                                )
                            case 10:
                                OnboardingSelectionView(
                                    title: LocalizedStringKey("onboarding.disruptionTolerance"),
                                    description: LocalizedStringKey("onboarding.disruptionToleranceDescription"),
                                    options: DisruptionTolerance.allCases,
                                    selectedOption: $viewModel.disruptionTolerance
                                )
                            case 11:
                                OnboardingSelectionView(
                                    title: LocalizedStringKey("onboarding.chronotype"),
                                    description: LocalizedStringKey("onboarding.chronotypeDescription"),
                                    options: Chronotype.allCases,
                                    selectedOption: $viewModel.chronotype
                                )
                            default:
                                EmptyView()
                            }
                        }
                        .padding()
                        .animation(.easeInOut, value: viewModel.currentPage)
                    }
                    
                    // Navigation buttons
                    OnboardingNavigationButtons(
                        canMoveNext: viewModel.canMoveNext,
                        currentPage: viewModel.currentPage,
                        totalPages: viewModel.totalPages,
                        onNext: viewModel.moveNext,
                        onBack: viewModel.movePrevious
                    )
                }
                .padding(.top, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $viewModel.shouldNavigateToSleepSchedule) {
                SleepScheduleView()
                    .navigationBarBackButtonHidden(true)
            }
            
            if viewModel.showStartButton {
                VStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            viewModel.startUsingApp()
                        }
                    }) {
                        Text("onboarding.startUsingApp", tableName: "Onboarding")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.appPrimary)
                            )
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
}

#Preview {
    do {
        let schema = Schema([UserFactor.self])
        let modelConfiguration = ModelConfiguration(schema: schema)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = container.mainContext
        return OnboardingView(modelContext: context)
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
