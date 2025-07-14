import SwiftUI
import WatchKit
import PolyNapShared
import SwiftData

struct MainWatchView: View {
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    @StateObject private var mainViewModel = WatchMainViewModel()
    @StateObject private var adaptationViewModel = AdaptationViewModel()
    @StateObject private var sleepEntryViewModel = SleepEntryViewModel()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView {
            // Sayfa 1: Current Schedule (Ana Program)
            CurrentScheduleView(viewModel: mainViewModel)
                .tabItem {
                    Image(systemName: "moon.fill")
                    Text(L("watch.tab.schedule", tableName: "Watch"))
                }
                .tag(0)
            
            // Sayfa 2: Adaptation Progress (Adaptasyon İlerlemesi)  
            AdaptationProgressView(viewModel: adaptationViewModel)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text(L("watch.tab.adaptation", tableName: "Watch"))
                }
                .tag(1)
            
            // Sayfa 3: Quick Sleep Entry (Hızlı Uyku Girişi)
            QuickSleepEntryView(
                viewModel: sleepEntryViewModel,
                sleepTrackingService: mainViewModel.sleepTracking,
                statisticsService: mainViewModel.statistics
            )
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text(L("watch.tab.entry", tableName: "Watch"))
                }
                .tag(2)
        }
        .onAppear {
            Task { @MainActor in
                await setupWatchApp()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSExtensionHostDidBecomeActive)) { _ in
            // Uygulama aktif olduğunda sync et
            mainViewModel.requestDataSync()
        }
        .onReceive(mainViewModel.sync.$syncStatus) { syncStatus in
            // Sync durumunda değişiklikleri handle et
            handleSyncStatusChange(syncStatus)
        }
    }
    
    // MARK: - Private Methods
    
    /// Watch app'i sequential olarak setup eder
    @MainActor
    private func setupWatchApp() async {
        print("🚀 Watch: App setup başlatılıyor...")
        
        // 1. ModelContext'i setup et
        await setupModelContext()
        
        // 2. ViewModels'i configure et
        await configureViewModels()
        
        // 3. WatchConnectivity'yi başlat
        await setupWatchConnectivity()
        
        // 4. İlk data sync'i başlat
        await performInitialSync()
        
        print("✅ Watch: App setup tamamlandı")
    }
    
    /// ModelContext'i setup eder
    @MainActor
    private func setupModelContext() async {
        print("🔧 Watch: ModelContext setup ediliyor...")
        
        // SharedRepository'nin ModelContext'ini kontrol et
        if SharedRepository.shared.getModelContext() == nil {
            print("⚙️ Watch: SharedRepository'de ModelContext bulunamadı, Environment'dan ayarlanıyor")
            SharedRepository.shared.setModelContext(modelContext)
            
            // ModelContext'in doğru ayarlandığını doğrula
            if SharedRepository.shared.getModelContext() != nil {
                print("✅ Watch: ModelContext başarıyla ayarlandı")
            } else {
                print("❌ Watch: ModelContext ayarlanamadı!")
            }
        } else {
            print("✅ Watch: ModelContext zaten mevcut")
        }
        
        // Kısa bir delay ModelContext'in tamamen hazır olması için
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 saniye
    }
    
    /// ViewModels'i configure eder
    @MainActor
    private func configureViewModels() async {
        print("📱 Watch: ViewModels configure ediliyor...")
        
        // MainViewModel'i configure et
        mainViewModel.configureSharedRepository(with: modelContext)
        
        // SleepEntryViewModel'i configure et
        sleepEntryViewModel.configureRepository(SharedRepository.shared)
        
        // AdaptationViewModel'i configure et
        adaptationViewModel.configureRepository(SharedRepository.shared)
        
        print("✅ Watch: ViewModels configure edildi")
        
        // ViewModels'in hazır olması için kısa bir delay
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 saniye
    }
    
    /// WatchConnectivity'yi setup eder
    @MainActor
    private func setupWatchConnectivity() async {
        print("🔗 Watch: WatchConnectivity setup ediliyor...")
        
        // WatchConnectivityManager zaten singleton olarak başlatıldı
        // Health check yap
        let isHealthy = watchConnectivity.performHealthCheck()
        
        if isHealthy {
            print("✅ Watch: WatchConnectivity healthy")
        } else {
            print("⚠️ Watch: WatchConnectivity health check failed, retry yapılacak")
        }
        
        // Connectivity'nin stabilize olması için kısa bir delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 saniye
    }
    
    /// İlk data sync'i yapar
    @MainActor
    private func performInitialSync() async {
        print("🔄 Watch: İlk data sync başlatılıyor...")
        
        // İlk sync'i request et
        mainViewModel.requestDataSync()
        
        // Sync'in başlaması için kısa bir delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 saniye
        
        print("📤 Watch: İlk sync request gönderildi")
    }
    
    /// Sync durumu değişikliklerini handle eder
    private func handleSyncStatusChange(_ syncStatus: SyncStatus) {
        switch syncStatus {
        case .success:
            print("✅ Sync successful - updating UI")
            // UI'yi güncelle
            
        case .failed(let error):
            print("❌ Sync failed: \(error)")
            // Hata durumunda haptic feedback
            WKInterfaceDevice.current().play(.failure)
            
        case .offline:
            print("📱 Device offline - using cached data")
            
        case .syncing:
            print("🔄 Syncing data...")
            
        case .idle:
            break
        }
    }
}

#Preview {
    MainWatchView()
} 
