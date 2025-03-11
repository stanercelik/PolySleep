import Foundation
import SwiftUI
import SwiftData
import Supabase
import Combine

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

/// Senkronizasyon durumunu takip etmek için kullanılan enum
enum SyncStatus {
    case synced
    case pendingSync
    case offline
    case error(String)
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
    @Published var isSyncing = false
    @Published var syncError: String?
    @Published var syncStatus: SyncStatus = .synced
    
    private var allHistoryItems: [HistoryModel] = []
    private var lastCustomDateRange: ClosedRange<Date>?
    private var modelContext: ModelContext?
    private var supabaseService: SupabaseHistoryService {
        return SupabaseService.shared.history
    }
    private var networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    private var pendingSyncEntries = Set<UUID>()
    
    init() {
        loadData()
        filterAndSortItems()
        setupNetworkMonitoring()
    }
    
    /// Ağ durumunu izlemek için gerekli ayarları yapar
    private func setupNetworkMonitoring() {
        // İnternet bağlantısı değişikliklerini izle
        networkMonitor.$isConnected
            .dropFirst() // İlk değeri atla (başlangıç değeri)
            .sink { [weak self] isConnected in
                if isConnected {
                    // İnternet bağlantısı sağlandığında bekleyen değişiklikleri senkronize et
                    self?.syncStatus = .synced
                    Task { @MainActor in
                        await self?.syncPendingChanges()
                    }
                } else {
                    // İnternet bağlantısı kesildiğinde offline durumuna geç
                    self?.syncStatus = .offline
                }
            }
            .store(in: &cancellables)
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
    
    // MARK: - Supabase Senkronizasyon Metodları
    
    /// Bekleyen tüm değişiklikleri senkronize eder
    @MainActor
    private func syncPendingChanges() async {
        guard networkMonitor.isConnected, !pendingSyncEntries.isEmpty else { return }
        
        isSyncing = true
        syncStatus = .synced
        syncError = nil
        
        do {
            // Bekleyen her kayıt için
            for entryId in pendingSyncEntries {
                // Yerel kayıtlarda bu ID ile bir kayıt var mı kontrol et
                let descriptor = FetchDescriptor<SleepEntry>(
                    predicate: #Predicate<SleepEntry> { entry in
                        entry.id == entryId
                    }
                )
                
                guard let modelContext = modelContext else { continue }
                let localEntries = try modelContext.fetch(descriptor)
                
                if let entry = localEntries.first {
                    // Kayıt hala varsa, Supabase'e senkronize et
                    await syncEntryToSupabase(entry)
                } else {
                    // Kayıt silinmişse, Supabase'den de sil
                    await deleteEntryFromSupabase(entryId)
                }
                
                // Senkronize edilen kaydı bekleyen listesinden çıkar
                pendingSyncEntries.remove(entryId)
            }
            
            // Tüm Supabase verilerini getir ve yerel verileri güncelle
            await syncDataFromSupabase()
            
            isSyncing = false
        } catch {
            print("PolySleep Debug: Bekleyen değişiklikleri senkronize ederken hata: \(error)")
            syncError = NSLocalizedString("supabase.error.sync", comment: "")
            syncStatus = .error(syncError ?? "")
            isSyncing = false
        }
    }
    
    /// Supabase'den verileri senkronize eder
    @MainActor
    func syncDataFromSupabase() async {
        guard networkMonitor.isConnected else {
            syncStatus = .offline
            return
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            // Supabase'den tüm uyku kayıtlarını getir
            let remoteEntries = try await supabaseService.fetchAllSleepEntries()
            
            // Yerel kayıtları güncelle
            await updateLocalEntriesWithRemote(remoteEntries)
            
            syncStatus = .synced
            isSyncing = false
        } catch {
            print("PolySleep Debug: Supabase senkronizasyon hatası: \(error)")
            syncError = NSLocalizedString("supabase.error.sync", comment: "")
            syncStatus = .error(syncError ?? "")
            isSyncing = false
        }
    }
    
