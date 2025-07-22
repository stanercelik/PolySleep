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
    @EnvironmentObject private var analyticsManager: AnalyticsManager
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var showSkipAlert = false
    
    // Circular transition states
    @State private var skipButtonPosition: CGPoint = .zero
    @State private var startSkipTransition = false {
        didSet {
            print("🔥 OnboardingView: startSkipTransition changed from \(oldValue) to \(startSkipTransition)")
        }
    }
    
    var body: some View {
        NavigationStack {
            mainContent
                .circularTransition(
                    to: Color.appBackground
                        .ignoresSafeArea()
                        .onAppear {
                            print("🔥 OnboardingView: Transition destination appeared - MainTabBarView should fade in through ContentView")
                        },
                    startPosition: skipButtonPosition,
                    isActive: $startSkipTransition
                )
                .navigationBarTitleDisplayMode(.inline)
                .onChange(of: startSkipTransition) { oldValue, newValue in
                    if newValue == true && oldValue == false {
                        print("🔥 OnboardingView: startSkipTransition became true - starting skip completion")
                        // Complete the skip process with perfect timing for circular transition
                        Task {
                            // Complete skip logic immediately
                            print("🔥 OnboardingView: Calling completeSkipAfterTransition immediately")
                            await viewModel.completeSkipAfterTransition()
                            
                            // Send notification immediately after skip completion
                            // This allows ContentView to prepare MainTabBarView for the transition
                            print("🔥 OnboardingView: Sending OnboardingCompleted notification immediately")
                            NotificationCenter.default.post(
                                name: NSNotification.Name("OnboardingCompleted"),
                                object: nil
                            )
                        }
                    }
                }
        }
    }
    
    private var mainContent: some View {
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
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(L("general.skip", table: "Common")) {
                            showSkipAlert = true
                        }
                        .tint(Color.appPrimary)
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .onAppear {
                                        let screenBounds = UIScreen.main.bounds
                                        skipButtonPosition = CGPoint(
                                            x: screenBounds.width - 40,
                                            y: 60
                                        )
                                    }
                            }
                        )
                    }
                }
                .onAppear {
                    viewModel.setModelContext(modelContext)
                    
                    // 📊 Analytics: Onboarding başlangıç
                    analyticsManager.logOnboardingStarted()
                    analyticsManager.logScreenView(screenName: "onboarding_screen", screenClass: "OnboardingView")
                }
                .onChange(of: viewModel.currentPage) { oldValue, newValue in
                    // 📊 Analytics: Onboarding adım tracking
                    let stepNames = [
                        0: "sleep_experience",
                        1: "age_range",
                        2: "work_schedule",
                        3: "nap_environment",
                        4: "lifestyle",
                        5: "knowledge_level",
                        6: "health_status",
                        7: "motivation_level",
                        8: "sleep_goal",
                        9: "social_obligations",
                        10: "disruption_tolerance",
                        11: "chronotype"
                    ]
                    
                    if let stepName = stepNames[newValue] {
                        analyticsManager.logOnboardingStepCompleted(step: newValue + 1, stepName: stepName)
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.showLoadingView, onDismiss: {
                print("📱 OnboardingView: LoadingView DISMISSED!")
                print("📱 OnboardingView: navigateToMainScreen değeri: \(viewModel.navigateToMainScreen)")
                
                // Loading view kapandığında ve navigateToMainScreen true ise ana ekrana geçiş yap
                if viewModel.navigateToMainScreen {
                    print("📱 OnboardingView: navigateToMainScreen TRUE, işlemler başlatılıyor...")
                    Task {
                        print("📱 OnboardingView: markOnboardingAsCompletedInSwiftData çağrılıyor...")
                        await viewModel.markOnboardingAsCompletedInSwiftData()
                        print("📱 OnboardingView: markOnboardingAsCompletedInSwiftData tamamlandı!")
                    }
                    print("📱 OnboardingView: handleNavigationToMainScreen çağrılıyor...")
                    viewModel.handleNavigationToMainScreen()
                    print("📱 OnboardingView: handleNavigationToMainScreen tamamlandı!")
                } else {
                    print("📱 OnboardingView: navigateToMainScreen FALSE, analytics event gönderilmeyecek!")
                }
            }) {
                LoadingRecommendationView(
                    progress: $viewModel.recommendationProgress,
                    statusMessage: $viewModel.recommendationStatusMessage,
                    isComplete: $viewModel.recommendationComplete,
                    navigateToMainScreen: $viewModel.navigateToMainScreen
                )
            }
            .alert(L("onboarding.skip.title", table: "Onboarding"), isPresented: $showSkipAlert) {
                Button(L("onboarding.skip.confirm", table: "Onboarding"), role: .destructive) {
                    print("🔥 OnboardingView: Skip confirmed by user, starting process...")
                    Task {
                        print("🔥 OnboardingView: Calling skipOnboardingForTransition()...")
                        // Use the transition-specific skip function
                        await viewModel.skipOnboardingForTransition()
                        print("🔥 OnboardingView: skipOnboardingForTransition() completed!")
                        
                        // Start circular transition after skip logic completes
                        await MainActor.run {
                            print("🔥 OnboardingView: Setting startSkipTransition = true after 0.1s delay...")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                print("🔥 OnboardingView: About to set startSkipTransition = true")
                                startSkipTransition = true
                                print("🔥 OnboardingView: startSkipTransition set to true!")
                            }
                        }
                    }
                }
                Button(L("general.cancel", table: "Common"), role: .cancel) {}
            } message: {
                Text(L("onboarding.skip.message", table: "Onboarding"))
            }
            .alert(L("general.error", table: "Common"), isPresented: $viewModel.showError) {
                Button(L("general.ok", table: "Common"), role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
                    .font(PSTypography.body)
            }
        }
    }


#Preview {
    return OnboardingView()
}
