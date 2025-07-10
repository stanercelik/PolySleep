import SwiftUI

/// Dil değişikliğinde otomatik güncellenen Text component'i
struct LocalizedText: View {
    let key: String
    let tableName: String?
    
    @EnvironmentObject private var languageManager: LanguageManager
    
    init(_ key: String, tableName: String? = nil) {
        self.key = key
        self.tableName = tableName
    }
    
    var body: some View {
        Text(languageManager.localizedString(key, tableName: tableName))
    }
}

/// Convenience extension for easier usage
extension LocalizedText {
    init(_ key: LocalizedStringKey) {
        self.key = String(describing: key)
        self.tableName = nil
    }
}

/// Helper function to get localized string
func L(_ key: String, tableName: String? = nil, fallback: String? = nil) -> String {
    return LanguageManager.shared.localizedString(key, tableName: tableName, fallback: fallback)
}

/// Macro-style helper for table-specific localizations
func L(_ key: String, table: String, fallback: String? = nil) -> String {
    return LanguageManager.shared.localizedString(key, tableName: table, fallback: fallback)
} 