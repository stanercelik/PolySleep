import SwiftUI
import SwiftData

// Emoji değişikliklerini dinlemek için ObservableObject sınıfı
class CalendarStateManager: ObservableObject {
    @Published var updateTrigger = false
    
    init() {
        // Emoji değişikliklerini dinle
        NotificationCenter.default.addObserver(forName: Notification.Name("CoreEmojiChanged"), object: nil, queue: .main) { [weak self] _ in
            // Görünümü yenile
            self?.objectWillChange.send()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("NapEmojiChanged"), object: nil, queue: .main) { [weak self] _ in
            // Görünümü yenile
            self?.objectWillChange.send()
        }
    }
}

struct CalendarView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @Environment(\.calendar) var calendar
    @Environment(\.timeZone) var timeZone
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMode: CalendarMode = .day
    @State private var rangeStart: Date?
    @State private var rangeEnd: Date?
    @State private var showMonthYear = false
    @State private var selectedMonthOffset = 0
    @StateObject private var stateManager = CalendarStateManager()
    
    private let daysInWeek = 7
    private let gridSpacing: CGFloat = 8
    private let cellSize: CGFloat = 40
    
    // Kullanıcının seçtiği emojiler
    private var coreEmoji: String {
        UserDefaults.standard.string(forKey: "selectedCoreEmoji") ?? "🌙"
    }
    
    private var napEmoji: String {
        UserDefaults.standard.string(forKey: "selectedNapEmoji") ?? "⚡"
    }
    
    // Kullanıcı emoji değişikliklerini takip et
    init(viewModel: HistoryViewModel) {
        self.viewModel = viewModel
    }
    
    private var month: Date {
        viewModel.selectedDay ?? Date()
    }
    
    private var weeks: [[Date]] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }
        let monthStart = monthInterval.start
        
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let weekdayOffset = (firstWeekday + 5) % 7
        
        let days = stride(from: -weekdayOffset, through: 40, by: 1).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: monthStart)
        }
        
        return days.chunked(into: 7)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Başlık ve mod seçimi
            VStack(spacing: 12) {
                HStack {
                    Text(monthTitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color("TextColor"))
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            if let newMonth = calendar.date(byAdding: .month, value: -1, to: month) {
                                viewModel.selectedDay = newMonth
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(Color("PrimaryColor"))
                                .font(.system(size: 14, weight: .semibold))
                                .padding(8)
                                .background(Circle().fill(Color("CardBackground")))
                        }
                        
                        Button(action: {
                            if let newMonth = calendar.date(byAdding: .month, value: 1, to: month) {
                                viewModel.selectedDay = newMonth
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color("PrimaryColor"))
                                .font(.system(size: 14, weight: .semibold))
                                .padding(8)
                                .background(Circle().fill(Color("CardBackground")))
                        }
                    }
                }
                
                // Mod seçimi
                HStack(spacing: 0) {
                    SegmentedModeButton(
                        title: "Gün",
                        systemImage: "calendar.day.fill",
                        isSelected: selectedMode == .day,
                        action: { selectedMode = .day }
                    )
                    
                    SegmentedModeButton(
                        title: "Aralık",
                        systemImage: "calendar.badge.clock",
                        isSelected: selectedMode == .range,
                        action: { selectedMode = .range }
                    )
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("CardBackground").opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("SecondaryTextColor").opacity(0.2), lineWidth: 1)
                )
            }
            .padding(.horizontal, 16)
            
            // Gün başlıkları
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: daysInWeek), spacing: gridSpacing) {
                ForEach(0..<daysInWeek, id: \.self) { index in
                    let weekdaySymbol = calendar.shortWeekdaySymbols[(index + 1) % 7]
                    Text(weekdaySymbol)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("SecondaryTextColor"))
                        .frame(width: cellSize, height: 24)
                }
            }
            
            // Ay görünümü
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: daysInWeek), spacing: gridSpacing) {
                ForEach(weeks.indices, id: \.self) { weekIndex in
                    ForEach(weeks[weekIndex].indices, id: \.self) { dayIndex in
                        let date = weeks[weekIndex][dayIndex]
                        DayCell(
                            date: date,
                            viewModel: viewModel,
                            selectionMode: selectedMode,
                            rangeStart: $rangeStart,
                            rangeEnd: $rangeEnd
                        )
                    }
                }
            }
            
            // Butonlar
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.selectedDay = Date()
                    if selectedMode == .day {
                        viewModel.selectDay(Date())
                    }
                }) {
                    Text("Bugün")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("PrimaryColor"))
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color("PrimaryColor"), lineWidth: 1.5)
                        )
                }
                
                if selectedMode == .range {
                    Button(action: {
                        if let start = rangeStart, let end = rangeEnd {
                            viewModel.setDateRange(start...end)
                            dismiss()
                        }
                    }) {
                        Text("Aralığı Uygula")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        rangeStart != nil && rangeEnd != nil ? Color("PrimaryColor") : Color.gray.opacity(0.3)
                                    )
                            )
                    }
                    .disabled(rangeStart == nil || rangeEnd == nil)
                } else {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Tamam")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color("PrimaryColor"))
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color("CardBackground"))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .onChange(of: selectedMode) { newMode in
            if newMode == .day {
                rangeStart = nil
                rangeEnd = nil
            }
        }
    }
    
    // Haftanın başlıkları
    private var daysOfWeek: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols
    }
    
    // Ay başlığı
    private var monthTitle: String {
        let date = Calendar.current.date(byAdding: .month, value: selectedMonthOffset, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

struct SegmentedModeButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 14))
                
                Text(title)
                    .font(.system(size: 14))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .foregroundColor(isSelected ? .white : Color("SecondaryTextColor"))
            .background(
                isSelected ?
                    RoundedRectangle(cornerRadius: 8)
                    .fill(Color("PrimaryColor"))
                    .shadow(color: Color("PrimaryColor").opacity(0.2), radius: 3, x: 0, y: 2)
                : nil
            )
        }
    }
}

