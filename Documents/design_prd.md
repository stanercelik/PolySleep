# PolySleep - Design System & UI/UX Guidelines

This document outlines the design system and UI/UX guidelines for the PolySleep app, following Apple's Human Interface Guidelines (HIG).

## 1. Design System

### 1.1 Color Palette

| Color Name | Light Mode | Dark Mode | Usage |
|------------|------------|-----------|--------|
| **AccentColor** | `#FF9800` | `#FF9800` | Primary CTAs, active toggles |
| **BackgroundColor** | `#F8F9FA` | `#121212` | Main background |
| **CardBackground** | `#FFFFFF` | `#171717` | Cards, modal surfaces |
| **PrimaryColor** | `#2196F3` | `#2196F3` | Headers, important interactions |
| **SecondaryColor** | `#4CAF50` | `#4CAF50` | Success states, positive emphasis |
| **TextColor** | `#2C2C2C` | `#FEFFFF` | Main text |
| **SecondaryTextColor** | `#6C757D` | `#BDBDBD` | Helper text, subtitles |

- All text contrasts must meet WCAG requirements (minimum 4.5:1)
- Use `AccentColor` for main CTAs
- Use `PrimaryColor` for headers and important labels

### 1.2 Typography

- **H1**: `SF Pro Rounded Bold`, 28pt
- **H2**: `SF Pro Rounded Semibold`, 22pt
- **Body**: `SF Pro Text Regular`, 16pt
- **Caption**: `SF Pro Text Light`, 14pt

Dynamic Type support is mandatory for accessibility.

### 1.3 Layout & Spacing

#### Corner Radius
- **Buttons, Cards**: 12px
- **Large Cards/Modals**: 20px
- **Circular Components**: 100% (circular)

#### Shadows
- **Light**: `0px 2px 8px rgba(0,0,0,0.1)`
- **Medium**: `0px 4px 12px rgba(0,0,0,0.15)`
- **Heavy**: `0px 8px 24px rgba(0,0,0,0.2)`

### 1.4 Animation & Interaction

#### Timing
- **Light Interactions**: 0.2s Ease-In-Out
- **Modals**: 0.3s Spring Effect
- **Screen Transitions**: Horizontal slide or smooth fade

#### Micro-interactions
- **Button Press**: Scale down to 0.95, opacity to 0.8
- **Haptic Feedback**: 
  - Success: Soft haptic
  - Error: Rigid haptic
- **Long Press Actions**: Additional action buttons

## 2. Accessibility Guidelines

### 2.1 Core Requirements
- Support Dynamic Type
- VoiceOver labels for all interactive elements
- Color blindness support (use icons/patterns with colors)
- Support system dark mode

### 2.2 Touch Targets
- Minimum touch target size: 44x44pt
- Adequate spacing between interactive elements
- Clear visual feedback on interaction

## 3. Component Library

### 3.1 Buttons
- Primary: `AccentColor` background, white text
- Secondary: Outlined with `SecondaryTextColor`
- Text-only: `PrimaryColor` text
- All buttons: 12px corner radius

### 3.2 Cards
- Background: `CardBackground`
- Corner radius: 12px or 20px based on size
- Medium shadow by default
- Padding: 16px

### 3.3 Text Fields
- Clear placeholder text
- Visual feedback on focus
- Error states with red highlight
- Helper text when needed

### 3.4 Navigation
- Tab bar with clear icons and labels
- Active state using `AccentColor`
- Consistent back button placement
- Clear hierarchical navigation

## 4. Assets Management

### 4.1 Icons
- Use SF Symbols where possible
- Custom icons should match SF Symbols style
- Consistent sizing across the app
- Support for light/dark variants

### 4.2 Images
- Store in Assets.xcassets
- Support @2x and @3x resolutions
- Optimize for size without quality loss
- Consider dark mode variants

### 4.3 App Icon
- Multiple sizes in Assets.xcassets
- Clear and recognizable at small sizes
- Follow Apple's app icon guidelines

## 5. Implementation Notes

### 5.1 SwiftUI Best Practices
- Use SwiftUI's built-in spacing system
- Implement custom ViewModifiers for repeated styles
- Create reusable components
- Use environment values for global styles

### 5.2 Performance
- Optimize image loading and caching
- Minimize view updates
- Use lazy loading for lists
- Monitor animation performance

### 5.3 Testing
- Test on multiple device sizes
- Verify dark mode appearance
- Test with different Dynamic Type sizes
- Verify VoiceOver functionality
