import Foundation
import SwiftUI
import PolyNapShared
import Combine

@MainActor
class SleepEntryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var recentEntries: [SharedSleepEntry] = []
    @Published var selectedQuality: Int = 3
    @Published var selectedEmoji: String = "😴"
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var lastSaveDate: Date?
    @Published var saveMessage: String = ""
    @Published var showSaveConfirmation: Bool = false
    
    // Quality rating
    @Published var qualityEmojis: [String] = ["😩", "😪", "😐", "😊", "🤩"]
    @Published var qualityDescriptions: [String] = [
        L("quality_very_bad", table: "ViewModels"),
        L("quality_bad", table: "ViewModels"),
        L("quality_average", table: "ViewModels"),
        L("quality_good", table: "ViewModels"),
        L("quality_excellent", table: "ViewModels")
    ]
    
    // MARK: - Private Properties
    private let watchConnectivity = WatchConnectivityManager.shared
    private var sharedRepository: SharedRepository?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var lastSleepEntry: SharedSleepEntry? {
        return recentEntries.first
    }
    
    var currentQualityDescription: String {
        let index = max(0, min(selectedQuality - 1, qualityDescriptions.count - 1))
        return qualityDescriptions[index]
    }
    
    var currentQualityEmoji: String {
        let index = max(0, min(selectedQuality - 1, qualityEmojis.count - 1))
        return qualityEmojis[index]
    }
    
    // MARK: - Initialization
    init() {
        self.sharedRepository = SharedRepository.shared
        setupConnectivityObservers()
        loadInitialData()
        setupQualityObserver()
    }
    
    // MARK: - Configuration
    func configureRepository(_ repository: SharedRepository) {
        self.sharedRepository = repository
        loadRecentEntries()
    }
    
    // MARK: - Public Methods
    
    func saveSleepEntry(quality: Int, emoji: String) {
        guard !isSaving else { return }
        
        isSaving = true
        
        let entry = SharedSleepEntry(
            date: Date(),
            startTime: Date().addingTimeInterval(-30*60), // Default 30 minutes ago
            endTime: Date(),
            durationMinutes: 30,
            isCore: false, // Manual entries are typically naps
            emoji: emoji,
            rating: quality
        )
        
        Task {
            await saveEntryToStorage(entry)
        }
    }
    
    func quickSave(quality: Int) {
        let emoji = qualityEmojis[max(0, min(quality - 1, qualityEmojis.count - 1))]
        saveSleepEntry(quality: quality, emoji: emoji)
    }
    
    func updateQuality(_ quality: Int) {
        selectedQuality = quality
        selectedEmoji = currentQualityEmoji
    }
    
    func requestDataSync() {
        isLoading = true
        loadRecentEntries()
        
        // Request sync from iPhone
        let syncMessage = WatchMessage(
            type: .syncRequest,
            data: ["source": "sleepEntry"]
        )
        watchConnectivity.sendMessage(syncMessage)
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
    
    private func setupQualityObserver() {
        // Update emoji when quality changes
        $selectedQuality
            .sink { [weak self] quality in
                self?.selectedEmoji = self?.currentQualityEmoji ?? "😴"
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        loadRecentEntries()
        loadMockData()
    }
    
    private func loadRecentEntries() {
        // Load recent entries from repository
        // For now, create mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isLoading = false
        }
    }
    
    private func loadMockData() {
        // Create some mock recent entries for testing
        let mockEntries: [SharedSleepEntry] = [
            SharedSleepEntry(
                date: Date().addingTimeInterval(-3600),
                startTime: Date().addingTimeInterval(-3900),
                endTime: Date().addingTimeInterval(-3600),
                durationMinutes: 20,
                isCore: false,
                emoji: "😊",
                rating: 4
            ),
            SharedSleepEntry(
                date: Date().addingTimeInterval(-7200),
                startTime: Date().addingTimeInterval(-7500),
                endTime: Date().addingTimeInterval(-7200),
                durationMinutes: 25,
                isCore: false,
                emoji: "😐",
                rating: 3
            )
        ]
        
        recentEntries = mockEntries
        print("📝 Sleep entry mock data loaded - \(mockEntries.count) entries")
    }
    
    private func saveEntryToStorage(_ entry: SharedSleepEntry) async {
        do {
            // Try to save to SharedRepository if available
            if let repository = sharedRepository,
               repository.getModelContext() != nil {
                
                // Create a user if doesn't exist
                let user = try await repository.createOrGetUser(
                    id: UUID(),
                    isAnonymous: true
                )
                
                // Save to SharedRepository
                let savedEntry = try await repository.createSleepEntry(
                    user: user,
                    date: entry.date,
                    startTime: entry.startTime,
                    endTime: entry.endTime,
                    durationMinutes: entry.durationMinutes,
                    isCore: entry.isCore,
                    blockId: entry.blockId,
                    emoji: entry.emoji,
                    rating: entry.rating,
                    syncId: entry.syncId
                )
                
                print("✅ Watch: Sleep entry saved to SharedRepository: \(savedEntry.rating) stars")
                
                // Update local recent entries
                await MainActor.run {
                    recentEntries.insert(savedEntry, at: 0)
                    if recentEntries.count > 10 {
                        recentEntries.removeLast()
                    }
                }
            } else {
                print("⚠️ Watch: SharedRepository not available, saving locally only")
                // Add to recent entries for local display
                await MainActor.run {
                    recentEntries.insert(entry, at: 0)
                    if recentEntries.count > 10 {
                        recentEntries.removeLast()
                    }
                }
            }
            
            // Update UI
            await MainActor.run {
                self.isSaving = false
                self.lastSaveDate = Date()
                self.saveMessage = L("sleep_entry_saved", table: "ViewModels")
                self.showSaveConfirmation = true
            }
            
            // Send to iPhone via WatchConnectivity
            watchConnectivity.notifySleepEntryAdded(entry.dictionary)
            
            // Hide confirmation after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.showSaveConfirmation = false
            }
            
            print("💾 Watch: Sleep entry processed successfully: \(entry.rating) stars")
            
        } catch {
            await MainActor.run {
                self.isSaving = false
                self.saveMessage = L("save_error", table: "ViewModels")
                self.showSaveConfirmation = true
            }
            
            print("❌ Sleep entry save failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - WatchMessage Extension
extension WatchConnectivityManager {
    func sendMessage(_ message: WatchMessage) {
        // Implementation will be added in WatchConnectivityManager
        print("📤 Sending watch message: \(message.type.rawValue)")
    }
} 