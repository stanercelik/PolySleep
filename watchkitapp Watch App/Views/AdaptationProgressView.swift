import SwiftUI
import WatchKit
import PolyNapShared

struct AdaptationProgressView: View {
    @ObservedObject var viewModel: AdaptationViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Adaptasyon Fazı Header
                phaseHeaderSection
                
                // Yeni Adaptasyon Verisi Bölümü
                adaptationDataSection
                
                // İlerleme Çubuğu
                progressBarSection
                
                // İstatistik Kartları
                statisticsSection
                
                // Faz Açıklaması
                phaseDescriptionSection
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .navigationTitle("Adaptasyon")
    }
    
    @ViewBuilder
    private var phaseHeaderSection: some View {
        VStack(spacing: 4) {
            Text("Adaptasyon Fazı")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(viewModel.currentPhaseDescription)
                .font(.system(size: 11))
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
    
    @ViewBuilder
    private var progressBarSection: some View {
        VStack(spacing: 6) {
            // İlerleme Çubuğu
            if let progress = viewModel.adaptationProgress {
                AdaptationProgressBar(
                    progress: progress.progressPercentage,
                    currentPhase: progress.currentPhase,
                    totalPhases: progress.totalPhases
                )
                .frame(height: 6)
                
                // Gün Bilgisi
                HStack {
                    Text("Gün \(progress.daysSinceStart)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(progress.estimatedTotalDays) Gün")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            } else {
                // Placeholder
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 6)
            }
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var remainingTimeSection: some View {
        if let progress = viewModel.adaptationProgress {
            if !progress.isCompleted {
                VStack(spacing: 2) {
                    Text("Kalan Süre")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Text("\(progress.remainingDays) Gün")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                }
            } else {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    
                    Text("Tamamlandı!")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    @ViewBuilder
    private var phaseDescriptionSection: some View {
        Text(viewModel.phaseDescription)
            .font(.system(size: 10))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 6)
            .lineLimit(4)
    }
    
    @ViewBuilder
    private var adaptationDataSection: some View {
        let data = viewModel.adaptationData
        
        VStack(spacing: 8) {
            // Ana Adaptasyon Yüzdesi
            VStack(spacing: 2) {
                Text("\(data.adaptationPercentage)%")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.blue)
                
                Text("Adaptasyon")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            // Daire Grafik
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: CGFloat(data.adaptationPercentage) / 100.0)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .blue.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: data.adaptationPercentage)
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var statisticsSection: some View {
        let data = viewModel.adaptationData
        
        HStack(spacing: 8) {
            // Ortalama Rating
            statCard(
                title: "Ortalama",
                value: String(format: "%.1f", data.averageRating),
                subtitle: "⭐",
                color: .orange
            )
            
            // Son 7 Gün Entry
            statCard(
                title: "Bu Hafta",
                value: "\(data.last7DaysEntries)",
                subtitle: "uyku",
                color: .green
            )
            
            // Adaptasyon Fazı
            statCard(
                title: "Faz",
                value: "\(data.adaptationPhase)",
                subtitle: "/4",
                color: .purple
            )
        }
    }
    
    @ViewBuilder
    private func statCard(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Watch için optimize edilmiş AdaptationProgressBar
struct AdaptationProgressBar: View {
    let progress: Double
    let currentPhase: Int
    let totalPhases: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 6)
                
                // Progress
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .blue.opacity(0.7)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: geometry.size.width * CGFloat(progress), height: 6)
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
        }
        .frame(height: 6)
    }
}

#Preview {
    AdaptationProgressView(viewModel: AdaptationViewModel())
} 