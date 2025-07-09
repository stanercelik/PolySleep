import SwiftUI
import WatchKit
import PolyNapShared
import SwiftData

struct MainWatchView: View {
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    @StateObject private var mainViewModel = WatchMainViewModel()
    @StateObject private var adaptationViewModel = AdaptationViewModel()
    @StateObject private var sleepEntryViewModel = SleepEntryViewModel()
    
    var body: some View {
        TabView {
            // Sayfa 1: Current Schedule (Ana Program)
            CurrentScheduleView(viewModel: mainViewModel)
                .tabItem {
                    Image(systemName: "moon.fill")
                    Text("Program")
                }
                .tag(0)
            
            // Sayfa 2: Adaptation Progress (Adaptasyon İlerlemesi)  
            AdaptationProgressView(viewModel: adaptationViewModel)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Adaptasyon")
                }
                .tag(1)
            
            // Sayfa 3: Quick Sleep Entry (Hızlı Uyku Girişi)
            QuickSleepEntryView(viewModel: sleepEntryViewModel)
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Giriş")
                }
                .tag(2)
        }
        .onAppear {
            configureSharedRepository()
            mainViewModel.requestDataSync()
        }
    }
    
    // MARK: - Private Methods
    
    /// SharedRepository'yi Apple Watch için konfigüre eder
    private func configureSharedRepository() {
        do {
            // SharedModels için ModelContainer oluştur
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            let container = try ModelContainer(
                for: SharedUser.self, SharedUserSchedule.self, SharedSleepBlock.self, SharedSleepEntry.self,
                configurations: config
            )
            
            let modelContext = container.mainContext
            
            // SharedRepository'ye ModelContext ayarla
            SharedRepository.shared.setModelContext(modelContext)
            
            // ViewModels'e SharedRepository'nin hazır olduğunu bildir
            mainViewModel.configureSharedRepository(with: modelContext)
            
            print("✅ Apple Watch: SharedRepository başarıyla konfigüre edildi")
        } catch {
            print("❌ Apple Watch: SharedRepository konfigürasyon hatası - \(error.localizedDescription)")
            
            // Hata durumunda fallback data yükle
            mainViewModel.loadMockData()
        }
    }
}

// MARK: - Sayfa 1: Current Schedule View

struct CurrentScheduleView: View {
    @ObservedObject var viewModel: WatchMainViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Program Adı
                VStack(spacing: 4) {
                    Text(viewModel.currentSchedule?.name ?? "Program Yok")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text("Aktif Program")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Circular Sleep Chart
                if let schedule = viewModel.currentSchedule {
                    WatchCircularSleepChart(schedule: schedule)
                        .frame(width: 140, height: 140)
                } else {
                    // Placeholder için boş chart
                    Circle()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 20)
                        .frame(width: 140, height: 140)
                        .overlay(
                            VStack {
                                Image(systemName: "moon.circle")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("Program\nYükleniyor...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        )
                }
                
                // Status ve Next Sleep Info
                statusInfoSection
                
                // Enhanced Sleep Tracking Controls
                sleepTrackingControlsSection
            }
            .padding()
        }
        .navigationTitle("Program")
    }
    
