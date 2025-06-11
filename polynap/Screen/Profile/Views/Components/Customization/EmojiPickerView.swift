import SwiftUI

// MARK: - Emoji Picker View
struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let emojis: [String] = [
        "😴", "💤", "🌙", "⭐", "🛌", "🌃", "🌌", "💫", "✨", "🌠",
        "🔋", "⚡", "🌟", "💎", "🎯", "🚀", "💪", "🏆", "🎉", "🔥",
        "❄️", "🌊", "🍃", "🌸", "🌺", "🌻", "🌈", "☀️", "🌤️", "⛅"
    ]
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 6)
    
    var body: some View {
        NavigationStack {
            VStack(spacing: PSSpacing.lg) {
                // Seçili emoji gösterimi
                selectedEmojiSection
                
                // Emoji grid
                emojiGridSection
                
                // Save button
                saveButtonSection
            }
            .padding(.vertical, PSSpacing.lg)
            .background(Color.appBackground)
            .navigationTitle(L("profile.emoji.picker.title", table: "Profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("general.cancel", table: "Profile")) {
                        dismiss()
                    }
                    .foregroundColor(.appPrimary)
                }
            }
        }
    }
    
    @ViewBuilder
    private var selectedEmojiSection: some View {
        VStack(spacing: PSSpacing.md) {
            Text(L("profile.emoji.selected", table: "Profile"))
                .font(.headline)
                .foregroundColor(.appText)
            
            Text(selectedEmoji)
                .font(.system(size: 60))
                .padding(PSSpacing.lg)
                .background(
                    Circle()
                        .fill(Color.appPrimary.opacity(0.1))
                )
        }
    }
    
    @ViewBuilder
    private var emojiGridSection: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: PSSpacing.md) {
                ForEach(emojis, id: \.self) { emoji in
                    emojiButton(for: emoji)
                }
            }
            .padding(.horizontal, PSSpacing.lg)
        }
    }
    
    @ViewBuilder
    private func emojiButton(for emoji: String) -> some View {
        let isSelected = selectedEmoji == emoji
        
        Button(action: {
            selectedEmoji = emoji
        }) {
            Text(emoji)
                .font(.system(size: 32))
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(isSelected ? Color.appPrimary.opacity(0.2) : Color.clear)
                )
                .overlay(
                    Circle()
                        .stroke(
                            isSelected ? Color.appPrimary : Color.clear,
                            lineWidth: 2
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var saveButtonSection: some View {
        PSPrimaryButton(
            L("general.save", table: "Profile")
        ) {
            onSave()
            dismiss()
        }
        .frame(height: 50)
        .padding(.horizontal, PSSpacing.lg)
    }
} 