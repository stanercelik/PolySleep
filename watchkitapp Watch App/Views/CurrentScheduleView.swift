import SwiftUI
import WatchKit
import PolyNapShared

struct CurrentScheduleView: View {
    @ObservedObject var viewModel: WatchMainViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 1. Schedule İsmi ve Bilgisi
                scheduleHeaderSection
                
                // 2. Optimized Watch Circular Chart
                sleepChartSection
                
                // 3. Sonraki Uykuya Kalan Süre
                nextSleepSection
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .navigationTitle("Program")
        .onAppear {
            viewModel.requestDataSync()
        }
    }
    
    // MARK: - Schedule Header Section
    @ViewBuilder
    private var scheduleHeaderSection: some View {
        VStack(spacing: 6) {
            Text(viewModel.currentSchedule?.name ?? "Program Yükleniyor...")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if let schedule = viewModel.currentSchedule {
                Text("\(schedule.totalSleepHours ?? 0, specifier: "%.1f")s toplam")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Sleep Chart Section
    @ViewBuilder
    private var sleepChartSection: some View {
        VStack(spacing: 8) {
            if let schedule = viewModel.currentSchedule {
                WatchCircularSleepChart(schedule: schedule)
                    .frame(width: 140, height: 140)
            } else {
                // Loading placeholder
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 16)
                        .frame(width: 140, height: 140)
                    
                    VStack(spacing: 6) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(0.7)
                        
                        Text("Yükleniyor...")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
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
}

#Preview {
    CurrentScheduleView(viewModel: WatchMainViewModel())
} 