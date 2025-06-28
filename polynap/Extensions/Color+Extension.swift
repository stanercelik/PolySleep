import SwiftUI

extension Color {
    // Temel Eylemler
    static let appPrimary = Color("PrimaryColor")
    static let appPrimaryVariant = Color("PrimaryVariantColor")
    static let appSecondary = Color("SecondaryColor")
    static let appSecondaryVariant = Color("SecondaryVariantColor")

    // Arka Planlar ve Yüzeyler
    static let appBackground = Color("BackgroundColor")
    static let appCardBackground = Color("CardBackground")
    static let appElevatedSurface = Color("ElevatedSurfaceColor")
    static let appSecondaryBackground = Color("ElevatedSurfaceColor") // Secondary background for buttons
    static let appBorder = Color("BorderColor")
    static let appOverlay = Color("OverlayColor")

    // Metin Renkleri
    static let appTextOnPrimary = Color("TextOnPrimaryColor")
    static let appText = Color("TextColor")
    static let appTextSecondary = Color("SecondaryTextColor")
    static let appSecondaryText = Color("SecondaryTextColor") // Alias for consistency
    static let appTextTertiary = Color("TextTertiaryColor")

    // Durum Renkleri
    static let appSuccess = Color("SuccessColor")
    static let appWarning = Color("WarningColor")
    static let appError = Color("ErrorColor")
    static let appInfo = Color("InfoColor")

    // Grafik Renkleri
    static let appGraphSleepMain = Color("GraphSleepMainColor")
    static let appGraphNap = Color("GraphNapColor")
    static let appGraphGoalLine = Color("GraphGoalLineColor")

    // Diğer Renkler
    static let appDisabled = Color("DisabledColor")
    static let appAccent = Color("AccentColor") // Önceden AccentColor.colorset olarak adlandırılmıştı
}