    /// Uzak kayıtlarla yerel kayıtları günceller
    @MainActor
    private func updateLocalEntriesWithRemote(_ remoteEntries: [SupabaseHistoryService.SleepEntryDTO]) async {
        guard let modelContext = modelContext else { return }
        
        let calendar = Calendar.current
        
        // Her uzak kayıt için
        for remoteEntry in remoteEntries {
            // Yerel kayıtlarda bu ID ile bir kayıt var mı kontrol et
            let descriptor = FetchDescriptor<SleepEntry>(
                predicate: #Predicate<SleepEntry> { entry in
                    entry.id == remoteEntry.id
                }
            )
            
            do {
                let localEntries = try modelContext.fetch(descriptor)
                
                if localEntries.isEmpty {
                    // Yerel kayıt yoksa, yeni bir kayıt oluştur
                    let entryDate = remoteEntry.date
                    let startTime = entryDate
                    
                    // Block ID'den uyku tipini belirle
                    let sleepType: SleepType = remoteEntry.block_id.contains("nap") ? .powerNap : .core
                    
                    // Bitiş zamanını hesapla (örnek olarak, gerçek uygulamada block_id'ye göre süreyi belirleyebilirsiniz)
                    let endTime = calendar.date(byAdding: .hour, value: sleepType == .core ? 3 : 1, to: startTime)!
                    
                    // Yeni uyku kaydı oluştur
                    let newEntry = SleepEntry(
                        id: remoteEntry.id,
                        type: sleepType,
                        startTime: startTime,
                        endTime: endTime,
                        rating: remoteEntry.rating
                    )
                    
                    // Yerel veritabanına ekle
                    modelContext.insert(newEntry)
                    
                    // Uygun HistoryModel'e ekle veya yeni bir HistoryModel oluştur
                    let entryDay = calendar.startOfDay(for: entryDate)
                    if let existingItemIndex = allHistoryItems.firstIndex(where: { calendar.isDate($0.date, equalTo: entryDay, toGranularity: .day) }) {
                        allHistoryItems[existingItemIndex].sleepEntries.append(newEntry)
                        updateCompletionStatus(for: allHistoryItems[existingItemIndex])
                    } else {
                        let newItem = HistoryModel(date: entryDay, sleepEntries: [newEntry])
                        allHistoryItems.append(newItem)
                    }
                } else {
                    // Yerel kayıt varsa, güncelle (şu an için sadece rating'i güncelliyoruz)
                    let localEntry = localEntries[0]
                    localEntry.rating = remoteEntry.rating
                }
            } catch {
                print("PolySleep Debug: Yerel kayıt kontrolü sırasında hata: \(error)")
            }
        }
        
        // Değişiklikleri kaydet
        try? modelContext.save()
        
        // Filtreleri uygula ve sırala
        filterAndSortItems()
    }
    
    /// Uyku kaydını Supabase'e senkronize eder
    @MainActor
    private func syncEntryToSupabase(_ entry: SleepEntry) async {
        guard networkMonitor.isConnected else {
            // İnternet bağlantısı yoksa, bekleyen değişiklikler listesine ekle
            pendingSyncEntries.insert(entry.id)
            syncStatus = .pendingSync
            return
        }
        
        do {
            // Kullanıcı ID'sini al
            let currentUser = try await SupabaseService.shared.getCurrentUser()
            guard let userId = currentUser?.id else {
                print("PolySleep Debug: Kullanıcı oturum açmamış")
                return
            }
            
            // Sync ID oluştur (yerel ve uzak kayıtları eşleştirmek için)
            let syncId = entry.id.uuidString
            
            // Block ID oluştur (gerçek uygulamada daha anlamlı bir ID kullanılabilir)
            let blockId = entry.type == .core ? "core_sleep" : "power_nap"
            
            // Emoji değeri (gerçek uygulamada kullanıcının seçtiği emoji kullanılabilir)
            let emoji = entry.type == .core ? "😴" : "⚡️"
            
            // DTO oluştur
            let dto = SupabaseHistoryService.SleepEntryDTO(
                id: entry.id,
                user_id: userId,
                date: entry.startTime,
                block_id: blockId,
                emoji: emoji,
                rating: entry.rating,
                sync_id: syncId,
                created_at: nil,
                updated_at: nil
            )
            
            // Kayıt zaten var mı kontrol et
            let exists = try await supabaseService.checkSleepEntryExists(syncId: syncId)
            
            if exists {
                // Kayıt varsa güncelle
                _ = try await supabaseService.updateSleepEntry(dto)
            } else {
                // Kayıt yoksa ekle
                _ = try await supabaseService.addSleepEntry(dto)
            }
            
            // Bekleyen değişiklikler listesinden çıkar
            pendingSyncEntries.remove(entry.id)
            
            // Tüm bekleyen değişiklikler senkronize edildiyse, durumu güncelle
            if pendingSyncEntries.isEmpty {
                syncStatus = .synced
            }
        } catch {
            print("PolySleep Debug: Supabase'e kayıt senkronizasyonu sırasında hata: \(error)")
            syncStatus = .error(NSLocalizedString("supabase.error.sync", comment: ""))
        }
    }
    
    /// Uyku kaydını Supabase'den siler
    @MainActor
    private func deleteEntryFromSupabase(_ entryId: UUID) async {
        guard networkMonitor.isConnected else {
            // İnternet bağlantısı yoksa, bekleyen değişiklikler listesine ekle
            pendingSyncEntries.insert(entryId)
            syncStatus = .pendingSync
            return
        }
        
        do {
            try await supabaseService.deleteSleepEntry(id: entryId)
            
            // Bekleyen değişiklikler listesinden çıkar
            pendingSyncEntries.remove(entryId)
            
            // Tüm bekleyen değişiklikler senkronize edildiyse, durumu güncelle
            if pendingSyncEntries.isEmpty {
                syncStatus = .synced
            }
        } catch {
            print("PolySleep Debug: Supabase'den kayıt silme sırasında hata: \(error)")
            syncStatus = .error(NSLocalizedString("supabase.error.sync", comment: ""))
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
                
                // Supabase'e senkronize et
                Task {
                    await syncEntryToSupabase(entry)
                }
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
            
            // Supabase'e senkronize et
            Task {
                await syncEntryToSupabase(entry)
            }
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
                
                // Supabase'den sil
                Task {
                    await deleteEntryFromSupabase(entry.id)
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
    
    // SwiftData ve Supabase ile veri yükleme
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
            
            // Supabase'den verileri senkronize et
            Task {
                await syncDataFromSupabase()
            }
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
