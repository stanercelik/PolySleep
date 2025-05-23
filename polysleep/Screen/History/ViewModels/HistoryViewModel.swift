import Foundation
import SwiftUI
import SwiftData
import Combine

enum TimeFilter: String, CaseIterable {
    case today = "history.filter.today"
    case thisWeek = "history.filter.thisWeek"
    case thisMonth = "history.filter.thisMonth"
    case allTime = "history.filter.allTime"
}

enum SyncStatus {
    case synced
    case pendingSync
    case offline
    case error(String)
}

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var historyItems: [HistoryModel] = []
    @Published var selectedFilter: TimeFilter = .allTime
    @Published var isFilterMenuPresented = false
    @Published var selectedDay: Date?
    @Published var isDayDetailPresented = false
    @Published var isAddSleepEntryPresented = false
    @Published var isSyncing = false
    @Published var syncError: String?
    @Published var syncStatus: SyncStatus = .synced
    
    var modelContext: ModelContext?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        if modelContext != nil {
            loadHistoryItems()
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadHistoryItems()
    }
    
    func setFilter(_ filter: TimeFilter) {
        selectedFilter = filter
        loadHistoryItems()
    }
    
    func selectDateForDetail(_ date: Date) {
        selectedDay = date
        isDayDetailPresented = true
    }
    
    func getHistoryItem(for date: Date) -> HistoryModel? {
        let calendar = Calendar.current
        return historyItems.first { item in
            calendar.isDate(item.date, inSameDayAs: date)
        }
    }
    
    func addSleepEntry(_ newSleepEntry: SleepEntry) {
        guard let modelContext = modelContext else { return }
        
        let calendar = Calendar.current
        let entryDayStart = calendar.startOfDay(for: newSleepEntry.date)
        
        var historyModelForDay: HistoryModel?
        let predicate = #Predicate<HistoryModel> { $0.date == entryDayStart }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            historyModelForDay = try modelContext.fetch(descriptor).first
            
            if historyModelForDay == nil {
                historyModelForDay = HistoryModel(date: entryDayStart)
                modelContext.insert(historyModelForDay!)
                print("Yeni HistoryModel oluşturuldu: \(entryDayStart)")
            }
            
            newSleepEntry.historyDay = historyModelForDay
            historyModelForDay?.sleepEntries?.append(newSleepEntry)
            
            modelContext.insert(newSleepEntry)
            
            try modelContext.save()
            print("SleepEntry ve HistoryModel bağlantısı kaydedildi.")
            loadHistoryItems()
            
        } catch {
            print("SleepEntry eklenirken veya HistoryModel bulunurken hata: \(error)")
            syncStatus = .error("Failed to add sleep entry: \(error.localizedDescription)")
        }
    }
    
    func deleteSleepEntry(_ entry: SleepEntry) {
        guard let modelContext = modelContext else { return }
        
        modelContext.delete(entry)
        saveChanges()
    }
    
    private func loadHistoryItems() {
        guard let modelContext = modelContext else {
            self.historyItems = []
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        var predicate: Predicate<HistoryModel>? = nil

        switch selectedFilter {
        case .today:
            let todayStart = calendar.startOfDay(for: now)
            predicate = #Predicate<HistoryModel> { $0.date == todayStart }
        case .thisWeek:
            guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else { return }
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
            predicate = #Predicate<HistoryModel> { $0.date >= startOfWeek && $0.date < endOfWeek }
        case .thisMonth:
            guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else { return }
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            predicate = #Predicate<HistoryModel> { $0.date >= startOfMonth && $0.date < endOfMonth }
        case .allTime:
            predicate = nil
        }

        let descriptor = FetchDescriptor<HistoryModel>(predicate: predicate, sortBy: [SortDescriptor(\HistoryModel.date, order: .reverse)])
        
        do {
            self.historyItems = try modelContext.fetch(descriptor)
            print("\(self.historyItems.count) adet HistoryModel yüklendi (Filtre: \(selectedFilter.rawValue)).")
            syncStatus = .synced
        } catch {
            print("HistoryModel verileri yüklenirken hata oluştu: \(error)")
            syncStatus = .error("Failed to load history: \(error.localizedDescription)")
        }
    }
    
    private func saveChanges() {
        guard let modelContext = modelContext else {
            print("ModelContext ayarlanmamış, veriler kaydedilemedi")
            syncStatus = .error("Data context not available.")
            return
        }
        
        do {
            try modelContext.save()
            print("Değişiklikler başarıyla kaydedildi")
            loadHistoryItems()
            syncStatus = .synced
        } catch {
            print("Değişiklikler kaydedilirken hata oluştu: \(error)")
            syncStatus = .error("Failed to save data: \(error.localizedDescription)")
        }
    }
    
    func reloadData() {
        loadHistoryItems()
    }
    
    func syncData() {
        isSyncing = true
        syncError = nil
        print("SyncData çağrıldı (offline modda işlem yok).")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isSyncing = false
        }
    }
}
