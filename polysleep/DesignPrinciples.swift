import SwiftUI

// MARK: - PolySleep Design System
/**
 PolySleep Tasarım Sistemi
 Bu dosya, uygulamanın tüm UI bileşenlerinde kullanılacak tutarlı tasarım prensiplerini içerir.
 */

// MARK: - Typography Scale
enum PSTypography {
    /// H1 - Sayfa Başlığı: SF Pro Bold, 28-34pt
    static var largeTitle: Font { .largeTitle.bold() }
    
    /// H2 - Bölüm Başlığı: SF Pro Semibold, 22-24pt  
    static var title1: Font { .title.weight(.semibold) }
    
    /// H3 - Kart Başlığı: SF Pro Semibold, 18-20pt
    static var headline: Font { .headline.weight(.semibold) }
    
    /// Gövde Metni: SF Pro Regular, 16-17pt
    static var body: Font { .body }
    
    /// Alt Başlık / İkincil Metin: SF Pro Regular, 15pt
    static var subheadline: Font { .subheadline }
    
    /// Alt Metin / Açıklama: SF Pro Regular, 13-15pt
    static var caption: Font { .caption }
    
    /// Düğme Metni: SF Pro Semibold, 15-17pt
    static var button: Font { .subheadline.weight(.semibold) }
}

// MARK: - Spacing System (8pt Grid)
enum PSSpacing {
    static let xxs: CGFloat = 2      // 4pt
    static let xs: CGFloat = 4      // 4pt
    static let sm: CGFloat = 8      // 8pt
    static let md: CGFloat = 12     // 12pt
    static let lg: CGFloat = 16     // 16pt
    static let xl: CGFloat = 24     // 24pt
    static let xxl: CGFloat = 32    // 32pt
    static let xxxl: CGFloat = 48   // 48pt
}

// MARK: - Corner Radius
enum PSCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 20
    static let button: CGFloat = 28
}

// MARK: - Icon Sizes
enum PSIconSize {
    static let small: CGFloat = 16
    static let medium: CGFloat = 24
    static let large: CGFloat = 32
    static let extraLarge: CGFloat = 48
    static let headerIcon: CGFloat = 64
    static let avatar: CGFloat = 64
}

// MARK: - Card Component
struct PSCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    
    init(
        padding: CGFloat = PSSpacing.lg,
        cornerRadius: CGFloat = PSCornerRadius.large,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Primary Button
struct PSPrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let destructive: Bool
    let customBackgroundColor: Color?
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        destructive: Bool = false,
        customBackgroundColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.destructive = destructive
        self.customBackgroundColor = customBackgroundColor
        self.action = action
    }
    
    private var currentBackgroundColor: Color {
        if let customBg = customBackgroundColor {
            return customBg
        }
        return destructive ? Color.red : Color.appPrimary
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: PSSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .appTextOnPrimary))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: PSIconSize.small, weight: .semibold))
                }
                
                Text(title)
                    .font(PSTypography.button)
            }
            .foregroundColor(.appTextOnPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(currentBackgroundColor, in: RoundedRectangle(cornerRadius: PSCornerRadius.button))
        }
        .disabled(isLoading)
    }
}

// MARK: - Secondary Button
struct PSSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: PSSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: PSIconSize.small, weight: .semibold))
                }
                
                Text(title)
                    .font(PSTypography.button)
            }
            .foregroundColor(.appPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: PSCornerRadius.button)
                    .stroke(Color.appPrimary, lineWidth: 1.5)
            )
        }
    }
}

// MARK: - Tertiary Button
struct PSTertiaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: PSSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: PSIconSize.small, weight: .medium))
                }
                
                Text(title)
                    .font(PSTypography.button)
            }
            .foregroundColor(.appPrimary)
        }
    }
}

// MARK: - Icon Button
struct PSIconButton: View {
    let icon: String
    let size: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void
    
    init(
        icon: String,
        size: CGFloat = 32,
        backgroundColor: Color = Color.appPrimary.opacity(0.15),
        foregroundColor: Color = .appPrimary,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.5, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(width: size, height: size)
                .background(backgroundColor, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Badge
struct PSStatusBadge: View {
    let text: String
    let icon: String?
    let color: Color
    let backgroundColor: Color
    
    init(
        _ text: String,
        icon: String? = nil,
        color: Color = .appPrimary,
        backgroundColor: Color? = nil
    ) {
        self.text = text
        self.icon = icon
        self.color = color
        self.backgroundColor = backgroundColor ?? color.opacity(0.15)
    }
    
    var body: some View {
        HStack(spacing: PSSpacing.xs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
            }
            
            Text(text)
                .font(PSTypography.caption)
                .foregroundColor(color)
        }
        .padding(.horizontal, PSSpacing.sm)
        .padding(.vertical, PSSpacing.xs)
        .background(backgroundColor, in: Capsule())
    }
}

// MARK: - Section Header
struct PSSectionHeader: View {
    let title: String
    let icon: String
    let action: (() -> Void)?
    let actionIcon: String?
    
    init(
        _ title: String,
        icon: String,
        action: (() -> Void)? = nil,
        actionIcon: String? = nil
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.actionIcon = actionIcon
    }
    
    var body: some View {
        HStack {
            Label {
                Text(title)
                    .font(PSTypography.headline)
                    .foregroundColor(.appText)
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(.appPrimary)
            }
            
            Spacer()
            
            if let action = action, let actionIcon = actionIcon {
                PSIconButton(icon: actionIcon, action: action)
            }
        }
    }
}

// MARK: - Loading State
struct PSLoadingState: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: PSSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                .scaleEffect(1.2)
            
            if let message = message {
                Text(message)
                    .font(PSTypography.body)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

// MARK: - Empty State
struct PSEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: PSSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: PSIconSize.extraLarge))
                .foregroundColor(.appTextSecondary)
            
            VStack(spacing: PSSpacing.sm) {
                Text(title)
                    .font(PSTypography.headline)
                    .foregroundColor(.appText)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(PSTypography.body)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                PSPrimaryButton(actionTitle, action: action)
                    .frame(maxWidth: 200)
            }
        }
        .padding(PSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

// MARK: - Error State
struct PSErrorState: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?
    
    init(
        title: String = "Bir hata oluştu",
        message: String,
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: PSSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: PSIconSize.extraLarge))
                .foregroundColor(.appError)
            
            VStack(spacing: PSSpacing.sm) {
                Text(title)
                    .font(PSTypography.headline)
                    .foregroundColor(.appText)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(PSTypography.body)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let retryAction = retryAction {
                PSPrimaryButton("Tekrar Dene", icon: "arrow.clockwise", action: retryAction)
                    .frame(maxWidth: 200)
            }
        }
        .padding(PSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

// MARK: - Progress Bar
struct PSProgressBar: View {
    let progress: Double
    let height: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    
    init(
        progress: Double,
        height: CGFloat = 3,
        backgroundColor: Color = Color.appTextSecondary.opacity(0.25),
        foregroundColor: Color = .appPrimary
    ) {
        self.progress = progress
        self.height = height
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(backgroundColor)
                
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(foregroundColor)
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Animated Modifier Extensions
extension View {
    /// Standart spring animasyonu
    func psSpringAnimation() -> some View {
        self.animation(.spring(response: 0.4, dampingFraction: 0.8), value: UUID())
    }
    
    /// Standart padding
    func psPadding() -> some View {
        self.padding(PSSpacing.lg)
    }
    
    /// Shimmer loading effect
    func psShimmer(isActive: Bool) -> some View {
        self.redacted(reason: isActive ? .placeholder : [])
            .redactedShimmer(if: isActive)
    }
} 
