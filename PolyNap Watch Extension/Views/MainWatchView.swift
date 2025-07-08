import SwiftUI
import WatchKit
import PolyNapShared

struct MainWatchView: View {
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    @StateObject private var viewModel = WatchMainViewModel()
    
    var body: some View {
        TabView {
            // Ana Durum Ekranı
            CurrentStatusView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "moon.fill")
                    Text("Durum")
                }
                .tag(0)
            
            // Hızlı Eylemler
            QuickActionsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Eylemler")
                }
                .tag(1)
            
            // Günlük Özet
            DailySummaryView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Özet")
                }
                .tag(2)
        }
        .onAppear {
            viewModel.startTracking()
        }
        .onDisappear {
            viewModel.stopTracking()
        }
    }
}

// MARK: - Current Status View

struct CurrentStatusView: View {
    @ObservedObject var viewModel: WatchMainViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Bağlantı Durumu
                ConnectionStatusCard()
                
                // Mevcut Uyku Bloğu
                if let currentBlock = viewModel.currentSleepBlock {
                    CurrentSleepBlockCard(block: currentBlock)
                } else {
                    NoActiveSleepCard()
                }
                
                // Sonraki Uyku Bloğu
                if let nextBlock = viewModel.nextSleepBlock {
                    NextSleepBlockCard(block: nextBlock)
                }
                
                Spacer()
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("PolyNap")
    }
}

// MARK: - Quick Actions View

struct QuickActionsView: View {
    @ObservedObject var viewModel: WatchMainViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Uyku Başlat/Bitir
                if viewModel.isSleeping {
                    Button(action: viewModel.endSleep) {
                        HStack {
                            Image(systemName: "bed.double.fill")
                            Text("Uykuyu Bitir")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                } else {
                    Button(action: viewModel.startSleep) {
                        HStack {
                            Image(systemName: "moon.zzz.fill")
                            Text("Uyku Başlat")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
                
                // Kalite Puanı Ver
                if viewModel.canRateLastSleep {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Son Uykunuzu Puanlayın")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            ForEach(1...5, id: \.self) { rating in
                                Button(action: {
                                    viewModel.rateSleep(rating: rating)
                                }) {
                                    Image(systemName: rating <= viewModel.selectedRating ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.title3)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("Eylemler")
    }
}

// MARK: - Daily Summary View

struct DailySummaryView: View {
    @ObservedObject var viewModel: WatchMainViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Günlük İstatistikler
                VStack(spacing: 8) {
                    StatisticRow(
                        title: "Toplam Uyku", 
                        value: formatDuration(viewModel.todayTotalSleep)
                    )
                    
                    StatisticRow(
                        title: "Uyku Sayısı", 
                        value: "\(viewModel.todaySleepCount)"
                    )
                    
                    StatisticRow(
                        title: "Ortalama Kalite", 
                        value: String(format: "%.1f", viewModel.todayAverageQuality)
                    )
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                // Bu Hafta Özeti
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bu Hafta")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    StatisticRow(
                        title: "Haftalık Uyku", 
                        value: formatDuration(viewModel.weekTotalSleep)
                    )
                    
                    StatisticRow(
                        title: "Hedef Tutma", 
                        value: "\(Int(viewModel.weekGoalCompletion * 100))%"
                    )
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("Özet")
    }
}

// MARK: - Supporting Views

struct ConnectionStatusCard: View {
    @StateObject private var connectivity = WatchConnectivityManager.shared
    
    var body: some View {
        HStack {
            Image(systemName: connectivity.isReachable ? "iphone" : "iphone.slash")
                .foregroundColor(connectivity.isReachable ? .green : .orange)
            
            Text(connectivity.isReachable ? "Bağlı" : "Bağlı Değil")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if let lastSync = connectivity.lastSyncDate {
                Text(lastSync, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
}

struct CurrentSleepBlockCard: View {
    let block: SharedSleepBlock
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: block.isCore ? "bed.double.fill" : "power")
                    .foregroundColor(block.isCore ? .blue : .orange)
                
                Text(block.isCore ? "Ana Uyku" : "Şekerleme")
                    .font(.headline)
                
                Spacer()
            }
            
            HStack {
                Text("\(block.startTime) - \(block.endTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(block.durationMinutes) dk")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

struct NextSleepBlockCard: View {
    let block: SharedSleepBlock
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                
                Text("Sonraki Uyku")
                    .font(.headline)
                
                Spacer()
            }
            
            HStack {
                Text("\(block.startTime) - \(block.endTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(block.isCore ? "Ana Uyku" : "Şekerleme")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

struct NoActiveSleepCard: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.circle")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("Aktif uyku bloğu yok")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

struct StatisticRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Helper Functions

private func formatDuration(_ seconds: TimeInterval) -> String {
    let hours = Int(seconds) / 3600
    let minutes = (Int(seconds) % 3600) / 60
    
    if hours > 0 {
        return "\(hours)s \(minutes)d"
    } else {
        return "\(minutes)d"
    }
}

// MARK: - Preview

#Preview {
    MainWatchView()
} 