    @ViewBuilder
    private var statusInfoSection: some View {
        VStack(spacing: 8) {
            // Durum Bildirimi
            Text(viewModel.currentStatusMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Sonraki Uyku Bloğu
            if let nextSleep = viewModel.nextSleepTime {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("Sonraki: \(nextSleep)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Sleep Session Timer
            if case .sleeping = viewModel.sleepTrackingState {
                VStack(spacing: 4) {
                    Text("Uyku Süresi")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.sleepSessionTimer)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .monospacedDigit()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    @ViewBuilder 
    private var sleepTrackingControlsSection: some View {
        VStack(spacing: 12) {
            // Ana sleep tracking butonu
            sleepActionButton
            
            // Rating section (sadece rating modunda göster)
            if viewModel.isRatingMode {
                sleepRatingSection
            }
            
            // Sync status indicator
            syncStatusIndicator
        }
    }
    
    @ViewBuilder
    private var sleepActionButton: some View {
        Button(action: {
            viewModel.toggleSleepState()
        }) {
            HStack(spacing: 8) {
                Image(systemName: sleepButtonIcon)
                    .font(.title3)
                
                Text(sleepButtonText)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(sleepButtonColor)
            .cornerRadius(18)
        }
        .disabled(viewModel.isProcessing)
    }
    
    @ViewBuilder
    private var sleepRatingSection: some View {
        VStack(spacing: 12) {
            Text("Uyku Kalitesi")
                .font(.caption)
                .fontWeight(.medium)
            
            // Star rating
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Button(action: {
                        viewModel.setSleepRating(star)
                    }) {
                        Image(systemName: star <= viewModel.currentRating ? "star.fill" : "star")
                            .font(.system(size: 18))
                            .foregroundColor(star <= viewModel.currentRating ? .yellow : .gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Rating confirmation
            if viewModel.currentRating > 0 {
                Button("Kaydet") {
                    viewModel.confirmSleepRating()
                }
                .font(.caption)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .background(Color.blue)
                .cornerRadius(14)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var syncStatusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(viewModel.syncStatus.color)
                .frame(width: 6, height: 6)
            
            Text(viewModel.syncStatus.message)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Computed Properties
    
    private var sleepButtonIcon: String {
        switch viewModel.sleepTrackingState {
        case .idle:
            return "moon.fill"
        case .sleeping:
            return "sun.max.fill"
        case .waitingForRating:
            return "star.fill"
        default:
            return "moon.fill"
        }
    }
    
    private var sleepButtonText: String {
        switch viewModel.sleepTrackingState {
        case .idle:
            return "Uyku Başlat"
        case .sleeping:
            return "Uyku Bitir"
        case .waitingForRating:
            return "Değerlendirme"
        default:
            return "Uyku Başlat"
        }
    }
    
    private var sleepButtonColor: Color {
        switch viewModel.sleepTrackingState {
        case .idle:
            return .blue
        case .sleeping:
            return .orange
        case .waitingForRating:
            return .green
        default:
            return .blue
        }
    }
}

// MARK: - Sayfa 2: Adaptation Progress View

struct AdaptationProgressView: View {
    @ObservedObject var viewModel: AdaptationViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Adaptasyon Fazı Header
                phaseHeaderSection
                
                // İlerleme Çubuğu
                progressBarSection
                
                // Kalan Süre veya Tamamlanma Durumu
                remainingTimeSection
                
                // Faz Açıklaması
                phaseDescriptionSection
            }
            .padding()
        }
        .navigationTitle("Adaptasyon")
    }
    
    @ViewBuilder
    private var phaseHeaderSection: some View {
        VStack(spacing: 8) {
            Text("Adaptasyon Fazı")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(viewModel.currentPhaseDescription)
                .font(.caption)
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private var progressBarSection: some View {
        VStack(spacing: 8) {
            // İlerleme Çubuğu
            if let progress = viewModel.adaptationProgress {
                AdaptationProgressBar(
                    progress: progress.progressPercentage,
                    currentPhase: progress.currentPhase,
                    totalPhases: progress.totalPhases
                )
                
                // Gün Bilgisi
                HStack {
                    Text("Gün \(progress.daysSinceStart)")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(progress.estimatedTotalDays) Gün")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                // Placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 8)
            }
        }
    }
    
    @ViewBuilder
    private var remainingTimeSection: some View {
        if let progress = viewModel.adaptationProgress {
            if !progress.isCompleted {
                VStack(spacing: 4) {
                    Text("Kalan Süre")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(progress.remainingDays) Gün")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Tamamlandı!")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    @ViewBuilder
    private var phaseDescriptionSection: some View {
        Text(viewModel.phaseDescription)
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }
}

// MARK: - Sayfa 3: Quick Sleep Entry View

struct QuickSleepEntryView: View {
    @ObservedObject var viewModel: SleepEntryViewModel
    @State private var selectedQuality: Int = 3
    @State private var selectedEmoji: String = "😴"
    
    private let qualityEmojis = ["😩", "😴", "😊", "😃", "🤩"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Emoji Display
                emojiDisplaySection
                
                // Star Rating
                starRatingSection
                
                // Save Button
                saveButtonSection
                
                // Last Entry Info
                lastEntrySection
            }
            .padding()
        }
        .navigationTitle("Uyku Girişi")
        .onChange(of: selectedQuality) { _, quality in
            selectedEmoji = qualityEmojis[quality - 1]
        }
    }
    
    @ViewBuilder
    private var emojiDisplaySection: some View {
        VStack(spacing: 8) {
            Text("Uyku Kalitesi")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(selectedEmoji)
                .font(.system(size: 40))
                .scaleEffect(1.2)
        }
    }
    
    @ViewBuilder
    private var starRatingSection: some View {
        VStack(spacing: 8) {
            // Star Rating
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Button(action: {
                        selectedQuality = star
                        // Haptic feedback
                        WKInterfaceDevice.current().play(.click)
                    }) {
                        Image(systemName: star <= selectedQuality ? "star.fill" : "star")
                            .font(.system(size: 24))
                            .foregroundColor(star <= selectedQuality ? .yellow : .gray)
                            .scaleEffect(star == selectedQuality ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedQuality)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Quality Description
            Text(qualityDescription(for: selectedQuality))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private var saveButtonSection: some View {
        Button(action: {
            viewModel.saveSleepEntry(
                quality: selectedQuality,
                emoji: selectedEmoji
            )
        }) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Kaydet")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(Color.blue)
            .cornerRadius(18)
        }
        .disabled(viewModel.isSaving)
    }
    
    @ViewBuilder
    private var lastEntrySection: some View {
        if let lastEntry = viewModel.lastSleepEntry {
            VStack(spacing: 4) {
                Text("Son Kayıt")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Text(lastEntry.emoji ?? "😴")
                        .font(.title3)
                    
                    Text("\(lastEntry.rating)/5")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text(lastEntry.date, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 8)
        }
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

// MARK: - Watch Components

/// Watch için optimize edilmiş CircularSleepChart
struct WatchCircularSleepChart: View {
    let schedule: SharedUserSchedule
    
    var body: some View {
        // iOS'dan CircularSleepChart'ı watch için optimize et
        Circle()
            .stroke(Color.secondary.opacity(0.3), lineWidth: 20)
            .overlay(
                VStack {
                    Image(systemName: "moon.circle")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    Text(schedule.name)
                        .font(.caption2)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
            )
    }
}

/// Watch için adaptasyon progress bar
struct AdaptationProgressBar: View {
    let progress: Double
    let currentPhase: Int
    let totalPhases: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 8)
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .blue.opacity(0.7)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Preview

#Preview {
    MainWatchView()
} 