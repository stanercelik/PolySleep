import SwiftUI
import SwiftData

struct AddSleepEntrySheet: View {
    @ObservedObject var viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEmoji = "😊"
    @State private var rating = 3
    @State private var selectedDate = Date()
    @State private var selectedBlock: SleepBlock?
    @State private var showEmojiSelector = false
    @State private var showBlockError = false
    @State private var blockErrorMessage = ""
    
    // MainScreenViewModel'den uyku bloklarını almak için
    @StateObject private var mainViewModel = MainScreenViewModel()
    
    private let emojis = ["😩", "😪", "😐", "😊", "😄"]
    private let emojiDescriptions = [
        "😄": "sleep.quality.veryGood",
        "😊": "sleep.quality.good",
        "😐": "sleep.quality.okay",
        "😪": "sleep.quality.bad",
        "😩": "sleep.quality.veryBad"
    ]
    private let ratingValues = [1, 2, 3, 4, 5]
    
    // Seçilen tarih için uyku bloklarını filtreleme
    private var availableBlocks: [SleepBlock] {
        return mainViewModel.model.schedule.schedule
    }
    
    // Seçilen tarih için uyku bloklarını kontrol etme
    private var isDateValid: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: selectedDate)
        
        // Geçmiş tarihler ve bugün geçerli
        return selectedDay <= today
    }
    
    // Seçilen tarih için uyku bloğunun zaten eklenip eklenmediğini kontrol etme
    private func isBlockAlreadyAdded(_ block: SleepBlock) -> Bool {
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: selectedDate)
        
        return viewModel.historyItems.contains { historyItem in
            guard calendar.startOfDay(for: historyItem.date) == selectedDay else { return false }
            
            return historyItem.sleepEntries.contains { entry in
                let entryStartHour = calendar.component(.hour, from: entry.startTime)
                let entryStartMinute = calendar.component(.minute, from: entry.startTime)
                let blockStartComponents = TimeFormatter.time(from: block.startTime)!
                
                return entryStartHour == blockStartComponents.hour && 
                       entryStartMinute == blockStartComponents.minute
            }
        }
    }
    
    // MARK: - View Components
    private var datePickerSection: some View {
        Section(header: Text("sleepEntry.date", tableName: "AddSleepEntrySheet")) {
            DatePicker(
                NSLocalizedString("sleepEntry.selectDate", tableName: "AddSleepEntrySheet", comment: ""),
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
            .onChange(of: selectedDate) { _ in
                selectedBlock = nil
            }
        }
    }
    
    private var blockSelectionSection: some View {
        Section(header: Text("sleepEntry.selectBlock", tableName: "AddSleepEntrySheet")) {
            if availableBlocks.isEmpty {
                Text("sleepEntry.noBlocks", tableName: "AddSleepEntrySheet", comment: "")
                    .foregroundColor(Color("SecondaryTextColor"))
                    .padding(.vertical, 8)
            } else {
                ForEach(availableBlocks, id: \.id) { block in
                    BlockSelectionButton(
                        block: block,
                        isSelected: selectedBlock?.id == block.id,
                        onTap: {
                            if isBlockAlreadyAdded(block) {
                                blockErrorMessage = "sleepEntry.error.alreadyAdded"
                                showBlockError = true
                            } else {
                                selectedBlock = block
                            }
                        }
                    )
                }
            }
        }
    }
    
    private struct BlockSelectionButton: View {
        let block: SleepBlock
        let isSelected: Bool
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                HStack {
                    Image(systemName: block.isCore ? "moon.fill" : "moon")
                        .foregroundColor(isSelected ? Color("AccentColor") : (block.isCore ? Color("PrimaryColor") : Color("SecondaryTextColor")))
                    
                    Text("\(block.startTime) - \(block.endTime)")
                        .foregroundColor(isSelected ? Color("AccentColor") : Color("TextColor"))
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(Color("AccentColor"))
                    }
                }
            }
        }
    }
    
    private var qualitySection: some View {
        Section(header: Text(NSLocalizedString("sleepEntry.quality", tableName: "AddSleepEntrySheet", comment: ""))) {
            VStack(alignment: .center, spacing: 12) {
                HStack {
                    Text(NSLocalizedString("sleepEntry.howDidYouFeel", tableName: "AddSleepEntrySheet", comment: ""))
                        .font(.headline)
                        .foregroundColor(Color("TextColor"))
                    
                    Spacer()
                    
                    Button(action: {
                        showEmojiSelector.toggle()
                    }) {
                        Text(selectedEmoji)
                            .font(.title)
                    }
                }
                
                
                if showEmojiSelector {
                    VStack(spacing: 16) {
                        Text(NSLocalizedString(emojiDescriptions[selectedEmoji] ?? "", tableName: "AddSleepEntrySheet", comment: ""))
                            .font(.subheadline)
                            .foregroundColor(Color("SecondaryTextColor"))
                        
                        HStack(spacing: 24) {
                            ForEach(emojis, id: \.self) { emoji in
                                Button(action: {
                                    selectedEmoji = emoji
                                    showEmojiSelector = false
                                }) {
                                    Text(emoji)
                                        .font(.title)
                                        .opacity(emoji == selectedEmoji ? 1.0 : 0.5)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets())
            .padding(.vertical, 8)
        }
    }
    
    private var ratingSection: some View {
        Section(header: Text(NSLocalizedString("sleepEntry.rating", tableName: "AddSleepEntrySheet", comment: ""))) {
            HStack(spacing: 16) {
                ForEach(ratingValues, id: \.self) { value in
                    Button(action: {
                        rating = value
                    }) {
                        Image(systemName: value <= rating ? "star.fill" : "star")
                            .foregroundColor(value <= rating ? .yellow : Color("SecondaryTextColor"))
                            .font(.title2)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets())
            .padding(.vertical, 8)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                datePickerSection
                blockSelectionSection
                
                if selectedBlock != nil {
                    qualitySection
                    ratingSection
                }
            }
            .navigationTitle(NSLocalizedString("sleepEntry.add", tableName: "AddSleepEntrySheet", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("general.cancel", tableName: "AddSleepEntrySheet", comment: "")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("general.save", tableName: "AddSleepEntrySheet", comment: "")) {
                        saveSleepEntry()
                        dismiss()
                    }
                    .disabled(!isValidEntry())
                }
            }
            .alert(isPresented: $showBlockError) {
                Alert(
                    title: Text("sleepEntry.error.title", tableName: "AddSleepEntrySheet"),
                    message: Text(blockErrorMessage),
                    dismissButton: .default(Text("general.ok", tableName: "AddSleepEntrySheet"))
                )
            }
        }
    }
    
    private func isValidEntry() -> Bool {
        return selectedBlock != nil && isDateValid
    }
    
    private func saveSleepEntry() {
        guard let block = selectedBlock else { return }
        
        // Seçilen tarih ve blok saatlerini birleştir
        let calendar = Calendar.current
        let startComponents = TimeFormatter.time(from: block.startTime)!
        let endComponents = TimeFormatter.time(from: block.endTime)!
        
        var startDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        startDateComponents.hour = startComponents.hour
        startDateComponents.minute = startComponents.minute
        
        var endDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        endDateComponents.hour = endComponents.hour
        endDateComponents.minute = endComponents.minute
        
        // Eğer bitiş saati başlangıç saatinden küçükse, bir sonraki güne geçmiş demektir
        if endComponents.hour < startComponents.hour || 
           (endComponents.hour == startComponents.hour && endComponents.minute < startComponents.minute) {
            endDateComponents = calendar.dateComponents([.year, .month, .day], from: calendar.date(byAdding: .day, value: 1, to: selectedDate)!)
            endDateComponents.hour = endComponents.hour
            endDateComponents.minute = endComponents.minute
        }
        
        let startTime = calendar.date(from: startDateComponents)!
        let endTime = calendar.date(from: endDateComponents)!
        
        // Benzersiz bir UUID oluştur
        let uniqueId = UUID()
        
        let entry = SleepEntry(
            id: uniqueId,
            type: block.isCore ? .core : .powerNap,
            startTime: startTime,
            endTime: endTime,
            rating: rating
        )
        
        viewModel.addSleepEntry(entry)
    }
}

#Preview {
    AddSleepEntrySheet(viewModel: HistoryViewModel())
}
