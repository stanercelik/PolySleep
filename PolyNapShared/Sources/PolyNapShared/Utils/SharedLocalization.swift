import Foundation
import SwiftUI

/// Shared localization helper for Watch app and main app
/// Helper function to get localized string in shared contexts
public func L(_ key: String, tableName: String? = nil, fallback: String? = nil) -> String {
    let bundle = Bundle.main
    let localizedString = NSLocalizedString(key, tableName: tableName, bundle: bundle, value: fallback ?? key, comment: "")
    return localizedString
}

/// Table-specific helper for better organization
public func LTable(_ key: String, table: String, fallback: String? = nil) -> String {
    return L(key, tableName: table, fallback: fallback)
}