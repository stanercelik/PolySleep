import SwiftUI

struct CircularSleepChart: View {
    let schedule: SleepScheduleModel
    @Environment(\.colorScheme) var colorScheme
    
    private let circleRadius: CGFloat = 150
    private let strokeWidth: CGFloat = 50
    private let hourMarkers = [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22] // Changed to 2-hour intervals
    private let innerRadius: CGFloat = 110
    private let tickLength: CGFloat = 10
    
    var body: some View {
        ZStack {
            backgroundCircle
            hourTickMarks
            hourMarkersView
            sleepBlocksView
            innerTimeLabelsView
        }
        .frame(width: circleRadius * 2 + strokeWidth, height: circleRadius * 2 + strokeWidth)
        .padding(.horizontal, strokeWidth)
        .padding(.vertical, strokeWidth / 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(generateAccessibilityLabel())
    }
    
    private var backgroundCircle: some View {
        Circle()
            .stroke(Color("SecondaryTextColor").opacity(0.12), lineWidth: strokeWidth)
            .frame(width: circleRadius * 2)
            .padding(.bottom, strokeWidth)
            .padding(.trailing, strokeWidth)
    }
    
    private var hourTickMarks: some View {
        ForEach(0..<24, id: \.self) { hour in
            createTickMark(for: hour)
        }
    }
    
    private func createTickMark(for hour: Int) -> some View {
        let angle = Double(hour) * (360.0 / 24.0) - 90
        let outerRadius = circleRadius + strokeWidth / 2
        let innerRadius = circleRadius - strokeWidth / 2
        
        let startPoint = CGPoint(
            x: circleRadius + outerRadius * cos(angle * .pi / 180),
            y: circleRadius + outerRadius * sin(angle * .pi / 180)
        )
        
        let endPoint = CGPoint(
            x: circleRadius + innerRadius * cos(angle * .pi / 180),
            y: circleRadius + innerRadius * sin(angle * .pi / 180)
        )
        
        return Path { path in
            path.move(to: startPoint)
            path.addLine(to: endPoint)
        }
        .stroke(style: StrokeStyle(
            lineWidth: 1,
            dash: hour % 3 == 0 ? [] : [4, 4] // Solid lines for main markers
        ))
        .foregroundColor(Color("SecondaryTextColor").opacity(hour % 3 == 0 ? 0.3 : 0.2))
    }
    
    private var hourMarkersView: some View {
        ForEach(hourMarkers, id: \.self) { hour in
            hourMarkerLabel(for: hour)
        }
    }
    
    private func hourMarkerLabel(for hour: Int) -> some View {
        let angle = Double(hour) * (360.0 / 24.0) - 90
        let radius = circleRadius + strokeWidth * 1.2
        let xPosition = circleRadius + radius * cos(angle * .pi / 180)
        let yPosition = circleRadius + radius * sin(angle * .pi / 180)
        
        return Text(String(format: "%02d:00", hour))
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color("SecondaryTextColor"))
            .position(x: xPosition, y: yPosition)
    }
    
    private var sleepBlocksView: some View {
        ForEach(schedule.schedule.indices, id: \.self) { index in
            sleepBlockArc(for: schedule.schedule[index])
        }
    }
    
