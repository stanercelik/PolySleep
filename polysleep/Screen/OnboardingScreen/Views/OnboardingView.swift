//
//  OnboardingView.swift
//  polysleep
//
//  Created by Taner Çelik on 29.12.2024.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToSleepSchedule = false
    @State private var opacity = 1.0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProgressView(value: Double(viewModel.currentPage), total: Double(viewModel.totalPages))
                        .tint(Color("PrimaryColor"))
                        .padding(.horizontal)
                        .accessibilityValue("\(viewModel.currentPage + 1) of \(viewModel.totalPages) pages")
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            switch viewModel.currentPage {
                            case 0: // Previous Sleep Experience
                                OnboardingSelectionView(
                                    title: "onboarding.sleepExperience",
                                    description: "onboarding.sleepExperienceQuestion",
                                    options: PreviousSleepExperience.allCases,
                                    selectedOption: $viewModel.previousSleepExperience
                                )
                            case 1: // Age Range
                                OnboardingSelectionView(
                                    title: "onboarding.ageRange",
                                    description: "onboarding.ageRangeDescription",
                                    options: AgeRange.allCases,
                                    selectedOption: $viewModel.ageRange
                                )
                            case 2: // Work Schedule
                                OnboardingSelectionView(
                                    title: "onboarding.workSchedule",
                                    description: "onboarding.workScheduleQuestion",
                                    options: WorkSchedule.allCases,
                                    selectedOption: $viewModel.workSchedule
                                )
                            case 3: // Nap Environment
                                OnboardingSelectionView(
                                    title: "onboarding.napEnvironment",
                                    description: "onboarding.napEnvironmentDescription",
                                    options: NapEnvironment.allCases,
                                    selectedOption: $viewModel.napEnvironment
                                )
                            case 4: // Lifestyle
                                OnboardingSelectionView(
                                    title: "onboarding.lifestyle",
                                    description: "onboarding.lifestyleDescription",
                                    options: Lifestyle.allCases,
                                    selectedOption: $viewModel.lifestyle
                                )
                            case 5: // Knowledge Level
                                OnboardingSelectionView(
                                    title: "onboarding.knowledgeLevel",
                                    description: "onboarding.knowledgeLevelDescription",
                                    options: KnowledgeLevel.allCases,
                                    selectedOption: $viewModel.knowledgeLevel
                                )
                            case 6: // Health Status
                                OnboardingSelectionView(
                                    title: "onboarding.healthStatus",
                                    description: "onboarding.healthStatusDescription",
                                    options: HealthStatus.allCases,
                                    selectedOption: $viewModel.healthStatus
                                )
                            case 7: // Motivation Level
                                OnboardingSelectionView(
                                    title: "onboarding.motivationLevel",
                                    description: "onboarding.motivationLevelDescription",
                                    options: MotivationLevel.allCases,
                                    selectedOption: $viewModel.motivationLevel
                                )
                            default:
                                EmptyView()
                            }
                        }
                        .padding()
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                        .animation(.easeInOut, value: viewModel.currentPage)
                    }
                    
                    OnboardingNavigationButtons(
                        canMoveNext: viewModel.canMoveNext,
                        currentPage: viewModel.currentPage,
                        totalPages: viewModel.totalPages,
                        onNext: {
                            if viewModel.currentPage < viewModel.totalPages - 1 {
                                withAnimation {
                                    viewModel.currentPage += 1
                                }
                            } else {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    opacity = 0
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    navigateToSleepSchedule = true
                                }
                            }
                        },
                        onBack: {
                            withAnimation {
                                viewModel.currentPage -= 1
                            }
                        }
                    )
                }
                .opacity(opacity)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToSleepSchedule) {
                SleepScheduleView()
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}

// MARK: - Medical Condition View
struct MedicalConditionView: View {
    @Binding var hasMedicalCondition: Bool?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("onboarding.medicalCondition", bundle: .main)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("onboarding.medicalConditionDescription", bundle: .main)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                Button {
                    hasMedicalCondition = true
                } label: {
                    HStack {
                        Text("onboarding.yes", bundle: .main)
                        Spacer()
                        if hasMedicalCondition == true {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                
                Button {
                    hasMedicalCondition = false
                } label: {
                    HStack {
                        Text("onboarding.no", bundle: .main)
                        Spacer()
                        if hasMedicalCondition == false {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}
