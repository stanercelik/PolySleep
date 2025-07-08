import SwiftUI
import WatchKit

struct MainWatchView: View {
    @State private var currentTime = Date()
    
    var body: some View {
        TabView {
            // Ana Durum Ekranı
            CurrentStatusView()
                .tabItem {
                    Image(systemName: "moon.fill")
                    Text("Durum")
                }
                .tag(0)
            
            // Hızlı Eylemler
            QuickActionsView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Eylemler")
                }
                .tag(1)
            
            // Günlük Özet
            DailySummaryView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Özet")
                }
                .tag(2)
        }
        .onAppear {
            startTimeUpdates()
        }
    }
    
    private func startTimeUpdates() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
    }
}

// MARK: - Current Status View

struct CurrentStatusView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // PolyNap Logo/Başlık
                VStack {
                    Text("🌙")
                        .font(.largeTitle)
                    Text("PolyNap")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.top)
                
                // Bağlantı Durumu
                ConnectionStatusCard()
                
                // Bir sonraki uyku
                NextSleepCard()
                
                Spacer()
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("Durum")
    }
}

// MARK: - Quick Actions View

struct QuickActionsView: View {
    @State private var isSleeping = false
    @State private var selectedRating = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Hızlı Eylemler")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                // Uyku Başlat/Bitir
                if isSleeping {
                    Button(action: {
                        isSleeping = false
                    }) {
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
                    Button(action: {
                        isSleeping = true
                    }) {
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
                
                // Kalite Puanı
                VStack(alignment: .leading, spacing: 8) {
                    Text("Uyku Kalitesi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ForEach(1...5, id: \.self) { rating in
                            Button(action: {
                                selectedRating = rating
                            }) {
                                Image(systemName: rating <= selectedRating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.title3)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("Eylemler")
    }
}

// MARK: - Daily Summary View

struct DailySummaryView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Günlük Özet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                // Günlük İstatistikler
                VStack(spacing: 8) {
                    StatisticRow(title: "Toplam Uyku", value: "6.5s")
                    StatisticRow(title: "Uyku Sayısı", value: "4")
                    StatisticRow(title: "Ortalama Kalite", value: "4.2")
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                // Bu Hafta Özeti
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bu Hafta")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    StatisticRow(title: "Haftalık Uyku", value: "45.5s")
                    StatisticRow(title: "Hedef Tutma", value: "87%")
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
    @State private var isConnected = false
    
    var body: some View {
        HStack {
            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(isConnected ? "iPhone Bağlı" : "iPhone Bağlantısı Yok")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            // Simüle edilmiş bağlantı durumu
            isConnected = Bool.random()
        }
    }
}

struct NextSleepCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sonraki Uyku")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Text("🌙")
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("14:30 - 15:50")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Core Sleep · 1s 20dk")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
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

// MARK: - Previews

#Preview {
    MainWatchView()
}

#Preview("Current Status") {
    CurrentStatusView()
}

#Preview("Quick Actions") {
    QuickActionsView()
}

#Preview("Daily Summary") {
    DailySummaryView()
} 