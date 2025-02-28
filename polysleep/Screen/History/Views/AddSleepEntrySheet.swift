import SwiftUI
import SwiftData

struct AddSleepEntrySheet: View {
    @ObservedObject var viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedEmoji = "😊"
    @State private var sliderValue: Double = 2 // 0-4 arası değer (5 emoji için)
    @State private var selectedDate = Date()
    @State private var selectedBlock: SleepBlock?
    @State private var showBlockError = false
    @State private var blockErrorMessage = ""
    @State private var previousEmojiLabel: String = ""
    @State private var labelOffset: CGFloat = 0
    
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
    
    private let emojiLabels = [
        "😄": "great",
        "😊": "good",
        "😐": "okay",
        "😪": "bad",
        "😩": "awful"
    ]
    
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
    
    // Slider değerine göre emoji seçimi
    private var currentEmoji: String {
        let index = min(Int(sliderValue.rounded()), emojis.count - 1)
        return emojis[index]
    }
    
    // Slider değerine göre emoji açıklaması
    private var currentEmojiDescription: String {
        return NSLocalizedString(emojiDescriptions[currentEmoji] ?? "", tableName: "AddSleepEntrySheet", comment: "")
    }
    
    // Slider değerine göre emoji etiketi
    private var currentEmojiLabel: String {
        return emojiLabels[currentEmoji] ?? ""
    }
    
    // MARK: - View Components
    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("sleepEntry.date", tableName: "AddSleepEntrySheet")
                .font(.headline)
                .foregroundColor(Color("TextColor"))
            
            DatePicker(
                NSLocalizedString("sleepEntry.selectDate", tableName: "AddSleepEntrySheet", comment: ""),
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
            .tint(Color("AccentColor"))
            .onChange(of: selectedDate) { _ in
                selectedBlock = nil
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("CardBackground"))
            )
        }
        .padding(.horizontal)
    }
    
    private var blockSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("sleepEntry.selectBlock", tableName: "AddSleepEntrySheet")
                .font(.headline)
                .foregroundColor(Color("TextColor"))
            
            if availableBlocks.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("🌙")
                            .font(.title)
                        
                        Text("sleepEntry.noBlocks", tableName: "AddSleepEntrySheet", comment: "")
                            .font(.subheadline)
                            .foregroundColor(Color("SecondaryTextColor"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    Spacer()
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("CardBackground"))
                )
                .padding(.horizontal)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(availableBlocks.prefix(max(5, availableBlocks.count)), id: \.id) { block in
                            BlockSelectionButton(
                                block: block,
                                isSelected: selectedBlock?.id == block.id,
                                onTap: {
                                    if isBlockAlreadyAdded(block) {
                                        blockErrorMessage = "sleepEntry.error.alreadyAdded"
                                        showBlockError = true
                                    } else {
                                        selectedBlock = block
                                        // Haptic feedback
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    }
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(height: 250)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("CardBackground"))
                )
            }
        }
        .padding(.horizontal)
    }
    
    private struct BlockSelectionButton: View {
        let block: SleepBlock
        let isSelected: Bool
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Text(block.isCore ? "🛏️" : "⚡️")
                        .font(.system(size: 16))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(isSelected ? Color("AccentColor").opacity(0.2) : Color.clear)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(block.startTime) - \(block.endTime)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color("TextColor"))
                        
                        Text(block.isCore ? NSLocalizedString("sleepBlock.type.core", tableName: "AddSleepEntrySheet", comment: "") : NSLocalizedString("sleepBlock.type.nap", tableName: "AddSleepEntrySheet", comment: ""))
                            .font(.system(size: 12))
                            .foregroundColor(Color("SecondaryTextColor"))
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color("AccentColor"))
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color("AccentColor").opacity(0.1) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color("AccentColor") : Color.clear, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 8)
        }
    }
    
    private var qualitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rate your sleep quality")
                .font(.headline)
                .foregroundColor(Color("TextColor"))
                .padding(.horizontal)
            
            VStack(alignment: .center, spacing: 16) {
                HStack(spacing: 12) {
                    Text(currentEmoji)
                        .font(.system(size: 52))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentEmoji)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ZStack {
                            Text(previousEmojiLabel)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color("SecondaryTextColor"))
                                .opacity(labelOffset != 0 ? 0.3 : 0)
                                .offset(y: labelOffset)
                            
                            Text(currentEmojiLabel)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color("SecondaryTextColor"))
                                .offset(y: labelOffset)
                        }
                        .frame(height: 20)
                        .clipped()
                        
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                Image(systemName: index <= Int(sliderValue.rounded()) ? "star.fill" : "star")
                                    .foregroundColor(index <= Int(sliderValue.rounded()) ? getSliderColor() : Color("SecondaryTextColor").opacity(0.3))
                                    .font(.system(size: 12))
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                Slider(value: $sliderValue, in: 0...4, step: 1)
                    .tint(getSliderColor())
                    .padding(.horizontal)
                    .onChange(of: sliderValue) { newValue in
                        // Haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        
                        // Etiket animasyonu için
                        if currentEmojiLabel != previousEmojiLabel {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                labelOffset = 20 // Aşağı doğru kaydır
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                labelOffset = -20 // Yukarı konumla
                                previousEmojiLabel = currentEmojiLabel
                                
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    labelOffset = 0 // Ortaya getir
                                }
                            }
                        }
                    }
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("CardBackground"))
            )
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private func getSliderColor() -> Color {
        let index = Int(sliderValue.rounded())
        switch index {
        case 0:
            return Color.red
        case 1:
            return Color.orange
        case 2:
            return Color.yellow
        case 3:
            return Color.blue
        case 4:
            return Color.green
        default:
            return Color.yellow
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    datePickerSection
                    blockSelectionSection
                    
                    if selectedBlock != nil {
                        qualitySection
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
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
                        // Haptic feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        dismiss()
                    }
                    .disabled(!isValidEntry())
                    .opacity(isValidEntry() ? 1.0 : 0.5)
                    .font(.headline)
                }
            }
            .background(Color("BackgroundColor").edgesIgnoringSafeArea(.all))
            .alert(isPresented: $showBlockError) {
                Alert(
                    title: Text("sleepEntry.error.title", tableName: "AddSleepEntrySheet"),
                    message: Text(LocalizedStringKey(blockErrorMessage), tableName: "AddSleepEntrySheet"),
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
        
        // Emoji'den rating değerini hesapla (1-5 arası)
        let rating = Int(sliderValue.rounded()) + 1 // 0-4 aralığını 1-5 aralığına dönüştür
        
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
