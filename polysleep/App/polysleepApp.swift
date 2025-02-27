//
//  polysleepApp.swift
//  polysleep
//
//  Created by Taner Çelik on 27.12.2024.
//

import SwiftUI
import FirebaseCore
import SwiftData

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    
    // Initialize notification manager
    let notificationManager = SleepQualityNotificationManager.shared
    notificationManager.requestAuthorization()

    return true
  }
}

@main
struct polysleepApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    let modelContainer: ModelContainer
    
    init() {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(
                for: SleepScheduleStore.self,
                UserPreferences.self,
                UserFactor.self,
                HistoryModel.self,
                SleepEntry.self,
                configurations: config
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, .current)
        }
        .modelContainer(modelContainer)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userPreferences: [UserPreferences]
    @Query private var sleepSchedules: [SleepScheduleStore]
    
    var body: some View {
        Group {
            if let preferences = userPreferences.first {
                if preferences.hasCompletedOnboarding {
                    MainTabBarView()
                } else {
                    WelcomeView()
                }
            } else {
                // Only create UserPreferences once when app first launches
                WelcomeView()
                    .onAppear {
                        let newPreferences = UserPreferences()
                        modelContext.insert(newPreferences)
                        try? modelContext.save()
                    }
            }
        }
    }
}
