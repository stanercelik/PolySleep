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
    
    @Published var currentLanguage: String = UserDefaults.standard.string(forKey: "appLanguage") ?? "tr" {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "appLanguage")
            updateLocale()
            // Force refresh all views
            objectWillChange.send()
        }
    }
    
    @Published var currentLocale: Locale = Locale(identifier: UserDefaults.standard.string(forKey: "appLanguage") ?? "tr")
    
    private init() {
        updateLocale()
    }
    
    /// Dil ayarını değiştirir ve tüm uygulamayı günceller
    func changeLanguage(to language: String) {
        currentLanguage = language
    }
    
    /// Locale'i günceller
    private func updateLocale() {
        currentLocale = Locale(identifier: currentLanguage)
    }
    
    /// Mevcut dilde lokalize edilmiş string döndürür
    func localizedString(_ key: String, tableName: String? = nil) -> String {
        return NSLocalizedString(key, tableName: tableName, bundle: Bundle.appBundle, value: "", comment: "")
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