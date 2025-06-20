//
//  OnboardingView.swift
//  polynap
//
//  Created by Taner Çelik on 29.12.2024.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @StateObject private var viewModel = OnboardingViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: PSSpacing.lg) {
                    // ProgressView -> 11 Pages
                    ProgressView(value: Double(viewModel.currentPage + 1), total: Double(viewModel.totalPages))
                        .tint(Color.appPrimary)
                        .padding(.horizontal, PSSpacing.lg)
                        .accessibilityValue(String(format: L("accessibility.progressPages", table: "Onboarding"), viewModel.currentPage + 1, viewModel.totalPages))
                    
                    ScrollView {
                        VStack(spacing: PSSpacing.xl) {
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
                        .padding(PSSpacing.lg)
                        .animation(.easeInOut(duration: 0.25), value: viewModel.currentPage)
                    }
                    
                    // Navigation buttons
                    OnboardingNavigationButtons(
                        canMoveNext: viewModel.canMoveNext,
                        currentPage: viewModel.currentPage,
                        totalPages: viewModel.totalPages,
                        onNext: viewModel.moveNext,
                        onBack: viewModel.movePrevious
                    )
                    .padding(.horizontal, PSSpacing.lg)
                    .padding(.bottom, PSSpacing.md)
                }
                .padding(.top, PSSpacing.lg)
                .onAppear {
                    viewModel.setModelContext(modelContext)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $viewModel.showLoadingView, onDismiss: {
                // Loading view kapandığında ve navigateToMainScreen true ise ana ekrana geçiş yap
                if viewModel.navigateToMainScreen {
                    Task {
                        await viewModel.markOnboardingAsCompletedInSwiftData()
                    }
                    viewModel.handleNavigationToMainScreen()
                }
            }) {
                LoadingRecommendationView(
                    progress: $viewModel.recommendationProgress,
                    statusMessage: $viewModel.recommendationStatusMessage,
                    isComplete: $viewModel.recommendationComplete,
                    navigateToMainScreen: $viewModel.navigateToMainScreen
                )
            }
            .background(
                // Görünmeyen bir view ile MainTabBarView'a geçişi sağlar
                NavigationLink(
                    destination: MainTabBarView()
                        .navigationBarBackButtonHidden(true),
                    isActive: $viewModel.goToMainScreen,
                    label: { EmptyView() }
                )
            )
            .alert(L("general.error", table: "Common"), isPresented: $viewModel.showError) {
                Button(L("general.ok", table: "Common"), role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
                    .font(PSTypography.body)
            }
        }
    }
}

#Preview {
    return OnboardingView()
}
