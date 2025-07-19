import Foundation
import SwiftUI
import RevenueCat
import RevenueCatUI
import Combine

// MARK: - Paywall Scenario Types

enum PaywallScenario {      // Senaryo 1-2: İlk ve ikinci karşılaşma (tüm planları göster)
    case exitDiscount    // Senaryo 3: Özel indirim teklifi (bir kerelik son şans)
     // Senaryo 4: Standart teklif (ücretsiz deneme odaklı)
    case threePlansPaywall
}

// MARK: - Paywall Trigger Types

enum PaywallTrigger {
    case onboardingComplete  // Onboarding tamamlandığında
    case premiumFeatureAccess // Premium özellik erişimi
    case manualTrigger       // Manuel tetikleme
}

// MARK: - Paywall Manager

final class PaywallManager: ObservableObject {
    
    static let shared = PaywallManager()
    
    @Published var currentScenario: PaywallScenario = .threePlansPaywall
    @Published var isPaywallPresented = false
    
    private let userDefaults = UserDefaults.standard
    private let paywallCountKey = "paywall_presentation_count"
    private let lastPaywallDateKey = "last_paywall_presentation_date"
    private var userStateObserver: AnyCancellable?
    
    private init() {
        // RevenueCat user state değişikliklerini dinle
        userStateObserver = RevenueCatManager.shared.$userState
            .dropFirst() // İlk değeri ignore et
            .sink { [weak self] userState in
                self?.handleUserStateChange(userState)
            }
    }
    
    // MARK: - Public Methods
    
    /// Paywall'u senaryoya göre sunar
    func presentPaywall(trigger: PaywallTrigger) {
        let currentCount = getPaywallPresentationCount()
        let scenario = determineScenario(for: trigger)
        currentScenario = scenario
        
        print("\n📱 ========== PAYWALL GÖSTERIM BAŞLIYOR ==========")
        print("📱 PaywallManager: Paywall gösteriliyor")
        print("   Tetikleyici: \(trigger)")
        print("   Mevcut gösterim sayısı: \(currentCount)")
        print("   Seçilen senaryo: \(scenario)")
        print("   Offering ID: \(getOfferingIdentifier(for: scenario) ?? "unknown")")
        
        // Paywall gösterim sayısını artır
        incrementPaywallCount()
        
        let newCount = getPaywallPresentationCount()
        print("   Yeni gösterim sayısı: \(newCount)")
        print("📱 ===============================================\n")
        
        // Paywall'u göster
        isPaywallPresented = true
    }
    
    /// Paywall'u programatik olarak kapatır
func dismissPaywall(reason: String = "unknown") {
    print("📱 PaywallManager: Paywall programatik olarak kapatılıyor - Sebep: \(reason)")
    isPaywallPresented = false
    
    // Exit discount logic'ini de çalıştır
    handlePaywallDismiss(reason: reason)
}

/// Paywall kapatıldığında exit discount logic'ini handle eder
func handlePaywallDismiss(reason: String) {
    print("📱 PaywallManager: Paywall kapatılma işlemi handle ediliyor - Sebep: \(reason)")
    
    // Eğer all_plans scenario'su kapatıldıysa ve exit_discount koşulları sağlanıyorsa
    let shouldShowExitDiscount = checkShouldShowExitDiscount(reason: reason)
    
    // Exit discount'u göstermek için kısa bir delay ekle
    if shouldShowExitDiscount {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.presentExitDiscount()
        }
    }
}
    
    /// Exit discount koşullarını kontrol eder
private func checkShouldShowExitDiscount(reason: String) -> Bool {
    print("\n🔍 ========== EXIT DISCOUNT KONTROL ==========")
    print("🔍 PaywallManager: Exit discount koşulları kontrol ediliyor")
    print("   Kapatılma sebebi: \(reason)")
    print("   Mevcut scenario: \(currentScenario)")
    
    // Sadece kullanıcı manuel olarak kapattıysa ve all_plans scenario'suysa
    guard currentScenario == .threePlansPaywall &&
          reason == "user_dismissed" else {
        print("   ❌ Exit discount koşulları karşılanmadı:")
        print("      - Scenario all_plans mi? \(currentScenario == .threePlansPaywall)")
        print("      - User dismissed mi? \(reason == "user_dismissed")")
        print("🔍 =========================================\n")
        return false
    }
    
    let currentCount = getPaywallPresentationCount()
    print("   ✅ Temel koşullar karşılandı")
    print("   Mevcut gösterim sayısı: \(currentCount)")
    
    // Sadece count tam olarak 2 ise exit_discount göster
    let shouldShow = currentCount == 2
    print("   Count == 2 mi? \(shouldShow)")
    
    if shouldShow {
        print("   ✅ Exit discount gösterilecek (0.5s delay)")
    } else {
        print("   ❌ Exit discount gösterilmeyecek (count=\(currentCount), sadece count=2'de gösterilir)")
    }
    print("🔍 =========================================\n")
    
    return shouldShow
}
    
    /// Exit discount paywall'ını sunar
    private func presentExitDiscount() {
        print("\n🎁 ========== EXIT DISCOUNT OTOMATIK TETİKLENİYOR ==========")
        print("🎁 PaywallManager: Exit discount otomatik tetikleniyor")
        print("   Mevcut count: \(getPaywallPresentationCount()) (değişmeyecek)")
        print("   Offering ID: exit_discount")
        print("   Delay sonrası otomatik gösterim")
        print("🎁 ========================================================\n")
        
        currentScenario = .exitDiscount
        
        // Exit discount'u ayrı bir sayım olarak ARTIRMA - bu otomatik bir gösterim
        // incrementPaywallCount() // Bu satırı kaldırıyoruz
        
        isPaywallPresented = true
    }
    
    /// Hangi offering'in kullanılacağını belirler
    func getOfferingIdentifier(for scenario: PaywallScenario) -> String? {
        switch scenario {
        case .exitDiscount:
            return "exit_discount"
        case .threePlansPaywall:
            return "three_plans_offer"
        }
    }
    
    /// Kullanıcının paywall gösterim geçmişini sıfırlar (debug/test amaçlı)
