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
                    // 1. Schedule İsmi ve Bilgisi
                    scheduleHeaderSection
                    
                    // 2. Responsive Watch Circular Chart - telefon ile aynı tasarım
                    sleepChartSection(availableWidth: geometry.size.width)
                    
                    // 3. Sonraki Uykuya Kalan Süre + Current Time
                    nextSleepSection
                    
                    // 4. Sync Status ve Additional Info
                    syncStatusSection
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Program")
        .onAppear {
            viewModel.requestDataSync()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.requestDataSync()
            }
        }
    }
    
    // MARK: - Schedule Header Section
    @ViewBuilder
    private var scheduleHeaderSection: some View {
        VStack(spacing: 4) {
            Text(viewModel.currentSchedule?.name ?? "Program Yükleniyor...")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            HStack(spacing: 8) {
                if let schedule = viewModel.currentSchedule {
                    Text("\(schedule.totalSleepHours ?? 0, specifier: "%.1f")s")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 2, height: 2)
                    
                    Text("\(schedule.sleepBlocks?.count ?? 0) blok")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Sleep Chart Section - Responsive
    @ViewBuilder
    private func sleepChartSection(availableWidth: CGFloat) -> some View {
        VStack(spacing: 8) {
            if let schedule = viewModel.currentSchedule {
                // Responsive chart size based on screen width
                let chartSize: WatchChartSize = {
                    if availableWidth < 150 {
                        return .small
                    } else if availableWidth < 180 {
                        return .medium
                    } else {
                        return .large
                    }
                }()
                
                let frameSize = min(availableWidth - 32, chartSize.radius * 2 + chartSize.strokeWidth + 32)
                
                WatchCircularSleepChart(schedule: schedule, chartSize: chartSize)
                    .frame(width: frameSize, height: frameSize)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.02))
                            .frame(width: frameSize + 8, height: frameSize + 8)
                    )
            } else {
                // Enhanced loading placeholder
                let placeholderSize = min(availableWidth - 32, 140)
                
                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)]),
                                center: .center
                            ),
                            lineWidth: 16
                        )
                        .frame(width: placeholderSize, height: placeholderSize)
                        .rotationEffect(.degrees(45))
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: UUID())
                    
                    VStack(spacing: 4) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(0.6)
                        
                        Text("Senkronize ediliyor...")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(width: placeholderSize, height: placeholderSize)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
    
    // MARK: - Next Sleep Section
    @ViewBuilder
    private var nextSleepSection: some View {
        VStack(spacing: 8) {
            if let nextSleep = viewModel.nextSleepTime {
                VStack(spacing: 4) {
                    Text("Sonraki Uyku")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                        
                        Text(nextSleep)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            } else {
                VStack(spacing: 4) {
                    Text("Sonraki Uyku")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("Bilgi yükleniyor...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            
            // Status Message
            if !viewModel.currentStatusMessage.isEmpty {
                Text(viewModel.currentStatusMessage)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
    
    // MARK: - Sync Status Section
    @ViewBuilder
    private var syncStatusSection: some View {
        VStack(spacing: 6) {
            // Current Time Display
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
                
                Text(currentTimeString)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 0.5)
                    )
            )
            
            // Sync Status Indicator
            HStack(spacing: 4) {
                syncStatusIcon
                    .font(.system(size: 8))
                
                Text(syncStatusText)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.08))
            )
        }
        .frame(maxWidth: .infinity)
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
            // Timer for current time updates
        }
    }
    
    // MARK: - Helper Properties
    
    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    @ViewBuilder
    private var syncStatusIcon: some View {
        if viewModel.currentSchedule != nil {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        } else {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(.orange)
        }
    }
    
    private var syncStatusText: String {
        if viewModel.currentSchedule != nil {
            return "Senkronize"
        } else {
            return "Senkronize ediliyor..."
        }
    }
}

#Preview {
    CurrentScheduleView(viewModel: WatchMainViewModel())
} 