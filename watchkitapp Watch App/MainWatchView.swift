import SwiftUI
import WatchKit
import PolyNapShared
import SwiftData

struct MainWatchView: View {
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    @StateObject private var mainViewModel = WatchMainViewModel()
    @StateObject private var adaptationViewModel = AdaptationViewModel()
    @StateObject private var sleepEntryViewModel = SleepEntryViewModel()
    
    var body: some View {
        TabView {
            // Sayfa 1: Current Schedule (Ana Program)
            CurrentScheduleView(viewModel: mainViewModel)
                .tabItem {
                    Image(systemName: "moon.fill")
                    Text("Program")
                }
                .tag(0)
            
            // Sayfa 2: Adaptation Progress (Adaptasyon İlerlemesi)  
            AdaptationProgressView(viewModel: adaptationViewModel)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Adaptasyon")
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
                    Text("Giriş")
                }
                .tag(2)
        }
        .onAppear {
            configureSharedRepository()
            mainViewModel.requestDataSync()
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
    
    /// SharedRepository'yi Apple Watch için konfigüre eder
    private func configureSharedRepository() {
        do {
            // SharedModels için ModelContainer oluştur
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            let container = try ModelContainer(
                for: SharedUser.self, SharedUserSchedule.self, SharedSleepBlock.self, SharedSleepEntry.self,
                configurations: config
            )
            
            let modelContext = container.mainContext
            
            // SharedRepository'ye ModelContext ayarla
            SharedRepository.shared.setModelContext(modelContext)
            
            // ViewModels'e SharedRepository'nin hazır olduğunu bildir
            mainViewModel.configureSharedRepository(with: modelContext)
            
            print("✅ Apple Watch: SharedRepository başarıyla konfigüre edildi")
        } catch {
            print("❌ Apple Watch: SharedRepository konfigürasyon hatası - \(error.localizedDescription)")
            
            // Hata durumunda fallback data yükle
            mainViewModel.loadMockData()
        }
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
