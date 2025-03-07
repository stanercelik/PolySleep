import Foundation
import SwiftUI
import SwiftData

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
    @Published var isAddSleepEntryPresented = false
    
    private var allHistoryItems: [HistoryModel] = []
    private var lastCustomDateRange: ClosedRange<Date>?
    private var modelContext: ModelContext?
    
    init() {
        loadData()
        filterAndSortItems()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadData()
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
    
    // Yeni uyku kaydı ekleme
    func addSleepEntry(_ entry: SleepEntry) {
        // Giriş parametresi olarak verilen UUID'yi kullan, yeni oluşturma
        // entry.id = UUID()
        
        let calendar = Calendar.current
        let entryDate = calendar.startOfDay(for: entry.startTime)
        
        // Aynı güne ait bir kayıt var mı kontrol et
        if let existingItemIndex = allHistoryItems.firstIndex(where: { calendar.isDate($0.date, equalTo: entryDate, toGranularity: .day) }) {
            // Varsa, o güne ait kayıtlara ekle
            // Önce aynı zaman aralığında bir kayıt var mı kontrol et
            let existingEntries = allHistoryItems[existingItemIndex].sleepEntries
            let hasDuplicateEntry = existingEntries.contains { existingEntry in
                let sameStartHour = calendar.component(.hour, from: existingEntry.startTime) == calendar.component(.hour, from: entry.startTime)
                let sameStartMinute = calendar.component(.minute, from: existingEntry.startTime) == calendar.component(.minute, from: entry.startTime)
                let sameEndHour = calendar.component(.hour, from: existingEntry.endTime) == calendar.component(.hour, from: entry.endTime)
                let sameEndMinute = calendar.component(.minute, from: existingEntry.endTime) == calendar.component(.minute, from: entry.endTime)
                
                return sameStartHour && sameStartMinute && sameEndHour && sameEndMinute
            }
            
            if !hasDuplicateEntry {
                // ModelContext'e ekle
                if let modelContext = modelContext {
                    modelContext.insert(entry)
                }
                
                // Mevcut HistoryModel'e ekle
                allHistoryItems[existingItemIndex].sleepEntries.append(entry)
                
                // Kayıtları başlangıç saatine göre sırala
                allHistoryItems[existingItemIndex].sleepEntries.sort { $0.startTime < $1.startTime }
                
                // Tamamlanma durumunu güncelle
                updateCompletionStatus(for: allHistoryItems[existingItemIndex])
            }
        } else {
            // Yoksa, yeni bir gün kaydı oluştur
            let newItem = HistoryModel(date: entryDate, sleepEntries: [entry])
            
            // ModelContext'e ekle
            if let modelContext = modelContext {
                modelContext.insert(newItem)
                modelContext.insert(entry)
            }
            
            allHistoryItems.append(newItem)
        }
        
        // Filtreleri uygula ve sırala
        filterAndSortItems()
        
        // SwiftData'ya kaydet
        saveData()
    }
    
    // Uyku kaydını silme
    func deleteSleepEntry(_ entry: SleepEntry) {
        // Tüm geçmiş öğelerini kontrol et
        for (itemIndex, historyItem) in allHistoryItems.enumerated() {
            // Silinecek kaydı bul
            if let entryIndex = historyItem.sleepEntries.firstIndex(where: { $0.id == entry.id }) {
                // ModelContext'ten sil
                if let modelContext = modelContext {
                    modelContext.delete(entry)
                }
                
                // Kaydı sil
                allHistoryItems[itemIndex].sleepEntries.remove(at: entryIndex)
                
                // Tamamlanma durumunu güncelle
                updateCompletionStatus(for: allHistoryItems[itemIndex])
                
                // Eğer günde başka kayıt kalmadıysa, günü de sil
                if allHistoryItems[itemIndex].sleepEntries.isEmpty {
                    // ModelContext'ten sil
                    if let modelContext = modelContext {
                        modelContext.delete(allHistoryItems[itemIndex])
                    }
                    
                    allHistoryItems.remove(at: itemIndex)
                }
                
                // Filtreleri uygula ve sırala
                filterAndSortItems()
                
                // SwiftData'ya kaydet
                saveData()
                
                return
            }
        }
    }
    
    private func updateCompletionStatus(for historyItem: HistoryModel) {
        let totalSleepDuration = historyItem.totalSleepDuration
        
        if totalSleepDuration >= 21600 { // 6 saat veya daha fazla
            historyItem.completionStatus = .completed
        } else if totalSleepDuration >= 10800 { // 3 saat veya daha fazla
            historyItem.completionStatus = .partial
        } else {
            historyItem.completionStatus = .missed
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
            let newItem = item
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
    
    // SwiftData ile veri yükleme
    private func loadData() {
        guard let modelContext = modelContext else {
            // ModelContext henüz ayarlanmamış, örnek veri oluştur
            _ = Calendar.current
            let now = Date()
            
            // Bugün için boş bir kayıt oluştur
            let todayItem = HistoryModel(date: now, sleepEntries: [])
            allHistoryItems = [todayItem]
            
            filterAndSortItems()
            return
        }
        
        // SwiftData'dan tüm HistoryModel kayıtlarını al
        let descriptor = FetchDescriptor<HistoryModel>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        
        do {
            allHistoryItems = try modelContext.fetch(descriptor)
            
            // Eğer hiç kayıt yoksa, bugün için boş bir kayıt oluştur
            if allHistoryItems.isEmpty {
                let now = Date()
                let todayItem = HistoryModel(date: now, sleepEntries: [])
                allHistoryItems = [todayItem]
            }
            
            filterAndSortItems()
        } catch {
            print("HistoryModel verilerini yüklerken hata oluştu: \(error)")
        }
    }
    
    // SwiftData'ya kaydetme
    private func saveData() {
        guard let modelContext = modelContext else {
            print("ModelContext ayarlanmamış, veriler kaydedilemedi")
            return
        }
        
        do {
            try modelContext.save()
            print("Veriler başarıyla kaydedildi")
        } catch {
            print("Verileri kaydederken hata oluştu: \(error)")
        }
    }
}
