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
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.setFilter(filter)
                }
            }
        }
    }
    
    private var customDateFilterButton: some View {
        Group {
            if viewModel.isCustomFilterVisible, let range = viewModel.selectedDateRange {
                FilterButton(
                    title: "\(range.lowerBound.formatted(date: .abbreviated, time: .omitted)) - \(range.upperBound.formatted(date: .abbreviated, time: .omitted))",
                    isSelected: true
                )
                .onTapGesture {
                    viewModel.isCalendarPresented = true
                }
            }
        }
    }
    
    // Boş durum görünümü
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Text("💤")
                .font(.system(size: 48))
            Text("Bu dönemde kayıt bulunamadı", tableName: "History")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color("SecondaryTextColor"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
    
    // Geçmiş listesi görünümü
    private var historyListView: some View {
        ZStack {
            Color.appBackground.edgesIgnoringSafeArea(.all)
            
            List {
                historyItemsView
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }
    
    // Geçmiş öğeleri
    private var historyItemsView: some View {
        ForEach(viewModel.historyItems) { item in
            Section {
                sleepEntriesView(for: item)
            } header: {
                DayHeader(date: item.date, totalSleep: item.totalSleepDuration)
                    .textCase(nil)
                    .foregroundColor(Color("TextColor"))
                    .font(.system(size: 16, weight: .semibold))
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
            }
            .listRowBackground(Color("CardBackground"))
            .listRowSeparator(.hidden)
        }
    }
    
    // Uyku kayıtları
    private func sleepEntriesView(for item: HistoryModel) -> some View {
        ForEach(item.sleepEntries) { entry in
            SleepEntryRow(entry: entry)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        viewModel.deleteSleepEntry(entry)
                    } label: {
                        Label(NSLocalizedString("sleepEntry.delete", tableName: "History", comment: ""), systemImage: "trash")
                    }
                }
        }
    }
}

struct FilterButton: View {
    let title: LocalizedStringKey
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
            .foregroundColor(isSelected ? .white : Color("TextColor"))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color("AccentColor") : Color("CardBackground"))
            .cornerRadius(8)
    }
}

struct DayHeader: View {
    let date: Date
    let totalSleep: TimeInterval
    
    private var totalSleepText: String {
        let hours = Int(totalSleep / 3600)
        let minutes = Int((totalSleep.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
    
    private var dayQualityColor: Color {
        // Uyku kalitesine göre renk belirleme (8 saat üzeri ideal, 6-8 saat iyi, 6 saat altı yetersiz)
        let hours = totalSleep / 3600
        if hours >= 8 {
            return Color("SuccessColor")
        } else if hours >= 6 {
            return Color("WarningColor")
        } else {
            return Color("ErrorColor")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color("TextColor"))
                    
                    Text(date.formatted(.dateTime.weekday(.wide)))
                        .font(.system(size: 12))
                        .foregroundColor(Color("SecondaryTextColor"))
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(totalSleepText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color("TextColor"))
                        
                        Text("Toplam Uyku", tableName: "History")
                            .font(.system(size: 10))
                            .foregroundColor(Color("SecondaryTextColor"))
                    }
                    
                    Circle()
                        .fill(dayQualityColor)
                        .frame(width: 12, height: 12)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color("SecondaryTextColor").opacity(0.1))
        }
        .background(Color.appBackground)
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
        let hours = Int(entry.duration / 3600)
        let minutes = Int((entry.duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
    
    private var sleepTypeColor: Color {
        switch entry.type {
        case .core:
            return Color("PrimaryColor")
        case .powerNap:
            return Color("SecondaryColor")
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Image(systemName: entry.type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(sleepTypeColor)
                    .cornerRadius(8)
                
                Rectangle()
                    .fill(sleepTypeColor.opacity(0.2))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, 2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(LocalizedStringKey(entry.type.title))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("TextColor"))
                    
                    Spacer()
                    
                    starsView
                }
                
                HStack(spacing: 16) {
                    timeView
                    durationView
                }
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
    
    private var starsView: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= entry.rating ? "star.fill" : "star")
                    .foregroundColor(index <= entry.rating ? Color("SecondaryColor") : Color("SecondaryTextColor").opacity(0.3))
                    .font(.system(size: 12))
            }
        }
    }
    
    private var timeView: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 12))
                .foregroundColor(Color("SecondaryTextColor"))
            Text(timeRangeText)
                .font(.system(size: 14))
                .foregroundColor(Color("SecondaryTextColor"))
        }
    }
    
    private var durationView: some View {
        HStack(spacing: 4) {
            Image(systemName: "hourglass")
                .font(.system(size: 12))
                .foregroundColor(Color("SecondaryTextColor"))
            Text(durationText)
                .font(.system(size: 14))
                .foregroundColor(Color("SecondaryTextColor"))
        }
    }
}
