// WelcomeViewModel.swift
// polynap
//
// Created by Taner Çelik on 27.12.2024.

import SwiftUI
import Combine
import SwiftData

class WelcomeViewModel: ObservableObject {
    let totalPages = 4
    
    @Published var currentPageIndex: Int = 0
    @Published var progressValues: [CGFloat] = [0, 0, 0, 0]
    @Published var showTitle: Bool = false
    @Published var showDescription: Bool = false
    @Published var showImage: Bool = false
    
    private let pageDuration: TimeInterval = 10
    private var elapsedTime: TimeInterval = 0
    private var timer: AnyCancellable?
    
    @Published var isPrimaryCircleExpanded: Bool = false
    @Published var isBackgroundCircleExpanded: Bool = false
    @Published var isOnboardingPresented: Bool = false {
        didSet {
            print("🔄 WelcomeViewModel: isOnboardingPresented changed from \(oldValue) to \(isOnboardingPresented)")
        }
    }
    @Published var isContinueButtonVisible: Bool = true
    
    private var modelContext: ModelContext?

    private var cancellables = Set<AnyCancellable>()

    init() {
        resetPage()
    }
    
    // Model context'i tanımlamak için kullanılacak
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
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
    
    func stopTimer() {
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
        showImage = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.showTitle = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.showDescription = true
                    self.showImage = true
                }
            }
        }
    }
    
    func fadeOutAnimations() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showTitle = false
            showDescription = false
            showImage = false
        }
    }
    
    // Button Animation Controller
    func animateAndPresentOnboarding() {
        print("🚀 WelcomeViewModel: animateAndPresentOnboarding() STARTED")
        
        // Timer'ı durdur
        stopTimer()
        
        // Button Text Visibility
        withAnimation(.easeInOut(duration: 0.3)) {
            isContinueButtonVisible = false
        }
        
        print("🚀 WelcomeViewModel: Button visibility set to false, starting circle animations...")
        
        // 1) PrimaryColor Circle - Butondan çıkıp tüm ekranı kaplar
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.7)) {
                self.isPrimaryCircleExpanded = true
            }
        }
        
        // 2) BackgroundColor Circle - Ortadan çıkıp tüm ekranı kaplar
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.7)) {
                self.isBackgroundCircleExpanded = true
            }
        }
        
        // 3) OnboardingView smooth fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            print("🚀 WelcomeViewModel: Setting isOnboardingPresented = true")
            withAnimation(.easeInOut(duration: 0.6)) {
                self.isOnboardingPresented = true
            }
            print("🚀 WelcomeViewModel: isOnboardingPresented set to true, OnboardingView should now appear")
            
            // OnboardingCompleted notification is handled automatically by the app's ContentView
            // The OnboardingViewModel itself handles all UserPreferences updates
            // No need for additional handling here
        }
    }
    
    deinit {
        stopTimer()
        NotificationCenter.default.removeObserver(self)
    }
}
