//
//  OnboardingViewModel.swift
//  polysleep
//
//  Created by Taner Çelik on 29.12.2024.
//

import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentPage = 0
    let totalPages = 8  // Total number of onboarding pages
    @Published var previousSleepExperience: PreviousSleepExperience?
    @Published var knowledgeLevel: KnowledgeLevel?
    @Published var selectedAgeRange: AgeRange?
    @Published var hasMedicalCondition: Bool? = nil
    @Published var sleepQuality: SleepQuality?
    @Published var sleepDuration: SleepDuration?
    @Published var sleepScheduleType: SleepScheduleType?
    @Published var workSchedule: WorkSchedule?
    @Published var lifestyle: Lifestyle?
    @Published var sleepEnvironment: SleepEnvironment?
    @Published var napEnvironment: NapEnvironment?
    
    // MARK: - Computed Properties
    var canMoveNext: Bool {
        switch currentPage {
        case 0: return previousSleepExperience != nil
        case 1: return knowledgeLevel != nil
        case 2: return selectedAgeRange != nil
        case 3: return hasMedicalCondition != nil
        case 4: return sleepQuality != nil
        case 5: return sleepDuration != nil
        case 6: return sleepScheduleType != nil
        case 7: return true // SleepScheduleView
        default: return false
        }
    }
    
    // MARK: - Methods
    func moveNext() {
        if currentPage < totalPages - 1 {
            withAnimation {
                currentPage += 1
            }
        }
    }
    
    func moveBack() {
        if currentPage > 0 {
            withAnimation {
                currentPage -= 1
            }
        }
    }
}
