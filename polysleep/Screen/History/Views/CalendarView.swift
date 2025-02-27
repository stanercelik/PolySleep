import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @Environment(\.calendar) var calendar
    @Environment(\.timeZone) var timeZone
    
    private let daysInWeek = 7
    private let gridSpacing: CGFloat = 8
    private let cellSize: CGFloat = 40
    
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
            HStack {
                Text(month.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color("TextColor"))
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: {
                        if let newMonth = calendar.date(byAdding: .month, value: -1, to: month) {
                            viewModel.selectedDay = newMonth
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color("AccentColor"))
                    }
                    
                    Button(action: {
                        if let newMonth = calendar.date(byAdding: .month, value: 1, to: month) {
                            viewModel.selectedDay = newMonth
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color("AccentColor"))
                    }
                }
            }
            .padding(.horizontal)
            
            HStack(spacing: gridSpacing) {
                ForEach(0..<7, id: \.self) { index in
                    let weekday = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"][index]
                    Text("weekday.\(weekday)", tableName: "CalendarView")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("SecondaryTextColor"))
                        .frame(width: cellSize)
                }
            }
            
            VStack(spacing: gridSpacing) {
                ForEach(weeks, id: \.self) { week in
                    HStack(spacing: gridSpacing) {
                        ForEach(week, id: \.self) { date in
                            if calendar.isDate(date, equalTo: month, toGranularity: .month) {
                                DayCell(date: date, viewModel: viewModel)
                            } else {
                                Color.clear.frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical)
        .background(Color("CardBackground"))
    }
}

struct DayCell: View {
    let date: Date
    @ObservedObject var viewModel: HistoryViewModel
    @Environment(\.calendar) var calendar
    
    private var historyItem: HistoryModel? {
        viewModel.getHistoryItem(for: date)
    }
    
    private var isSelected: Bool {
        guard let selectedDay = viewModel.selectedDay else { return false }
        return calendar.isDate(date, inSameDayAs: selectedDay)
    }
    
    var body: some View {
        Button(action: {
            viewModel.selectDay(date)
        }) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : Color("TextColor"))
                
                if let item = historyItem {
                    Circle()
                        .fill(Color(item.completionStatus.color))
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(isSelected ? Color("PrimaryColor") : Color.clear)
            )
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
