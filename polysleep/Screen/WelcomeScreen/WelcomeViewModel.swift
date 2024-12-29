// WelcomeViewModel.swift
// polysleep
//
// Created by Taner Çelik on 27.12.2024.

import SwiftUI
import Combine

class WelcomeViewModel: ObservableObject {
    let totalPages = 4
    
    @Published var currentPageIndex: Int = 0
    @Published var progressValues: [CGFloat] = [0, 0, 0, 0]
    @Published var showTitle: Bool = false
    @Published var showDescription: Bool = false
    
    private let pageDuration: TimeInterval = 10
    private var elapsedTime: TimeInterval = 0
    private var timer: AnyCancellable?
    
    @Published var isPrimaryCircleExpanded: Bool = false
    @Published var isBackgroundCircleExpanded: Bool = false
    @Published var isOnboardingPresented: Bool = false
    @Published var isContinueButtonVisible: Bool = true

    private var cancellables = Set<AnyCancellable>()

    init() {
        resetPage()
    }
    
    // Timer Management
    private func startTimer() {
        stopTimer()
        timer = Timer.publish(every: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateProgress()
            }
    }
    
    private func stopTimer() {
        timer?.cancel()
    }
    
    private func updateProgress() {
        elapsedTime += 0.01
        let currentProgress = CGFloat(elapsedTime / pageDuration)

        if currentProgress <= 1.0 {
            progressValues[currentPageIndex] = currentProgress
        } else {
            progressValues[currentPageIndex] = 1.0
            if currentPageIndex == totalPages - 1 {
                resetToFirstPage()
            } else {
                nextPage()
            }
        }
    }
    
    // Page Changes
    
    func nextPage() {
        if currentPageIndex < totalPages - 1 {
            progressValues[currentPageIndex] = 1.0
            currentPageIndex += 1
        } else {
            resetToFirstPage()
        }
        resetPage()
    }
    
    func previousPage() {
        if currentPageIndex > 0 {
            progressValues[currentPageIndex] = 0.0
            currentPageIndex -= 1
        } else {
            progressValues[currentPageIndex] = 0.0
        }
        resetPage()
    }
    
    private func resetToFirstPage() {
        currentPageIndex = 0
        elapsedTime = 0
        progressValues = Array(repeating: 0.0, count: totalPages)
        startTimer()
        startAnimations()
    }
    
    private func resetPage() {
        elapsedTime = 0
        progressValues[currentPageIndex] = 0.0
        startTimer()
        startAnimations()
    }
    
    // Title and Description Animations

    private func startAnimations() {
        showTitle = false
        showDescription = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.showTitle = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.showDescription = true
                }
            }
        }
    }
    
    func fadeOutAnimations() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showTitle = false
            showDescription = false
        }
    }
    
    // Button Animation Controller
    func animateAndPresentOnboarding() {
        // Button Text Visibility
        withAnimation(.easeInOut(duration: 0.1)) {
            isContinueButtonVisible = false
        }
        
        // 1) PrimaryColor Circle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.8)) {
                self.isPrimaryCircleExpanded = true
            }
        }
        
        // 2) BackgroundColor Circle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.8)) {
                self.isBackgroundCircleExpanded = true
            }
        }
        
        // 3) OnboardingView’ın fade-in Presenting
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.easeInOut(duration: 2)) {
                self.isOnboardingPresented = true
            }
        }
    }
    
    deinit {
        stopTimer()
    }
}
