import SwiftUI

struct CategoryFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.appPrimary : Color.appCardBackground)
            )
            .foregroundColor(isSelected ? .appTextOnPrimary : .appText)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.appPrimary : Color.clear,
                        lineWidth: isSelected ? 0 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    HStack {
        CategoryFilterChip(
            title: "All",
            icon: "square.grid.2x2",
            isSelected: true
        ) { }
        
        CategoryFilterChip(
            title: "Basics",
            icon: "book",
            isSelected: false
        ) { }
    }
    .padding()
} 