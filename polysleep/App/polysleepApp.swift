//
//  polysleepApp.swift
//  polysleep
//
//  Created by Taner Çelik on 27.12.2024.
//

import SwiftUI
import SwiftData
import Supabase

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // Initialize notification manager
    let notificationManager = SleepQualityNotificationManager.shared
    notificationManager.requestAuthorization()

    return true
  }
  
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    // URL şemasını işle
    if url.scheme == "polysleep" {
        // Supabase auth callback'i işle
        Task {
            do {
                try await SupabaseService.shared.client.auth.session(from: url)
                return true
            } catch {
                print("Supabase auth callback error: \(error)")
                return false
            }
        }
    }
    return false
  }
}

@main
struct polysleepApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("isDarkMode") private var isDarkMode = true
    @StateObject private var authManager = AuthManager.shared
    
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
                OnboardingAnswer.self,
                configurations: config
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
        
        // Supabase servisini başlat
        _ = SupabaseService.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, .current)
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .task {
                    do {
                        // Anonim giriş yap, SupabaseService.signInAnonymously 
                        // metodu UserDefaults kontrolü yaptığı için 
                        // her seferinde yeni kullanıcı oluşturmayacak
                        try await AuthManager.shared.signInAnonymously()
                    } catch {
                        print(LocalizedStringKey("error.anonymous_signin"), error.localizedDescription)
                    }
                }
                .onOpenURL { url in
                    // URL şemasını işle
                    if url.scheme == "polysleep" {
                        // Supabase auth callback'i işle
                        Task {
                            do {
                                try await SupabaseService.shared.client.auth.session(from: url)
                            } catch {
                                print("Supabase auth callback error: \(error)")
                            }
                        }
                    }
                }
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
