import SwiftUI
import SwiftData
import Combine
import Network
import UserNotifications
import RevenueCat

// Uygulama içi iletişim için özel bildirim adları
extension Notification.Name {
    static let startAlarm = Notification.Name("startAlarmNotification")
    static let stopAlarm = Notification.Name("stopAlarmNotification")
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    // Gerekirse servislere iletmek için model konteynerini sakla
    var modelContainer: ModelContainer?
    
    // AlarmManager referansı ekle
    var alarmManager: AlarmManager?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Bu sınıfı kullanıcı bildirimleri için delege olarak ayarla
        UNUserNotificationCenter.current().delegate = self
        
        // Uygulama açılışında uygulama simgesi sayacını temizle
        application.applicationIconBadgeNumber = 0
        
        // AlarmService singleton'ını başlatarak izinlerin erken istenmesini sağla
        _ = AlarmService.shared
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("🔄 AppDelegate: applicationDidBecomeActive çağrıldı")
        // Uygulama her aktif olduğunda sayacı temizle
        application.applicationIconBadgeNumber = 0
        
        // DEĞİŞİKLİK: Pending alarm kontrolü kaldırıldı. Bu görev artık ContentView'e ait.
        // Background'dan foreground'a geçişte pending alarm kontrolü artık ContentView'da yapılacak.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("🔄 AppDelegate: applicationWillEnterForeground çağrıldı")
        // DEĞİŞİKLİK: Pending alarm kontrolü kaldırıldı. Bu görev artık ContentView'e ait.
        // Bu da background'dan foreground'a geçişi yakalar ama kontrolü ContentView yapacak.
    }
    
    // DEĞİŞİKLİK: checkAndTriggerPendingBackgroundAlarm metodu tamamen kaldırıldı.
    // Bu sorumluluk artık ContentView'in onAppear metodunda checkForPendingAlarm() ile yapılacak.

    // MARK: - UNUserNotificationCenterDelegate
    
    /// Bildirim ön plandaki bir uygulamaya ulaştığında çağrılır.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let content = notification.request.content
        
        // --- SENARYO 3: Uygulama ön planda ---
        if content.categoryIdentifier == AlarmService.alarmCategoryIdentifier {
            print("📱 AppDelegate (Ön Plan): Alarm bildirimi alındı.")
            
            // 1. Sistem banner/sesinin gösterilmesini engelle
            completionHandler([])
            
            // 2. Uygulama içi AlarmFiringView'ı tetiklemek için dahili bir bildirim gönder
            NotificationCenter.default.post(name: .startAlarm, object: notification, userInfo: content.userInfo)
            
            return
        }
        
        // Diğer tüm bildirim türleri için varsayılan sistem arayüzünü göster
        completionHandler([.banner, .sound, .badge])
    }

    /// Kullanıcı bir bildirime yanıt verdiğinde (dokunma veya eylemlerden birini seçme) çağrılır.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("🔔 AppDelegate: didReceive response çağrıldı!")
        print("📋 AppDelegate: Response actionIdentifier: \(response.actionIdentifier)")
        print("📋 AppDelegate: Notification identifier: \(response.notification.request.identifier)")
        
        let content = response.notification.request.content
        print("📋 AppDelegate: Content categoryIdentifier: \(content.categoryIdentifier)")
        print("📋 AppDelegate: Expected categoryIdentifier: \(AlarmService.alarmCategoryIdentifier)")
        print("📋 AppDelegate: Content userInfo: \(content.userInfo)")
        print("📋 AppDelegate: Content title: \(content.title)")
        print("📋 AppDelegate: Content body: \(content.body)")
        
        // Sadece kendi alarm bildirimlerimizi işle
        guard content.categoryIdentifier == AlarmService.alarmCategoryIdentifier else {
            print("⚠️ AppDelegate: Kategori uyuşmuyor, işlem yapılmıyor")
            completionHandler()
            return
        }
        
        print("✅ AppDelegate: Alarm bildirimi doğrulandı, işleme başlanıyor...")
        
        // --- SENARYO 1 & 2: Uygulama arka planda veya sonlandırılmış ---
        switch response.actionIdentifier {
            
        case "SNOOZE_ACTION":
            print("▶️ EYLEM: Kullanıcı alarmı ERTELEMEYİ seçti.")
            Task {
                await AlarmService.shared.snoozeAlarm(from: response.notification)
            }
            
        case "STOP_ACTION":
            print("🛑 EYLEM: Kullanıcı alarmı DURDURMAYI seçti.")
            // Alarm sesi otomatik olarak durur.
            NotificationCenter.default.post(name: .stopAlarm, object: nil)

        case UNNotificationDefaultActionIdentifier:
            // Bu durum, kullanıcı bildirim gövdesine dokunduğunda tetiklenir.
            print("▶️ EYLEM: Kullanıcı bildirime dokundu.")
            
            // --- EN ÖNEMLİ DEĞİŞİKLİK ---
            // Sadece durumu UserDefaults'a kaydet. Başka bir şey yapma.
            // UI katmanı (ContentView) hazır olduğunda bu bayrağı kontrol edecek.
            UserDefaults.standard.set(true, forKey: "pendingBackgroundAlarm")
            UserDefaults.standard.set(content.userInfo, forKey: "pendingAlarmInfo")
            
            print("📝 AppDelegate: Background alarm tetikleme isteği UserDefaults'a kaydedildi. UI'ın kontrol etmesi beklenecek.")
            
        default:
            print("▶️ EYLEM: Bilinmeyen eylem tanımlayıcısı: \(response.actionIdentifier)")
        }
        
        completionHandler()
    }
}


