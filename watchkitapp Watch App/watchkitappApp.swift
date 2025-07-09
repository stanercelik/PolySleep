//
//  watchkitappApp.swift
//  watchkitapp Watch App
//
//  Created by Taner Çelik on 5.07.2025.
//

import SwiftUI
import WatchKit
import PolyNapShared

@main
struct PolyNap_Watch_AppApp: App {
    
    // MARK: - Scene Configuration
    var body: some Scene {
        WindowGroup {
            MainWatchView()
                .onAppear {
                    // App aktif olduğunda sync isteği
                    WatchConnectivityManager.shared.requestSync()
                }
        }
        .backgroundTask(.appRefresh("refresh-data")) {
            // Background refresh task
            await handleBackgroundRefresh()
        }
    }
    
    // MARK: - App Lifecycle
    
    init() {
        // App did finish launching
        print("🌙 PolyNap Watch App launched")
        
        // WatchConnectivity'yi başlat
        _ = WatchConnectivityManager.shared
        
        // İlk veri senkronizasyonu
        requestInitialDataSync()
        
        // Background refresh schedule et
        scheduleBackgroundRefresh()
    }
    
    // MARK: - Background Processing
    
    private func scheduleBackgroundRefresh() {
        // Modern watchOS background refresh approach
        Task.detached {
            let refreshDate = Date().addingTimeInterval(30 * 60) // 30 dakika sonra
            print("✅ Background refresh scheduled for: \(refreshDate)")
            
            // Periyodik sync scheduling
            DispatchQueue.main.asyncAfter(deadline: .now() + 1800) { // 30 dakika
                WatchConnectivityManager.shared.requestSync()
            }
        }
    }
    
    // MARK: - Background Tasks
    
    private func handleBackgroundRefresh() async {
        print("🔄 Background refresh started")
        
        // Sync request (not async)
        WatchConnectivityManager.shared.requestSync()
        
        print("✅ Background refresh completed")
    }
    
    // MARK: - Data Sync
    
    private func requestInitialDataSync() {
        WatchConnectivityManager.shared.requestSync()
    }
}
