import SwiftUI
import WatchKit
import PolyNapShared

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
            mainViewModel.requestDataSync()
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
        }
    }
}

// MARK: - Sayfa 2: Adaptation Progress View (Placeholder)

struct AdaptationProgressView: View {
    @ObservedObject var viewModel: AdaptationViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Placeholder content for Milestone 2.2
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("Adaptasyon İlerlemesi")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Milestone 2.2'de implement edilecek")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Adaptasyon")
    }
}

// MARK: - Sayfa 3: Quick Sleep Entry View (Placeholder)

struct QuickSleepEntryView: View {
    @ObservedObject var viewModel: SleepEntryViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Placeholder content for Milestone 2.3
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    
                    Text("Hızlı Uyku Girişi")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Milestone 2.3'te implement edilecek")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Uyku Girişi")
    }
}

// MARK: - WatchCircularSleepChart Component

/// Watch için optimize edilmiş CircularSleepChart - iOS'tan adapt edilmiş
struct WatchCircularSleepChart: View {
    let schedule: SharedUserSchedule
    let textOpacity: Double
    let isEditing: Bool
    let chartSize: WatchCircularChartSize
    @Environment(\.colorScheme) var colorScheme

    private var circleRadius: CGFloat { chartSize.radius }
    private var strokeWidth: CGFloat { chartSize.strokeWidth }
    private let hourMarkers = [0, 6, 12, 18] // Watch için sadece ana saatler

    init(
        schedule: SharedUserSchedule,
        textOpacity: Double = 1.0,
        isEditing: Bool = false,
        chartSize: WatchCircularChartSize = .small
    ) {
        self.schedule = schedule
        self.textOpacity = textOpacity
        self.isEditing = isEditing
        self.chartSize = chartSize
    }

