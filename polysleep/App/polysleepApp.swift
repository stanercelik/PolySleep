//
//  polysleepApp.swift
//  polysleep
//
//  Created by Taner Çelik on 27.12.2024.
//

import SwiftUI
import SwiftData
import Combine
import Network

// Offline-first model ve servislerimizi import ediyoruz
// Eğer bunlar farklı modüllerde olsaydı, modül adlarını belirtmemiz gerekirdi
// Ancak aynı modül içinde olduğu için direkt dosya adlarını belirtebiliriz

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // Initialize notification manager
    let notificationManager = SleepQualityNotificationManager.shared
    notificationManager.requestAuthorization()
    
    // Uygulama ilk kez açıldığında onboarding durumunu ve aktif programı sıfırla
    if !UserDefaults.standard.bool(forKey: "AppFirstLaunch") {
        print("Uygulama ilk kez başlatılıyor, varsayılan değerler ayarlanıyor...")
        
        // İlk açılış işaretini ayarla
        UserDefaults.standard.set(true, forKey: "AppFirstLaunch")
        
        // Onboarding durumunu sıfırla
        UserDefaults.standard.set(false, forKey: "onboardingCompleted")
    }

    return true
  }
  
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    // URL şemasını işle
    if url.scheme == "polysleep" {
        print("URL şeması işleniyor: \(url)")
        // Burada spesifik URL tabanlı eylemleriniz varsa işleyebilirsiniz.
        // Artık Apple Sign In ile ilgili bir kontrol yok.
    }
    // Diğer URL işleyicileriniz varsa ve işlendiğini belirtmek istiyorsanız true döndürün.
    return false
  }
}

@main
struct polysleepApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("userSelectedTheme") private var userSelectedTheme: Bool?
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var scheduleManager = ScheduleManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    
    // Sınıf düzeyinde @Query tanımlıyoruz, böylece yerel alan içinde kullanmamış oluruz
    @Query var preferences: [UserPreferences]
    
    let modelContainer: ModelContainer
    
    init() {
        do {
            // SwiftData schema'sını yapılandırıyoruz
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(
                for: 
                // Mevcut modeller
                SleepScheduleStore.self,
                UserPreferences.self,
                UserFactor.self,
                HistoryModel.self,
                SleepEntry.self,
                OnboardingAnswerData.self,
                User.self,
                UserSchedule.self,
                UserSleepBlock.self,
                
                // Offline-first modeller
                ScheduleEntity.self,
                SleepBlockEntity.self,
                SleepEntryEntity.self,
                PendingChange.self,
                
                configurations: config
            )
            
            // Repository ve SyncEngine'e ModelContext'i ayarla
            let context = modelContainer.mainContext
            Repository.shared.setModelContext(context)
            
            print("SwiftData başarıyla yapılandırıldı")
            
            // Migration işlemini başlat
            Task {
                do {
                    try await Repository.shared.migrateScheduleEntitiesToUserSchedules()
                    print("✅ Migration başarıyla tamamlandı")
                } catch {
                    print("❌ Migration hatası: \(error)")
                }
            }
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    /// Uygulama verilerini sıfırlar (test ve geliştirme amaçlı)
    func resetAppData() {
        // UserDefaults'ı temizle
        UserDefaults.standard.set(false, forKey: "AppFirstLaunch")
        UserDefaults.standard.set(false, forKey: "onboardingCompleted")
        UserDefaults.standard.removeObject(forKey: "userSelectedTheme")
        
        // Kullanıcı ve program verilerini sıfırla
        Task {
            do {
                // UserPreferences sıfırla - sınıf düzeyindeki @Query kullanılıyor
                if let firstPref = preferences.first {
                    firstPref.resetPreferences()
                }
                
                print("✅ Uygulama verileri başarıyla sıfırlandı")
            } catch {
                print("❌ Uygulama verileri sıfırlanırken hata: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: languageManager.currentLanguage))
                .environmentObject(authManager)
                .environmentObject(scheduleManager)
                .environmentObject(languageManager)
                .withLanguageEnvironment()
                .onAppear {
                    LocalNotificationService.shared.requestAuthorization { granted, error in
                        if granted {
                            print("AppDelegate: Bildirim izni uygulama başlangıcında alındı.")
                        } else {
                            print("AppDelegate: Bildirim izni verilmedi veya hata oluştu.")
                            if let error = error {
                                print("Hata: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                .onOpenURL { url in
                    // URL şemasını işle
                    if url.scheme == "polysleep" {
                        print("Uygulama URL ile açıldı: \(url)")
                        
                        // Apple Sign In URL'leri ile ilgili kısım kaldırıldı
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var systemColorScheme
    @AppStorage("userSelectedTheme") private var userSelectedTheme: Bool?
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
        .preferredColorScheme(getPreferredColorScheme())
        .onAppear {
            // İlk açılışta kullanıcı tema tercihi yoksa sistem temasını ayarla
            if userSelectedTheme == nil {
                print("İlk açılış: Sistem teması kullanılıyor - \(systemColorScheme == .dark ? "Koyu" : "Açık")")
            }
        }
    }
    
    /// Kullanıcının tema tercihine göre color scheme döndürür
    private func getPreferredColorScheme() -> ColorScheme? {
        // Eğer kullanıcı tema seçimi yapmışsa, onu kullan
        if let userChoice = userSelectedTheme {
            return userChoice ? .dark : .light
        }
        // Aksi halde sistem temasını kullan (nil dönerek)
        return nil
    }
}
