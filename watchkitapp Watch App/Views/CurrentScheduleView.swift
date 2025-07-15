import SwiftUI
import WatchKit
import PolyNapShared
import Foundation

struct CurrentScheduleView: View {
    @ObservedObject var viewModel: WatchMainViewModel
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 12) {
                    // 1. Responsive Watch Circular Chart - Ana bölüm (üst)
                    sleepChartSection(availableWidth: geometry.size.width)
                    
                    // 2. Schedule Bilgileri (orta)
                    scheduleInfoSection
                    
                    // 3. Kalan Süre ve Toplam Uyku (alt)
                    timeInfoSection
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Program")
        .onAppear {
            viewModel.requestDataSync()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                viewModel.requestDataSync()
            }
        }
    }
    
    // MARK: - Schedule Info Section
    @ViewBuilder
    private var scheduleInfoSection: some View {
        VStack(spacing: 6) {
            // Program Adı
            Text(viewModel.currentSchedule?.name ?? "Program Yükleniyor...")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Program Detayları
            if let schedule = viewModel.currentSchedule, !schedule.name.isEmpty {
                HStack(spacing: 8) {
                    // Toplam Uyku Badge
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.blue)
                        Text(String(format: "%.1f sa", schedule.totalSleepHours ?? 0.0))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Blok Sayısı Badge
                    if let blockCount = viewModel.currentSchedule?.sleepBlocks?.count {
                        HStack(spacing: 4) {
                            Image(systemName: "bed.double.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                            Text("\(blockCount) blok")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(0.15), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Sleep Chart Section - Responsive
    @ViewBuilder
    private func sleepChartSection(availableWidth: CGFloat) -> some View {
        VStack(spacing: 8) {
            if let schedule = viewModel.currentSchedule {
                // Responsive chart size based on screen width
                let chartDimension: CGFloat = {
                    if availableWidth < 150 {
                        return 120
                    } else if availableWidth < 180 {
                        return 140
                    } else {
                        return 160
                    }
                }()
                
                let frameSize = min(availableWidth - 32, chartDimension + 32)
                
                WatchCircularSleepChart(schedule: schedule)
                .frame(width: frameSize, height: frameSize)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.02))
                        .frame(width: frameSize + 8, height: frameSize + 8)
                )
            } else {
                // Enhanced loading placeholder
                let placeholderSize = min(availableWidth - 32, 140)
                
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.2)
                    
                    Text("Senkronize ediliyor...")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(width: placeholderSize, height: placeholderSize)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
    
    // MARK: - Time Info Section (Sonraki Uyku ve Kalan Süre)
    @ViewBuilder
    private var timeInfoSection: some View {
        HStack(spacing: 8) {
            // Sonraki Uyku Zamanı
            VStack(spacing: 4) {
                HStack(spacing: 3) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                    Text("Sonraki")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                if !viewModel.timeUntilNextSleep.isEmpty {
                    Text(viewModel.timeUntilNextSleep)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                } else {
                    Text("--:--")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            // Kalan Süre
            VStack(spacing: 4) {
                HStack(spacing: 3) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("Kalan")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Text(viewModel.timeUntilNextSleep.isEmpty ? "Hesaplanıyor" : viewModel.timeUntilNextSleep)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(.horizontal, 4)
    }
    
}

#Preview {
    CurrentScheduleView(viewModel: WatchMainViewModel())
} 