func resetPaywallHistory() {
    let oldCount = getPaywallPresentationCount()
    let oldDate = getLastPaywallDate()
    let hadOnboardingTrigger = UserDefaults.standard.bool(forKey: "has_triggered_onboarding_paywall")
    
    userDefaults.removeObject(forKey: paywallCountKey)
    userDefaults.removeObject(forKey: lastPaywallDateKey)
    UserDefaults.standard.removeObject(forKey: "has_triggered_onboarding_paywall")
    
    print("\n🔄 ========== PAYWALL GEÇMİŞİ SIFIRLANDI ==========")
    print("🔄 PaywallManager: Paywall geçmişi temizlendi")
    print("   Eski gösterim sayısı: \(oldCount) -> 0")
    print("   Eski son tarih: \(oldDate?.description ?? "yok") -> yok")
    print("   Onboarding flag: \(hadOnboardingTrigger) -> false")
    print("   Sonraki gösterim: all_plans (onboarding senaryosu)")
    print("🔄 =============================================\n")
}

/// Manuel test amaçlı exit discount tetikler
func triggerExitDiscountForTesting() {
    print("🧪 PaywallManager: Test amaçlı exit discount tetikleniyor")
    presentExitDiscount()
}
    
    /// Debug amaçlı paywall durumunu yazdırır
    func printPaywallStatus() {
        let count = getPaywallPresentationCount()
        let lastDate = getLastPaywallDate()
        let nextScenarioForPremium = determineScenario(for: .premiumFeatureAccess)
        let nextScenarioForManual = determineScenario(for: .manualTrigger)
        
        print("\n📊 ========== PAYWALL DURUM RAPORU ==========")
        print("📊 PaywallManager Mevcut Durum:")
        print("   Toplam gösterim sayısı: \(count)")
        print("   Son gösterim tarihi: \(lastDate?.description ?? "Hiç gösterilmemiş")")
        print("   Sonraki premium erişim senaryosu: \(nextScenarioForPremium)")
        print("   Sonraki premium offering: \(getOfferingIdentifier(for: nextScenarioForPremium) ?? "unknown")")
        print("   Sonraki manuel senaryosu: \(nextScenarioForManual)")
        print("   Sonraki manuel offering: \(getOfferingIdentifier(for: nextScenarioForManual) ?? "unknown")")
        print("📊 ==========================================\n")
        
        // Akış açıklaması
        print("🎯 Beklenen Akış:")
        print("   Count 0: all_plans (onboarding sonrası)")
        print("   Count 1: all_plans (ikinci gösterim)")
        print("   Count 2+: threePlansPaywall (üçüncü ve sonraki)")
        print("   Exit discount: sadece count=2'de all_plans kapatıldığında otomatik")
        print("🎯 ==========================================\n")
    }
    
    // MARK: - Private Methods
    
    /// Tetikleyici ve geçmiş veriler temelinde scenario belirleme
    private func determineScenario(for trigger: PaywallTrigger) -> PaywallScenario {
        let currentCount = getPaywallPresentationCount()
        
        print("📱 PaywallManager: Scenario belirleniyor - Trigger: \(trigger), Count: \(currentCount)")
        
        switch trigger {
        case .onboardingComplete:
            // Senaryo 1: İlk karşılaşma (onboarding sonrası)
            print("📱 PaywallManager: Onboarding tamamlandı -> all_plans")
            return .threePlansPaywall
            
        case .premiumFeatureAccess:
            if currentCount == 0 {
                // İlk kez premium özelliğe erişmeye çalışıyor - all_plans
                print("📱 PaywallManager: İlk premium erişim (count=0) -> all_plans")
                return .threePlansPaywall
            } else if currentCount == 1 {
                // İkinci kez - tekrar all_plans
                print("📱 PaywallManager: İkinci premium erişim (count=1) -> all_plans")
                return .threePlansPaywall
            } else {
                // Üçüncü ve sonraki gösterimler - trial_focus
                print("📱 PaywallManager: Üçüncü+ premium erişim (count=\(currentCount)) -> three_plans_offer")
                return .threePlansPaywall
            }
            
        case .manualTrigger:
            // Manuel tetiklemede mevcut sayıya göre scenario belirle
            if currentCount <= 1 {
                print("📱 PaywallManager: Manuel tetikleme (count=\(currentCount)) -> threePlansPaywall")
                return .threePlansPaywall
            } else {
                print("📱 PaywallManager: Manuel tetikleme (count=\(currentCount)) -> threePlansPaywall")
                return .threePlansPaywall
            }
        }
    }
    
    /// Paywall gösterim sayısını getirir
    private func getPaywallPresentationCount() -> Int {
        return userDefaults.integer(forKey: paywallCountKey)
    }
    
    /// Paywall gösterim sayısını artırır ve tarihi günceller
    private func incrementPaywallCount() {
        let currentCount = getPaywallPresentationCount()
        userDefaults.set(currentCount + 1, forKey: paywallCountKey)
        userDefaults.set(Date(), forKey: lastPaywallDateKey)
    }
    
    /// Son paywall gösterim tarihini getirir
    private func getLastPaywallDate() -> Date? {
        return userDefaults.object(forKey: lastPaywallDateKey) as? Date
    }
    
    /// User state değişikliklerini handle eder
    private func handleUserStateChange(_ userState: UserState) {
        if userState == .premium && isPaywallPresented {
            print("📱 PaywallManager: Kullanıcı premium oldu, paywall kapatılıyor")
            DispatchQueue.main.async {
                self.dismissPaywall(reason: "purchase_completed_auto")
            }
        }
    }
}

