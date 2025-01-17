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
    let totalPages = 8
    
    // Question 1: Previous Sleep Experience
    @Published var previousSleepExperience: PreviousSleepExperience?
    
    // Question 2: Age Range
    @Published var ageRange: AgeRange?
    
    // Question 3: Work Schedule
    @Published var workSchedule: WorkSchedule?
    
    // Question 4: Nap Environment
    @Published var napEnvironment: NapEnvironment?
    
    // Question 5: Lifestyle
    @Published var lifestyle: Lifestyle?
    
    // Question 6: Knowledge Level
    @Published var knowledgeLevel: KnowledgeLevel?
    
    // Question 7: Health Status
    @Published var healthStatus: HealthStatus?
    
    // Question 8: Motivation Level
    @Published var motivationLevel: MotivationLevel?
    
    // MARK: - Navigation State
    @Published var shouldNavigateToSleepSchedule = false
    
    // MARK: - Computed Properties
    var canMoveNext: Bool {
        switch currentPage {
        case 0: return previousSleepExperience != nil
        case 1: return ageRange != nil
        case 2: return workSchedule != nil
        case 3: return napEnvironment != nil
        case 4: return lifestyle != nil
        case 5: return knowledgeLevel != nil
        case 6: return healthStatus != nil
        case 7: return motivationLevel != nil
        default: return false
        }
    }
    
    // MARK: - Methods
    func moveNext() {
        if currentPage < totalPages - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
    }
    
    func moveBack() {
        if currentPage > 0 {
            withAnimation {
                currentPage -= 1
            }
        }
    }
    
    private func completeOnboarding() {
        print("\nSaving onboarding answers to UserDefaults...")
        
        // Save all answers to UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(previousSleepExperience?.rawValue, forKey: "onboarding.sleepExperience")
        defaults.set(ageRange?.rawValue, forKey: "onboarding.ageRange")
        defaults.set(workSchedule?.rawValue, forKey: "onboarding.workSchedule")
        defaults.set(napEnvironment?.rawValue, forKey: "onboarding.napEnvironment")
        defaults.set(lifestyle?.rawValue, forKey: "onboarding.lifestyle")
        defaults.set(knowledgeLevel?.rawValue, forKey: "onboarding.knowledgeLevel")
        defaults.set(healthStatus?.rawValue, forKey: "onboarding.healthStatus")
        defaults.set(motivationLevel?.rawValue, forKey: "onboarding.motivationLevel")
        
        // NEW: Ek soru da kaydetmek istersek:
        // defaults.set(circadianPreference?.rawValue, forKey: "onboarding.circadianPreference")
        
        print("All answers saved. Navigating to Sleep Schedule...")
        
        // Navigate to sleep schedule
        withAnimation {
            shouldNavigateToSleepSchedule = true
        }
    }
    
    // MARK: - Navigation Methods
    func navigateToSleepSchedule() {
        shouldNavigateToSleepSchedule = true
    }
}
