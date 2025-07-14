import SwiftUI
import WatchKit
import PolyNapShared

enum WatchChartSize {
    case small
    case medium
    case large
    
    var radius: CGFloat {
        switch self {
        case .small: return 50
        case .medium: return 65
        case .large: return 80
        }
    }
    
    var strokeWidth: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 20
        case .large: return 24
        }
    }
}

/// Watch için optimize edilmiş CircularSleepChart - telefon ile aynı tasarım + current time indicator
struct WatchCircularSleepChart: View {
    let schedule: SharedUserSchedule
    let chartSize: WatchChartSize
    @State private var currentTime = Date()
    @Environment(\.colorScheme) var colorScheme
    
    private var circleRadius: CGFloat { chartSize.radius }
    private var strokeWidth: CGFloat { chartSize.strokeWidth }
    private let hourMarkers = [0, 3, 6, 9, 12, 15, 18, 21]
    
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect() // Her 30 saniye güncelle
    
    init(schedule: SharedUserSchedule, chartSize: WatchChartSize = .large) {
        self.schedule = schedule
        self.chartSize = chartSize
    }
    
    var body: some View {
        GeometryReader { geometry in
            let availableSize = min(geometry.size.width, geometry.size.height)
            let labelPadding: CGFloat = 12
            let totalPadding = strokeWidth + labelPadding + 16 // 16 for label width
            let chartDiameter = availableSize - totalPadding
            let adjustedRadius = max(circleRadius, chartDiameter / 2)
            let center = CGPoint(x: availableSize / 2, y: availableSize / 2)
            
            ZStack {
                // Background circle - telefon ile aynı tasarım
                backgroundCircle(center: center, radius: adjustedRadius)
                
                // Hour tick marks - telefon ile aynı tasarım
                hourTickMarks(center: center, radius: adjustedRadius)
                
                // Sleep blocks - telefon ile aynı tasarım
                sleepBlocksView(center: center, radius: adjustedRadius)
                
                // Hour markers - telefon ile aynı tasarım
                hourMarkersView(center: center, radius: adjustedRadius, labelPadding: labelPadding)
                
                // Sleep block time labels - telefon ile aynı tasarım
                sleepBlockTimeLabels(center: center, radius: adjustedRadius)
                
                // Current time indicator - sadece saat için özel
                currentTimeIndicator(center: center, radius: adjustedRadius)
            }
            .frame(width: availableSize, height: availableSize)
        }
        .aspectRatio(1, contentMode: .fit)
        .onReceive(timer) { time in
            currentTime = time
        }
        .onAppear {
            currentTime = Date()
        }
    }
    
