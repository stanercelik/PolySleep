import SwiftUI

struct EditableCircularSleepChart: View {
    @ObservedObject var viewModel: MainScreenViewModel
    let chartSize: CircularChartSize
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var activeDragInfo: String?
    
    @State private var center: CGPoint = .zero
    @State private var radius: CGFloat = 0
    @State private var strokeWidth: CGFloat = 0

    private var circleRadius: CGFloat { chartSize.radius }
    private var defaultStrokeWidth: CGFloat { chartSize.strokeWidth }
    private let hourMarkers = [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22]

    init(viewModel: MainScreenViewModel, chartSize: CircularChartSize = .extraLarge, activeDragInfo: Binding<String?>) {
        self.viewModel = viewModel
        self.chartSize = chartSize
        self._activeDragInfo = activeDragInfo
    }

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let labelFontSize = max(8, availableWidth / 35)
            let labelWidthApproximation = labelFontSize * 5
            let labelPadding: CGFloat = 8

            let totalPadding = defaultStrokeWidth + labelPadding + labelWidthApproximation
            let chartDiameter = availableWidth - totalPadding
            let adjustedRadius = chartDiameter / 2
            let chartCenter = CGPoint(x: availableWidth / 2, y: availableWidth / 2)
            let adjustedStrokeWidth = adjustedRadius * (defaultStrokeWidth / circleRadius)

