import SwiftUI
import SwiftData

struct DayDetailView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var isAddingSleepEntry = false
    
    // Kullanıcının seçtiği emojiler
    private var coreEmoji: String {
        UserDefaults.standard.string(forKey: "selectedCoreEmoji") ?? "🌙"
    }
    
    private var napEmoji: String {
        UserDefaults.standard.string(forKey: "selectedNapEmoji") ?? "⚡"
    }
    
    var dayEntries: [SleepEntry] {
        guard let day = viewModel.selectedDay,
              let historyItemForDay = viewModel.getHistoryItem(for: day) else {
            return []
        }
        return historyItemForDay.sleepEntries?.sorted { $0.startTime < $1.startTime } ?? []
    }
    
    var hasSleepData: Bool {
        !dayEntries.isEmpty
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: viewModel.selectedDay ?? Date())
    }
    
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: viewModel.selectedDay ?? Date())
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Tarih Başlığı
                    VStack(spacing: 4) {
                        Text(formattedDate)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color("TextColor"))
                        
                        Text(dayOfWeek)
                            .font(.system(size: 16))
                            .foregroundColor(Color("SecondaryTextColor"))
                    }
                    .padding(.top, 8)
                    
                    if hasSleepData {
                        // Sleep Entries
                        VStack(spacing: 16) {
                            ForEach(dayEntries) { entry in
                                SleepEntryDetailCard(entry: entry, coreEmoji: coreEmoji, napEmoji: napEmoji) {
                                    viewModel.deleteSleepEntry(entry)
                                }
                            }
                        }
                        
                        // Özet Kart
                        SummarySectionCard(entries: dayEntries)
                    } else {
                        // Veri Yok Görünümü
                        NoDataView()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color("PrimaryColor"))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isAddingSleepEntry = true
                    }) {
                        Text(L("general.add", table: "DayDetail"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color("PrimaryColor"))
                    }
                }
            }
            .sheet(isPresented: $isAddingSleepEntry) {
                if let selectedDay = viewModel.selectedDay {
                    AddSleepEntrySheet(viewModel: viewModel, initialDate: selectedDay)
                }
            }
        }
    }
}

// MARK: - Sleep Entry Detail Card
struct SleepEntryDetailCard: View {
    let entry: SleepEntry
    let coreEmoji: String
    let napEmoji: String
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    
    // Computed properties
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_GB")
        return formatter
    }
    
    private var timeText: String {
        return "\(timeFormatter.string(from: entry.startTime)) - \(timeFormatter.string(from: entry.endTime))"
    }
    
    private var durationText: String {
        let hours = entry.durationMinutes / 60
        let minutes = entry.durationMinutes % 60
        if hours > 0 {
            return "\(hours) s \(minutes) dk"
        } else {
            return "\(minutes) dk"
        }
    }
    
    private var ratingColor: Color {
        switch entry.rating {
        case 5:
            return Color.green
        case 4:
            return Color("SecondaryColor")
        case 3:
            return Color.yellow
        case 2:
            return Color.orange
        default:
            return Color.red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Blok tipi emojisi
                Text(entry.isCore ? coreEmoji : napEmoji)
                    .font(.system(size: 24))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(entry.isCore ? Color("PrimaryColor").opacity(0.2) : Color("AccentColor").opacity(0.2))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.isCore ? L("sleep.type.core", table: "DayDetail") : L("sleep.type.nap", table: "DayDetail"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color("TextColor"))
                    
                    Text(timeText)
                        .font(.caption)
                        .foregroundColor(Color("SecondaryTextColor"))
                }
                
                Spacer()
                
                // Kalite yıldızları - tam yıldız gösterimi korundu (tekli entry için)
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= entry.rating ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(star <= entry.rating ? ratingColor : Color.gray.opacity(0.3))
                    }
                }
                
                Button(action: {
                    showDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(Color.red.opacity(0.7))
                        .padding(8)
                }
            }
            
            // Süre ve emoji
            HStack {
                Text(durationText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("PrimaryColor"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("PrimaryColor").opacity(0.1))
                    )
                
                Spacer()
                
                if ((entry.emoji?.isEmpty) == nil) {
                    Text(entry.emoji ?? "")
                        .font(.system(size: 20))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text(L("dayDetail.delete.title", table: "DayDetail")),
                message: Text(L("dayDetail.delete.message", table: "DayDetail")),
                primaryButton: .destructive(Text(L("general.delete", table: "DayDetail"))) {
                    onDelete()
                },
                secondaryButton: .cancel(Text(L("general.cancel", table: "DayDetail")))
            )
        }
    }
}

// MARK: - Özet Kartı
struct SummarySectionCard: View {
    let entries: [SleepEntry]
    
    var totalSleepDuration: (Int, Int) {
        let totalMinutes = entries.reduce(0) { $0 + $1.durationMinutes }
        return (totalMinutes / 60, totalMinutes % 60)
    }
    
    var averageRating: Double {
        let totalRating = entries.reduce(0) { $0 + $1.rating }
        return Double(totalRating) / Double(max(entries.count, 1))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("dayDetail.summary.title", table: "DayDetail"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color("TextColor"))
            
            HStack(spacing: 20) {
                // Toplam uyku süresi
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(Color("PrimaryColor"))
                        
                        Text(L("dayDetail.summary.totalSleep", table: "DayDetail"))
                            .font(.system(size: 14))
                            .foregroundColor(Color("SecondaryTextColor"))
                    }
                    
                    Text("\(totalSleepDuration.0) s \(totalSleepDuration.1) dk")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color("TextColor"))
                }
                .frame(maxWidth: .infinity)
                
                // Ortalama kalite - Yarım yıldız desteği ekli
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(Color("SecondaryColor"))
                        
                        Text(L("dayDetail.summary.averageQuality", table: "DayDetail"))
                            .font(.system(size: 14))
                            .foregroundColor(Color("SecondaryTextColor"))
                    }
                    
                    // Yarım yıldız desteği ile yıldız gösterimi
                    StarsView(rating: averageRating, size: 16)
                    
                    Text(String(format: "%.1f/5", averageRating))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("TextColor"))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Veri Yok Görünümü
struct NoDataView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 60))
                .foregroundColor(Color("SecondaryTextColor").opacity(0.7))
            
            Text(L("dayDetail.noData.title", table: "DayDetail"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color("TextColor"))
            
            Text(L("dayDetail.noData.message", table: "DayDetail"))
                .font(.system(size: 16))
                .foregroundColor(Color("SecondaryTextColor"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct DayDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = HistoryViewModel()
        viewModel.selectedDay = Date()
        
        return DayDetailView(viewModel: viewModel)
    }
}
