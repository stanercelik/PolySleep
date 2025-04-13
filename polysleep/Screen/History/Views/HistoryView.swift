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
                    // Filtreleme Segmenti
                    segmentedFilterView
                    
                    // Senkronizasyon göstergesi (gerektiğinde görünür)
                    syncIndicator
                    
                    // Ana içerik
                    if viewModel.historyItems.isEmpty {
                        emptyStateView
                    } else {
                        historyListView
                    }
                }
                
                // Yeni kayıt ekleme butonu
                floatingActionButton
            }
            .navigationTitle("Uyku Geçmişi")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    syncButton
                }
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
        .accentColor(Color.appPrimary)
    }
    
    // MARK: - Subviews
    
    // Segmented filter view
    private var segmentedFilterView: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TimeFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: LocalizedStringKey(filter.rawValue),
                            isSelected: viewModel.selectedFilter == filter,
                            action: { viewModel.setFilter(filter) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color.clear)
            
            Divider()
                .opacity(0.4)
        }
    }
    
    // Sync indicator
    private var syncIndicator: some View {
        Group {
            switch viewModel.syncStatus {
            case .synced where viewModel.isSyncing:
                syncStatusBanner(
                    icon: "arrow.triangle.2.circlepath",
                    color: Color.appPrimary,
                    text: "Senkronize ediliyor..."
                )
                
            case .pendingSync:
                syncStatusBanner(
                    icon: "clock.arrow.circlepath",
                    color: Color.orange,
                    text: "Bekleyen değişiklikler"
                )
                
            case .offline:
                syncStatusBanner(
                    icon: "wifi.slash",
                    color: Color.gray,
                    text: "Çevrimdışı mod"
                )
                
            case .error(let message):
                syncStatusBanner(
                    icon: "exclamationmark.triangle",
                    color: Color.red,
                    text: message
                )
                
            default:
                EmptyView()
            }
        }
    }
    
    private func syncStatusBanner(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 8) {
            if icon == "arrow.triangle.2.circlepath" {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.7)
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
            }
            
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.appSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color("CardBackground").opacity(0.9))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // Sync button
    private var syncButton: some View {
        Button(action: {
            Task {
                await viewModel.syncDataFromSupabase()
            }
        }) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.appPrimary)
                )
                .contentShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(viewModel.isSyncing)
        .opacity(viewModel.isSyncing ? 0.5 : 1.0)
    }
    
    // Floating action button
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    viewModel.isAddSleepEntryPresented = true
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 54, height: 54)
                        .background(
                            Circle()
                                .fill(Color.appPrimary)
                                .shadow(color: Color.appPrimary.opacity(0.3), radius: 8, x: 0, y: 2)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "bed.double")
                .font(.system(size: 60))
                .foregroundColor(Color.appPrimary.opacity(0.2))
                .padding(.bottom, 5)
            
            Text("Kayıt Bulunamadı")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color.appText)
            
            Text("Bu zaman aralığında hiç uyku kaydı bulunamadı.")
                .font(.system(size: 15))
                .foregroundColor(Color.appSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 10)
            
            Button(action: {
                viewModel.isAddSleepEntryPresented = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Yeni Kayıt Ekle")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.appPrimary)
                        .shadow(color: Color.appPrimary.opacity(0.3), radius: 6, x: 0, y: 3)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // History list view
    private var historyListView: some View {
        ScrollView {
            LazyVStack(spacing: 8, pinnedViews: []) {
                // Günleri aylara göre gruplama
                ForEach(groupedByMonth(), id: \.0) { monthGroup in
                    monthSection(month: monthGroup.0, items: monthGroup.1)
                }
            }
            .padding(.top, 8)
        }
        .background(Color.appBackground)
    }
    
    // Ayları grupla
    private func groupedByMonth() -> [(String, [HistoryModel])] {
        let groupedItems = Dictionary(grouping: viewModel.historyItems) { item -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: item.date)
        }
        
        return groupedItems.sorted { item1, item2 in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            
            guard let date1 = formatter.date(from: item1.key),
                  let date2 = formatter.date(from: item2.key) else {
                return false
            }
            
            return date1 > date2
        }
    }
    
    // Ay bölümü
    private func monthSection(month: String, items: [HistoryModel]) -> some View {
        VStack(spacing: 4) {
            // Ay başlığı
            HStack {
                Text(month)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.appPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                
                Spacer()
            }
            
            // Günler
            VStack(spacing: 8) {
                ForEach(items.sorted(by: { $0.date > $1.date })) { item in
                    dayCard(item: item)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.clear)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    // Gün kartı
    private func dayCard(item: HistoryModel) -> some View {
        Button(action: {
            viewModel.selectedDay = item.date
            viewModel.isDayDetailPresented = true
        }) {
            VStack(spacing: 0) {
                // Gün başlığı
                HStack {
                    HStack(spacing: 8) {
                        // Tarih ve gün
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.appText)
                            
                            Text(dayOfWeek(from: item.date))
                                .font(.system(size: 12))
                                .foregroundColor(Color.appSecondaryText)
                        }
                        
                        if Calendar.current.isDateInToday(item.date) {
                            Text("Bugün")
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.appPrimary.opacity(0.15))
                                )
                                .foregroundColor(Color.appPrimary)
                        }
                    }
                    
                    Spacer()
                    
                    // Uyku kalitesi
                    if item.sleepEntries.isEmpty {
                        Text("Kayıt yok")
                            .font(.system(size: 12))
                            .foregroundColor(Color.appSecondaryText)
                    } else {
                        HStack(spacing: 4) {
                            Text(String(format: "%.1f", item.averageRating))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.appPrimary)
                            
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color.appPrimary)
                                .offset(y: -1)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                    .opacity(0.6)
                
                // Uyku blokları
                VStack(spacing: 0) {
                    if item.sleepEntries.isEmpty {
                        Text("Kayıt yok")
                            .font(.system(size: 14))
                            .foregroundColor(Color.appSecondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    } else {
                        ForEach(item.sleepEntries.sorted { $0.startTime < $1.startTime }.prefix(2), id: \.id) { entry in
                            miniSleepEntryRow(entry: entry)
                            
                            if entry.id != item.sleepEntries.sorted { $0.startTime < $1.startTime }.prefix(2).last?.id {
                                Divider()
                                    .padding(.leading, 52)
                                    .opacity(0.3)
                            }
                        }
                        
                        if item.sleepEntries.count > 2 {
                            HStack {
                                Text("+ \(item.sleepEntries.count - 2) blok daha")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.appPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.appSecondaryText)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                HStack(spacing: 16) {
                    // Toplam uyku süresi
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(Color.appPrimary)
                        
                        Text(formatDuration(item.totalSleepDuration))
                            .font(.system(size: 12))
                            .foregroundColor(Color.appText)
                    }
                    
                    // Uyku bloğu sayısı
                    HStack(spacing: 4) {
                        Image(systemName: "bed.double")
                            .font(.system(size: 12))
                            .foregroundColor(Color.appPrimary)
                        
                        Text("\(item.sleepEntries.count) blok")
                            .font(.system(size: 12))
                            .foregroundColor(Color.appText)
                    }
                    
                    Spacer()
                    
                    // Durum göstergesi
                    Circle()
                        .fill(Color(item.completionStatus.color))
                        .frame(width: 8, height: 8)
                        .padding(4)
                        .background(
                            Circle()
                                .stroke(Color(item.completionStatus.color).opacity(0.2), lineWidth: 2)
                        )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.clear)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground"))
                    .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
            )
        }
        .buttonStyle(CardButtonStyle())
    }
    
    // Mini uyku girişi satırı
    private func miniSleepEntryRow(entry: SleepEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.isCore ? "bed.double" : "powersleep")
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(entry.isCore ? Color.appPrimary : Color.appSecondary)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(formatTime(entry.startTime)) - \(formatTime(entry.endTime))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.appText)
                
                Text(entry.isCore ? "Ana Uyku" : "Şekerleme")
                    .font(.system(size: 12))
                    .foregroundColor(Color.appSecondaryText)
            }
            
            Spacer()
            
            // Süre
            Text(formatEntryDuration(entry.duration))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.appPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.appPrimary.opacity(0.1))
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // Helper functions
    private func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        return String(format: "%ds %02ddk", hours, minutes)
    }
    
    private func formatEntryDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)s \(minutes)dk"
        } else {
            return "\(minutes)dk"
        }
    }
}