    private func sleepBlockArc(for block: SleepScheduleModel.SleepBlock) -> some View {
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
                    center: CGPoint(x: circleRadius, y: circleRadius),
                    radius: circleRadius,
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(endAngle),
                    clockwise: false
                )
            }
            .stroke(block.type == "core" ? Color("PrimaryColor") : Color("SecondaryColor"), lineWidth: strokeWidth)
            .opacity(0.85)
        )
    }
    
    private var innerTimeLabelsView: some View {
        ForEach(schedule.schedule.indices, id: \.self) { index in
            let block = schedule.schedule[index]
            let startTime = timeComponents(from: Int(block.startTime) ?? 0)
            let endTime = calculateEndTime(startTime: startTime, duration: block.duration)
            
            VStack {
                innerTimeLabel(time: String(format: "%02d:%02d", startTime.hour, startTime.minute), angle: angleForTime(hour: startTime.hour, minute: startTime.minute), isStart: true)
                innerTimeLabel(time: String(format: "%02d:%02d", endTime.hour, endTime.minute), angle: angleForTime(hour: endTime.hour, minute: endTime.minute), isStart: false)
            }
        }
    }
    
    private func innerTimeLabel(time: String, angle: Double, isStart: Bool) -> some View {
        let radius = circleRadius - strokeWidth
        let xPosition = circleRadius + radius * cos(angle * .pi / 180)
        let yPosition = circleRadius + radius * sin(angle * .pi / 180)
        
        return Text(time)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(Color("SecondaryTextColor"))
            .position(x: xPosition, y: yPosition)
            .rotationEffect(.degrees(angle + 90))
    }
    
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
            
            // Format the time strings
            let startTimeStr = String(format: "%02d:%02d", startTime.hour, startTime.minute)
            let endTimeStr = String(format: "%02d:%02d", endTime.hour, endTime.minute)
            
            // Get block type
            let blockType = block.type == "core" ? 
                NSLocalizedString("sleepBlock.core", comment: "Core sleep block") : 
                NSLocalizedString("sleepBlock.nap", comment: "Nap block")
            
            // Create the description string
            let description = String(
                format: NSLocalizedString(
                    "sleepBlock.description",
                    comment: "Sleep block description format"
                ),
                arguments: [
                    "\(index + 1)",
                    blockType,
                    startTimeStr,
                    endTimeStr
                ]
            )
            descriptions.append(description)
        }
        
        let scheduleDescription = descriptions.joined(separator: ". ")
        return String(
            format: NSLocalizedString(
                "sleepSchedule.description",
                comment: "Sleep schedule description"
            ),
            arguments: [scheduleDescription]
        )
    }
}

struct CircularSleepChart_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Everyman Schedule Preview
            CircularSleepChart(schedule: SleepScheduleModel(
                id: "everyman",
                name: "Everyman",
                description: .init(
                    en: "A schedule with one core sleep and three 20-minute naps",
                    tr: "Bir ana uyku ve üç adet 20 dakikalık şekerleme içeren uyku düzeni"
                ),
                totalSleepHours: 4,
                schedule: [
                    .init(type: "core", startTime: "22:00", duration: 180),
                    .init(type: "nap", startTime: "06:00", duration: 20),
                    .init(type: "nap", startTime: "12:00", duration: 20),
                    .init(type: "nap", startTime: "17:00", duration: 20)
                ]
            ))
            .previewDisplayName("Everyman Schedule - Light")
            
            // Dual Core Schedule Preview
            CircularSleepChart(schedule: SleepScheduleModel(
                id: "dualcore",
                name: "Dual Core",
                description: .init(
                    en: "A schedule with two core sleeps and one nap",
                    tr: "İki ana uyku ve bir şekerleme içeren uyku düzeni"
                ),
                totalSleepHours: 5,
                schedule: [
                    .init(type: "core", startTime: "22:00", duration: 180),
                    .init(type: "core", startTime: "04:00", duration: 90),
                    .init(type: "nap", startTime: "14:00", duration: 20)
                ]
            ))
            .preferredColorScheme(.dark)
            .previewDisplayName("Dual Core Schedule - Dark")
            
            // Uberman Schedule Preview
            CircularSleepChart(schedule: SleepScheduleModel(
                id: "uberman",
                name: "Uberman",
                description: .init(
                    en: "An extreme schedule with six 20-minute naps throughout the day",
                    tr: "Gün boyunca altı adet 20 dakikalık şekerleme içeren ekstrem bir uyku düzeni"
                ),
                totalSleepHours: 2,
                schedule: [
                    .init(type: "nap", startTime: "02:00", duration: 20),
                    .init(type: "nap", startTime: "06:00", duration: 20),
                    .init(type: "nap", startTime: "10:00", duration: 20),
                    .init(type: "nap", startTime: "14:00", duration: 20),
                    .init(type: "nap", startTime: "18:00", duration: 20),
                    .init(type: "nap", startTime: "22:00", duration: 20)
                ]
            ))
            .previewDisplayName("Uberman Schedule")
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
