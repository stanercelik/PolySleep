import SwiftUI
import WatchKit
import PolyNapShared

struct QuickSleepEntryView: View {
    @ObservedObject var viewModel: SleepEntryViewModel
    @ObservedObject var sleepTrackingService: SleepTrackingService
    @ObservedObject var statisticsService: SleepStatisticsService
    
    @State private var selectedQuality: Int = 3
    @State private var selectedEmoji: String = "😴"
    @State private var isShowingRatingView: Bool = false
    
    private let qualityEmojis = ["😩", "😪", "😐", "😊", "🤩"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Sleep Status Section
                sleepStatusSection
                
                // Sleep Action Button
                sleepActionSection
                
                // Rating Section (if needed)
                if sleepTrackingService.sleepTrackingState.canRate || isShowingRatingView {
                    ratingSection
                }
                
                // Statistics Section
                statisticsSection
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .navigationTitle("Uyku Girişi")
        .onChange(of: selectedQuality) { _, quality in
            selectedEmoji = qualityEmojis[quality - 1]
        }
        .onChange(of: sleepTrackingService.sleepTrackingState) { _, state in
            // Rating view'i göster/gizle
            if state.canRate {
                isShowingRatingView = true
            } else if case .completed = state {
                isShowingRatingView = false
            }
        }
    }
    
    @ViewBuilder
    private var sleepStatusSection: some View {
        VStack(spacing: 6) {
            // Status Icon
            Image(systemName: sleepTrackingService.sleepTrackingState.isSleeping ? "moon.zzz.fill" : "moon.fill")
                .font(.system(size: 24))
                .foregroundColor(sleepTrackingService.sleepTrackingState.isSleeping ? .blue : .secondary)
            
            // Status Text
            Text(sleepTrackingService.getCurrentStatusMessage())
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Timer (if sleeping)
            if sleepTrackingService.sleepTrackingState.isSleeping {
                Text(sleepTrackingService.sleepSessionTimer)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var sleepActionSection: some View {
        Button(action: {
            sleepTrackingService.toggleSleepState()
        }) {
            HStack(spacing: 6) {
                Image(systemName: sleepTrackingService.sleepTrackingState.isSleeping ? "stop.fill" : "play.fill")
                    .font(.system(size: 12))
                
                Text(sleepTrackingService.sleepTrackingState.isSleeping ? "Uyku Bitir" : "Uyku Başlat")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(sleepTrackingService.sleepTrackingState.isSleeping ? Color.red : Color.blue)
            .cornerRadius(18)
        }
        .disabled(sleepTrackingService.isProcessing)
        .opacity(sleepTrackingService.isProcessing ? 0.6 : 1.0)
    }
    
    @ViewBuilder
    private var ratingSection: some View {
        VStack(spacing: 8) {
            // Title
            Text("Uyku Kalitesi")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            // Emoji Display
            Text(selectedEmoji)
                .font(.system(size: 28))
                .padding(.vertical, 4)
            
            // Star Rating
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Button(action: {
                        selectedQuality = star
                        // Haptic feedback
                        WKInterfaceDevice.current().play(.click)
                    }) {
                        Image(systemName: star <= selectedQuality ? "star.fill" : "star")
                            .font(.system(size: 16))
                            .foregroundColor(star <= selectedQuality ? .yellow : .gray)
                            .scaleEffect(star == selectedQuality ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedQuality)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Quality Description
            Text(qualityDescription(for: selectedQuality))
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Confirm Button
            Button(action: {
                confirmRating()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                    Text("Onayla")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(Color.green)
                .cornerRadius(15)
            }
            .disabled(sleepTrackingService.isProcessing)
            .opacity(sleepTrackingService.isProcessing ? 0.6 : 1.0)
        }
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var statisticsSection: some View {
        VStack(spacing: 8) {
            Text("Bugün")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                // Total Sleep
                VStack(spacing: 2) {
                    Text("Toplam")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text(statisticsService.getTodayTotalSleepFormatted())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                // Sleep Count
                VStack(spacing: 2) {
                    Text("Uyku")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text("\(statisticsService.todaySleepCount)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                // Average Quality
                VStack(spacing: 2) {
                    Text("Kalite")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text(statisticsService.getAverageQualityFormatted())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func confirmRating() {
        sleepTrackingService.confirmSleepRating(rating: selectedQuality, emoji: selectedEmoji)
        
        // Reset rating state
        selectedQuality = 3
        selectedEmoji = "😴"
        isShowingRatingView = false
    }
    
    private func qualityDescription(for quality: Int) -> String {
        switch quality {
        case 1: return "Çok Kötü"
        case 2: return "Kötü"
        case 3: return "Orta"
        case 4: return "İyi"
        case 5: return "Mükemmel"
        default: return "Orta"
        }
    }
}

#Preview {
    QuickSleepEntryView(
        viewModel: SleepEntryViewModel(),
        sleepTrackingService: SleepTrackingService(),
        statisticsService: SleepStatisticsService()
    )
} 