import Foundation
import FirebaseAnalytics

/// Firebase Analytics yönetim sınıfı
/// PolyNap uygulaması için özel analytics event'larını yönetir
class AnalyticsManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AnalyticsManager()
    
    private init() {}
    
    // MARK: - Core Analytics Methods
    
    /// Özel event gönder
    /// - Parameters:
    ///   - name: Event adı (snake_case formatında)
    ///   - parameters: Event parametreleri
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
        print("📊 Analytics: Event logged - \(name)")
        if let params = parameters {
            print("📊 Analytics: Parameters - \(params)")
        }
    }
    
    /// Screen view event'ı gönder
    /// - Parameters:
    ///   - screenName: Ekran adı
    ///   - screenClass: Ekran sınıfı (View adı)
    func logScreenView(screenName: String, screenClass: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass
        ])
        print("📱 Analytics: Screen view - \(screenName)")
    }
    
    /// User property set et
    /// - Parameters:
    ///   - name: Property adı
    ///   - value: Property değeri
    func setUserProperty(_ name: String, value: String?) {
        Analytics.setUserProperty(value, forName: name)
        print("👤 Analytics: User property set - \(name): \(value ?? "nil")")
    }
    
    /// User ID set et
    /// - Parameter userId: Kullanıcı ID'si
    func setUserId(_ userId: String?) {
        Analytics.setUserID(userId)
        print("🆔 Analytics: User ID set - \(userId ?? "nil")")
    }
    
    // MARK: - App Lifecycle Events
    
    /// Uygulama açılış event'ı
    func logAppOpen() {
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
        print("🚀 Analytics: App opened")
    }
    
    /// Uygulama background'a giriş event'ı
    func logAppBackground() {
        logEvent("app_background")
    }
    
    /// Uygulama foreground'a dönüş event'ı
    func logAppForeground() {
        logEvent("app_foreground")
    }
    
    // MARK: - Onboarding Events
    
    /// Onboarding başlangıç event'ı
    func logOnboardingStarted() {
        logEvent("onboarding_started")
    }
    
    /// Onboarding tamamlama event'ı
    /// - Parameters:
    ///   - timeTaken: Tamamlanma süresi (saniye)
    ///   - stepsCompleted: Tamamlanan adım sayısı
    ///   - selectedSchedule: Seçilen uyku programı
    func logOnboardingCompleted(timeTaken: TimeInterval? = nil, stepsCompleted: Int? = nil, selectedSchedule: String? = nil) {
        print("🔥 AnalyticsManager: logOnboardingCompleted BAŞLADI")
        
        var parameters: [String: Any] = [:]
        
        if let time = timeTaken {
            parameters["total_time_spent"] = Int(time)
            print("   ✅ total_time_spent: \(Int(time)) seconds")
        }
        
        if let steps = stepsCompleted {
            parameters["steps_completed"] = steps
            print("   ✅ steps_completed: \(steps)")
        }
        
        if let schedule = selectedSchedule {
            parameters["selected_schedule"] = schedule
            print("   ✅ selected_schedule: \(schedule)")
        }
        
        // Firebase Analytics için value parametresi (conversion value)
        parameters[AnalyticsParameterValue] = 100
        parameters[AnalyticsParameterCurrency] = "USD"
        print("   ✅ conversion value: 100 USD")
        
        print("📊 Firebase Analytics'e GÖNDERİLİYOR: onboarding_completed")
        print("📊 Parametreler: \(parameters)")
        
        logEvent("onboarding_completed", parameters: parameters.isEmpty ? nil : parameters)
        
        print("🎉 AnalyticsManager: onboarding_completed EVENT'I GÖNDERİLDİ!")
    }
    
    /// Onboarding adım tamamlama event'ı
    /// - Parameters:
    ///   - step: Adım numarası
    ///   - stepName: Adım adı
    func logOnboardingStepCompleted(step: Int, stepName: String) {
        logEvent("onboarding_step_completed", parameters: [
            "step_number": step,
            "step_name": stepName
        ])
    }
    
    // MARK: - Sleep Schedule Events
    
    /// Uyku programı seçimi event'ı
    /// - Parameters:
    ///   - scheduleName: Program adı (örn: "Biphasic", "Everyman")
    ///   - difficulty: Zorluk seviyesi
    func logScheduleSelected(scheduleName: String, difficulty: String) {
        logEvent("schedule_selected", parameters: [
            "schedule_name": scheduleName,
            "difficulty_level": difficulty
        ])
    }
    
    /// Uyku programı değişikliği event'ı
    /// - Parameters:
    ///   - fromSchedule: Eski program
    ///   - toSchedule: Yeni program
    ///   - reason: Değişiklik sebebi
    func logScheduleChanged(fromSchedule: String, toSchedule: String, reason: String? = nil) {
        var parameters: [String: Any] = [
            "from_schedule": fromSchedule,
            "to_schedule": toSchedule
        ]
        if let reason = reason {
            parameters["change_reason"] = reason
        }
        logEvent("schedule_changed", parameters: parameters)
    }
    
    // MARK: - Sleep Entry Events
    
    /// Uyku girişi ekleme event'ı
    /// - Parameters:
    ///   - sleepType: Uyku tipi (core, nap)
    ///   - duration: Süre (dakika)
    ///   - quality: Kalite puanı (1-5)
    func logSleepEntryAdded(sleepType: String, duration: Int, quality: Int? = nil) {
        var parameters: [String: Any] = [
            "sleep_type": sleepType,
            "duration_minutes": duration
        ]
        if let quality = quality {
            parameters["quality_rating"] = quality
        }
        logEvent("sleep_entry_added", parameters: parameters)
    }
    
    /// Uyku kalitesi puanlama event'ı
    /// - Parameters:
    ///   - rating: Puan (1-5)
    ///   - sleepType: Uyku tipi
    func logSleepQualityRated(rating: Int, sleepType: String) {
        logEvent("sleep_quality_rated", parameters: [
            "rating": rating,
            "sleep_type": sleepType
        ])
    }
    
    // MARK: - Alarm Events
    
    /// Alarm kurma event'ı
    /// - Parameters:
    ///   - alarmType: Alarm tipi
    ///   - soundName: Alarm sesi
    func logAlarmSet(alarmType: String, soundName: String) {
        logEvent("alarm_set", parameters: [
            "alarm_type": alarmType,
            "sound_name": soundName
        ])
    }
    
    /// Alarm tetikleme event'ı
    func logAlarmTriggered() {
        logEvent("alarm_triggered")
    }
    
    /// Alarm durdurma event'ı
    /// - Parameter snoozeUsed: Erteleme kullanıldı mı
    func logAlarmStopped(snoozeUsed: Bool = false) {
        logEvent("alarm_stopped", parameters: [
            "snooze_used": snoozeUsed
        ])
    }
    
    // MARK: - Premium/Revenue Events
    
    /// Paywall görüntüleme event'ı
    /// - Parameters:
    ///   - source: Paywall kaynağı (hangi ekrandan geldi)
    ///   - placement: Paywall yerleşimi
    func logPaywallViewed(source: String, placement: String? = nil) {
        var parameters: [String: Any] = ["source": source]
        if let placement = placement {
            parameters["placement"] = placement
        }
        logEvent("paywall_viewed", parameters: parameters)
    }
    
    /// Satın alma denemesi event'ı
    /// - Parameters:
    ///   - productId: Ürün ID'si
    ///   - source: Kaynak ekran
    func logPurchaseAttempt(productId: String, source: String) {
        logEvent("purchase_attempt", parameters: [
            "product_id": productId,
            "source": source
        ])
    }
    
    /// Başarılı satın alma event'ı
    /// - Parameters:
    ///   - productId: Ürün ID'si
    ///   - revenue: Gelir miktarı
    ///   - currency: Para birimi
    func logPurchaseSuccess(productId: String, revenue: Double, currency: String) {
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterItemID: productId,
            AnalyticsParameterValue: revenue,
            AnalyticsParameterCurrency: currency
        ])
        print("💰 Analytics: Purchase completed - \(productId)")
    }
    
    // MARK: - User Engagement Events
    
    /// Bildirim açma event'ı
    /// - Parameter notificationType: Bildirim tipi
    func logNotificationOpened(notificationType: String) {
        logEvent("notification_opened", parameters: [
            "notification_type": notificationType
        ])
    }
    
    /// Ayar değişikliği event'ı
    /// - Parameters:
    ///   - settingName: Ayar adı
    ///   - oldValue: Eski değer
    ///   - newValue: Yeni değer
    func logSettingChanged(settingName: String, oldValue: String, newValue: String) {
        logEvent("setting_changed", parameters: [
            "setting_name": settingName,
            "old_value": oldValue,
            "new_value": newValue
        ])
    }
    
    /// Feature kullanımı event'ı
    /// - Parameters:
    ///   - featureName: Feature adı
    ///   - action: Yapılan aksiyon
    func logFeatureUsed(featureName: String, action: String) {
        logEvent("feature_used", parameters: [
            "feature_name": featureName,
            "action": action
        ])
    }
    
    // MARK: - Key Business Events
    
    /// İlk uygulama açılışı event'ı (Key Event)
    func logFirstAppOpen() {
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: [
            "first_time_user": true
        ])
        print("🎉 Analytics: First app open")
    }
    
    /// Sleep entry ekleme event'ı (Key Event)
    /// - Parameters:
    ///   - sleepType: Uyku tipi (core, nap)
    ///   - duration: Süre (dakika)
    ///   - quality: Kalite puanı (1-5)
    ///   - isFirstEntry: İlk uyku girişi mi?
    func logSleepEntryAdded(sleepType: String, duration: Int, quality: Int? = nil, isFirstEntry: Bool = false) {
        var parameters: [String: Any] = [
            "sleep_type": sleepType,
            "duration_minutes": duration,
            "is_first_entry": isFirstEntry
        ]
        if let quality = quality {
            parameters["quality_rating"] = quality
        }
        logEvent("sleep_entry_added", parameters: parameters)
    }
    
    /// Schedule başarılı uygulanması event'ı (Key Event)
    /// - Parameters:
    ///   - scheduleName: Program adı
    ///   - daysUsed: Kaç gündür kullanılıyor
    func logScheduleSuccessfullyApplied(scheduleName: String, daysUsed: Int) {
        logEvent("schedule_successfully_applied", parameters: [
            "schedule_name": scheduleName,
            "days_used": daysUsed
        ])
    }
    
    /// Kullanıcı retention event'ı (Key Event)
    /// - Parameter daysSinceInstall: Kurulumdan bu yana geçen gün
    func logUserRetention(daysSinceInstall: Int) {
        logEvent("user_retention", parameters: [
            "days_since_install": daysSinceInstall
        ])
    }
    
    // MARK: - Analytics State Management
    
    /// Analytics'i aktif/pasif hale getir
    /// - Parameter enabled: Aktif mi
    func setAnalyticsEnabled(_ enabled: Bool) {
        Analytics.setAnalyticsCollectionEnabled(enabled)
        print("📊 Analytics: Collection \(enabled ? "enabled" : "disabled")")
    }
    
    /// Debug modunu aktif et (sadece development için)
    func enableDebugMode() {
        #if DEBUG
        Analytics.setAnalyticsCollectionEnabled(true)
        print("🐛 Analytics: Debug mode enabled")
        #endif
    }
} 