            VStack {
                ZStack {
                    backgroundCircle(center: chartCenter, radius: adjustedRadius, strokeWidth: adjustedStrokeWidth)
                    editableSleepBlocksView(center: chartCenter, radius: adjustedRadius, strokeWidth: adjustedStrokeWidth)
                    hourTickMarks(center: chartCenter, radius: adjustedRadius, strokeWidth: adjustedStrokeWidth)
                    hourMarkersView(center: chartCenter, radius: adjustedRadius, strokeWidth: adjustedStrokeWidth, labelPadding: labelPadding)
                    innerTimeLabelsView(center: chartCenter, radius: adjustedRadius, strokeWidth: adjustedStrokeWidth)
                    
                    if viewModel.isChartEditMode {
                        snapIndicators(center: chartCenter, radius: adjustedRadius)
                    }
                }
                .onAppear {
                    center = chartCenter
                    radius = adjustedRadius
                    strokeWidth = adjustedStrokeWidth
                }
                .onChange(of: chartCenter) { newCenter in
                    center = newCenter
                }
                .onChange(of: adjustedRadius) { newRadius in
                    radius = newRadius
                }
                .onChange(of: adjustedStrokeWidth) { newStrokeWidth in
                    strokeWidth = newStrokeWidth
                }
            }
            .frame(width: availableWidth, height: availableWidth)
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isChartEditMode)
    }
    
    // MARK: - Background Circle with Shimmer Effect
    
    private func backgroundCircle(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        ZStack {
            // Base circle
            Circle()
                .stroke(Color.appTextSecondary.opacity(0.12), lineWidth: strokeWidth)
                .frame(width: radius * 2, height: radius * 2)
                .position(center)
            
            // Shimmer effect for edit mode
            if viewModel.isChartEditMode {
                ShimmerCircle(
                    center: center,
                    radius: radius,
                    strokeWidth: strokeWidth
                )
            }
        }
    }
    
    // MARK: - Hour Tick Marks
    
    private func hourTickMarks(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        ZStack {
            ForEach(0..<24, id: \.self) { hour in
                createTickMark(for: hour, center: center, radius: radius, strokeWidth: strokeWidth)
            }
        }
    }
    
    private func createTickMark(for hour: Int, center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        let angle = Double(hour) * (360.0 / 24.0) - 90
        
        let outerRadius = radius + strokeWidth / 2
        let innerRadius = radius - strokeWidth / 2
        
        let startX = center.x + outerRadius * cos(angle * .pi / 180)
        let startY = center.y + outerRadius * sin(angle * .pi / 180)
        
        let endX = center.x + innerRadius * cos(angle * .pi / 180)
        let endY = center.y + innerRadius * sin(angle * .pi / 180)
        
        return Path { path in
            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: endX, y: endY))
        }
        .stroke(style: StrokeStyle(lineWidth: 1, dash: hour % 3 == 0 ? [] : [4, 4]))
        .foregroundColor(Color.appTextSecondary.opacity(hour % 3 == 0 ? 0.3 : 0.2))
    }
    
    // MARK: - Hour Markers
    
    private func hourMarkersView(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat, labelPadding: CGFloat) -> some View {
        ZStack {
            ForEach(hourMarkers, id: \.self) { hour in
                hourMarkerLabel(for: hour, center: center, radius: radius, strokeWidth: strokeWidth, labelPadding: labelPadding)
            }
        }
    }
    
    private func hourMarkerLabel(for hour: Int, center: CGPoint, radius: CGFloat, strokeWidth: CGFloat, labelPadding: CGFloat) -> some View {
        let angle = Double(hour) * (360.0 / 24.0) - 90
        let labelRadius = radius + strokeWidth / 2 + labelPadding + 12
        let xPosition = center.x + labelRadius * cos(angle * .pi / 180)
        let yPosition = center.y + labelRadius * sin(angle * .pi / 180)
        
        let availableWidth = 2 * (radius + strokeWidth / 2 + labelPadding)
        let fontSize = max(8, availableWidth / 40)

        return Text(String(format: "%02d:00", hour))
            .font(.system(size: fontSize, weight: .medium))
            .foregroundColor(Color.appTextSecondary.opacity(viewModel.isChartEditMode ? 0.6 : 1.0))
            .position(x: xPosition, y: yPosition)
    }
    
    // MARK: - Editable Sleep Blocks
    
    private func editableSleepBlocksView(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        ZStack {
            let schedule = viewModel.isChartEditMode ? viewModel.tempScheduleBlocks : viewModel.model.schedule.schedule
            
            ForEach(Array(schedule.enumerated()), id: \.element.id) { index, block in
                editableSleepBlockArc(
                    for: block,
                    center: center,
                    radius: radius,
                    strokeWidth: strokeWidth
                )
            }
        }
    }
    
    @ViewBuilder
    private func editableSleepBlockArc(for block: SleepBlock, center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        if let startTimeComponents = TimeFormatter.time(from: block.startTime) {
            let startAngle = angleForTime(hour: startTimeComponents.hour, minute: startTimeComponents.minute)
            let durationHours = Double(block.duration) / 60.0
            let endAngle = startAngle + (durationHours * (360.0 / 24.0))
            
            let isDragged = viewModel.draggedBlockId == block.id
            
            ZStack {
                // Ana blok with drag gesture
                Path { path in
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(startAngle),
                        endAngle: .degrees(endAngle),
                        clockwise: false
                    )
                }
                .stroke(
                    block.isCore ? Color.appPrimary : Color.appSecondary,
                    lineWidth: strokeWidth
                )
                .opacity(isDragged ? 0.7 : 0.85)
                .scaleEffect(isDragged ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isDragged)
                .gesture(
                    viewModel.isChartEditMode ?
                    DragGesture(coordinateSpace: .local)
                        .onChanged { value in
                            if viewModel.draggedBlockId == nil && !viewModel.isResizing {
                                viewModel.startDragging(blockId: block.id, at: value.location)
                            }
                            
                            if viewModel.draggedBlockId == block.id {
                                updateBlockPosition(
                                    blockId: block.id,
                                    to: value.location,
                                    center: center,
                                    radius: radius
                                )
                            }
                        }
                        .onEnded { _ in
                            if viewModel.draggedBlockId == block.id {
                                viewModel.endDragging()
                                
                                let lastTime = viewModel.liveBlockTimeString
                                
                                // Set the binding with the final time
                                activeDragInfo = lastTime

                                // After 1 second, clear the binding, but only if a new drag hasn't started
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    if activeDragInfo == lastTime {
                                        activeDragInfo = nil
                                    }
                                }
                                
                                // Clear the internal VM property so it doesn't persist
                                viewModel.liveBlockTimeString = nil
                            }
                        }
                    : nil
                )
                
                // Enhanced drag handle sadece edit mode'da
                if viewModel.isChartEditMode && !viewModel.isResizing {
                    enhancedDragHandle(
                        for: block,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        center: center,
                        radius: radius,
                        strokeWidth: strokeWidth
                    )
                }
                
                // Resizing handles
                if viewModel.isChartEditMode {
                    ResizeHandleView(
                        viewModel: viewModel,
                        blockId: block.id,
                        handleType: .start,
                        angle: startAngle,
                        center: center,
                        radius: radius,
                        strokeWidth: strokeWidth
                    )
                    
                    ResizeHandleView(
                        viewModel: viewModel,
                        blockId: block.id,
                        handleType: .end,
                        angle: endAngle,
                        center: center,
                        radius: radius,
                        strokeWidth: strokeWidth
                    )
                }
            }
        }
    }
    
    // MARK: - Enhanced Drag Handle
    
    private func enhancedDragHandle(for block: SleepBlock, startAngle: Double, endAngle: Double, center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        let midAngle = (startAngle + endAngle) / 2
        let handleRadius = radius // - strokeWidth / 4
        
        // Büyük dokunma alanı (44pt minimum)
        let touchAreaSize: CGFloat = max(strokeWidth * 1.5, 44)
        
        let posX = center.x + handleRadius * cos(midAngle * .pi / 180)
        let posY = center.y + handleRadius * sin(midAngle * .pi / 180)
        
        return ZStack {
            // Görsel gösterge
            Circle()
                .fill(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.9))
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(block.isCore ? Color.appPrimary : Color.appSecondary)
                )
                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)


            // Dokunma alanı (görünmez)
            Circle()
                .fill(Color.clear)
                .frame(width: touchAreaSize, height: touchAreaSize)
        }
        .position(x: posX, y: posY)
        .scaleEffect(viewModel.draggedBlockId == block.id ? 1.15 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.draggedBlockId == block.id)
        
    }
    
    // MARK: - Time Labels (Normal Mode)
    
    private func innerTimeLabelsView(center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        ZStack {
            let schedule = viewModel.isChartEditMode ? viewModel.tempScheduleBlocks : viewModel.model.schedule.schedule
            ForEach(schedule.indices, id: \.self) { index in
                timeLabel(for: schedule[index], center: center, radius: radius, strokeWidth: strokeWidth)
            }
        }
    }
    
    @ViewBuilder
    private func timeLabel(for block: SleepBlock, center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> some View {
        if let labelData = generateLabelData(for: block, center: center, radius: radius, strokeWidth: strokeWidth) {
            let isDragged = viewModel.draggedBlockId == block.id
            Group {
                if labelData.isVertical {
                    VStack(spacing: 1) {
                        Text(labelData.startTimeStr)
                            .font(.system(size: labelData.fontSize, weight: .semibold))
                        Text(labelData.endTimeStr)
                            .font(.system(size: labelData.fontSize, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, labelData.isLongBlock ? 6 : 4)
                    .padding(.vertical, labelData.isLongBlock ? 3 : 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.black.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            )
                    )
                    .position(x: labelData.xPosition, y: labelData.yPosition)
                } else {
                    HStack(spacing: 2) {
                        Text(labelData.startTimeStr)
                            .font(.system(size: labelData.fontSize, weight: .semibold))
                        Text("-")
                            .font(.system(size: labelData.fontSize - 1, weight: .medium))
                        Text(labelData.endTimeStr)
                            .font(.system(size: labelData.fontSize, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, labelData.isLongBlock ? 6 : 4)
                    .padding(.vertical, labelData.isLongBlock ? 3 : 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.black.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            )
                    )
                    .position(x: labelData.xPosition, y: labelData.yPosition)
                }
            }
            .opacity(viewModel.isChartEditMode && isDragged ? 0 : 1)
            .animation(.easeInOut(duration: 0.2), value: viewModel.draggedBlockId)
        }
    }
    
    // MARK: - Snap Indicators
    
    private func snapIndicators(center: CGPoint, radius: CGFloat) -> some View {
        let totalMinutes = 24 * 60
        let snapInterval = 5 // 5 dakika sabit
        let indicatorCount = totalMinutes / snapInterval
        let indicatorRadius = radius + 8
        
        return ZStack {
            ForEach(0..<indicatorCount, id: \.self) { index in
                let angle = Double(index * snapInterval) * (360.0 / Double(totalMinutes)) - 90
                
                let indicatorX = center.x + indicatorRadius * cos(angle * .pi / 180)
                let indicatorY = center.y + indicatorRadius * sin(angle * .pi / 180)
                
                Circle()
                    .fill(Color.appAccent.opacity(0.3))
                    .frame(width: 2, height: 2)
                    .position(x: indicatorX, y: indicatorY)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func angleForTime(hour: Int, minute: Int) -> Double {
        let totalMinutes = Double(hour * 60 + minute)
        return (totalMinutes / (24 * 60)) * 360 - 90
    }
    
    private func normalizeAngle(_ angle: Double) -> Double {
        var normalized = angle
        while normalized < 0 {
            normalized += 360
        }
        while normalized >= 360 {
            normalized -= 360
        }
        return normalized
    }
    
    private struct LabelData {
        let startTimeStr: String
        let endTimeStr: String
        let isVertical: Bool
        let isLongBlock: Bool
        let fontSize: CGFloat
        let xPosition: CGFloat
        let yPosition: CGFloat
    }
    
    private func generateLabelData(for block: SleepBlock, center: CGPoint, radius: CGFloat, strokeWidth: CGFloat) -> LabelData? {
        guard let startTimeComponents = TimeFormatter.time(from: block.startTime) else { return nil }
        let endTimeComponents = TimeFormatter.time(from: block.endTime) ?? (0, 0)
        
        let startAngle = angleForTime(hour: startTimeComponents.hour, minute: startTimeComponents.minute)
        let endAngle = angleForTime(hour: endTimeComponents.hour, minute: endTimeComponents.minute)
        
        var adjustedEndAngle = endAngle
        if endAngle < startAngle {
            adjustedEndAngle = endAngle + 360
        }
        
        let midAngle = (startAngle + adjustedEndAngle) / 2
        let normalizedAngle = normalizeAngle(midAngle)
        
        let isVertical = (normalizedAngle >= 315 || normalizedAngle <= 45) || (normalizedAngle >= 135 && normalizedAngle <= 225)
        let isLongBlock = block.duration > 90
        let fontSize = max(7, radius / 12)
        let labelRadius = radius - strokeWidth / 2 - (isLongBlock ? 24 : 28) // 18/22'den 24/28'e artırıldı (daha uzağa)
        let xPosition = center.x + labelRadius * cos(midAngle * .pi / 180)
        let yPosition = center.y + labelRadius * sin(midAngle * .pi / 180)
        
        let startTimeStr = String(format: "%02d:%02d", startTimeComponents.hour, startTimeComponents.minute)
        let endTimeStr = String(format: "%02d:%02d", endTimeComponents.hour, endTimeComponents.minute)
        
        return LabelData(
            startTimeStr: startTimeStr,
            endTimeStr: endTimeStr,
            isVertical: isVertical,
            isLongBlock: isLongBlock,
            fontSize: fontSize,
            xPosition: xPosition,
            yPosition: yPosition
        )
    }
    
    // MARK: - Block Position Update
    
    /// Bloğun pozisyonunu günceller (5 dakika snap ile)
    private func updateBlockPosition(blockId: UUID, to position: CGPoint, center: CGPoint, radius: CGFloat) {
        guard viewModel.draggedBlockId == blockId else { return }
        
        // Pozisyondan açıyı hesapla
        let dx = position.x - center.x
        let dy = position.y - center.y
        
        // Sadece sürükleme işlemi başladıysa açıyı hesapla
        guard let startAngle = viewModel.dragStartAngle else {
            // Sürükleme başlangıcındaki açıyı sakla
            let initialAngle = atan2(dy, dx)
            
            // Başlangıç bloğunun açısını al
            guard let blockIndex = viewModel.tempScheduleBlocks.firstIndex(where: { $0.id == blockId }),
                  let startTime = TimeFormatter.time(from: viewModel.tempScheduleBlocks[blockIndex].startTime) else {
                return
            }
            let blockStartAngle = angleForTime(hour: startTime.hour, minute: startTime.minute) * .pi / 180
            
            // Dokunma açısı ile blok açısı arasındaki farkı sakla
            viewModel.dragAngleOffset = initialAngle - blockStartAngle
            viewModel.dragStartAngle = initialAngle
            return
        }

        let currentAngle = atan2(dy, dx)
        let angleDifference = currentAngle - startAngle
        
        // Bloğun başlangıç açısını al
        guard let originalStartTimeString = viewModel.initialDragState[blockId]?.startTime,
              let originalStartTime = TimeFormatter.time(from: originalStartTimeString) else {
            return
        }

        let originalStartAngle = angleForTime(hour: originalStartTime.hour, minute: originalStartTime.minute) * .pi / 180
        
        // Yeni açıyı hesapla
        let newAngleInRadians = originalStartAngle + angleDifference
        let newAngleInDegrees = newAngleInRadians * 180 / .pi
        
        // 5 dakika snap
        let snappedAngle = viewModel.snapAngleToFiveMinutes(newAngleInDegrees)
        
        // Açıdan zamanı hesapla
        let newStartTime = viewModel.timeFromAngle(snappedAngle)
        
        // Temp schedule'da bloğu güncelle
        if let blockIndex = viewModel.tempScheduleBlocks.firstIndex(where: { $0.id == blockId }) {
            let currentBlock = viewModel.tempScheduleBlocks[blockIndex]
            
            // Yeni start time ile end time'ı hesapla
            let newEndTime = TimeFormatter.addMinutes(currentBlock.duration, to: newStartTime)
            
            // Canlı zaman gösterimini güncelle
            let timeString = "\(newStartTime) - \(newEndTime)"
            viewModel.liveBlockTimeString = timeString
            activeDragInfo = timeString
            
            // Collision detection - diğer bloklar ile çakışma kontrolü
            if !viewModel.hasCollisionInTemp(
                blockId: blockId,
                startTime: newStartTime,
                endTime: newEndTime
            ) {
                // Yeni SleepBlock oluştur (immutable property'ler nedeniyle, ID'yi koru)
                let newBlock = SleepBlock(
                    id: currentBlock.id,
                    startTime: newStartTime,
                    duration: currentBlock.duration,
                    type: currentBlock.type,
                    isCore: currentBlock.isCore
                )
                viewModel.tempScheduleBlocks[blockIndex] = newBlock
            }
        }
    }
    

}

// MARK: - Resize Handle View
struct ResizeHandleView: View {
    @ObservedObject var viewModel: MainScreenViewModel
    let blockId: UUID
    let handleType: MainScreenViewModel.ResizeHandle
    let angle: Double
    let center: CGPoint
    let radius: CGFloat
    let strokeWidth: CGFloat
    
    private var isBeingResized: Bool {
        viewModel.resizeBlockId == blockId && viewModel.resizeHandle == handleType
    }
    
    var body: some View {
        let handleRadius: CGFloat = radius
        let posX = center.x + handleRadius * cos(angle * .pi / 180)
        let posY = center.y + handleRadius * sin(angle * .pi / 180)
        let touchAreaSize: CGFloat = max(strokeWidth, 44)
        
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: isBeingResized ? 20 : 14, height: isBeingResized ? 20 : 14)
                .overlay(
                    Circle()
                        .stroke(Color.appPrimary, lineWidth: 2)
                )
                .shadow(radius: 2)
            
            Circle()
                .fill(Color.clear)
                .frame(width: touchAreaSize, height: touchAreaSize)
        }
        .position(x: posX, y: posY)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isBeingResized)
        .gesture(
            DragGesture(coordinateSpace: .local)
                .onChanged { value in
                    if !viewModel.isResizing {
                        viewModel.startResizing(blockId: blockId, handle: handleType, at: value.location, center: center)
                    }
                    viewModel.updateResize(to: value.location, center: center, radius: radius)
                }
                .onEnded { _ in
                    viewModel.endResizing()
                }
        )
    }
}


// MARK: - Shimmer Effect Component

struct ShimmerCircle: View {
    let center: CGPoint
    let radius: CGFloat
    let strokeWidth: CGFloat
    
    @State private var rotation: Double = 0
    
    var body: some View {
        Circle()
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [
                        Color.appTextSecondary.opacity(0.0),
                        Color.appTextSecondary.opacity(0.1),
                        Color.appTextSecondary.opacity(0.2),
                        Color.appTextSecondary.opacity(0.1),
                        Color.appTextSecondary.opacity(0.0)
                    ]),
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360)
                ),
                lineWidth: strokeWidth
            )
            .frame(width: radius * 2, height: radius * 2)
            .position(center)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}