enum CalendarMode {
    case day
    case range
}

struct DayCell: View {
    let date: Date
    @ObservedObject var viewModel: HistoryViewModel
    let selectionMode: CalendarMode
    @Binding var rangeStart: Date?
    @Binding var rangeEnd: Date?
    @Environment(\.calendar) var calendar
    
    private var historyItem: HistoryModel? {
        viewModel.getHistoryItem(for: date)
    }
    
    private var isSelected: Bool {
        if selectionMode == .day {
            guard let selectedDay = viewModel.selectedDay else { return false }
            return calendar.isDate(date, inSameDayAs: selectedDay)
        } else {
            return isInSelectedRange
        }
    }
    
    private var isInSelectedRange: Bool {
        if let start = rangeStart, let end = rangeEnd {
            let startDay = calendar.startOfDay(for: start)
            let endDay = calendar.startOfDay(for: end)
            let thisDay = calendar.startOfDay(for: date)
            
            return (thisDay >= startDay && thisDay <= endDay) ||
                   (thisDay >= endDay && thisDay <= startDay)
        } else if let start = rangeStart {
            return calendar.isDate(date, inSameDayAs: start)
        }
        return false
    }
    
    private var isRangeStart: Bool {
        guard let start = rangeStart else { return false }
        return calendar.isDate(date, inSameDayAs: start)
    }
    
    private var isRangeEnd: Bool {
        guard let end = rangeEnd else { return false }
        return calendar.isDate(date, inSameDayAs: end)
    }
    
    private var isInCurrentMonth: Bool {
        guard let selectedDay = viewModel.selectedDay else { return true }
        return calendar.component(.month, from: date) == calendar.component(.month, from: selectedDay)
    }
    
    private var isToday: Bool {
        return calendar.isDateInToday(date)
    }
    
    var body: some View {
        Button(action: {
            if selectionMode == .day {
                viewModel.selectDay(date)
            } else {
                handleRangeSelection()
            }
        }) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected || isToday ? .semibold : .regular))
                    .foregroundColor(cellTextColor)
                
                if let item = historyItem {
                    Circle()
                        .fill(Color(item.completionStatus.color))
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 38, height: 38)
            .background(
                ZStack {
                    if isRangeStart {
                        // Aralık başlangıcı
                        HStack {
                            Circle()
                                .fill(Color("PrimaryColor"))
                            Rectangle()
                                .fill(Color("PrimaryColor").opacity(0.2))
                        }
                        .clipped()
                    } else if isRangeEnd {
                        // Aralık sonu
                        HStack {
                            Rectangle()
                                .fill(Color("PrimaryColor").opacity(0.2))
                            Circle()
                                .fill(Color("PrimaryColor"))
                        }
                        .clipped()
                    } else if isInSelectedRange {
                        // Aralık içi
                        Rectangle()
                            .fill(Color("PrimaryColor").opacity(0.2))
                    }
                    
                    // Tek gün seçimi veya bugün gösterimi
                    if isSelected && selectionMode == .day || (isRangeStart && rangeEnd == nil) {
                        Circle()
                            .fill(Color("PrimaryColor"))
                    } else if isToday && !isSelected {
                        Circle()
                            .stroke(Color("PrimaryColor"), lineWidth: 1.5)
                    }
                }
            )
            .opacity(isInCurrentMonth ? 1.0 : 0.3)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func handleRangeSelection() {
        // Eğer hiç seçim yoksa, başlangıç olarak ayarla
        if rangeStart == nil {
            rangeStart = date
            return
        }
        
        // Eğer başlangıç varsa ama bitiş yoksa, bitiş ayarla
        if rangeEnd == nil {
            let startDate = calendar.startOfDay(for: rangeStart!)
            let currentDate = calendar.startOfDay(for: date)
            
            if currentDate < startDate {
                // Eğer seçilen tarih başlangıçtan önceyse, yer değiştir
                rangeEnd = rangeStart
                rangeStart = date
            } else {
                rangeEnd = date
            }
            return
        }
        
        // Eğer iki tarih de seçiliyse, sıfırla ve yeni başlangıç ayarla
        rangeStart = date
        rangeEnd = nil
    }
    
    private var cellTextColor: Color {
        if isSelected || (isInSelectedRange && (isRangeStart || isRangeEnd)) {
            return .white
        } else if !isInCurrentMonth {
            return Color("SecondaryTextColor").opacity(0.3)
        } else {
            return Color("TextColor")
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
