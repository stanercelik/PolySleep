import SwiftUI
import SwiftData

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
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
                
                // Yeni kayıt ekleme butonu (floating action button)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.isAddSleepEntryPresented = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Circle().fill(Color("PrimaryColor")))
                                .shadow(color: Color("PrimaryColor").opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(Text("Uyku Geçmişi", tableName: "History"))
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: 
                HStack(spacing: 16) {
                    // Takvim butonu
                    Button(action: {
                        viewModel.isCalendarPresented = true
                    }) {
                        Image(systemName: "calendar")
                            .foregroundColor(Color("PrimaryColor"))
                            .font(.system(size: 18, weight: .medium))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color("CardBackground")))
                    }
                    
                    // Elle güncelleştirme butonu
                    Button(action: {
                        Task {
                            await viewModel.syncDataFromSupabase()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color("AccentColor"))
                            .font(.system(size: 18, weight: .medium))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color("CardBackground")))
                    }
                    .disabled(viewModel.isSyncing)
                    .opacity(viewModel.isSyncing ? 0.5 : 1.0)
                }
            )
            .sheet(isPresented: $viewModel.isFilterMenuPresented) {
                FilterMenuView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isDayDetailPresented) {
                if let selectedDay = viewModel.selectedDay,
                   let historyItem = viewModel.getHistoryItem(for: selectedDay) {
                    DayDetailView(viewModel: viewModel)
                }
            }
            .sheet(isPresented: $viewModel.isAddSleepEntryPresented) {
                AddSleepEntrySheet(viewModel: viewModel)
            }
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
                            .frame(width: 14, height: 14)
                        Text("Senkronize ediliyor...", tableName: "Common")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color("CardBackground").opacity(0.7))
                }
                
            case .pendingSync:
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.orange)
                        .font(.system(size: 13))
                    Text("Bekleyen değişiklikler", tableName: "Common")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color("CardBackground").opacity(0.7))
                
            case .offline:
                HStack {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.secondary)
                        .font(.system(size: 13))
                    Text("Çevrimdışı mod", tableName: "Common")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color("CardBackground").opacity(0.7))
                
            case .error(let message):
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                        .font(.system(size: 13))
                    Text(message)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color("CardBackground").opacity(0.7))
            }
        }
        .padding(0)
    }
    
    // Filtre butonları bölümü
    private var filterButtonsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Filtreler", tableName: "History")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color("SecondaryTextColor"))
                
                Spacer()
                
                Button(action: {
                    viewModel.isFilterMenuPresented = true
                }) {
                    HStack(spacing: 5) {
                        Text("Daha Fazla", tableName: "History")
                            .font(.system(size: 14))
                        Image(systemName: "slider.horizontal.3")
                    }
                    .foregroundColor(Color("PrimaryColor"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color("PrimaryColor").opacity(0.1))
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    sleepTypeFilterButtons
                    
                    Divider()
                        .frame(height: 24)
                        .padding(.horizontal, 4)
                    
                    timeFilterButtons
                    
                    if viewModel.isCustomFilterVisible {
                        customDateFilterView
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .background(
            Rectangle()
                .fill(Color("CardBackground"))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
    }
    
    private var sleepTypeFilterButtons: some View {
        HStack(spacing: 8) {
            ForEach(SleepTypeFilter.allCases, id: \.self) { filter in
                Button(action: {
                    viewModel.setSleepTypeFilter(filter)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: filter == .core ? "bed.double.fill" : 
                                         filter == .nap ? "powersleep" : "moon.stars.fill")
                            .font(.system(size: 12))
                        Text(LocalizedStringKey(filter.rawValue), tableName: "History")
                            .font(.system(size: 13))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(viewModel.selectedSleepTypeFilter == filter ? 
                                 Color("PrimaryColor") : Color("CardBackground"))
                            .shadow(color: Color.black.opacity(viewModel.selectedSleepTypeFilter == filter ? 0.1 : 0), 
                                   radius: 3, x: 0, y: 2)
                            .overlay(
                                Capsule()
                                    .stroke(viewModel.selectedSleepTypeFilter == filter ? 
                                          Color.clear : Color("SecondaryTextColor").opacity(0.2), 
                                          lineWidth: 1)
                            )
                    )
                    .foregroundColor(viewModel.selectedSleepTypeFilter == filter ? 
                                   .white : Color("TextColor"))
                    .animation(.easeInOut(duration: 0.2), value: viewModel.selectedSleepTypeFilter)
                }
            }
        }
    }
    
    private var timeFilterButtons: some View {
        HStack(spacing: 8) {
            ForEach(TimeFilter.allCases, id: \.self) { filter in
                Button(action: {
                    viewModel.setFilter(filter)
                }) {
                    Text(LocalizedStringKey(filter.rawValue), tableName: "History")
                        .font(.system(size: 13))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(!viewModel.isCustomFilterVisible && viewModel.selectedFilter == filter ? 
                                     Color("AccentColor") : Color("CardBackground"))
                                .shadow(color: Color.black.opacity(!viewModel.isCustomFilterVisible && viewModel.selectedFilter == filter ? 0.1 : 0), 
                                      radius: 3, x: 0, y: 2)
                                .overlay(
                                    Capsule()
                                        .stroke(!viewModel.isCustomFilterVisible && viewModel.selectedFilter == filter ? 
                                             Color.clear : Color("SecondaryTextColor").opacity(0.2), 
                                             lineWidth: 1)
                                )
                        )
                        .foregroundColor(!viewModel.isCustomFilterVisible && viewModel.selectedFilter == filter ? 
                                       .white : Color("TextColor"))
                        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedFilter)
                }
            }
            
            Button(action: {
                viewModel.isCalendarPresented = true
            }) {
                Text("Özel Aralık", tableName: "History")
                    .font(.system(size: 13))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(viewModel.isCustomFilterVisible ? 
                                 Color("PrimaryColor") : Color("CardBackground"))
                            .shadow(color: Color.black.opacity(viewModel.isCustomFilterVisible ? 0.1 : 0), 
                                   radius: 3, x: 0, y: 2)
                            .overlay(
                                Capsule()
                                    .stroke(viewModel.isCustomFilterVisible ? 
                                         Color.clear : Color("SecondaryTextColor").opacity(0.2), 
                                         lineWidth: 1)
                            )
                    )
                    .foregroundColor(viewModel.isCustomFilterVisible ? 
                                   .white : Color("TextColor"))
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isCustomFilterVisible)
            }
        }
    }
    
    private var customDateFilterView: some View {
        HStack {
            if let range = viewModel.selectedDateRange {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                    Text("\(range.lowerBound.formatted(.dateTime.day().month(.abbreviated))) - \(range.upperBound.formatted(.dateTime.day().month(.abbreviated)))")
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color("PrimaryColor"))
                )
                .foregroundColor(.white)
            }
        }
    }
    
    // Geçmiş listesi görünümü
    private var historyListView: some View {
        List {
            ForEach(viewModel.historyItems, id: \.id) { item in
                HistoryItemSection(item: item, viewModel: viewModel)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    .background(Color.appBackground)
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.appBackground)
    }
    
    // Boş durum görünümü
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 70))
                .foregroundColor(Color("PrimaryColor").opacity(0.2))
                .padding(.bottom, 10)
            
            VStack(spacing: 8) {
                Text("Kayıt Bulunamadı", tableName: "History")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color("TextColor"))
                
                Text("Bu zaman aralığında hiç uyku kaydı bulunamadı. Bir kayıt eklemek için aşağıdaki butona tıklayabilirsiniz.", tableName: "History")
                    .font(.system(size: 15))
                    .foregroundColor(Color("SecondaryTextColor"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: {
                viewModel.isAddSleepEntryPresented = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Uyku Kaydı Ekle", tableName: "History")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("PrimaryColor"), Color("PrimaryColor").opacity(0.8)]), 
                                startPoint: .topLeading, 
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color("PrimaryColor").opacity(0.3), radius: 8, x: 0, y: 4)
                )
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
        VStack(alignment: .leading, spacing: 0) {
            // Günün başlığı
            sectionHeader
            
            // Uyku kayıtları
            VStack(spacing: 8) {
                ForEach(item.sleepEntries, id: \.id) { entry in
                    SleepEntryRow(entry: entry)
                        .swipeActions {
                            Button(role: .destructive) {
                                viewModel.deleteSleepEntry(entry)
                            } label: {
                                Label(NSLocalizedString("Sil", tableName: "History", comment: ""), systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    private var sectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 8) {
                    Text(item.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color("TextColor"))
                    
                    if Calendar.current.isDateInToday(item.date) {
                        Text("Bugün")
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color("PrimaryColor").opacity(0.2))
                            )
                            .foregroundColor(Color("PrimaryColor"))
                    }
                }
                
                HStack(spacing: 12) {
                    // Toplam uyku süresi
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color("SecondaryTextColor"))
                        
                        Text("\(formatDuration(item.totalSleepDuration))")
                            .font(.system(size: 13))
                            .foregroundColor(Color("SecondaryTextColor"))
                    }
                    
                    // Uyku bloğu sayısı
                    HStack(spacing: 4) {
                        Image(systemName: "bed.double.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color("SecondaryTextColor"))
                        
                        Text("\(item.sleepEntries.count) blok")
                            .font(.system(size: 13))
                            .foregroundColor(Color("SecondaryTextColor"))
                    }
                    
                    Spacer()
                    
                    // Ortalama puan
                    HStack(spacing: 4) {
                        ForEach(0..<Int(item.averageRating.rounded()), id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Tamamlanma durumu göstergesi
            Circle()
                .fill(Color(item.completionStatus.color))
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color("CardBackground"))
                .cornerRadius(16, corners: [.topLeft, .topRight])
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color("SecondaryTextColor").opacity(0.1)),
            alignment: .bottom
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        return String(format: "%ds %02ddk", hours, minutes)
    }
}

struct FilterButton: View {
    let title: LocalizedStringKey
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(isSelected ? .white : Color("PrimaryColor"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color("PrimaryColor") : Color("CardBackground"))
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
            return String(format: "%ds %02ddk", hours, minutes)
        } else {
            return String(format: "%ddk", minutes)
        }
    }
    
    private var sleepTypeIcon: some View {
        Image(systemName: entry.type == .core ? "bed.double.fill" : "powersleep")
            .foregroundColor(entry.type == .core ? Color("PrimaryColor") : Color.orange)
            .font(.system(size: 16))
            .frame(width: 32, height: 32)
            .background(
                Circle()
                    .fill(entry.type == .core ? Color("PrimaryColor").opacity(0.1) : Color.orange.opacity(0.1))
            )
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            sleepTypeIcon
            
            VStack(alignment: .leading, spacing: 2) {
                Text(timeRangeText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color("TextColor"))
                
                Text(entry.type == .core ? "Ana Uyku" : "Kısa Uyku")
                    .font(.system(size: 13))
                    .foregroundColor(Color("SecondaryTextColor"))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(durationText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("TextColor"))
                
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= entry.rating ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(star <= entry.rating ? .yellow : .gray.opacity(0.3))
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("CardBackground"))
                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        )
    }
}

// RoundedCorner utility
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
