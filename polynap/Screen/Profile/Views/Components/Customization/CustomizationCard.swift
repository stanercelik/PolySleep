import SwiftUI

// MARK: - Customization Card
struct CustomizationCard: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    @Binding var showEmojiPicker: Bool
    @Binding var isPickingCoreEmoji: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "paintbrush.fill")
                    .font(.title2)
                    .foregroundColor(.appPrimary)
                
                Text(L("profile.customization.title", table: "Profile"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
                
                Spacer()
                
                // Premium badge
                Text("PREMIUM")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.appPrimary.opacity(0.2))
                    .foregroundColor(.appPrimary)
                    .cornerRadius(4)
            }
            
            VStack(spacing: 12) {
                // Core Sleep Emoji
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("profile.customization.coreEmoji", table: "Profile"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.appText)
                        
                        Text(L("profile.customization.coreEmoji.description", table: "Profile"))
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        isPickingCoreEmoji = true
                        showEmojiPicker = true
                    }) {
                        HStack(spacing: 8) {
                            Text(viewModel.selectedCoreEmoji)
                                .font(.title2)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.appCardBackground)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Divider()
                
                // Nap Sleep Emoji
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("profile.customization.napEmoji", table: "Profile"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.appText)
                        
                        Text(L("profile.customization.napEmoji.description", table: "Profile"))
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        isPickingCoreEmoji = false
                        showEmojiPicker = true
                    }) {
                        HStack(spacing: 8) {
                            Text(viewModel.selectedNapEmoji)
                                .font(.title2)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.appCardBackground)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(PSSpacing.lg)
        .background(Color.appCardBackground)
        .cornerRadius(PSCornerRadius.large)
        .shadow(color: .appBorder.opacity(0.3), radius: PSSpacing.xs, x: 0, y: 2)
    }
} 