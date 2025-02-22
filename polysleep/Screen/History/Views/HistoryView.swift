import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
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
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    .background(Color("BackgroundColor"))
                    
                    if viewModel.historyItems.isEmpty {
                        VStack(spacing: 16) {
                            Text("💤")
                                .font(.system(size: 48))
                            Text(LocalizedStringKey("Bu dönemde kayıt bulunamadı"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color("SecondaryTextColor"))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color("BackgroundColor"))
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                                ForEach(viewModel.historyItems) { item in
                                    Section {
                                        VStack(spacing: 0) {
                                            ForEach(item.sleepEntries) { entry in
                                                SleepEntryRow(entry: entry)
                                                if entry.id != item.sleepEntries.last?.id {
                                                    Divider()
                                                        .background(Color("SecondaryTextColor").opacity(0.2))
                                                }
                                            }
                                        }
                                        .background(Color("CardBackground"))
                                        .cornerRadius(12)
                                        .shadow(color: Color("PrimaryColor").opacity(0.1), radius: 8, x: 0, y: 2)
                                        .padding(.horizontal)
                                        .padding(.bottom, 24)
                                    } header: {
                                        DayHeader(date: item.date, totalSleep: item.totalSleepDuration)
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                
                PopupView(isPresented: $viewModel.isCalendarPresented) {
                    CalendarView(viewModel: viewModel)
                        .frame(width: 320)
                }
            }
            .navigationTitle(Text(LocalizedStringKey("Sleep History")))
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
            .background(Color("BackgroundColor").ignoresSafeArea())
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
    
    var body: some View {
        HStack {
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color("TextColor"))
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(Color("AccentColor"))
                Text(totalSleepText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("SecondaryTextColor"))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color("BackgroundColor"))
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
    
    var body: some View {
        HStack {
            Image(systemName: entry.type.icon)
                .font(.system(size: 24))
                .foregroundColor(Color("AccentColor"))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(entry.type.title))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("TextColor"))
                
                Text(timeRangeText)
                    .font(.system(size: 14))
                    .foregroundColor(Color("SecondaryTextColor"))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= entry.rating ? "star.fill" : "star")
                            .foregroundColor(index <= entry.rating ? Color("SecondaryColor") : Color("SecondaryTextColor").opacity(0.3))
                            .font(.system(size: 12))
                    }
                }
                
                Text(durationText)
                    .font(.system(size: 14))
                    .foregroundColor(Color("SecondaryTextColor"))
            }
        }
        .padding()
    }
}
