import SwiftUI
import Combine

/// Bundle extension to handle dynamic language switching
extension Bundle {
    static var appBundle: Bundle {
        guard let path = Bundle.main.path(forResource: LanguageManager.shared.currentLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return Bundle.main
        }
        return bundle
    }
}

/// Uygulamanın dil ayarlarını yöneten global manager
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: String {
        didSet {
            print("🔄 LanguageManager: Language changed from '\(oldValue)' to '\(currentLanguage)'")
            UserDefaults.standard.set(currentLanguage, forKey: "appLanguage")
            updateLocale()
            // Force refresh all views
            objectWillChange.send()
        }
    }
    
    @Published var currentLocale: Locale
    
    private init() {
        // İlk açılışta sistem dilini kontrol et, sonrasında kullanıcı tercihini kullan
        let initialLanguage: String
        
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage") {
            // Kullanıcı daha önce bir dil seçmiş, onu kullan
            print("🔄 LanguageManager: Kaydedilmiş dil tercihi bulundu: \(savedLanguage)")
            initialLanguage = savedLanguage
        } else {
            // İlk açılış - sistem dilini algıla
            print("🆕 LanguageManager: İlk açılış tespit edildi, sistem dili algılanıyor...")
            
            let preferredLanguages = Locale.preferredLanguages
            let supportedLanguages = ["tr", "en", "ja", "de", "ms", "th"] // Uygulamanın desteklediği diller
            
            print("🌍 LanguageManager: Sistem dili algılama başlatıldı")
            print("🌍 LanguageManager: Kullanıcının tercih ettiği diller: \(preferredLanguages.prefix(3))")
            
            var systemLanguage = "en" // Varsayılan
            
            // Kullanıcının tercih ettiği diller arasından desteklenen ilkini bul
            for preferredLang in preferredLanguages {
                let languageCode = String(preferredLang.prefix(2))
                print("🌍 LanguageManager: Kontrol edilen dil kodu: \(languageCode)")
                if supportedLanguages.contains(languageCode) {
                    print("✅ LanguageManager: Desteklenen dil bulundu: \(languageCode)")
                    systemLanguage = languageCode
                    break
                }
            }
            
            if systemLanguage == "en" {
                print("⚠️ LanguageManager: Desteklenen dil bulunamadı, varsayılan İngilizce kullanılacak")
            }
            
            initialLanguage = systemLanguage
            // İlk açılışta kullanıcı tercihini kaydet
            UserDefaults.standard.set(systemLanguage, forKey: "appLanguage")
            print("💾 LanguageManager: Sistem dili kaydedildi: \(systemLanguage)")
        }
        
        // Tüm property'leri başlat
        self.currentLanguage = initialLanguage
        self.currentLocale = Locale(identifier: initialLanguage)
        print("✅ LanguageManager: Başlatma tamamlandı. Aktif dil: \(initialLanguage)")
        
        updateLocale()
        
        // DEBUG: Schedule descriptions test (devre dışı - performance sorunları)
        // DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        //     SleepScheduleService.shared.debugScheduleDescriptions()
        // }
    }
    
    /// Dil ayarını değiştirir ve tüm uygulamayı günceller
    func changeLanguage(to language: String) {
        print("🔄 LanguageManager: Dil değiştiriliyor: \(currentLanguage) -> \(language)")
        currentLanguage = language
        print("✅ LanguageManager: Dil değişikliği tamamlandı: \(language)")
    }
    
    /// Locale'i günceller
    private func updateLocale() {
        let localeIdentifier: String
        switch currentLanguage {
        case "tr":
            localeIdentifier = "tr_TR"
        case "de":
            localeIdentifier = "de_DE"
        case "ja":
            localeIdentifier = "ja_JP"
        case "ms":
            localeIdentifier = "ms_MY"
        case "th":
            localeIdentifier = "th_TH"
        default:
            localeIdentifier = "en_US"
        }
        currentLocale = Locale(identifier: localeIdentifier)
    }
    
    /// Mevcut dilde lokalize edilmiş string döndürür
    func localizedString(_ key: String, tableName: String? = nil, fallback: String? = nil) -> String {
        let localized = NSLocalizedString(key, tableName: tableName, bundle: Bundle.appBundle, value: "", comment: "")
        
        // Eğer çeviri bulunamazsa NSLocalizedString key'in kendisini döner.
        // Bu durumda, fallback değerini kullanalım.
        if localized == key {
            return fallback ?? key
        }
        
        return localized
    }
    
    /// LocalizedStringKey için custom implementation
    func localizedStringKey(_ key: String, tableName: String? = nil) -> String {
        return localizedString(key, tableName: tableName)
    }
}

/// SwiftUI ViewModifier to apply language globally
struct LanguageEnvironmentModifier: ViewModifier {
    @ObservedObject private var languageManager = LanguageManager.shared
    
    func body(content: Content) -> some View {
        content
            .environment(\.locale, languageManager.currentLocale)
            .id(languageManager.currentLanguage) // Force view recreation on language change
    }
}

extension View {
    /// Dil ortamını uygular
    func withLanguageEnvironment() -> some View {
        self.modifier(LanguageEnvironmentModifier())
    }
} 
