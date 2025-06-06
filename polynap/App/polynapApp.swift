//
//  polynapApp.swift
//  polynap
//
//  Created by Taner Çelik on 27.12.2024.
//

import SwiftUI
import SwiftData
import Combine
import Network
import UserNotifications
import RevenueCat

// AppDelegate ve SwiftUI arasında iletişim için özel bir bildirim adı
extension Notification.Name {
    static let startAlarm = Notification.Name("startAlarmNotification")
    static let stopAlarm = Notification.Name("stopAlarmNotification")
}

// Offline-first model ve servislerimizi import ediyoruz
// Eğer bunlar farklı modüllerde olsaydı, modül adlarını belirtmemiz gerekirdi
// Ancak aynı modül içinde olduğu için direkt dosya adlarını belirtebiliriz

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  static var shared: AppDelegate!
  var modelContainer: ModelContainer?
  func application(_ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    AppDelegate.shared = self
    // Initialize notification manager
    let notificationManager = SleepQualityNotificationManager.shared
    notificationManager.requestAuthorization()
    
    // Alarm servisini başlat ve yetkileri iste
    AlarmService.shared.requestAuthorization()
    
    // Eski alarm servisi - bunu yeni sisteme entegre edebiliriz veya ayrı tutabiliriz. Şimdilik ayrı tutuyorum.
    let alarmNotificationService = AlarmNotificationService.shared
    alarmNotificationService.registerNotificationCategories()
    
    // Bildirim delegate'ini ayarla
    UNUserNotificationCenter.current().delegate = self
    
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
  
  // MARK: - UNUserNotificationCenterDelegate
  
  /// Uygulama ön plandayken bildirim geldiğinde çağrılır
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
      let content = notification.request.content
      
      print("PolyNap Debug: Uygulama önplandayken bildirim geldi - \(content.categoryIdentifier)")
      
      // Yeni ALARM_CATEGORY için - sleep block bitimi alarmları
      if content.categoryIdentifier == "ALARM_CATEGORY" {
          print("PolyNap Debug: ALARM_CATEGORY bildirimi - uygulama önplanda, sistem notification gösterilmeyecek")
          // Alarm geldi! Sistem bildirimini gösterme, kendi UI'ımızı göstereceğiz.
          completionHandler([])
          // AlarmManager'ı tetikle
          NotificationCenter.default.post(name: .startAlarm, object: nil)
          return
      }
      
      // Mevcut alarm mantığı
      if content.userInfo["type"] as? String == "sleep_alarm" {
          completionHandler([.banner, .sound, .badge])
      } else {
          completionHandler([.banner, .sound])
      }
  }
  
  /// Kullanıcı bildirime tıkladığında veya eylem seçtiğinde çağrılır
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
      let content = response.notification.request.content
      let userInfo = content.userInfo
      
      print("PolyNap Debug: Bildirim action alındı - Category: \(content.categoryIdentifier), Action: \(response.actionIdentifier)")
      
      // Yeni ALARM_CATEGORY için - sleep block bitimi alarmları
      if content.categoryIdentifier == "ALARM_CATEGORY" {
          switch response.actionIdentifier {
          case "SNOOZE_ACTION":
              print("PolyNap Debug: ALARM_CATEGORY - Snooze action")
              // Settings'ten erteleme süresini al
              if let context = self.modelContainer?.mainContext {
                  let request = FetchDescriptor<AlarmSettings>()
                  do {
                      let alarmSettingsList = try context.fetch(request)
                      let snoozeDuration = alarmSettingsList.first?.snoozeDurationMinutes ?? 5
                      let snoozeDate = Date().addingTimeInterval(TimeInterval(snoozeDuration * 60))
                      AlarmService.shared.scheduleAlarmNotification(date: snoozeDate, repeats: false, modelContext: context)
                      print("PolyNap Debug: Bildirimden alarm \(snoozeDuration) dakika ertelendi")
                  } catch {
                      print("PolyNap Debug: Bildirimden erteleme - Settings alınamadı: \(error)")
                      let snoozeDate = Date().addingTimeInterval(5 * 60) // 5 dakika varsayılan
                      AlarmService.shared.scheduleAlarmNotification(date: snoozeDate, repeats: false, modelContext: context)
                  }
              } else {
                  let snoozeDate = Date().addingTimeInterval(5 * 60) // 5 dakika varsayılan
                  AlarmService.shared.scheduleAlarmNotification(date: snoozeDate, repeats: false)
              }
          case "STOP_ACTION":
              print("PolyNap Debug: ALARM_CATEGORY - Stop action")
              // Alarmı tamamen durdur. Belki çalan bir ses varsa onu durdurmak için sinyal gönderilir.
              NotificationCenter.default.post(name: .stopAlarm, object: nil)
              print("PolyNap Debug: Alarm kullanıcı tarafından bildirim üzerinden kapatıldı.")
          default:
              print("PolyNap Debug: ALARM_CATEGORY - Default action (notification tapped)")
              // Kullanıcı bildirimin kendisine tıkladı. Uygulama açılacak.
              // Uygulama açılırken alarmı tetiklemeliyiz.
              NotificationCenter.default.post(name: .startAlarm, object: nil)
          }
          completionHandler()
          return
      }
      
      // Mevcut alarm mantığı
      if userInfo["type"] as? String == "sleep_alarm" {
          switch response.actionIdentifier {
          case "START_LONG_ALARM_ACTION":
              handleStartLongAlarmAction(userInfo: userInfo)
          case "SNOOZE_ACTION":
              handleSnoozeAction(userInfo: userInfo)
          case "STOP_ACTION":
              handleStopAction(userInfo: userInfo)
          case UNNotificationDefaultActionIdentifier:
              // Bildirime tıklandı - uzun alarmı başlat
              handleStartLongAlarmAction(userInfo: userInfo)
          default:
              break
          }
      }
      // Uzun alarm eylemleri
      else if userInfo["type"] as? String == "long_sleep_alarm" {
          switch response.actionIdentifier {
          case "STOP_LONG_ALARM_ACTION":
              handleStopLongAlarmAction(userInfo: userInfo)
          case UNNotificationDefaultActionIdentifier:
              // Uzun alarm bildirimine tıklandı - ana ekrana git
              handleLongAlarmTapped(userInfo: userInfo)
          default:
              break
          }
      }
      
      completionHandler()
  }
  
  /// Uzun alarmı başlatır
  private func handleStartLongAlarmAction(userInfo: [AnyHashable: Any]) {
      guard let blockIdString = userInfo["blockId"] as? String,
            let blockId = UUID(uuidString: blockIdString),
            let scheduleIdString = userInfo["scheduleId"] as? String,
            let scheduleId = UUID(uuidString: scheduleIdString),
            let userIdString = userInfo["userId"] as? String,
            let userId = UUID(uuidString: userIdString) else { return }
      
      print("PolyNap Debug: Uzun alarm başlatılıyor - Block ID: \(blockId)")
      
      Task {
          // Varsayılan alarm ayarları - gerçek uygulamada kullanıcı ayarlarından alınacak
          let alarmSettings = AlarmSettings(
              userId: userId,
              isEnabled: true,
              soundName: "alarm.caf",
              volume: 1.0,
              vibrationEnabled: true
          )
          
          await MainActor.run {
              AlarmNotificationService.shared.startLongDurationAlarm(
                  blockId: blockId,
                  scheduleId: scheduleId,
                  userId: userId,
                  alarmSettings: alarmSettings
              )
          }
      }
  }
  
  /// Uzun alarmı durdurur
  private func handleStopLongAlarmAction(userInfo: [AnyHashable: Any]) {
      guard let blockIdString = userInfo["blockId"] as? String,
            let blockId = UUID(uuidString: blockIdString) else { return }
      
      print("PolyNap Debug: Uzun alarm durduruldu - Block ID: \(blockId)")
      
      Task {
          await MainActor.run {
              AlarmNotificationService.shared.stopLongDurationAlarm()
          }
          
          // UI'ya sinyal gönder
          await MainActor.run {
              NotificationCenter.default.post(
                  name: NSNotification.Name("LongAlarmStopped"),
                  object: nil,
                  userInfo: ["blockId": blockId.uuidString]
              )
          }
      }
  }
  
  /// Uzun alarm bildirimine tıklandığında
  private func handleLongAlarmTapped(userInfo: [AnyHashable: Any]) {
      print("PolyNap Debug: Uzun alarm bildirimine tıklandı")
      
      // Uygulamayı ana ekrana yönlendir
      NotificationCenter.default.post(
          name: NSNotification.Name("NavigateToMainScreen"),
          object: nil,
          userInfo: userInfo
      )
  }
  
  private func handleSnoozeAction(userInfo: [AnyHashable: Any]) {
      guard let blockIdString = userInfo["blockId"] as? String,
            let blockId = UUID(uuidString: blockIdString) else { return }
      
      print("PolyNap Debug: Alarm ertelendi - Block ID: \(blockId)")
      
      // Erteleme işlemini gerçekleştir
      Task {
          // 5 dakika sonra yeni alarm planla
          let snoozeTime = Date().addingTimeInterval(5 * 60) // 5 dakika
          
          let content = UNMutableNotificationContent()
          content.title = "⏰ Ertelenmiş Uyku Alarmı"
          content.body = "5 dakika doldu! Uyanma zamanı!"
          content.categoryIdentifier = "SLEEP_ALARM"
          content.sound = UNNotificationSound.defaultCritical
          content.interruptionLevel = .critical
          content.userInfo = userInfo // Aynı bilgileri koru
          
          let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 * 60, repeats: false)
          let request = UNNotificationRequest(
              identifier: "snooze_\(blockId.uuidString)_\(Date().timeIntervalSince1970)",
              content: content,
              trigger: trigger
          )
          
          do {
              try await UNUserNotificationCenter.current().add(request)
              print("PolyNap Debug: Erteleme alarmı planlandı")
          } catch {
              print("PolyNap Debug: Erteleme alarmı planlanamadı: \(error)")
          }
      }
  }
  
  private func handleStopAction(userInfo: [AnyHashable: Any]) {
      guard let blockIdString = userInfo["blockId"] as? String,
            let blockId = UUID(uuidString: blockIdString) else { return }
      
      print("PolyNap Debug: Alarm kapatıldı - Block ID: \(blockId)")
      
      // Alarm durdurma işlemini gerçekleştir
      Task {
          // Bu blok için tüm bekleyen alarmları iptal et
          await AlarmNotificationService.shared.cancelAlarmForBlock(blockId: blockId)
          
          // Erteleme alarmları da iptal et
          let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
          let snoozeIdentifiers = pendingRequests.compactMap { request in
              if request.identifier.contains("snooze_\(blockId.uuidString)") {
                  return request.identifier
              }
              return nil
          }
          
          if !snoozeIdentifiers.isEmpty {
              UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: snoozeIdentifiers)
              print("PolyNap Debug: Erteleme alarmları da iptal edildi")
          }
          
          // Başarı bildirimi göster (opsiyonel)
          await MainActor.run {
              // UI'da başarı mesajı gösterilebilir
              NotificationCenter.default.post(
                  name: NSNotification.Name("AlarmStopped"),
                  object: nil,
                  userInfo: ["blockId": blockId.uuidString]
              )
          }
      }
  }
  
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    // URL şemasını işle
    if url.scheme == "polynap" {
        print("URL şeması işleniyor: \(url)")
        // Burada spesifik URL tabanlı eylemleriniz varsa işleyebilirsiniz.
        // Artık Apple Sign In ile ilgili bir kontrol yok.
    }
    // Diğer URL işleyicileriniz varsa ve işlendiğini belirtmek istiyorsanız true döndürün.
    return false
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
    @StateObject private var alarmManager = AlarmManager() // Yeni AlarmManager'ı ekliyoruz
    
    // Sınıf düzeyinde @Query tanımlıyoruz, böylece yerel alan içinde kullanmamış oluruz
    @Query var preferences: [UserPreferences]
    
    let modelContainer: ModelContainer
    
    init() {
        // RevenueCat'i yapılandır
        RevenueCatManager.configure()

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
                
                // Alarm modelleri
                AlarmSettings.self,
                AlarmNotification.self,
                
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
                .environmentObject(revenueCatManager)
                .environmentObject(alarmManager) // AlarmManager'ı environment'a ekliyoruz
                .withLanguageEnvironment()
                .onAppear {
                    // AppDelegate'e modelContainer'ı geçir
                    delegate.modelContainer = modelContainer
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
                    if url.scheme == "polynap" {
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
    @EnvironmentObject var alarmManager: AlarmManager // AlarmManager'ı alıyoruz
    
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
        .fullScreenCover(isPresented: $alarmManager.isAlarmFiring) {
            AlarmFiringView()
        }
        .onAppear {
            // İlk açılışta kullanıcı tema tercihi yoksa sistem temasını ayarla
            if userSelectedTheme == nil {
                print("İlk açılış: Sistem teması kullanılıyor - \(systemColorScheme == .dark ? "Koyu" : "Açık")")
            }
            
            // AlarmManager'a ModelContext'i ayarla
            alarmManager.setModelContext(modelContext)
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
