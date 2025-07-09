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
                
                // İlerleme Çubuğu
                progressBarSection
                
                // Kalan Süre veya Tamamlanma Durumu
                remainingTimeSection
                
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