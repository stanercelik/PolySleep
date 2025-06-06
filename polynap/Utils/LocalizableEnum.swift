import Foundation

/// Protocol for enums that can provide a localization key
public protocol LocalizableEnum: CaseIterable, RawRepresentable where RawValue == String {
    var localizedKey: String { get }
    static var tableName: String { get }
    static func printAvailableValues()
}

// Default implementation for printing available values and tableName
public extension LocalizableEnum {
    static func printAvailableValues() {
        print("\nAvailable \(String(describing: Self.self)) values:")
        Self.allCases.forEach { print("- \($0.rawValue)") }
    }
    
    static var tableName: String {
        "Onboarding"
    }
}
