import Foundation
import SwiftUI
import PolyNapShared
import Combine

@MainActor
class AdaptationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var adaptationProgress: SharedAdaptationProgress?
    @Published var currentPhaseDescription: String = "Başlangıç Fazı"
    @Published var phaseDescription: String = "Adaptasyon süreci başlıyor..."
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    private let watchConnectivity = WatchConnectivityManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupConnectivityObservers()
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    func requestDataSync() {
        isLoading = true
        
        // Mock data for Milestone 2.2 - actual implementation in later milestones
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.loadMockData()
            self?.isLoading = false
        }
    }
    
    // MARK: - Private Methods
    
    private func setupConnectivityObservers() {
        watchConnectivity.$isReachable
            .sink { [weak self] isReachable in
                if isReachable {
                    self?.requestDataSync()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        loadMockData()
    }
    
    private func loadMockData() {
        // Mock adaptation data for Milestone 2.2
        let mockProgress = SharedAdaptationProgress(
            currentPhase: 2,
            totalPhases: 5,
            daysSinceStart: 7,
            estimatedTotalDays: 30,
            progressPercentage: 7.0/30.0,
            isCompleted: false,
            phaseName: "Uyum Fazı",
            phaseDescription: "Vücut yeni uyku düzenine alışmaya başlıyor",
            remainingDays: 23
        )
        
        adaptationProgress = mockProgress
        currentPhaseDescription = mockProgress.phaseName
        phaseDescription = mockProgress.phaseDescription
        
        print("📊 Adaptation mock data loaded - Phase: \(mockProgress.currentPhase)/\(mockProgress.totalPhases), Day: \(mockProgress.daysSinceStart)")
    }
}

// MARK: - SharedAdaptationProgress Model (Mock)
struct SharedAdaptationProgress {
    let currentPhase: Int
    let totalPhases: Int
    let daysSinceStart: Int
    let estimatedTotalDays: Int
    let progressPercentage: Double
    let isCompleted: Bool
    let phaseName: String
    let phaseDescription: String
    let remainingDays: Int
} 