// MARK: - Helper Components

struct FilterChip: View {
    let title: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.appPrimary : Color.clear)
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.clear : Color.appPrimary.opacity(0.3), lineWidth: 1)
                        )
                )
                .foregroundColor(isSelected ? .white : Color.appPrimary)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SleepEntryCard: View {
    let entry: SleepEntry
    let viewModel: HistoryViewModel
    
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
    
    var body: some View {
        HStack(spacing: 14) {
            // İkon
            ZStack {
                Circle()
                    .fill(entry.isCore ? 
                        Color.appPrimary.opacity(0.15) : 
                        Color.appSecondary.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: entry.isCore ? "bed.double" : "powersleep")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(entry.isCore ? Color.appPrimary : Color.appSecondary)
            }
            
            // Bilgiler
            VStack(alignment: .leading, spacing: 3) {
                Text(timeRangeText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.appText)
                
                Text(entry.isCore ? "Ana Uyku" : "Kısa Uyku")
                    .font(.system(size: 13))
                    .foregroundColor(Color.appSecondaryText)
            }
            
            Spacer()
            
            // Süre ve değerlendirme
            VStack(alignment: .trailing, spacing: 3) {
                Text(durationText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.appText)
                
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= entry.rating ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(star <= entry.rating ? Color.appPrimary : Color.appSecondaryText.opacity(0.3))
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("CardBackground"))
                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        )
        .contextMenu {
            Button(role: .destructive) {
                viewModel.deleteSleepEntry(entry)
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
        .swipeActions {
            Button(role: .destructive) {
                viewModel.deleteSleepEntry(entry)
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
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
