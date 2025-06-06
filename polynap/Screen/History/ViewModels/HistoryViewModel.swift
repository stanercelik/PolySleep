import Foundation
import SwiftUI
import SwiftData
import Combine

enum TimeFilter: String, CaseIterable {
    case today = "history.filter.today"
    case thisWeek = "history.filter.thisWeek"
    case thisMonth = "history.filter.thisMonth"
    case allTime = "history.filter.allTime"
    
    var localizedTitle: String {
        return L(self.rawValue, table: "History")
    }
}

enum SyncStatus {
    case synced
    case pendingSync
    case offline
    case error(String)
}

@MainActor
class HistoryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var historyItems: [HistoryModel] = []
    @Published var selectedFilter: TimeFilter = .allTime
    @Published var isFilterMenuPresented = false
    @Published var selectedDay: Date?
    @Published var isDayDetailPresented = false
    @Published var isAddSleepEntryPresented = false
    @Published var isSyncing = false
    @Published var syncError: String?
    @Published var syncStatus: SyncStatus = .synced
    
    // MARK: - Private Properties
    var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        if modelContext != nil {
            loadHistoryItems()
        }
    }
    
    // MARK: - Public Methods
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
        guard let modelContext = modelContext else {
            handleError("ModelContext not available")
            return
        }
        
        do {
            let historyModel = try getOrCreateHistoryModel(for: newSleepEntry.date)
            
            // Entry'yi history model'e bağla
            newSleepEntry.historyDay = historyModel
            historyModel.sleepEntries?.append(newSleepEntry)
            
            // Context'e ekle ve kaydet
            modelContext.insert(newSleepEntry)
            try modelContext.save()
            
            loadHistoryItems()
            print("SleepEntry başarıyla eklendi: \(newSleepEntry.id)")
            
        } catch {
            handleError("Failed to add sleep entry: \(error.localizedDescription)")
        }
    }
    
    func deleteSleepEntry(_ entry: SleepEntry) {
        guard let modelContext = modelContext else {
            handleError("ModelContext not available")
            return
        }
        
        let historyDay = entry.historyDay
        
        Task { @MainActor in
            do {
                // Entry'yi sil
                modelContext.delete(entry)
                
                // Eğer HistoryModel boş kaldıysa onu da sil
                if let historyDay = historyDay,
                   let sleepEntries = historyDay.sleepEntries,
                   sleepEntries.count <= 1 { // <= 1 çünkü henüz silinmemiş
                    modelContext.delete(historyDay)
                    print("Boş HistoryModel silindi: \(historyDay.date)")
                }
                
                try modelContext.save()
                
                // UI'ı güncelle
                await refreshData()
                
                print("SleepEntry başarıyla silindi: \(entry.id)")
                
            } catch {
                handleError("Failed to delete sleep entry: \(error.localizedDescription)")
            }
        }
    }
    
    func updateSleepEntry(_ entry: SleepEntry) {
        guard let modelContext = modelContext else {
            handleError("ModelContext not available")
            return
        }
        
        do {
            entry.updatedAt = Date()
            try modelContext.save()
            loadHistoryItems()
            print("SleepEntry başarıyla güncellendi: \(entry.id)")
            
        } catch {
            handleError("Failed to update sleep entry: \(error.localizedDescription)")
        }
    }
    
    func deleteHistoryDay(_ historyModel: HistoryModel) {
        guard let modelContext = modelContext else {
            handleError("ModelContext not available")
            return
        }
        
        do {
            // İlişkili tüm sleep entry'leri de silinecek (cascade delete)
            modelContext.delete(historyModel)
            try modelContext.save()
            loadHistoryItems()
            print("HistoryModel ve ilişkili entry'ler silindi: \(historyModel.date)")
            
        } catch {
            handleError("Failed to delete history day: \(error.localizedDescription)")
        }
    }
    
    func reloadData() {
        // State'leri temizle
        isAddSleepEntryPresented = false
        isDayDetailPresented = false
        selectedDay = nil
        
        // Data'yı yeniden yükle
        loadHistoryItems()
        
        // UI'ı güncelle
        objectWillChange.send()
    }
    
    func syncData() {
        isSyncing = true
        syncError = nil
        print("SyncData çağrıldı (offline modda işlem yok).")
        
        // Simulated sync delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isSyncing = false
            self?.syncStatus = .synced
        }
    }
    
    // MARK: - Private Methods
    private func loadHistoryItems() {
        guard let modelContext = modelContext else {
            self.historyItems = []
            handleError("ModelContext not available")
            return
        }
        
        do {
            let predicate = createFilterPredicate()
            let descriptor = FetchDescriptor<HistoryModel>(
                predicate: predicate,
                sortBy: [SortDescriptor(\HistoryModel.date, order: .reverse)]
            )
            
            let allHistoryItems = try modelContext.fetch(descriptor)
            
            // Sadece en az bir SleepEntry'si olan günleri filtrele
            self.historyItems = allHistoryItems.filter { historyModel in
                guard let sleepEntries = historyModel.sleepEntries else { return false }
                return !sleepEntries.isEmpty
            }
            
            syncStatus = .synced
            print("\(self.historyItems.count) adet HistoryModel yüklendi (Filtre: \(selectedFilter.rawValue))")
            
        } catch {
            handleError("Failed to load history: \(error.localizedDescription)")
        }
    }
    
    private func createFilterPredicate() -> Predicate<HistoryModel>? {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedFilter {
        case .today:
            let todayStart = calendar.startOfDay(for: now)
            return #Predicate<HistoryModel> { $0.date == todayStart }
            
        case .thisWeek:
            guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
                return nil
            }
            guard let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else {
                return nil
            }
             return #Predicate<HistoryModel> { $0.date >= startOfWeek && $0.date < endOfWeek }

         case .thisMonth:
             guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
                 return nil
             }
            guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
                return nil
            }
             return #Predicate<HistoryModel> { $0.date >= startOfMonth && $0.date < endOfMonth }
            
        case .allTime:
            return nil
        }
    }
    
    private func getOrCreateHistoryModel(for date: Date) throws -> HistoryModel {
        guard let modelContext = modelContext else {
            throw HistoryError.contextNotAvailable
        }
        
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        // Var olan HistoryModel'i ara
        let predicate = #Predicate<HistoryModel> { $0.date == dayStart }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        if let existingModel = try modelContext.fetch(descriptor).first {
            return existingModel
        }
        
        // Yeni HistoryModel oluştur
        let newModel = HistoryModel(date: dayStart)
        modelContext.insert(newModel)
        print("Yeni HistoryModel oluşturuldu: \(dayStart)")
        
        return newModel
    }
    
    private func handleError(_ message: String) {
        syncError = message
        syncStatus = .error(message)
        print("HistoryViewModel Error: \(message)")
    }
    
    // Yeni refresh metodu
    @MainActor
    private func refreshData() {
        // State'leri sıfırla
        isAddSleepEntryPresented = false
        isDayDetailPresented = false
        selectedDay = nil
        
        // Data'yı yeniden yükle
        loadHistoryItems()
        
        // Published property'leri güncelle
        objectWillChange.send()
    }
}

// MARK: - Error Types
enum HistoryError: LocalizedError {
    case contextNotAvailable
    case invalidDate
    case entryNotFound
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Data context is not available"
        case .invalidDate:
            return "Invalid date provided"
        case .entryNotFound:
            return "Sleep entry not found"
        }
    }
}
