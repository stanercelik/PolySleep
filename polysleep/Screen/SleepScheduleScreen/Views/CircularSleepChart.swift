import SwiftUI

enum CircularChartSize {
    case small
    case medium
    case large
    
    var radius: CGFloat {
        switch self {
        case .small: return 80
        case .medium: return 100
        case .large: return 110
        }
    }
    
    var strokeWidth: CGFloat {
        switch self {
        case .small: return 25
        case .medium: return 35
        case .large: return 40
        }
    }
}

struct CircularSleepChart: View {
    let schedule: SleepScheduleModel
    let textOpacity: Double
    let isEditing: Bool
    let chartSize: CircularChartSize
    @Environment(\.colorScheme) var colorScheme

    private var circleRadius: CGFloat { chartSize.radius }
    private var strokeWidth: CGFloat { chartSize.strokeWidth }
    private let hourMarkers = [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22]

    init(
        schedule: SleepScheduleModel,
        textOpacity: Double = 1.0,
        isEditing: Bool = false,
        chartSize: CircularChartSize = .large
    ) {
        self.schedule = schedule
        self.textOpacity = textOpacity
        self.isEditing = isEditing
        self.chartSize = chartSize
    }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
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
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.easeInOut(duration: 0.3), value: textOpacity)
        .animation(.easeInOut(duration: 0.3), value: isEditing)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(generateAccessibilityLabel())
        
    }
    
    // MARK: - Alt Görünümler
    
    private func backgroundCircle(center: CGPoint, size: CGFloat) -> some View {
        Circle()
            .stroke(Color.appSecondaryText.opacity(0.12), lineWidth: strokeWidth)
            .frame(width: circleRadius * 2, height: circleRadius * 2)
            .position(center)
    }
    
    private func hourTickMarks(center: CGPoint, size: CGFloat) -> some View {
        ZStack {
            ForEach(0..<24, id: \.self) { hour in
                createTickMark(for: hour, center: center)
            }
        }
    }
    
    private func createTickMark(for hour: Int, center: CGPoint) -> some View {
        let angle = Double(hour) * (360.0 / 24.0) - 90
        
        // Tick mark'ın başlangıç ve bitiş noktaları için radius değerleri
        let outerRadius = circleRadius + strokeWidth / 2
        let innerRadius = circleRadius - strokeWidth / 2
        
        // Tick mark'ın başlangıç noktası (dış çemberde)
        let startX = center.x + outerRadius * cos(angle * .pi / 180)
        let startY = center.y + outerRadius * sin(angle * .pi / 180)
        
        // Tick mark'ın bitiş noktası (iç çemberde)
        let endX = center.x + innerRadius * cos(angle * .pi / 180)
        let endY = center.y + innerRadius * sin(angle * .pi / 180)
        
        return Path { path in
            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: endX, y: endY))
        }
        .stroke(style: StrokeStyle(lineWidth: 1, dash: hour % 3 == 0 ? [] : [4, 4]))
        .foregroundColor(Color.appSecondaryText.opacity(hour % 3 == 0 ? 0.3 : 0.2))
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
        // Saat etiketleri için, dış çemberin biraz dışında konumlandırıyoruz
        let labelRadius = circleRadius + strokeWidth / 2 + 20
        let xPosition = center.x + labelRadius * cos(angle * .pi / 180)
        let yPosition = center.y + labelRadius * sin(angle * .pi / 180)
        
        return Text(String(format: "%02d:00", hour))
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color.appSecondaryText)
            .position(x: xPosition, y: yPosition)
    }
    
    private func sleepBlocksView(center: CGPoint, size: CGFloat) -> some View {
        ZStack {
            ForEach(schedule.schedule.indices, id: \.self) { index in
                sleepBlockArc(for: schedule.schedule[index], center: center)
            }
        }
    }
    
    private func sleepBlockArc(for block: SleepBlock, center: CGPoint) -> some View {
        guard let startTimeInt = Int(block.startTime.replacingOccurrences(of: ":", with: "")) else {
            return AnyView(EmptyView())
        }
        let startTime = timeComponents(from: startTimeInt)
        let startAngle = angleForTime(hour: startTime.hour, minute: startTime.minute)
        let durationHours = Double(block.duration) / 60.0
        let endAngle = startAngle + (durationHours * (360.0 / 24.0))
        
        return AnyView(
            Path { path in
                path.addArc(
                    center: center,
                    radius: circleRadius,
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(endAngle),
                    clockwise: false
                )
            }
            .stroke(block.type == "core" ? Color.appPrimary : Color.appSecondary, lineWidth: strokeWidth)
            .opacity(0.85)
        )
    }
    
    private func innerTimeLabelsView(center: CGPoint, size: CGFloat) -> some View {
        ZStack {
            ForEach(schedule.schedule.indices, id: \.self) { index in
                let block = schedule.schedule[index]
                if let startTimeInt = Int(block.startTime.replacingOccurrences(of: ":", with: "")) {
                    let startTime = timeComponents(from: startTimeInt)
                    let endTime = calculateEndTime(startTime: startTime, duration: block.duration)
                    
                    // Başlangıç ve bitiş açıları
                    let startAngle = angleForTime(hour: startTime.hour, minute: startTime.minute)
                    let endAngle = angleForTime(hour: endTime.hour, minute: endTime.minute)
                    
                    // Etiketleri konumlandır
                    if block.duration <= 30 {
                        // Kısa bloklar için etiketleri birleştir
                        let midAngle = (startAngle + endAngle) / 2
                        combinedTimeLabel(
                            startTime: String(format: "%02d:%02d", startTime.hour, startTime.minute),
                            endTime: String(format: "%02d:%02d", endTime.hour, endTime.minute),
                            angle: midAngle,
                            center: center
                        )
                    } else {
                        // Uzun bloklar için ayrı etiketler
                        Group {
                            innerTimeLabel(
                                time: String(format: "%02d:%02d", startTime.hour, startTime.minute),
                                angle: startAngle,
                                center: center
                            )
                            innerTimeLabel(
                                time: String(format: "%02d:%02d", endTime.hour, endTime.minute),
                                angle: endAngle,
                                center: center
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func combinedTimeLabel(startTime: String, endTime: String, angle: Double, center: CGPoint) -> some View {
        let radius = circleRadius - strokeWidth / 2 - 15
        let xPosition = center.x + radius * cos(angle * .pi / 180)
        let yPosition = center.y + radius * sin(angle * .pi / 180)
        
        return VStack(spacing: 2) {
            Text(startTime)
                .font(.system(size: 9, weight: .medium))
            Text(endTime)
                .font(.system(size: 9, weight: .medium))
        }
        .foregroundColor(Color.appSecondaryText)
        .padding(2)
        .background(Color.black.opacity(0.3))
        .cornerRadius(4)
        .position(x: xPosition, y: yPosition)
    }
    
    private func innerTimeLabel(time: String, angle: Double, center: CGPoint) -> some View {
        // İç etiketler için, iç çemberin biraz içinde konumlandırıyoruz
        let radius = circleRadius - strokeWidth / 2 - 15
        let xPosition = center.x + radius * cos(angle * .pi / 180)
        let yPosition = center.y + radius * sin(angle * .pi / 180)
        return Text(time)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(Color.appSecondaryText)
            .padding(2)
            .background(Color.black.opacity(0.3))
            .cornerRadius(4)
            .position(x: xPosition, y: yPosition)
    }
    
    // MARK: - Yardımcı Fonksiyonlar
    
    private func timeComponents(from time: Int) -> (hour: Int, minute: Int) {
        let timeString = String(format: "%04d", time)
        let hour = Int(timeString.prefix(2)) ?? 0
        let minute = Int(timeString.suffix(2)) ?? 0
        return (hour, minute)
    }
    
    private func angleForTime(hour: Int, minute: Int) -> Double {
        let totalMinutes = Double(hour * 60 + minute)
        return (totalMinutes / (24 * 60)) * 360 - 90
    }
    
    private func calculateEndTime(startTime: (hour: Int, minute: Int), duration: Int) -> (hour: Int, minute: Int) {
        let totalMinutes = startTime.hour * 60 + startTime.minute + duration
        let hour = (totalMinutes / 60) % 24
        let minute = totalMinutes % 60
        return (hour: hour, minute: minute)
    }
    
    private func generateAccessibilityLabel() -> String {
        var descriptions: [String] = []
        for (index, block) in schedule.schedule.enumerated() {
            let startTime = timeComponents(from: Int(block.startTime) ?? 1)
            let endTime = calculateEndTime(startTime: startTime, duration: block.duration)
            let startTimeStr = String(format: "%02d:%02d", startTime.hour, startTime.minute)
            let endTimeStr = String(format: "%02d:%02d", endTime.hour, endTime.minute)
            let blockType = block.type == "core" ?
                NSLocalizedString("sleepBlock.core", comment: "Core sleep block") :
                NSLocalizedString("sleepBlock.nap", comment: "Nap block")
            let description = String(
                format: NSLocalizedString("sleepBlock.description", comment: "Sleep block description format"),
                arguments: ["\(index + 1)", blockType, startTimeStr, endTimeStr]
            )
            descriptions.append(description)
        }
        let scheduleDescription = descriptions.joined(separator: ". ")
        return String(
            format: NSLocalizedString("sleepSchedule.description", comment: "Sleep schedule description"),
            arguments: [scheduleDescription]
        )
    }
}

#Preview {
    let schedule = SleepScheduleModel(
        id: "everyman",
        name: "Everyman",
        description: LocalizedDescription(
            en: "A schedule with one core sleep and multiple naps",
            tr: "Bir ana uyku ve birden fazla şekerleme içeren uyku düzeni"
        ),
        totalSleepHours: 4.6,
        schedule: [
            SleepBlock(
                startTime: "22:00",
                duration: 240,
                type: "core",
                isCore: true
            ),
            SleepBlock(
                startTime: "06:00",
                duration: 20,
                type: "nap",
                isCore: false
            ),
            SleepBlock(
                startTime: "12:00",
                duration: 20,
                type: "nap",
                isCore: false
            ),
            SleepBlock(
                startTime: "18:00",
                duration: 20,
                type: "nap",
                isCore: false
            )
        ]
    )
    Group {
        CircularSleepChart(schedule: schedule, textOpacity: 1)
            .frame(width: 300, height: 300)
            .previewDisplayName("Everyman Schedule - Text On")
    }
    .previewLayout(.sizeThatFits)
    .padding()
}
