import SwiftUI
import SwiftData

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Filtre butonları
                    filterButtonsSection
                    
                    // Senkronizasyon durumu
                    syncStatusView
                    
                    // Ana içerik
                    if viewModel.historyItems.isEmpty {
                        emptyStateView
                    } else {
                        historyListView
                    }
                }
                
                // Takvim popup
                PopupView(isPresented: $viewModel.isCalendarPresented) {
                    CalendarView(viewModel: viewModel)
                        .frame(width: 320)
                }
            }
            .navigationTitle(Text("Sleep History", tableName: "History"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.isAddSleepEntryPresented = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color("AccentColor"))
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .accessibilityLabel(Text("Add Sleep Entry", tableName: "History"))
                }
            }
            .navigationBarItems(trailing: Button(action: {
                viewModel.isCalendarPresented = true
            }) {
                Image(systemName: "calendar")
                    .foregroundColor(Color("AccentColor"))
            })
            .sheet(isPresented: $viewModel.isFilterMenuPresented) {
                FilterMenuView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isDayDetailPresented) {
                if let selectedDay = viewModel.selectedDay,
                   let historyItem = viewModel.getHistoryItem(for: selectedDay) {
                    DayDetailView(historyItem: historyItem)
                }
            }
            .sheet(isPresented: $viewModel.isAddSleepEntryPresented) {
                AddSleepEntrySheet(viewModel: viewModel)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
    }
    
    // MARK: - Subviews
    
    // Senkronizasyon durumu görünümü
    private var syncStatusView: some View {
        VStack {
            switch viewModel.syncStatus {
            case .synced:
                if viewModel.isSyncing {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("supabase.syncing", tableName: "Common")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.appBackground)
                }
                
            case .pendingSync:
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.orange)
                    Text("supabase.pending.changes", tableName: "Common")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.appBackground)
                
            case .offline:
                HStack {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.secondary)
                    Text("supabase.offline.mode", tableName: "Common")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.appBackground)
                
            case .error(let message):
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text(message)
                        .font(.footnote)
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.appBackground)
            }
        }
        .padding(0)
    }
    
    // Filtre butonları bölümü
    private var filterButtonsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.isFilterMenuPresented = true
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(Color("AccentColor"))
                        .padding(8)
                        .background(Color("CardBackground"))
                        .cornerRadius(8)
                }
                
                filterButtonsView
                
                customDateFilterButton
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color.appBackground)
    }
    
    private var filterButtonsView: some View {
        ForEach(TimeFilter.allCases, id: \.self) { filter in
            FilterButton(
                title: LocalizedStringKey(filter.rawValue),
                isSelected: !viewModel.isCustomFilterVisible && viewModel.selectedFilter == filter
            )
            .onTapGesture {
                viewModel.setFilter(filter)
            }
        }
    }
    
    private var customDateFilterButton: some View {
        FilterButton(
            title: "Custom Range",
            isSelected: viewModel.isCustomFilterVisible
        )
        .onTapGesture {
            viewModel.isCalendarPresented = true
        }
    }
    
    // Geçmiş listesi görünümü
    private var historyListView: some View {
        List {
            ForEach(viewModel.historyItems, id: \.id) { item in
                HistoryItemSection(item: item, viewModel: viewModel)
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.appBackground)
    }
    
    // Boş durum görünümü
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Text("💤")
                .font(.system(size: 48))
            Text("Bu dönemde kayıt bulunamadı", tableName: "History")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button(action: {
                viewModel.isAddSleepEntryPresented = true
            }) {
                Text("Uyku Kaydı Ekle", tableName: "History")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color("AccentColor"))
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

struct HistoryItemSection: View {
    let item: HistoryModel
    let viewModel: HistoryViewModel
    
    var body: some View {
        Section(header: sectionHeader) {
            ForEach(item.sleepEntries, id: \.id) { entry in
                SleepEntryRow(entry: entry)
                    .swipeActions {
                        Button(role: .destructive) {
                            viewModel.deleteSleepEntry(entry)
                        } label: {
                            Label(NSLocalizedString("sleepEntry.delete", tableName: "History", comment: ""), systemImage: "trash")
                        }
                    }
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .background(Color.appBackground)
    }
    
    private var sectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.date, style: .date)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(formatDuration(item.totalSleepDuration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    ForEach(0..<Int(item.averageRating.rounded()), id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            Spacer()
            
            Circle()
                .fill(Color(item.completionStatus.color))
                .frame(width: 12, height: 12)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.appBackground)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        return String(format: "%dh %02dm", hours, minutes)
    }
}

struct FilterButton: View {
    let title: LocalizedStringKey
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(isSelected ? .white : Color("AccentColor"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color("AccentColor") : Color("CardBackground"))
            .cornerRadius(8)
    }
}

struct SleepEntryRow: View {
    let entry: SleepEntry
    
    private var timeRangeText: String {
        let startTime = entry.startTime.formatted(date: .omitted, time: .shortened)
        let endTime = entry.endTime.formatted(date: .omitted, time: .shortened)
        return "\(startTime) - \(endTime)"
    }
    
    private var durationText: String {
        let hours = Int(entry.duration) / 3600
        let minutes = (Int(entry.duration) % 3600) / 60
        
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Uyku tipi ikonu
            ZStack {
                Circle()
                    .fill(entry.type == .core ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: entry.type.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(entry.type == .core ? .blue : .orange)
            }
            
            // Bilgiler
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.type.title)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    // Zaman aralığı
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(timeRangeText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Süre
                    HStack(spacing: 4) {
                        Image(systemName: "hourglass")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(durationText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Yıldız derecelendirmesi
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= entry.rating ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundColor(star <= entry.rating ? .yellow : .gray.opacity(0.3))
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color("CardBackground"))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