    var body: some View {
        GeometryReader { geometry in
            let safeWidth = max(100, geometry.size.width.isNaN || geometry.size.width.isInfinite ? 140 : geometry.size.width)
            let safeHeight = max(100, geometry.size.height.isNaN || geometry.size.height.isInfinite ? 140 : geometry.size.height)
            let size = min(safeWidth, safeHeight)
            let center = CGPoint(x: size / 2, y: size / 2)
            
            ZStack {
                backgroundCircle(center: center, size: size)
                sleepBlocksView(center: center, size: size)
                hourTickMarks(center: center, size: size)
                    .opacity(textOpacity)
                hourMarkersView(center: center, size: size)
                    .opacity(textOpacity)
                innerTimeLabelsView(center: center, size: size)
                    .opacity(textOpacity)
            }
            .frame(width: size, height: size)
            .position(x: safeWidth / 2, y: safeHeight / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.easeInOut(duration: 0.3), value: textOpacity)
    }
    
    // MARK: - Chart Components
    
    private func backgroundCircle(center: CGPoint, size: CGFloat) -> some View {
        Circle()
            .stroke(Color.secondary.opacity(0.2), lineWidth: strokeWidth)
            .frame(width: circleRadius * 2, height: circleRadius * 2)
            .position(center)
    }
    
    private func hourTickMarks(center: CGPoint, size: CGFloat) -> some View {
        ZStack {
            // Watch için sadece ana saatlerde tick marks
            ForEach([0, 6, 12, 18], id: \.self) { hour in
                createTickMark(for: hour, center: center)
            }
        }
    }
    
    private func createTickMark(for hour: Int, center: CGPoint) -> some View {
        let angle = Double(hour) * (360.0 / 24.0) - 90
        let outerRadius = circleRadius + strokeWidth / 2
        let innerRadius = circleRadius - strokeWidth / 2
        
        let startX = center.x + outerRadius * cos(angle * .pi / 180)
        let startY = center.y + outerRadius * sin(angle * .pi / 180)
        let endX = center.x + innerRadius * cos(angle * .pi / 180)
        let endY = center.y + innerRadius * sin(angle * .pi / 180)
        
        return Path { path in
            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: endX, y: endY))
        }
        .stroke(Color.secondary.opacity(0.4), lineWidth: 2)
    }
    
    private func hourMarkersView(center: CGPoint, size: CGFloat) -> some View {
        ZStack {
            ForEach(hourMarkers, id: \.self) { hour in
                hourMarkerLabel(for: hour, center: center)
            }
        }
    }
    
    private func hourMarkerLabel(for hour: Int, center: CGPoint) -> some View {
        let angle = Double(hour) * (360.0 / 24.0) - 90
        let labelRadius = circleRadius + strokeWidth / 2 + 12
        let xPosition = center.x + labelRadius * cos(angle * .pi / 180)
        let yPosition = center.y + labelRadius * sin(angle * .pi / 180)
        
        return Text(String(format: "%02d", hour))
            .font(.system(size: 8, weight: .medium))
            .foregroundColor(.secondary)
            .position(x: xPosition, y: yPosition)
    }
    
    private func sleepBlocksView(center: CGPoint, size: CGFloat) -> some View {
        ZStack {
            if let sleepBlocks = schedule.sleepBlocks {
                ForEach(Array(sleepBlocks.enumerated()), id: \.offset) { index, block in
                    sleepBlockArc(for: block, center: center)
                }
            }
        }
    }
    
    @ViewBuilder
    private func sleepBlockArc(for block: SharedSleepBlock, center: CGPoint) -> some View {
        if let startTime = timeComponents(from: block.startTime) {
            let startAngle = angleForTime(hour: startTime.hour, minute: startTime.minute)
            let durationHours = Double(block.durationMinutes) / 60.0
            let endAngle = startAngle + (durationHours * (360.0 / 24.0))
            
            Path { path in
                path.addArc(
                    center: center,
                    radius: circleRadius,
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(endAngle),
                    clockwise: false
                )
            }
            .stroke(block.isCore ? Color.blue : Color.orange, lineWidth: strokeWidth)
            .opacity(0.85)
        }
    }
    
    // MARK: - Time Labels
    
    private func innerTimeLabelsView(center: CGPoint, size: CGFloat) -> some View {
        ZStack {
            if let sleepBlocks = schedule.sleepBlocks {
                ForEach(Array(sleepBlocks.enumerated()), id: \.offset) { index, block in
                    timeLabel(for: block, center: center)
                }
            }
        }
    }
    
    @ViewBuilder
    private func timeLabel(for block: SharedSleepBlock, center: CGPoint) -> some View {
        if let labelData = generateLabelData(for: block, center: center) {
            Group {
                if labelData.isVertical {
                    // Dikey layout - sağ/sol tarafta
                    VStack(spacing: 1) {
                        Text(labelData.startTimeStr)
                            .font(.system(size: 7, weight: .semibold))
                        Text(labelData.endTimeStr)
                            .font(.system(size: 7, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.black.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            )
                    )
                    .position(x: labelData.xPosition, y: labelData.yPosition)
                } else {
                    // Yatay layout - üst/alt tarafta
                    HStack(spacing: 1) {
                        Text(labelData.startTimeStr)
                            .font(.system(size: 7, weight: .semibold))
                        Text("-")
                            .font(.system(size: 6, weight: .medium))
                        Text(labelData.endTimeStr)
                            .font(.system(size: 7, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.black.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            )
                    )
                    .position(x: labelData.xPosition, y: labelData.yPosition)
                }
            }
        } else {
            EmptyView()
        }
    }
    
    private struct LabelData {
        let startTimeStr: String
        let endTimeStr: String
        let isVertical: Bool
        let isLongBlock: Bool
        let xPosition: CGFloat
        let yPosition: CGFloat
    }
    
    private func generateLabelData(for block: SharedSleepBlock, center: CGPoint) -> LabelData? {
        guard let startTime = timeComponents(from: block.startTime) else {
            return nil
        }
        
        let endTime = calculateEndTime(startTime: startTime, duration: block.durationMinutes)
        
        // Başlangıç ve bitiş açıları
        let startAngle = angleForTime(hour: startTime.hour, minute: startTime.minute)
        let endAngle = angleForTime(hour: endTime.hour, minute: endTime.minute)
        
        // Gece yarısını geçen uyku bloklarını doğru şekilde hesapla
        var adjustedEndAngle = endAngle
        if endAngle < startAngle {
            adjustedEndAngle = endAngle + 360
        }
        
        // Bloğun ortasında etiket göster
        let midAngle = (startAngle + adjustedEndAngle) / 2
        
        // Açıyı normalize et
        let normalizedAngle = normalizeAngle(midAngle)
        
        // Watch için kompakt etiket yönü
        let isVertical = (normalizedAngle >= 315 || normalizedAngle <= 45) || (normalizedAngle >= 135 && normalizedAngle <= 225)
        
        // Watch için optimize edilmiş radius
        let isLongBlock = block.durationMinutes > 90
        let radius = circleRadius - strokeWidth / 2 - (isLongBlock ? 6 : 10)
        let xPosition = center.x + radius * cos(midAngle * .pi / 180)
        let yPosition = center.y + radius * sin(midAngle * .pi / 180)
        
        let startTimeStr = String(format: "%02d:%02d", startTime.hour, startTime.minute)
        let endTimeStr = String(format: "%02d:%02d", endTime.hour, endTime.minute)
        
        return LabelData(
            startTimeStr: startTimeStr,
            endTimeStr: endTimeStr,
            isVertical: isVertical,
            isLongBlock: isLongBlock,
            xPosition: xPosition,
            yPosition: yPosition
        )
    }
    
    private func normalizeAngle(_ angle: Double) -> Double {
        var normalizedAngle = angle
        while normalizedAngle < 0 {
            normalizedAngle += 360
        }
        while normalizedAngle >= 360 {
            normalizedAngle -= 360
        }
        return normalizedAngle
    }
    
    private func calculateEndTime(startTime: (hour: Int, minute: Int), duration: Int) -> (hour: Int, minute: Int) {
        let totalMinutes = startTime.hour * 60 + startTime.minute + duration
        let hour = (totalMinutes / 60) % 24
        let minute = totalMinutes % 60
        return (hour: hour, minute: minute)
    }

    // MARK: - Helper Functions
    
    private func timeComponents(from timeString: String) -> (hour: Int, minute: Int)? {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return nil
        }
        return (hour, minute)
    }
    
    private func angleForTime(hour: Int, minute: Int) -> Double {
        let totalMinutes = Double(hour * 60 + minute)
        return (totalMinutes / (24 * 60)) * 360 - 90
    }
}

// MARK: - Watch Chart Size Enum

enum WatchCircularChartSize {
    case small
    case medium
    
    var radius: CGFloat {
        switch self {
        case .small: return 60    // Watch için küçültülmüş
        case .medium: return 70   // Watch için küçültülmüş
        }
    }
    
    var strokeWidth: CGFloat {
        switch self {
        case .small: return 16    // Watch için küçültülmüş
        case .medium: return 20   // Watch için küçültülmüş
        }
    }
}

// MARK: - Placeholder ViewModels

@MainActor
class AdaptationViewModel: ObservableObject {
    // Milestone 2.2'de implement edilecek
    @Published var adaptationProgress: SharedAdaptationProgress?
    @Published var currentPhaseDescription: String = ""
    @Published var phaseDescription: String = ""
    
    init() {
        // Placeholder initialization
    }
}

@MainActor  
class SleepEntryViewModel: ObservableObject {
    // Milestone 2.3'te implement edilecek
    @Published var lastSleepEntry: SharedSleepEntry?
    @Published var isSaving: Bool = false
    
    init() {
        // Placeholder initialization
    }
}

// MARK: - Preview

#Preview {
    MainWatchView()
} 