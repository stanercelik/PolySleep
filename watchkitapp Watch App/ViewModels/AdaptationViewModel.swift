import Foundation
import SwiftUI
import PolyNapShared
import Combine

@MainActor
class AdaptationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var adaptationProgress: SharedAdaptationProgress?
    @Published var currentPhaseDescription: String = L("beginning_phase", tableName: "ViewModels")
    @Published var phaseDescription: String = L("adaptation_starting", tableName: "ViewModels")
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    private let watchConnectivity = WatchConnectivityManager.shared
    private var sharedRepository: SharedRepository?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        self.sharedRepository = SharedRepository.shared
        setupConnectivityObservers()
        loadInitialData()
    }
    
    // MARK: - Configuration
    func configureRepository(_ repository: SharedRepository) {
        self.sharedRepository = repository
        loadAdaptationData()
    }
    
    // MARK: - Public Methods
    
    func requestDataSync() {
        isLoading = true
        loadAdaptationData()
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
        loadAdaptationData()
    }
    
    private func loadAdaptationData() {
        Task {
            await loadAdaptationFromRepository()
        }
    }
    
    @MainActor
    private func loadAdaptationFromRepository() async {
        isLoading = true
        
        // Try to load from SharedRepository if available
        guard let repository = sharedRepository,
              repository.getModelContext() != nil else {
            print("⚠️ Watch: SharedRepository not available for adaptation, using mock data")
            loadMockDataIfNeeded()
            isLoading = false
            return
        }
        
        do {
            // For now, create a basic adaptation progress
            // In the future, this will come from actual user data
            let mockProgress = SharedAdaptationProgress(
                currentPhase: 1,
                totalPhases: 4,
                daysSinceStart: 1,
                estimatedTotalDays: 21,
                progressPercentage: 1.0/21.0,
                isCompleted: false,
                phaseName: L("beginning_phase", tableName: "ViewModels"),
                phaseDescription: L("adaptation_started", tableName: "ViewModels")
            )
            
            adaptationProgress = mockProgress
            currentPhaseDescription = mockProgress.phaseName
            phaseDescription = mockProgress.phaseDescription
            
            print("✅ Watch: Adaptation data loaded - Phase: \(mockProgress.currentPhase)/\(mockProgress.totalPhases)")
            
        } catch {
            print("❌ Watch: Adaptation data load failed: \(error.localizedDescription)")
            loadMockDataIfNeeded()
        }
        
        isLoading = false
    }
    
    private func loadMockDataIfNeeded() {
        #if DEBUG
        // Mock adaptation data for development
        let mockProgress = SharedAdaptationProgress(
            currentPhase: 2,
            totalPhases: 5,
            daysSinceStart: 7,
            estimatedTotalDays: 30,
            progressPercentage: 7.0/30.0,
            isCompleted: false,
            phaseName: L("adaptation_phase", tableName: "ViewModels"),
            phaseDescription: L("body_adapting_description", tableName: "ViewModels")
        )
        
        adaptationProgress = mockProgress
        currentPhaseDescription = mockProgress.phaseName
        phaseDescription = mockProgress.phaseDescription
        
        print("📊 Watch: Development adaptation data loaded")
        #else
        currentPhaseDescription = L("waiting_for_data", tableName: "ViewModels")
        phaseDescription = L("loading_adaptation_data", tableName: "ViewModels")
        #endif
    }
} 