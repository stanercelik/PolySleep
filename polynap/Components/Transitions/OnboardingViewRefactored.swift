// OnboardingViewRefactored.swift
// polynap
//
// Refactored OnboardingView to use CircularTransition component for skip functionality

import SwiftUI
import SwiftData

struct OnboardingViewRefactored: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var analyticsManager: AnalyticsManager
    @StateObject private var viewModel = OnboardingViewModel()
    
    @State private var showSkipAlert = false
    @State private var skipButtonPosition: CGPoint = .zero
    @State private var startCircularTransition = false
    
    var body: some View {
        NavigationStack {
            mainOnboardingContent
                .circularTransition(
                    to: mainScreenDestination,
                    startPosition: skipButtonPosition,
                    isActive: $startCircularTransition,
                    primaryColor: .appPrimary,
                    backgroundColor: .appBackground
                )
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var mainOnboardingContent: some View {
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
                        // Capture skip button position
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear {
                                    // Skip button is in navigation bar, calculate approximate position
                                    let screenBounds = UIScreen.main.bounds
                                    skipButtonPosition = CGPoint(
                                        x: screenBounds.width - 40, // Right side with some padding
                                        y: 60 // Navigation bar height area
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
                analyticsManager.logScreenView(screenName: "onboarding_screen", screenClass: "OnboardingViewRefactored")
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
            print("📱 OnboardingViewRefactored: LoadingView DISMISSED!")
            print("📱 OnboardingViewRefactored: navigateToMainScreen değeri: \(viewModel.navigateToMainScreen)")
            
            // Loading view kapandığında ve navigateToMainScreen true ise ana ekrana geçiş yap
            if viewModel.navigateToMainScreen {
                print("📱 OnboardingViewRefactored: navigateToMainScreen TRUE, işlemler başlatılıyor...")
                Task {
                    print("📱 OnboardingViewRefactored: markOnboardingAsCompletedInSwiftData çağrılıyor...")
                    await viewModel.markOnboardingAsCompletedInSwiftData()
                    print("📱 OnboardingViewRefactored: markOnboardingAsCompletedInSwiftData tamamlandı!")
                }
                print("📱 OnboardingViewRefactored: handleNavigationToMainScreen çağrılıyor...")
                viewModel.handleNavigationToMainScreen()
                print("📱 OnboardingViewRefactored: handleNavigationToMainScreen tamamlandı!")
            } else {
                print("📱 OnboardingViewRefactored: navigateToMainScreen FALSE, analytics event gönderilmeyecek!")
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
                Task {
                    // Execute skip logic first
                    await viewModel.skipOnboarding()
                    
                    // Start circular transition after skip logic completes
                    await MainActor.run {
                        // Small delay to ensure skip logic is complete
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            startCircularTransition = true
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
    
    private var mainScreenDestination: some View {
        // This should be MainTabBarView or whatever comes after onboarding
        VStack {
            Text("Main Screen")
                .font(.largeTitle)
                .padding()
            
            Text("Onboarding was skipped successfully!")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .onAppear {
            // Notify that transition is complete
            NotificationCenter.default.post(
                name: NSNotification.Name("OnboardingCompleted"),
                object: nil
            )
        }
    }
}

// MARK: - Alternative Implementation with Better Skip Button Position Tracking
struct OnboardingViewWithBetterSkipTracking: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var analyticsManager: AnalyticsManager
    @StateObject private var viewModel = OnboardingViewModel()
    
    @State private var showSkipAlert = false
    @State private var startCircularTransition = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                if !startCircularTransition {
                    mainOnboardingContent
                }
                
                // Circular transition overlay
                if startCircularTransition {
                    CircularTransitionView(
                        config: CircularTransitionConfig(
                            startPosition: CGPoint(
                                x: UIScreen.main.bounds.width - 40, // Skip button position
                                y: 60 // Navigation bar area
                            ),
                            primaryColor: .appPrimary,
                            backgroundColor: .appBackground,
                            buttonFadeOutDuration: 0.3,
                            primaryCircleDelay: 0.2,
                            primaryCircleAnimationDuration: 0.7,
                            backgroundCircleDelay: 0.8,
                            backgroundCircleAnimationDuration: 0.7,
                            destinationFadeInDelay: 1.4,
                            destinationFadeInDuration: 0.6
                        ),
                        sourceContent: { mainOnboardingContent },
                        destinationContent: { mainScreenDestination }
                    )
                    .onAppear {
                        // Auto-start transition
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            // The CircularTransitionView will handle its own timing
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var mainOnboardingContent: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: PSSpacing.lg) {
                // ProgressView
                ProgressView(value: Double(viewModel.currentPage + 1), total: Double(viewModel.totalPages))
                    .tint(Color.appPrimary)
                    .padding(.horizontal, PSSpacing.lg)
                
                ScrollView {
                    VStack(spacing: PSSpacing.xl) {
                        // All onboarding pages here (same as original)
                        switch viewModel.currentPage {
                        case 0:
                            OnboardingSelectionView(
                                title: LocalizedStringKey("onboarding.sleepExperience"),
                                description: LocalizedStringKey("onboarding.sleepExperienceQuestion"),
                                options: PreviousSleepExperience.allCases,
                                selectedOption: $viewModel.previousSleepExperience
                            )
                        // ... other cases (same as original)
                        default:
                            EmptyView()
                        }
                    }
                    .padding(PSSpacing.lg)
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
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(L("general.skip", table: "Common")) {
                    showSkipAlert = true
                }
                .tint(Color.appPrimary)
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            analyticsManager.logOnboardingStarted()
            analyticsManager.logScreenView(screenName: "onboarding_screen", screenClass: "OnboardingViewWithBetterSkipTracking")
        }
        .alert(L("onboarding.skip.title", table: "Onboarding"), isPresented: $showSkipAlert) {
            Button(L("onboarding.skip.confirm", table: "Onboarding"), role: .destructive) {
                Task {
                    // Execute skip logic
                    await viewModel.skipOnboarding()
                    
                    // Start transition
                    await MainActor.run {
                        startCircularTransition = true
                    }
                }
            }
            Button(L("general.cancel", table: "Common"), role: .cancel) {}
        } message: {
            Text(L("onboarding.skip.message", table: "Onboarding"))
        }
    }
    
    private var mainScreenDestination: some View {
        VStack {
            Text("Main Screen")
                .font(.largeTitle)
                .padding()
            
            Text("Skipped successfully with circular transition!")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .onAppear {
            NotificationCenter.default.post(
                name: NSNotification.Name("OnboardingCompleted"),
                object: nil
            )
        }
    }
}

#Preview("Onboarding Refactored") {
    OnboardingViewRefactored()
}

#Preview("Better Skip Tracking") {
    OnboardingViewWithBetterSkipTracking()
}