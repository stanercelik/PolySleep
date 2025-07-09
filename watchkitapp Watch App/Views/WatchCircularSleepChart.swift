import SwiftUI
import WatchKit
import PolyNapShared

/// Watch için optimize edilmiş CircularSleepChart - kompakt ve çakışmasız layout
struct WatchCircularSleepChart: View {
    let schedule: SharedUserSchedule
    
    private var circleRadius: CGFloat { 55 }
    private var strokeWidth: CGFloat { 14 }
    private let majorHourMarkers = [0, 6, 12, 18] // Sadece ana saatler
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            
            ZStack {
                // Background circle
                backgroundCircle(center: center)
                
                // Hour tick marks (sadece ana saatler)
                hourTickMarks(center: center)
                
                // Sleep blocks
                sleepBlocksView(center: center)
                
                // Hour markers (sadece ana saatler)
                hourMarkersView(center: center)
                
                // Current time indicator
                currentTimeIndicator(center: center)
                
                // Sleep block time labels (optimize edilmiş)
                sleepBlockTimeLabels(center: center)
                
                // Center time info
                centerTimeInfo(center: center)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    // MARK: - Background Circle
    private func backgroundCircle(center: CGPoint) -> some View {
        Circle()
            .stroke(Color.secondary.opacity(0.2), lineWidth: strokeWidth)
            .frame(width: circleRadius * 2, height: circleRadius * 2)
            .position(center)
    }
    
    // MARK: - Hour Tick Marks (sadece ana saatler)
    private func hourTickMarks(center: CGPoint) -> some View {
        ZStack {
            ForEach(majorHourMarkers, id: \.self) { hour in
                createTickMark(for: hour, center: center)
            }
        }
    }
    
    private func createTickMark(for hour: Int, center: CGPoint) -> some View {
        let angle = angleForHour(hour)
        
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
        .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
    }
    
    // MARK: - Sleep Blocks View
    private func sleepBlocksView(center: CGPoint) -> some View {
        ZStack {
            if let sleepBlocks = schedule.sleepBlocks {
                ForEach(sleepBlocks.indices, id: \.self) { index in
                    sleepBlockArc(for: sleepBlocks[index], center: center)
                }
            }
        }
    }
    
    @ViewBuilder
    private func sleepBlockArc(for block: SharedSleepBlock, center: CGPoint) -> some View {
        let startAngle = angleForTime(from: block.startTime)
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
        .stroke(
            block.isCore ? Color.blue : Color.orange,
            lineWidth: strokeWidth
        )
        .opacity(0.9)
    }
    
    // MARK: - Hour Markers View (sadece ana saatler)
    private func hourMarkersView(center: CGPoint) -> some View {
        ZStack {
            ForEach(majorHourMarkers, id: \.self) { hour in
                hourMarker(for: hour, center: center)
            }
        }
    }
    
    @ViewBuilder
    private func hourMarker(for hour: Int, center: CGPoint) -> some View {
        let angle = angleForHour(hour)
        let markerRadius = circleRadius + strokeWidth/2 + 10
        
        let x = center.x + cos(angle * .pi / 180) * markerRadius
        let y = center.y + sin(angle * .pi / 180) * markerRadius
        
        Text(String(format: "%02d", hour))
            .font(.system(size: 8, weight: .medium))
            .foregroundColor(.secondary)
            .position(x: x, y: y)
    }
    
    // MARK: - Current Time Indicator
    @ViewBuilder
    private func currentTimeIndicator(center: CGPoint) -> some View {
        let now = Date()
        let currentAngle = angleForTime(from: now)
        let indicatorRadius = circleRadius + strokeWidth/2 + 2
        
        let x = center.x + cos(currentAngle * .pi / 180) * indicatorRadius
        let y = center.y + sin(currentAngle * .pi / 180) * indicatorRadius
        
        Circle()
            .fill(Color.red)
            .frame(width: 4, height: 4)
            .position(x: x, y: y)
    }
    
    // MARK: - Sleep Block Time Labels (optimize edilmiş)
    @ViewBuilder
    private func sleepBlockTimeLabels(center: CGPoint) -> some View {
        ZStack {
            if let sleepBlocks = schedule.sleepBlocks {
                ForEach(sleepBlocks.indices, id: \.self) { index in
                    sleepBlockTimeLabel(for: sleepBlocks[index], index: index, center: center)
                }
            }
        }
    }
    
    @ViewBuilder
    private func sleepBlockTimeLabel(for block: SharedSleepBlock, index: Int, center: CGPoint) -> some View {
        let startAngle = angleForTime(from: block.startTime)
        let durationHours = Double(block.durationMinutes) / 60.0
        let midAngle = startAngle + (durationHours * (360.0 / 24.0)) / 2
        
        // Daha kompakt label pozisyonu
        let labelRadius = circleRadius - strokeWidth/2 - 4
        let x = center.x + cos(midAngle * .pi / 180) * labelRadius
        let y = center.y + sin(midAngle * .pi / 180) * labelRadius
        
        // Sadece önemli bloklar için label göster
        if block.durationMinutes > 45 {
            VStack(spacing: 0) {
                Text(formatTime(block.startTime))
                    .font(.system(size: 6, weight: .semibold))
                Text(formatTime(block.endTime))
                    .font(.system(size: 6, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 2)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black.opacity(0.7))
            )
            .position(x: x, y: y)
        }
    }
    
    // MARK: - Center Time Info
    @ViewBuilder
    private func centerTimeInfo(center: CGPoint) -> some View {
        VStack(spacing: 1) {
            Text(schedule.name)
                .font(.system(size: 7, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text("\(schedule.totalSleepHours ?? 0, specifier: "%.1f")s")
                .font(.system(size: 6))
                .foregroundColor(.secondary)
                
            // Show current time
            Text(currentTimeString())
                .font(.system(size: 6))
                .foregroundColor(.red)
                .fontWeight(.medium)
        }
        .position(center)
    }
    
    // MARK: - Helper Methods
    
    /// Saat için açıyı hesaplar (12 saat = 0°, 6 saat = 180°)
    private func angleForHour(_ hour: Int) -> Double {
        return Double(hour) * (360.0 / 24.0) - 90.0
    }
    
    /// Date'den açıyı hesaplar
    private func angleForTime(from date: Date) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        let totalMinutes = Double(hour * 60 + minute)
        return (totalMinutes / (24 * 60)) * 360 - 90
    }
    
    /// String time'dan açıyı hesaplar - mobil ile tutarlı
    private func angleForTime(from timeString: String) -> Double {
        let components = timeString.components(separatedBy: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            print("⚠️ WatchCircularSleepChart: Geçersiz time format: \(timeString)")
            return 0.0
        }
        
        let totalMinutes = Double(hour * 60 + minute)
        return (totalMinutes / (24 * 60)) * 360 - 90
    }
    
    /// Time'ı display için formatlar
    private func formatTime(_ timeString: String) -> String {
        // HH:mm formatını kısalt
        let components = timeString.components(separatedBy: ":")
        if components.count == 2 {
            let hour = components[0]
            let minute = components[1]
            return "\(hour):\(minute)"
        }
        return timeString
    }
    
    /// Current time'ı display için formatlar
    private func currentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
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