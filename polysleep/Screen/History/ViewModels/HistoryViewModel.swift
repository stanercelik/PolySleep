import Foundation
import SwiftUI

enum TimeFilter: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case allTime = "All Time"
}

enum SleepTypeFilter: String, CaseIterable {
    case all = "All Sleep"
    case core = "Core Sleep Only"
    case nap = "Naps Only"
}

class HistoryViewModel: ObservableObject {
    @Published var historyItems: [HistoryModel] = []
    @Published var selectedFilter: TimeFilter = .today
    @Published var selectedSleepTypeFilter: SleepTypeFilter = .all
    @Published var isCalendarPresented = false
    @Published var isFilterMenuPresented = false
    @Published var selectedDateRange: ClosedRange<Date>?
    @Published var isCustomFilterVisible = false
    @Published var selectedDay: Date?
    @Published var isDayDetailPresented = false
    
    private var allHistoryItems: [HistoryModel] = []
    private var lastCustomDateRange: ClosedRange<Date>?
    
    init() {
        loadMockData()
        filterAndSortItems()
    }
    
    func setFilter(_ filter: TimeFilter) {
        selectedFilter = filter
        selectedDateRange = nil
        isCustomFilterVisible = false
        filterAndSortItems()
    }
    
    func setSleepTypeFilter(_ filter: SleepTypeFilter) {
        selectedSleepTypeFilter = filter
        filterAndSortItems()
    }
    
    func setDateRange(_ range: ClosedRange<Date>) {
        selectedDateRange = range
        lastCustomDateRange = range
        isCustomFilterVisible = true
        filterAndSortItems()
    }
    
    func selectDay(_ date: Date) {
        selectedDay = date
        isDayDetailPresented = true
    }
    
    func getHistoryItem(for date: Date) -> HistoryModel? {
        let calendar = Calendar.current
        return allHistoryItems.first { item in
            calendar.isDate(item.date, inSameDayAs: date)
        }
    }
    
    private func filterAndSortItems() {
        let calendar = Calendar.current
        let now = Date()
        
        // Time Filter
        var filteredItems: [HistoryModel]
        if isCustomFilterVisible, let range = selectedDateRange {
            filteredItems = allHistoryItems.filter { item in
                let startOfDay = calendar.startOfDay(for: item.date)
                return startOfDay >= calendar.startOfDay(for: range.lowerBound) &&
                       startOfDay <= calendar.startOfDay(for: range.upperBound)
            }
        } else {
            switch selectedFilter {
            case .today:
                filteredItems = allHistoryItems.filter { item in
                    calendar.isDate(item.date, equalTo: now, toGranularity: .day)
                }
                
            case .thisWeek:
                let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
                let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
                
                filteredItems = allHistoryItems.filter { item in
                    let itemDate = calendar.startOfDay(for: item.date)
                    return itemDate >= startOfWeek && itemDate < endOfWeek
                }
                
            case .thisMonth:
                let components = calendar.dateComponents([.year, .month], from: now)
                let startOfMonth = calendar.date(from: components)!
                let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
                
                filteredItems = allHistoryItems.filter { item in
                    let itemDate = calendar.startOfDay(for: item.date)
                    return itemDate >= startOfMonth && itemDate <= endOfMonth
                }
                
            case .allTime:
                filteredItems = allHistoryItems
            }
        }
        
        // Sleep Type Filter
        filteredItems = filteredItems.map { item in
            var newItem = item
            switch selectedSleepTypeFilter {
            case .all:
                break
            case .core:
                newItem.sleepEntries = item.sleepEntries.filter { $0.type == .core }
            case .nap:
                newItem.sleepEntries = item.sleepEntries.filter { $0.type == .powerNap }
            }
            return newItem
        }.filter { !$0.sleepEntries.isEmpty }
        
        // Sort by date (latest first)
        historyItems = filteredItems.sorted { $0.date > $1.date }
    }
    
    // Mock Data
    private func loadMockData() {
        let calendar = Calendar.current
        let now = Date()
        var mockItems: [HistoryModel] = []
        
        for dayOffset in 0...30 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            
            // Core Sleep
            let coreSleepStart = calendar.date(bySettingHour: 23, minute: Int.random(in: 0...59), second: 0, of: date)!
            let coreSleepEnd = calendar.date(byAdding: .hour, value: 6, to: coreSleepStart)!
            let coreSleep = SleepEntry(type: .core, startTime: coreSleepStart, endTime: coreSleepEnd, rating: Int.random(in: 3...5))
            
            // Power Nap
            var entries = [coreSleep]
            if Bool.random() {
                let napStart = calendar.date(bySettingHour: 14, minute: Int.random(in: 0...59), second: 0, of: date)!
                let napEnd = calendar.date(byAdding: .minute, value: 30, to: napStart)!
                let powerNap = SleepEntry(type: .powerNap, startTime: napStart, endTime: napEnd, rating: Int.random(in: 2...5))
                entries.append(powerNap)
            }
            
            let historyItem = HistoryModel(date: date, sleepEntries: entries)
            mockItems.append(historyItem)
        }
        
        allHistoryItems = mockItems.sorted { $0.date > $1.date }
        historyItems = allHistoryItems
    }
}
