//
//  welcomeViewModel.swift
//  polysleep
//
//  Created by Taner Çelik on 27.12.2024.
//

import SwiftUI
import Combine

class WelcomeViewModel: ObservableObject {
    
    let totalPages = 4
    
    @Published var currentPageIndex: Int = 0
    @Published var progressValues: [CGFloat] = [0, 0, 0, 0]
    
    private let pageDuration: TimeInterval = 6
    
    private var cancellables = Set<AnyCancellable>()
    private var timer: AnyCancellable?
    
    init() {
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.publish(every: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updateProgress()
            }
    }
    
    private var elapsedTime: TimeInterval = 0
    
    private func updateProgress() {
        elapsedTime += 0.01
        let currentProgress = CGFloat(elapsedTime / pageDuration)
        
        if currentProgress <= 1.0 {
            progressValues[currentPageIndex] = currentProgress
        } else {
            progressValues[currentPageIndex] = 1.0
            goToNextPage()
        }
    }
    
    private func goToNextPage() {
        elapsedTime = 0
        if currentPageIndex < totalPages - 1 {
            currentPageIndex += 1
        } else {
            currentPageIndex = 0
            progressValues = progressValues.map { _ in 0.0 }
        }
    }
    
    func stopTimer() {
        timer?.cancel()
    }
    
    deinit {
        stopTimer()
    }
}
