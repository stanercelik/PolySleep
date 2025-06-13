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
    
    // YENİ: Background'dan gelen alarm tetikleme bilgisi için
    var _pendingAlarmTrigger: AlarmTriggerInfo?
    private var pendingAlarmTrigger: AlarmTriggerInfo? {
        get {
            return _pendingAlarmTrigger
        }
        set {
            if let newValue = newValue {
                print("🔖 AppDelegate: Pending alarm SET edildi - title: \(newValue.title)")
            } else {
                print("🗑️ AppDelegate: Pending alarm TEMIZLENDI")
            }
            _pendingAlarmTrigger = newValue
        }
    }
    
    // YENİ: Alarm tetikleme bilgilerini saklayan struct
    struct AlarmTriggerInfo {
        let title: String
        let body: String
        let soundName: String
        let userInfo: [AnyHashable: Any]
        let originalNotification: UNNotification?
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Bu sınıfı kullanıcı bildirimleri için delege olarak ayarla
        UNUserNotificationCenter.current().delegate = self
        
        // Uygulama açılışında uygulama simgesi sayacını temizle
        application.applicationIconBadgeNumber = 0
        
        // Metal framework sorunu için ek gecikme
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // AlarmService singleton'ını başlatarak izinlerin erken istenmesini sağla
            _ = AlarmService.shared
        }
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("🔄🔄🔄 AppDelegate: applicationDidBecomeActive çağrıldı 🔄🔄🔄")
        print("📱 AppDelegate: Application state: \(application.applicationState.rawValue)")
        print("⏰ AppDelegate: Current time: \(Date())")
        print("🔍 AppDelegate: Pending alarm durumu: \(pendingAlarmTrigger != nil ? "VAR" : "YOK")")
        
        // Uygulama her aktif olduğunda sayacı temizle
        application.applicationIconBadgeNumber = 0
        
        // YENİ: Automatic pending alarm handling kaldırıldı - sadece SwiftUI observer üzerinden kontrole bırakıldı
        print("🔍 AppDelegate: Pending alarm kontrolü SwiftUI observer'a bırakıldı")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("🔄 AppDelegate: applicationWillEnterForeground çağrıldı")
        print("🔍 AppDelegate: applicationWillEnterForeground - Pending alarm durumu: \(pendingAlarmTrigger != nil ? "VAR" : "YOK")")
    }
    
    // YENİ: SwiftUI'den çağrılacak pending alarm handler
    func handlePendingAlarmTrigger() {
        print("🔍 AppDelegate: handlePendingAlarmTrigger çağrıldı")
        print("🔍 AppDelegate: Pending alarm durumu: \(pendingAlarmTrigger != nil ? "VAR" : "YOK")")
        print("🔍 AppDelegate: Thread: \(Thread.isMainThread ? "Main" : "Background")")
        print("🔍 AppDelegate: Current time: \(Date())")
        print("🔍 AppDelegate: AlarmManager current state - isAlarmFiring: \(AlarmManager.shared.isAlarmFiring)")
        
        if let triggerInfo = pendingAlarmTrigger {
            print("🚨 AppDelegate: Pending alarm bulundu, tetikleniyor...")
            print("📋 AppDelegate: Trigger - title: \(triggerInfo.title), body: \(triggerInfo.body)")
            print("📋 AppDelegate: Trigger - soundName: \(triggerInfo.soundName)")
            print("📋 AppDelegate: Trigger - userInfo: \(triggerInfo.userInfo)")
            
            // CRITICAL FIX: State validation before triggering
            if AlarmManager.shared.isAlarmFiring {
                print("⚠️ AppDelegate: AlarmManager zaten alarm firing state'de! Önce durduruyoruz...")
                AlarmManager.shared.stopAlarm()
                
                // Kısa gecikme ile state'in temizlenmesini bekle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.triggerPendingAlarm(with: triggerInfo)
                }
            } else {
                // Doğrudan tetikle
                triggerPendingAlarm(with: triggerInfo)
            }
            
        } else {
            print("📭 AppDelegate: Pending alarm trigger yok")
        }
    }
    
    // CRITICAL FIX: Separated trigger method for better error handling
    private func triggerPendingAlarm(with triggerInfo: AlarmTriggerInfo) {
        // Main thread'de alarm tetikle
        DispatchQueue.main.async {
            print("🎯 AppDelegate: Main queue'da AlarmManager.shared.triggerAlarm çağrılıyor...")
            print("🔍 PRE-TRIGGER STATE: isAlarmFiring: \(AlarmManager.shared.isAlarmFiring)")
            
            AlarmManager.shared.triggerAlarm(
                title: triggerInfo.title,
                body: triggerInfo.body,
                soundName: triggerInfo.soundName,
                userInfo: triggerInfo.userInfo,
                originalNotification: triggerInfo.originalNotification
            )
            
            print("🚨 AppDelegate: Pending alarm başarıyla tetiklendi!")
            
            // CRITICAL FIX: Validate trigger success
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("🔍 POST-TRIGGER VALIDATION: isAlarmFiring: \(AlarmManager.shared.isAlarmFiring)")
                
                if !AlarmManager.shared.isAlarmFiring {
                    print("🚨 CRITICAL: Alarm trigger failed! Retrying once...")
                    AlarmManager.shared.triggerAlarm(
                        title: triggerInfo.title,
                        body: triggerInfo.body,
                        soundName: triggerInfo.soundName,
                        userInfo: triggerInfo.userInfo,
                        originalNotification: triggerInfo.originalNotification
                    )
                } else {
                    print("✅ AppDelegate: Alarm trigger validation successful!")
                }
                
                // Clear pending trigger after validation
                self.pendingAlarmTrigger = nil
                print("🗑️ AppDelegate: Pending alarm trigger temizlendi")
            }
        }
    }
    


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
        
        print("🔔🔔🔔 AppDelegate: didReceive response çağrıldı! 🔔🔔🔔")
        print("📱 AppDelegate: Application state: \(UIApplication.shared.applicationState.rawValue)")
        print("📋 AppDelegate: Response actionIdentifier: \(response.actionIdentifier)")
        print("📋 AppDelegate: Notification identifier: \(response.notification.request.identifier)")
        
        let content = response.notification.request.content
        print("📋 AppDelegate: Content categoryIdentifier: \(content.categoryIdentifier)")
        print("📋 AppDelegate: Expected categoryIdentifier: \(AlarmService.alarmCategoryIdentifier)")
        print("📋 AppDelegate: Content userInfo: \(content.userInfo)")
        print("📋 AppDelegate: Content title: \(content.title)")
        print("📋 AppDelegate: Content body: \(content.body)")
        print("🕐 AppDelegate: Current time: \(Date())")
        
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
            print("📱 AppDelegate: App state check - \(UIApplication.shared.applicationState.rawValue)")
            print("📱 AppDelegate: App state details - active: \(UIApplication.shared.applicationState == .active), inactive: \(UIApplication.shared.applicationState == .inactive), background: \(UIApplication.shared.applicationState == .background)")
            
            let soundName = content.userInfo["soundName"] as? String ?? "Alarm 1.caf"
            
            // YENİ: Alarm trigger bilgisini her durumda sakla, applicationDidBecomeActive'de tetiklenecek
            pendingAlarmTrigger = AlarmTriggerInfo(
                title: content.title,
                body: content.body,
                soundName: soundName,
                userInfo: content.userInfo,
                originalNotification: response.notification
            )
            
            print("📝 AppDelegate: Alarm trigger bilgisi kaydedildi - Her durumda SwiftUI observer tetikleyecek")
            
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
    // DEĞİŞİKLİK: AlarmManager artık singleton olarak kullanılıyor
    // @StateObject private var alarmManager = AlarmManager() // KALDIRILDI
    
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
                // YENİ: Singleton AlarmManager.shared kullanımı
                .environmentObject(AlarmManager.shared)
                .withLanguageEnvironment()
                .onAppear {
                    delegate.modelContainer = modelContainer
                    // YENİ: ModelContext'i singleton AlarmManager'a ver
                    AlarmManager.shared.setModelContext(modelContainer.mainContext)
                    print("📱 polynapApp: AlarmManager ModelContext ayarlandı")
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    print("🔄 SwiftUI: didBecomeActiveNotification alındı")
                    print("🔍 SwiftUI: App became active, checking for pending alarms...")
                    print("🔍 SwiftUI: Current AlarmManager state: isAlarmFiring = \(AlarmManager.shared.isAlarmFiring)")
                    
                    // CRITICAL FIX: Multiple timing attempts for better reliability
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        delegate.handlePendingAlarmTrigger()
                    }
                    
                    // Backup timing - eğer ilki çalışmazsa
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // Sadece hala pending alarm varsa ve alarm firing değilse tekrar dene
                        if delegate._pendingAlarmTrigger != nil && !AlarmManager.shared.isAlarmFiring {
                            print("🔄 SwiftUI: Backup trigger attempt...")
                            delegate.handlePendingAlarmTrigger()
                        }
                    }
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
    // YENİ: Singleton AlarmManager.shared kullanımı
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
            
            print("📱 ContentView: AlarmManager.shared bağlandı")
            print("📱 ContentView: AlarmManager durumu: isAlarmFiring = \(alarmManager.isAlarmFiring)")
        }
        .onChange(of: alarmManager.isAlarmFiring) { oldValue, newValue in
            print("📱 ContentView: isAlarmFiring değişti: \(oldValue) -> \(newValue)")
            print("📱 ContentView: Thread: \(Thread.isMainThread ? "Main" : "Background")")
            print("📱 ContentView: UIApplication state: \(UIApplication.shared.applicationState.rawValue)")
            if newValue {
                print("🚨 ContentView: Alarm tetiklendi! AlarmFiringView gösterilecek.")
                print("🚨 ContentView: AlarmManager referansı: \(alarmManager === AlarmManager.shared ? "Singleton" : "Farklı instance")")
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
}
