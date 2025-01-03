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
                            case 0:
                                OnboardingSelectionView(
                                    title: "onboarding.sleepExperience",
                                    description: "onboarding.sleepExperienceQuestion",
                                    options: PreviousSleepExperience.allCases,
                                    selectedOption: $viewModel.previousSleepExperience
                                )
                            case 1:
                                OnboardingSelectionView(
                                    title: "onboarding.knowledgeLevel",
                                    description: "onboarding.knowledgeQuestion",
                                    options: KnowledgeLevel.allCases,
                                    selectedOption: $viewModel.knowledgeLevel
                                )
                            case 2:
                                OnboardingSelectionView(
                                    title: "onboarding.ageRange",
                                    description: "onboarding.ageRangeDescription",
                                    options: AgeRange.allCases,
                                    selectedOption: $viewModel.selectedAgeRange
                                )
                            case 3:
                                MedicalConditionView(hasMedicalCondition: $viewModel.hasMedicalCondition)
                            case 4:
                                OnboardingSelectionView(
                                    title: "onboarding.sleepQuality",
                                    description: "onboarding.sleepQualityQuestion",
                                    options: SleepQuality.allCases,
                                    selectedOption: $viewModel.sleepQuality
                                )
                            case 5:
                                OnboardingSelectionView(
                                    title: "onboarding.sleepDuration",
                                    description: "onboarding.sleepDurationQuestion",
                                    options: SleepDuration.allCases,
                                    selectedOption: $viewModel.sleepDuration
                                )
                            case 6:
                                OnboardingSelectionView(
                                    title: "onboarding.sleepSchedule",
                                    description: "onboarding.sleepScheduleQuestion",
                                    options: SleepScheduleType.allCases,
                                    selectedOption: $viewModel.sleepScheduleType
                                )
                            case 7:
                                SleepScheduleView()
                                    .frame(height: UIScreen.main.bounds.height * 0.7)
                            case 8:
                                OnboardingSelectionView(
                                    title: "onboarding.workSchedule",
                                    description: "onboarding.workScheduleQuestion",
                                    options: WorkSchedule.allCases,
                                    selectedOption: $viewModel.workSchedule
                                )
                            case 9:
                                OnboardingSelectionView(
                                    title: "onboarding.lifestyle",
                                    description: "onboarding.lifestyleQuestion",
                                    options: Lifestyle.allCases,
                                    selectedOption: $viewModel.lifestyle
                                )
                            case 10:
                                OnboardingSelectionView(
                                    title: "onboarding.sleepEnvironment",
                                    description: "onboarding.sleepEnvironmentQuestion",
                                    options: SleepEnvironment.allCases,
                                    selectedOption: $viewModel.sleepEnvironment
                                )
                            case 11:
                                OnboardingSelectionView(
                                    title: "onboarding.napEnvironment",
                                    description: "onboarding.napEnvironmentQuestion",
                                    options: NapEnvironment.allCases,
                                    selectedOption: $viewModel.napEnvironment
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
                        onNext: viewModel.moveNext,
                        onBack: viewModel.moveBack
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("onboarding.cancel") {
                        dismiss()
                    }
                }
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