// MARK: - Smart PaywallView

/// Senaryoya göre otomatik offering seçen PaywallView
struct SmartPaywallView: View {
    let scenario: PaywallScenario
    let displayCloseButton: Bool
    let locale: Locale

    @State private var offering: Offering?
    @State private var isLoading = true
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    
    init(scenario: PaywallScenario, displayCloseButton: Bool = true, locale: Locale) {
        self.scenario = scenario
        self.displayCloseButton = displayCloseButton
        self.locale = locale
    }
    
    var body: some View {
        Group {
            if isLoading {
                // Yükleme göstergesi
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Teklifler yükleniyor...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else {
                // PaywallView'i güvenli şekilde initialize et
                createPaywallView()
            }
        }
        .task {
            await fetchOffering()
        }
        .environment(\.locale, locale)
    }
    
    @ViewBuilder
    private func createPaywallView() -> some View {
        if let offering = offering {
            // Belirli offering ile paywall
            PaywallView(
                offering: offering,
                displayCloseButton: true // Close button'ı aktif et
            )
            .onAppear {
                print("📱 SmartPaywallView: PaywallView gösterildi - Offering: \(offering.identifier)")
            }
        } else {
            // Fallback - varsayılan paywall
            PaywallView(displayCloseButton: true)
            .onAppear {
                print("📱 SmartPaywallView: Fallback PaywallView gösterildi")
            }
        }
    }
    
    @MainActor
    private func fetchOffering() async {
        guard let offeringId = PaywallManager.shared.getOfferingIdentifier(for: scenario) else {
            print("📱 SmartPaywallView: \(scenario) için offering ID bulunamadı")
            isLoading = false
            return
        }
        
        print("📱 SmartPaywallView: Offering fetch başlıyor - Scenario: \(scenario), ID: \(offeringId)")
        
        // Offering'i fetch et
        offering = await revenueCatManager.getOffering(identifier: offeringId)
        
        if let offering = offering {
            print("📱 SmartPaywallView: Offering başarıyla yüklendi - \(offering.identifier)")
            print("📱 SmartPaywallView: Offering paket sayısı: \(offering.availablePackages.count)")
        } else {
            print("📱 SmartPaywallView: Offering yüklenemedi - nil döndü")
        }
        
        print("📱 SmartPaywallView: Loading tamamlandı, PaywallView render edilecek")
        
        // Kısa bir delay ekleyerek PaywallView'in stable hale gelmesini sağla
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 saniye
        
        isLoading = false
    }
}

// MARK: - SwiftUI ViewModifier

struct PaywallPresentationModifier: ViewModifier {
    @StateObject private var paywallManager = PaywallManager.shared
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @ObservedObject private var languageManager = LanguageManager.shared
    
    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: $paywallManager.isPaywallPresented,
                onDismiss: {
                    print("📱 PaywallPresentationModifier: Sheet onDismiss - Paywall kapatıldı")
                    // Sheet kapatıldığında sadece exit discount logic'ini çalıştır
                    paywallManager.handlePaywallDismiss(reason: "user_dismissed")
                }
            ) {
                SmartPaywallView(scenario: paywallManager.currentScenario, locale: languageManager.currentLocale)
                    .environmentObject(revenueCatManager)
                    .onAppear {
                        print("📱 PaywallPresentationModifier: Sheet gösterildi")
                    }
            }
    }
}

extension View {
    /// PaywallManager ile otomatik paywall yönetimi ekler
    func managePaywalls() -> some View {
        modifier(PaywallPresentationModifier())
    }
} 
