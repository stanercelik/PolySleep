import Foundation
import SwiftUI
import PolyNapShared
import Combine

// MARK: - Sync Status
public enum SyncStatus: Equatable {
    case idle
    case syncing
    case success(Date)
    case failed(String)
    case offline
    
    var color: Color {
        switch self {
        case .idle: return .gray
        case .syncing: return .blue
        case .success: return .green
        case .failed: return .red
        case .offline: return .orange
        }
    }
    
    var message: String {
        switch self {
        case .idle: return "Bekleniyor"
        case .syncing: return "Senkronize ediliyor"
        case .success(let date): return "Senkronize edildi \(date.formatted(date: .omitted, time: .shortened))"
        case .failed(let error): return "Hata: \(error)"
        case .offline: return "Çevrimdışı"
        }
    }
}

// MARK: - Sync Service
@MainActor
class SyncService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncTime: Date?
    @Published var hasPendingSync: Bool = false
    @Published var offlineEntries: [SharedSleepEntry] = []
    @Published var isConnected: Bool = false
    @Published var latestAdaptationData: [String: Any]? = nil
    
    // MARK: - Private Properties
    private let watchConnectivity = WatchConnectivityManager.shared
    private let sharedRepository = SharedRepository.shared
    private var cancellables = Set<AnyCancellable>()
    private var syncRetryCount = 0
    private let maxRetryAttempts = 3
    
    // MARK: - Initialization
    init() {
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    /// Data senkronizasyonu başlatır
    func requestDataSync() {
        guard !isCurrentlySyncing else {
            print("⏳ Sync already in progress")
            return
        }
        
        syncStatus = .syncing
        syncRetryCount = 0
        
        // iPhone'a sync request gönder
        watchConnectivity.requestSync()
        
        // Timeout için delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            self?.handleSyncTimeout()
        }
    }
    
    /// Offline entry'leri sync eder
    func syncOfflineEntries() {
        guard !offlineEntries.isEmpty else { return }
        
        print("📤 Syncing \(offlineEntries.count) offline entries")
        
        for entry in offlineEntries {
            let message = WatchMessage(
                type: .sleepEnded,
                data: entry.dictionary
            )
            watchConnectivity.sendMessage(message)
        }
        
        // Clear offline entries after successful sync
        offlineEntries.removeAll()
        hasPendingSync = false
    }
    
    /// Offline entry ekler
    func addOfflineEntry(_ entry: SharedSleepEntry) {
        offlineEntries.append(entry)
        hasPendingSync = true
        
        print("💾 Added offline entry: \(entry.id)")
        
        // Eğer bağlantı varsa hemen sync et
        if isConnected {
            syncOfflineEntries()
        }
    }
    
    /// Sync başarısını işler
    func handleSyncSuccess(with data: [String: Any]?) {
        syncStatus = .success(Date())
        lastSyncTime = Date()
        syncRetryCount = 0
        
        // Adaptasyon verisini işle
        if let syncData = data,
           let adaptationData = syncData["adaptationData"] as? [String: Any] {
            self.latestAdaptationData = adaptationData
            print("📊 Adaptasyon verisi güncellendi: \(adaptationData)")
            
            // Adaptasyon verisi güncellemesi notification'ı gönder
            NotificationCenter.default.post(
                name: .adaptationDataDidUpdate,
                object: nil,
                userInfo: ["adaptationData": adaptationData]
            )
        }
        
        // Offline entries'i sync et
        if hasPendingSync {
            syncOfflineEntries()
        }
        
        print("✅ Sync completed successfully")
    }
    
    /// Sync hatasını işler
    func handleSyncFailure(with error: String) {
        syncRetryCount += 1
        
        if syncRetryCount < maxRetryAttempts {
            print("⚠️ Sync failed, retrying (\(syncRetryCount)/\(maxRetryAttempts))")
            
            // Exponential backoff ile retry
            let delay = Double(syncRetryCount * 2)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.requestDataSync()
            }
        } else {
            syncStatus = .failed(error)
            print("❌ Sync failed after \(maxRetryAttempts) attempts: \(error)")
        }
    }
    
    /// Bağlantı durumunu günceller
    func updateConnectionStatus(_ isConnected: Bool) {
        self.isConnected = isConnected
        
        if isConnected {
            syncStatus = .idle
            
            // Bağlantı kurulduğunda pending sync'leri gönder
            if hasPendingSync {
                syncOfflineEntries()
            }
        } else {
            syncStatus = .offline
        }
    }
    
    /// Sync durumunu sıfırlar
    func resetSyncStatus() {
        syncStatus = .idle
        syncRetryCount = 0
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Watch connectivity durumunu observe et
        watchConnectivity.$isReachable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isReachable in
                self?.updateConnectionStatus(isReachable)
            }
            .store(in: &cancellables)
        
        // Uygulama foreground'a geldiğinde sync et
        NotificationCenter.default.publisher(for: .NSExtensionHostDidBecomeActive)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.requestDataSync()
            }
            .store(in: &cancellables)
    }
    
    private var isCurrentlySyncing: Bool {
        if case .syncing = syncStatus {
            return true
        }
        return false
    }
    
    private func handleSyncTimeout() {
        guard isCurrentlySyncing else { return }
        
        handleSyncFailure(with: "Zaman aşımı")
    }
}

// MARK: - Extensions
extension SyncService {
    
    /// Sync durumu için renk döndürür
    var syncStatusColor: Color {
        syncStatus.color
    }
    
    /// Sync durumu için mesaj döndürür
    var syncStatusMessage: String {
        syncStatus.message
    }
    
    /// Sync'in aktif olup olmadığını döndürür
    var isSyncing: Bool {
        isCurrentlySyncing
    }
}

// MARK: - Notification Names Extension
extension Notification.Name {
    static let adaptationDataDidUpdate = Notification.Name("AdaptationDataDidUpdate")
} 