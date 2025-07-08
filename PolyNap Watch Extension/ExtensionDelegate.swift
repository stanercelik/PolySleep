import WatchKit
import SwiftUI
import PolyNapShared

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    func applicationDidFinishLaunching() {
        print("🌙 PolyNap Watch Extension launched")
        
        // WatchConnectivity'yi başlat
        WatchConnectivityManager.shared.requestSync()
        
        // Background refresh schedule et
        scheduleBackgroundRefresh()
    }
    
    func applicationDidBecomeActive() {
        print("👁️ PolyNap Watch Extension became active")
        
        // Aktif olduğunda sync isteği gönder
        WatchConnectivityManager.shared.requestSync()
    }
    
    func applicationWillResignActive() {
        print("🌙 PolyNap Watch Extension will resign active")
    }
    
    // MARK: - Background Tasks
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let refreshTask as WKApplicationRefreshBackgroundTask:
                handleBackgroundRefresh(refreshTask)
                
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                handleConnectivityRefresh(connectivityTask)
                
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                handleURLSessionRefresh(urlSessionTask)
                
            default:
                // Unknown task type
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    private func handleBackgroundRefresh(_ task: WKApplicationRefreshBackgroundTask) {
        print("🔄 Background refresh started")
        
        // Uyku verilerini senkronize et
        syncSleepData { success in
            task.setTaskCompletedWithSnapshot(success)
            
            // Bir sonraki background refresh'i schedule et
            self.scheduleBackgroundRefresh()
        }
    }
    
    private func handleConnectivityRefresh(_ task: WKWatchConnectivityRefreshBackgroundTask) {
        print("📶 Connectivity refresh started")
        
        // WatchConnectivity üzerinden veri al
        WatchConnectivityManager.shared.requestSync()
        
        task.setTaskCompletedWithSnapshot(true)
    }
    
    private func handleURLSessionRefresh(_ task: WKURLSessionRefreshBackgroundTask) {
        print("🌐 URL session refresh started")
        
        // URL session işlemlerini handle et
        task.setTaskCompletedWithSnapshot(false)
    }
    
    // MARK: - Background Refresh Scheduling
    
    private func scheduleBackgroundRefresh() {
        // 30 dakika sonra background refresh schedule et
        let refreshDate = Date().addingTimeInterval(30 * 60)
        
        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: refreshDate,
            userInfo: nil
        ) { error in
            if let error = error {
                print("❌ Background refresh scheduling failed: \(error.localizedDescription)")
            } else {
                print("✅ Background refresh scheduled for: \(refreshDate)")
            }
        }
    }
    
    // MARK: - Data Sync
    
    private func syncSleepData(completion: @escaping (Bool) -> Void) {
        // Uyku verilerini senkronize et
        // Bu method gerçek implementasyonda SharedRepository üzerinden çalışacak
        
        DispatchQueue.global(qos: .background).async {
            // Simulated sync operation
            Thread.sleep(forTimeInterval: 2.0)
            
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
}

// MARK: - WKExtensionDelegate Factory

extension ExtensionDelegate {
    static func create() -> ExtensionDelegate {
        return ExtensionDelegate()
    }
} 