@main
struct polynapApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("userSelectedTheme") private var userSelectedTheme: Bool?
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var scheduleManager = ScheduleManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    @StateObject private var alarmManager = AlarmManager()
    
    @Query var preferences: [UserPreferences]
    
    let modelContainer: ModelContainer
    
    init() {
        RevenueCatManager.configure()

        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(
                for: 
                    SleepScheduleStore.self,
                UserPreferences.self,
                UserFactor.self,
                HistoryModel.self,
                SleepEntry.self,
                OnboardingAnswerData.self,
                User.self,
                UserSchedule.self,
                UserSleepBlock.self,
                ScheduleEntity.self,
                SleepBlockEntity.self,
                SleepEntryEntity.self,
                PendingChange.self,
                AlarmSettings.self,
                AlarmNotification.self
                ,
                configurations: config
            )
            
            let context = modelContainer.mainContext
            Repository.shared.setModelContext(context)
            
            print("SwiftData başarıyla yapılandırıldı")
            
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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: languageManager.currentLanguage))
                .environmentObject(authManager)
                .environmentObject(scheduleManager)
                .environmentObject(languageManager)
                .environmentObject(revenueCatManager)
                .environmentObject(alarmManager)
                .withLanguageEnvironment()
                .onAppear {
                    delegate.modelContainer = modelContainer
                    // AlarmManager referansını AppDelegate'e ver (erken başlatma)
                    delegate.alarmManager = alarmManager
                }
                .onOpenURL { url in
                    if url.scheme == "polynap" {
                        print("Uygulama URL ile açıldı: \(url)")
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
    @EnvironmentObject var alarmManager: AlarmManager
    
    var body: some View {
        Group {
            if let preferences = userPreferences.first {
                if preferences.hasCompletedOnboarding {
                    MainTabBarView()
                } else {
                    WelcomeView()
                }
            } else {
                WelcomeView()
                    .onAppear {
                        let newPreferences = UserPreferences()
                        modelContext.insert(newPreferences)
                        try? modelContext.save()
                    }
            }
        }
        .preferredColorScheme(getPreferredColorScheme())
        .fullScreenCover(isPresented: $alarmManager.isAlarmFiring) {
            AlarmFiringView()
                .onAppear {
                    print("📱 ContentView: AlarmFiringView gösterildi!")
                }
                .onDisappear {
                    print("📱 ContentView: AlarmFiringView kapatıldı!")
                }
        }
        .onAppear {
            if userSelectedTheme == nil {
                print("İlk açılış: Sistem teması kullanılıyor - \(systemColorScheme == .dark ? "Koyu" : "Açık")")
            }
            alarmManager.setModelContext(modelContext)
            
            // AppDelegate'e AlarmManager referansını ver
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.alarmManager = alarmManager
                print("📱 ContentView: AppDelegate'e AlarmManager referansı verildi")
                print("📱 ContentView: AlarmManager durumu: isAlarmFiring = \(alarmManager.isAlarmFiring)")
            } else {
                print("❌ ContentView: AppDelegate bulunamadı!")
            }
            
            // Burası, uygulama açıldığında veya ön plana geldiğinde
            // bekleyen bir alarm olup olmadığını kontrol etmek için en doğru yerdir.
            checkForPendingAlarm()
        }
        .onChange(of: alarmManager.isAlarmFiring) { oldValue, newValue in
            print("📱 ContentView: isAlarmFiring değişti: \(oldValue) -> \(newValue)")
            if newValue {
                print("🚨 ContentView: Alarm tetiklendi! AlarmFiringView gösterilecek.")
            } else {
                print("✅ ContentView: Alarm durduruldu! AlarmFiringView kapatılacak.")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .startAlarm)) { notification in
            // Bu dinleyici, uygulama zaten ön plandayken gelen alarmlar için hala gereklidir.
            print("📡 ContentView: .startAlarm notification alındı (Ön Plan Senaryosu)")
            if !alarmManager.isAlarmFiring {
                DispatchQueue.main.async {
                    alarmManager.isAlarmFiring = true
                }
            }
        }
    }
    
    private func getPreferredColorScheme() -> ColorScheme? {
        if let userChoice = userSelectedTheme {
            return userChoice ? .dark : .light
        }
        return nil
    }
    
    private func checkForPendingAlarm() {
        let hasPendingAlarm = UserDefaults.standard.bool(forKey: "pendingBackgroundAlarm")
        
        print("🔍 ContentView: onAppear -> Bekleyen alarm kontrol ediliyor.")
        
        if hasPendingAlarm {
            print("✅ ContentView: Bekleyen alarm tespit edildi! Tetikleniyor...")
            
            // AlarmFiringView'ı doğrudan AlarmManager üzerinden tetikle.
            // Artık kendi kendine NotificationCenter post etmesine gerek yok.
            DispatchQueue.main.async {
                // Alarm sesini ve diğer detayları da başlatmak için AlarmManager'daki merkezi fonksiyonu kullanalım:
                if let alarmInfo = UserDefaults.standard.object(forKey: "pendingAlarmInfo") as? [String: Any] {
                    NotificationCenter.default.post(
                        name: .startAlarm,
                        object: nil,
                        userInfo: alarmInfo
                    )
                } else {
                    // userInfo olmasa bile alarmı tetikle
                    alarmManager.isAlarmFiring = true
                }
                
            }
            
            // Bayrakları temizle. Görev tamamlandı.
            UserDefaults.standard.removeObject(forKey: "pendingBackgroundAlarm")
            UserDefaults.standard.removeObject(forKey: "pendingAlarmInfo")
            print("🧹 ContentView: Bekleyen alarm durumu temizlendi.")
        } else {
            print("📋 ContentView: Bekleyen alarm yok.")
        }
    }
}
