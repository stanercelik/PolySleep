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
                    Text(L("watch.tab.schedule", table: "Watch"))
                }
                .tag(0)
            
            // Sayfa 2: Adaptation Progress (Adaptasyon İlerlemesi)  
            AdaptationProgressView(viewModel: adaptationViewModel)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text(L("watch.tab.adaptation", table: "Watch"))
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
                    Text(L("watch.tab.entry", table: "Watch"))
                }
                .tag(2)
        }
        .onAppear {
            // Environment'dan gelen modelContext'i ViewModel'e ayarla
            if SharedRepository.shared.getModelContext() == nil {
                print("⚠️ SharedRepository'de ModelContext bulunamadı, Environment'dan ayarlanıyor")
                SharedRepository.shared.setModelContext(modelContext)
            }
            
            // ViewModels'i configure et
            mainViewModel.configureSharedRepository(with: modelContext)
            sleepEntryViewModel.configureRepository(SharedRepository.shared)
            adaptationViewModel.configureRepository(SharedRepository.shared)
            
            // İlk data sync
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
