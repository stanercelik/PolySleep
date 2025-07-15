import Foundation
import SwiftUI
import PolyNapShared
import Combine

// AdaptationData tanımlaması
struct AdaptationData: Codable, Equatable {
    let adaptationPhase: Int
    let adaptationPercentage: Int
    let averageRating: Double
    let totalEntries: Int
    let last7DaysEntries: Int
    let lastUpdated: Date
    
    init(
        adaptationPhase: Int = 1,
        adaptationPercentage: Int = 0,
        averageRating: Double = 0.0,
        totalEntries: Int = 0,
        last7DaysEntries: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.adaptationPhase = adaptationPhase
        self.adaptationPercentage = adaptationPercentage
        self.averageRating = averageRating
        self.totalEntries = totalEntries
        self.last7DaysEntries = last7DaysEntries
        self.lastUpdated = lastUpdated
    }
    
    init?(from dictionary: [String: Any]) {
        guard let adaptationPhase = dictionary["adaptationPhase"] as? Int,
              let adaptationPercentage = dictionary["adaptationPercentage"] as? Int,
              let averageRating = dictionary["averageRating"] as? Double,
              let totalEntries = dictionary["totalEntries"] as? Int,
              let last7DaysEntries = dictionary["last7DaysEntries"] as? Int else {
            return nil
        }
        
        self.adaptationPhase = adaptationPhase
        self.adaptationPercentage = adaptationPercentage
        self.averageRating = averageRating
        self.totalEntries = totalEntries
        self.last7DaysEntries = last7DaysEntries
        self.lastUpdated = Date()
    }
    
    var phaseDescription: String {
        switch adaptationPhase {
        case 1: return "Başlangıç"
        case 2: return "Uyum"
        case 3: return "İlerleme"
        case 4: return "Uzman"
        default: return "Bilinmiyor"
        }
    }
    
    static let empty = AdaptationData()
}

@MainActor
class AdaptationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var adaptationProgress: SharedAdaptationProgress?
    @Published var currentPhaseDescription: String = L("beginning_phase", tableName: "ViewModels")
    @Published var phaseDescription: String = L("adaptation_starting", tableName: "ViewModels")
    @Published var isLoading: Bool = false
    @Published var adaptationData: AdaptationData = .empty
    
    // MARK: - Private Properties
    private let watchConnectivity = WatchConnectivityManager.shared
    private let syncService = SyncService()
    private var sharedRepository: SharedRepository?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        self.sharedRepository = SharedRepository.shared
        setupConnectivityObservers()
        setupSyncServiceObservers()
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
    
    private func setupSyncServiceObservers() {
        // SyncService'ten adaptasyon verisi güncellemelerini dinle
        syncService.$latestAdaptationData
            .compactMap { $0 }
            .sink { [weak self] adaptationDataDict in
                if let data = AdaptationData(from: adaptationDataDict) {
                    self?.updateAdaptationData(data)
                }
            }
            .store(in: &cancellables)
        
        // NotificationCenter üzerinden adaptasyon verisi güncellemelerini dinle
        NotificationCenter.default.publisher(for: .adaptationDataDidUpdate)
            .compactMap { notification in
                notification.userInfo?["adaptationData"] as? [String: Any]
            }
            .sink { [weak self] adaptationDataDict in
                if let data = AdaptationData(from: adaptationDataDict) {
                    self?.updateAdaptationData(data)
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
    
    /// Adaptasyon verisini günceller
    private func updateAdaptationData(_ data: AdaptationData) {
        adaptationData = data
        
        // UI metinlerini güncelle
        currentPhaseDescription = data.phaseDescription
        
        switch data.adaptationPhase {
        case 1:
            phaseDescription = L("adaptation_starting", tableName: "ViewModels")
        case 2:
            phaseDescription = L("adaptation_progressing", tableName: "ViewModels")
        case 3:
            phaseDescription = L("adaptation_advanced", tableName: "ViewModels")
        case 4:
            phaseDescription = L("adaptation_expert", tableName: "ViewModels")
        default:
            phaseDescription = L("adaptation_unknown", tableName: "ViewModels")
        }
        
        print("📊 Watch: Adaptasyon verisi güncellendi - Faz: \(data.adaptationPhase), Yüzde: \(data.adaptationPercentage)%")
    }
} 