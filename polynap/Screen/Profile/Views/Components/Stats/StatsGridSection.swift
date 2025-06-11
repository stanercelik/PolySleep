import SwiftUI

// MARK: - Stats Grid Section
struct StatsGridSection: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.appPrimary)
                
                Text(L("profile.stats.title", table: "Profile"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                // Current Streak
                StatCard(
                    icon: "flame.fill",
                    title: L("profile.stats.currentStreak", table: "Profile"),
                    value: "\(viewModel.currentStreak)",
                    subtitle: L("profile.stats.days", table: "Profile"),
                    color: .orange,
                    gradientColors: [.orange, .red]
                )
                
                // Longest Streak
                StatCard(
                    icon: "trophy.fill",
                    title: L("profile.stats.longestStreak", table: "Profile"),
                    value: "\(viewModel.longestStreak)",
                    subtitle: L("profile.stats.days", table: "Profile"),
                    color: .appSecondary,
                    gradientColors: [.appSecondary, .appAccent]
                )
                
                // Total Sessions
                StatCard(
                    icon: "moon.zzz.fill",
                    title: L("profile.stats.totalSleep", table: "Profile"),
                    value: "\(calculateTotalSessions())",
                    subtitle: L("profile.stats.sessions", table: "Profile"),
                    color: .purple,
                    gradientColors: [.purple, .blue]
                )
                
                // Success Rate
                StatCard(
                    icon: "checkmark.seal.fill",
                    title: L("profile.stats.successRate", table: "Profile"),
                    value: "\(calculateSuccessRate())%",
                    subtitle: L("profile.stats.completion", table: "Profile"),
                    color: .green,
                    gradientColors: [.green, .mint]
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private func calculateTotalSessions() -> Int {
        // Bu gerçek implementasyonla değiştirilecek
        return viewModel.currentStreak + viewModel.longestStreak
    }
    
    private func calculateSuccessRate() -> Int {
        // Bu gerçek implementasyonla değiştirilecek
        let total = calculateTotalSessions()
        if total == 0 { return 0 }
        return min(95, 70 + (total * 2))
    }
} 