import SwiftUI

struct DayDetailView: View {
    let historyItem: HistoryModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(historyItem.date.formatted(date: .complete, time: .omitted))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color("TextColor"))
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color("SecondaryTextColor"))
                        .padding(8)
                        .background(Color("CardBackground"))
                        .clipShape(Circle())
                }
            }
            .padding()
            
            // Uyku blokları
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(historyItem.sleepEntries.enumerated()), id: \.element.id) { index, entry in
                        let nextEntry = index + 1 < historyItem.sleepEntries.count ? historyItem.sleepEntries[index + 1] : nil
                        HistorySleepBlockCard(
                            block: entry,
                            nextBlock: nextEntry,
                            nextBlockTime: nextEntry?.startTime,
                            viewModel: HistoryViewModel()
                        )
                    }
                }
                .padding()
            }
            
            Button(action: {
                // TODO: Düzenleme ekranına git
            }) {
                Text(NSLocalizedString("Düzenle", tableName: "History", comment: ""))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("AccentColor"))
                    .cornerRadius(12)
            }
            .padding()
        }
        .background(Color("BackgroundColor"))
    }
}

struct HistorySleepBlockCard: View {
    let block: SleepEntry
    let nextBlock: SleepEntry?
    let nextBlockTime: Date?
    @ObservedObject var viewModel: HistoryViewModel
    
    private var timeRangeText: String {
        let startTime = block.startTime.formatted(date: .omitted, time: .shortened)
        let endTime = block.endTime.formatted(date: .omitted, time: .shortened)
        return "\(startTime) - \(endTime)"
    }
    
    private var durationText: String {
        let hours = Int(block.duration / 3600)
        let minutes = Int((block.duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
    
    private var sleepEmoji: String {
        switch block.type {
        case .core:
            return "🛏️"
        case .powerNap:
            return "⚡️"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(sleepEmoji)
                    .font(.title2)
                Text(LocalizedStringKey(block.type.title))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color("TextColor"))
                Spacer()
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= block.rating ? "star.fill" : "star")
                            .foregroundColor(index <= block.rating ? Color("SecondaryColor") : Color("SecondaryTextColor").opacity(0.3))
                            .font(.system(size: 14))
                    }
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label(timeRangeText, systemImage: "clock")
                    Label(durationText, systemImage: "hourglass")
                }
                .font(.system(size: 14))
                .foregroundColor(Color("SecondaryTextColor"))
            }
            
            if let nextTime = nextBlockTime {
                let gap = nextTime.timeIntervalSince(block.endTime)
                let hours = Int(gap / 3600)
                let minutes = Int((gap.truncatingRemainder(dividingBy: 3600)) / 60)
                if gap > 0 {
                    HStack {
                        Image(systemName: "arrow.right")
                        Text("\(hours)h \(minutes)m")
                        Text(NSLocalizedString("until.next.sleep", tableName: "History", comment: ""))
                    }
                    .font(.system(size: 14))
                    .foregroundColor(Color("SecondaryTextColor"))
                }
            }
        }
        .padding()
        .background(Color("CardBackground"))
        .cornerRadius(12)
        .shadow(color: Color("PrimaryColor").opacity(0.1), radius: 8, x: 0, y: 2)
    }
}
