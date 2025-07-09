//
//  watchkitappApp.swift
//  watchkitapp Watch App
//
//  Created by Taner Çelik on 5.07.2025.
//

import SwiftUI
import WatchKit
import PolyNapShared
import SwiftData

@main
struct PolyNap_Watch_AppApp: App {
    
    // SwiftData Model Container
    private var sharedModelContainer: ModelContainer
    
    // MARK: - Scene Configuration
    var body: some Scene {
        WindowGroup {
            MainWatchView()
                .modelContainer(sharedModelContainer)
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
        
        // SwiftData Container'ı initialize et
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            sharedModelContainer = try ModelContainer(
                for: SharedUser.self, SharedUserSchedule.self, SharedSleepBlock.self, SharedSleepEntry.self,
                configurations: config
            )
            
            // SharedRepository'ye ModelContext'i hemen ayarla
            SharedRepository.shared.setModelContext(sharedModelContainer.mainContext)
            print("✅ SwiftData ModelContainer başarıyla initialize edildi")
            
        } catch {
            print("❌ SwiftData ModelContainer initialize hatası: \(error.localizedDescription)")
            
            // Fallback: In-memory container oluştur
            do {
                let memoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                sharedModelContainer = try ModelContainer(
                    for: SharedUser.self, SharedUserSchedule.self, SharedSleepBlock.self, SharedSleepEntry.self,
                    configurations: memoryConfig
                )
                SharedRepository.shared.setModelContext(sharedModelContainer.mainContext)
                print("⚠️ Fallback: In-memory ModelContainer kullanılıyor")
            } catch {
                print("💥 Fallback ModelContainer bile oluşturulamadı: \(error.localizedDescription)")
                // Bu durumda app crash olacak, fakat debug için daha iyi mesaj verir
                fatalError("SwiftData ModelContainer oluşturulamadı: \(error)")
            }
        }
        
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