    // MARK: - Background Circle
    private func backgroundCircle(center: CGPoint, radius: CGFloat) -> some View {
        Circle()
            .stroke(
                colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.12),
                lineWidth: strokeWidth
            )
            .frame(width: radius * 2, height: radius * 2)
            .position(center)
    }
    
    // MARK: - Hour Tick Marks
    private func hourTickMarks(center: CGPoint, radius: CGFloat) -> some View {
        ZStack {
            ForEach(0..<24, id: \.self) { hour in
                createTickMark(for: hour, center: center, radius: radius)
            }
        }
    }
    
    private func createTickMark(for hour: Int, center: CGPoint, radius: CGFloat) -> some View {
        let angle = Double(hour) * (360.0 / 24.0) - 90
        
        let outerRadius = radius + strokeWidth / 2
        let innerRadius = radius - strokeWidth / 2
        
        let startX = center.x + outerRadius * cos(angle * .pi / 180)
        let startY = center.y + outerRadius * sin(angle * .pi / 180)
        
        let endX = center.x + innerRadius * cos(angle * .pi / 180)
        let endY = center.y + innerRadius * sin(angle * .pi / 180)
        
        let isMainHour = hour % 3 == 0
        let strokeColor = colorScheme == .dark ? Color.white : Color.black
        
        return Path { path in
            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: endX, y: endY))
        }
        .stroke(
            style: StrokeStyle(
                lineWidth: 1,
                dash: isMainHour ? [] : [4, 4]
            )
        )
        .foregroundColor(strokeColor.opacity(isMainHour ? 0.3 : 0.2))
    }
    
    // MARK: - Sleep Blocks View
    private func sleepBlocksView(center: CGPoint, radius: CGFloat) -> some View {
        ZStack {
            if let sleepBlocks = schedule.sleepBlocks {
                ForEach(sleepBlocks.indices, id: \.self) { index in
                    sleepBlockArc(for: sleepBlocks[index], center: center, radius: radius)
                }
            }
        }
    }
    
    @ViewBuilder
    private func sleepBlockArc(for block: SharedSleepBlock, center: CGPoint, radius: CGFloat) -> some View {
        Group {
            let startAngle = angleForTime(timeString: block.startTime)
            let endAngle = angleForTime(timeString: block.endTime)
            
            // Gece yarısını geçen blokları handle et
            let adjustedEndAngle = endAngle < startAngle ? endAngle + 360 : endAngle
            let blockColor = block.isCore ? Color.blue : Color.orange
            
            Path { path in
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(adjustedEndAngle),
                    clockwise: false
                )
            }
            .stroke(blockColor, lineWidth: strokeWidth)
            .opacity(0.85)
        }
    }
    
    // MARK: - Hour Markers View
    private func hourMarkersView(center: CGPoint, radius: CGFloat, labelPadding: CGFloat) -> some View {
        ZStack {
            ForEach(hourMarkers, id: \.self) { hour in
                hourMarkerLabel(for: hour, center: center, radius: radius, labelPadding: labelPadding)
            }
        }
    }
    
    private func hourMarkerLabel(for hour: Int, center: CGPoint, radius: CGFloat, labelPadding: CGFloat) -> some View {
        let angle = Double(hour) * (360.0 / 24.0) - 90
        let labelRadius = radius + strokeWidth / 2 + labelPadding + 6
        let xPosition = center.x + labelRadius * cos(angle * .pi / 180)
        let yPosition = center.y + labelRadius * sin(angle * .pi / 180)
        
        let fontSize = max(7, radius / 12)
        let textColor = colorScheme == .dark ? Color.white : Color.black

        return Text(String(format: "%02d:00", hour))
            .font(.system(size: fontSize, weight: .medium))
            .foregroundColor(textColor.opacity(0.8))
            .position(x: xPosition, y: yPosition)
    }
    
    // MARK: - Current Time Indicator
    private func currentTimeIndicator(center: CGPoint, radius: CGFloat) -> some View {
        let currentAngle = angleForCurrentTime()
        let indicatorLength = strokeWidth / 2 + 6
        
        return Group {
            // Kırmızı ibre çizgisi
            Path { path in
                let startRadius = radius - indicatorLength
                let endRadius = radius + indicatorLength
                
                let startX = center.x + startRadius * cos(currentAngle * .pi / 180)
                let startY = center.y + startRadius * sin(currentAngle * .pi / 180)
                
                let endX = center.x + endRadius * cos(currentAngle * .pi / 180)
                let endY = center.y + endRadius * sin(currentAngle * .pi / 180)
                
                path.move(to: CGPoint(x: startX, y: startY))
                path.addLine(to: CGPoint(x: endX, y: endY))
            }
            .stroke(Color.red, lineWidth: 2)
            
            // Merkezdeki kırmızı nokta
            Circle()
                .fill(Color.red)
                .frame(width: 4, height: 4)
                .position(center)
            
            // İbre ucundaki kırmızı nokta
            Circle()
                .fill(Color.red)
                .frame(width: 3, height: 3)
                .position(
                    x: center.x + (radius + indicatorLength) * cos(currentAngle * .pi / 180),
                    y: center.y + (radius + indicatorLength) * sin(currentAngle * .pi / 180)
                )
        }
    }
    
    // MARK: - Sleep Block Time Labels
    private func sleepBlockTimeLabels(center: CGPoint, radius: CGFloat) -> some View {
        ZStack {
            if let sleepBlocks = schedule.sleepBlocks {
                ForEach(sleepBlocks.indices, id: \.self) { index in
                    sleepBlockTimeLabel(for: sleepBlocks[index], center: center, radius: radius)
                }
            }
        }
    }
    
    @ViewBuilder
    private func sleepBlockTimeLabel(for block: SharedSleepBlock, center: CGPoint, radius: CGFloat) -> some View {
        Group {
            let startAngle = angleForTime(timeString: block.startTime)
            let endAngle = angleForTime(timeString: block.endTime)
            
            // Gece yarısını geçen blokları handle et
            let adjustedEndAngle = endAngle < startAngle ? endAngle + 360 : endAngle
            
            // Bloğun ortasında tek bir etiket göster
            let midAngle = (startAngle + adjustedEndAngle) / 2
            let normalizedAngle = normalizeAngle(midAngle)
            
            // Label positioning
            let labelRadius = radius - strokeWidth / 2 - 16
            let xPosition = center.x + labelRadius * cos(midAngle * .pi / 180)
            let yPosition = center.y + labelRadius * sin(midAngle * .pi / 180)
            
            // Check if block is long enough to show labels
            let angleDifference = abs(adjustedEndAngle - startAngle)
            let isLongBlock = angleDifference > 20 // Minimum 20 derece
            
            // Etiket yönünü belirle
            let isVertical = (normalizedAngle >= 315 || normalizedAngle <= 45) || (normalizedAngle >= 135 && normalizedAngle <= 225)
            
            if isLongBlock {
            Group {
                if isVertical {
                    // Dikey layout - sağ/sol tarafta (alt alta)
                    VStack(spacing: 1) {
                        Text(formatTime(block.startTime))
                            .font(.system(size: max(6, radius / 15), weight: .semibold))
                        Text(formatTime(block.endTime))
                            .font(.system(size: max(6, radius / 15), weight: .semibold))
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
                    .position(x: xPosition, y: yPosition)
                } else {
                    // Yatay layout - üst/alt tarafta (yan yana)
                    HStack(spacing: 1) {
                        Text(formatTime(block.startTime))
                            .font(.system(size: max(6, radius / 15), weight: .semibold))
                        Text("-")
                            .font(.system(size: max(5, radius / 16), weight: .medium))
                        Text(formatTime(block.endTime))
                            .font(.system(size: max(6, radius / 15), weight: .semibold))
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
                    .position(x: xPosition, y: yPosition)
                }
            }
        }
        }
    }
    
    
    // MARK: - Helper Functions
    
    private func angleForTime(timeString: String) -> Double {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            print("⚠️ WatchCircularSleepChart: Geçersiz time format: \(timeString)")
            return 0.0
        }
        
        let totalMinutes = Double(hour * 60 + minute)
        return (totalMinutes / (24 * 60)) * 360 - 90
    }
    
    private func angleForCurrentTime() -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        
        let totalMinutes = Double(hour * 60 + minute)
        return (totalMinutes / (24 * 60)) * 360 - 90
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
    
    private func formatTime(_ timeString: String) -> String {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return timeString
        }
        
        return String(format: "%02d:%02d", hour, minute)
    }
}

#Preview {
    // Mock data for preview
    let mockSchedule = SharedUserSchedule(
        id: UUID(),
        user: nil,
        name: "Biphasic",
        scheduleDescription: "Test schedule",
        totalSleepHours: 6.5,
        adaptationPhase: 2,
        createdAt: Date(),
        updatedAt: Date(),
        isActive: true
    )
    
    WatchCircularSleepChart(schedule: mockSchedule)
        .frame(width: 140, height: 140)
} 