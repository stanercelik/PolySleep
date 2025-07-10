import SwiftUI

struct CategoryFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let category: EducationCategory?
    let action: () -> Void
    
    private var chipColor: Color {
        if let category = category {
            return category.color
        } else {
            return .appPrimary // Default color for "All" categories
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(isSelected ? chipColor : Color.appCardBackground)
            )
            .foregroundColor(isSelected ? .white : chipColor)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        chipColor.opacity(isSelected ? 0 : 0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    HStack {
        CategoryFilterChip(
            title: "All",
            icon: "square.grid.2x2",
            isSelected: true,
            category: nil
        ) { }
        
        CategoryFilterChip(
            title: "Basics",
            icon: "book",
            isSelected: false,
            category: .basics
        ) { }
        
        CategoryFilterChip(
            title: "Risks",
            icon: "exclamationmark.triangle.fill",
            isSelected: false,
            category: .risks
        ) { }
    }
    .padding()
} 