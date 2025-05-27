import SwiftUI

struct DisclaimerView: View {
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.appBackground,
                    Color.appBackground.opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 20) {
                    // Hero Header Section
                    VStack(spacing: 16) {
                        // Icon with gradient background
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue.opacity(0.8),
                                            Color.purple.opacity(0.6)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                                .shadow(
                                    color: Color.blue.opacity(0.3),
                                    radius: 12,
                                    x: 0,
                                    y: 6
                                )
                            
                            Image(systemName: "info.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text(L("disclaimer.title", table: "Profile"))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.appText)
                            
                            Text(L("disclaimer.subtitle", table: "Profile"))
                                .font(.subheadline)
                                .foregroundColor(.appTextSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 24)
                    
                    // Content Sections
                    ModernDisclaimerCard {
                        VStack(alignment: .leading, spacing: 16) {
                            // Main disclaimer section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.appPrimary.opacity(0.15))
                                            .frame(width: 32, height: 32)
                                        
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.appPrimary)
                                    }
                                    
                                    Text(L("disclaimer.general.warning", table: "Profile"))
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.appText)
                                    
                                    Spacer()
                                }
                                
                                Text(L("disclaimer.content", table: "Profile"))
                                    .font(.subheadline)
                                    .foregroundColor(.appText)
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    
                    // Medical disclaimer
                    ModernDisclaimerCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "cross.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.red)
                                }
                                
                                Text(L("disclaimer.medical", table: "Profile"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.appText)
                                
                                Spacer()
                            }
                            
                            Text(L("disclaimer.medical.content", table: "Profile"))
                                .font(.subheadline)
                                .foregroundColor(.appText)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    // Liability disclaimer
                    ModernDisclaimerCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.orange.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "shield.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.orange)
                                }
                                
                                Text(L("disclaimer.liability", table: "Profile"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.appText)
                                
                                Spacer()
                            }
                            
                            Text(L("disclaimer.liability.content", table: "Profile"))
                                .font(.subheadline)
                                .foregroundColor(.appText)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    // Contact information
                    ModernDisclaimerCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.appSecondary.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.appSecondary)
                                }
                                
                                Text(L("disclaimer.contact", table: "Profile"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.appText)
                                
                                Spacer()
                            }
                            
                            Text(L("disclaimer.contact.content", table: "Profile"))
                                .font(.subheadline)
                                .foregroundColor(.appText)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Contact button
                            Button(action: {
                                if let url = URL(string: "mailto:support@polysleep.app") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "envelope.fill")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    
                                    Text(L("disclaimer.contact.button", table: "Profile"))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.appSecondary,
                                                    Color.appSecondary.opacity(0.8)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color.appSecondary.opacity(0.3), radius: 8, x: 0, y: 4)
                                )
                            }
                            .buttonStyle(ModernContactButtonStyle())
                        }
                    }
                    
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle(L("settings.other.disclaimer", table: "Profile"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Modern Components

// Modern disclaimer card component with enhanced styling
struct ModernDisclaimerCard<Content: View>: View {
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCardBackground)
                    .overlay(
                        // Subtle border for light mode
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(colorScheme == .light ? 0.15 : 0),
                                        Color.gray.opacity(colorScheme == .light ? 0.05 : 0)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: colorScheme == .light ? 
                        Color.black.opacity(0.08) : 
                        Color.black.opacity(0.3),
                        radius: colorScheme == .light ? 12 : 16,
                        x: 0,
                        y: colorScheme == .light ? 6 : 8
                    )
            )
    }
}

struct DisclaimerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DisclaimerView()
        }
        .environmentObject(LanguageManager.shared)
    }
}
