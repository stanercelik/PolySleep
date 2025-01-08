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
        if currentPage < totalPages {
            withAnimation {
                currentPage += 1
            }
            
        }
        // If we are on the last page trigger navigation
        else {
            saveResponses()
            shouldNavigateToSleepSchedule = true
        }
    }
    
    func moveBack() {
        if currentPage > 0 {
            withAnimation {
                currentPage -= 1
            }
        }
    }
    
    // Save user responses to UserDefaults
    func saveResponses() {
        let defaults = UserDefaults.standard
        
        if let experience = previousSleepExperience {
            defaults.set(experience.rawValue, forKey: "onboarding.sleepExperience")
        }
        if let age = ageRange {
            defaults.set(age.rawValue, forKey: "onboarding.ageRange")
        }
        if let work = workSchedule {
            defaults.set(work.rawValue, forKey: "onboarding.workSchedule")
        }
        if let nap = napEnvironment {
            defaults.set(nap.rawValue, forKey: "onboarding.napEnvironment")
        }
        if let life = lifestyle {
            defaults.set(life.rawValue, forKey: "onboarding.lifestyle")
        }
        if let knowledge = knowledgeLevel {
            defaults.set(knowledge.rawValue, forKey: "onboarding.knowledgeLevel")
        }
        if let health = healthStatus {
            defaults.set(health.rawValue, forKey: "onboarding.healthStatus")
        }
        if let motivation = motivationLevel {
            defaults.set(motivation.rawValue, forKey: "onboarding.motivationLevel")
        }
    }
    
    // MARK: - Navigation Methods
    func navigateToSleepSchedule() {
        shouldNavigateToSleepSchedule = true
    }
}
