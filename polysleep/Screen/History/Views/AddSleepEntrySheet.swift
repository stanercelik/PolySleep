import SwiftUI
import SwiftData

struct AddSleepEntrySheet: View {
    @ObservedObject var viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedEmoji = "😊"
    @State private var sliderValue: Double = 2 // 0-4 arası değer (5 emoji için)
    @State private var selectedDate: Date
    @State private var selectedBlock: SleepBlock?
    @State private var showBlockError = false
    @State private var blockErrorMessage = ""
    @State private var previousEmojiLabel: String = ""
    @State private var labelOffset: CGFloat = 0
    @State private var animateSelection: Bool = false
    
    // MainScreenViewModel'den uyku bloklarını almak için
    @StateObject private var mainViewModel = MainScreenViewModel()
    
    // İlk tarih değerini dışarıdan alacak şekilde init
    init(viewModel: HistoryViewModel, initialDate: Date? = nil) {
        self.viewModel = viewModel
        _selectedDate = State(initialValue: initialDate ?? Date())
    }
    
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
    
    // Kullanıcının seçtiği emojiler
    private var coreEmoji: String {
        UserDefaults.standard.string(forKey: "selectedCoreEmoji") ?? "🌙"
    }
    
    private var napEmoji: String {
        UserDefaults.standard.string(forKey: "selectedNapEmoji") ?? "⚡"
    }
    
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Color.appPrimary)
                    .font(.system(size: 18, weight: .medium))
                
                Text("sleepEntry.date", tableName: "AddSleepEntrySheet")
                    .font(.headline)
                    .foregroundColor(Color.appText)
            }
            
            DatePicker(
                NSLocalizedString("sleepEntry.selectDate", tableName: "AddSleepEntrySheet", comment: ""),
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
            .tint(Color.appPrimary)
            .onChange(of: selectedDate) { _ in
                selectedBlock = nil
                // Hafif bir titreşim verelim
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground"))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .padding(.bottom, 8)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var blockSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(Color.appPrimary)
                    .font(.system(size: 18, weight: .medium))
                
                Text("sleepEntry.selectBlock", tableName: "AddSleepEntrySheet")
                    .font(.headline)
                    .foregroundColor(Color.appText)
            }
            
            if availableBlocks.isEmpty {
                EmptyBlocksView()
            } else {
                BlocksListView()
            }
        }
        .padding(.horizontal)
    }
    
    private func EmptyBlocksView() -> some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color.appSecondaryText.opacity(0.5))
                
                Text("sleepEntry.noBlocks", tableName: "AddSleepEntrySheet", comment: "")
                    .font(.headline)
                    .foregroundColor(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            Spacer()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .frame(height: 200)
    }
    
    private func BlocksListView() -> some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(availableBlocks, id: \.id) { block in
                    let alreadyAdded = isBlockAlreadyAdded(block)
                    
                    BlockSelectionButton(
                        block: block,
                        isSelected: selectedBlock?.id == block.id,
                        isAlreadyAdded: alreadyAdded,
                        onTap: {
                            if alreadyAdded {
                                blockErrorMessage = "sleepEntry.error.alreadyAdded"
                                showBlockError = true
                            } else {
                                withAnimation(.spring(duration: 0.3)) {
                                    // Seçimi değiştirdiğimizde animasyon tetikle
                                    selectedBlock = block
                                    animateSelection = true
                                }
                                
                                // Animasyonu sıfırla
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    animateSelection = false
                                }
                                
                                // Haptic feedback
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                            }
                        }
                    )
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
        }
        .frame(height: 250)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private func BlockSelectionButton(block: SleepBlock, isSelected: Bool, isAlreadyAdded: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack {
                // Blok tipi ikonu (core veya nap)
                Text(block.isCore ? coreEmoji : napEmoji)
                    .font(.system(size: 20))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(block.isCore ? Color.appPrimary.opacity(0.2) : Color.appSecondary.opacity(0.2))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(block.isCore ? "Ana Uyku" : "Şekerleme")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isAlreadyAdded ? Color.appText.opacity(0.6) : Color.appText)
                    
                    Text("\(TimeFormatter.formattedString(from: block.startTime)) - \(TimeFormatter.formattedString(from: block.endTime))")
                        .font(.caption)
                        .foregroundColor(isAlreadyAdded ? Color.appSecondaryText.opacity(0.6) : Color.appSecondaryText)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.appSecondary)
                        .scaleEffect(animateSelection ? 1.2 : 1.0)
                } else if isAlreadyAdded {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.gray.opacity(0.6))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected ? Color.appSecondary.opacity(0.1) : 
                        isAlreadyAdded ? Color.gray.opacity(0.1) : Color.clear
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.appSecondary : 
                                isAlreadyAdded ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3), 
                                lineWidth: 1
                            )
                    )
            )
            .opacity(isAlreadyAdded ? 0.8 : 1.0)
        }
        .disabled(isAlreadyAdded)
    }
    
    private var qualitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(Color.appPrimary)
                    .font(.system(size: 18, weight: .medium))
                
                Text("sleepEntry.quality", tableName: "AddSleepEntrySheet")
                    .font(.headline)
                    .foregroundColor(Color.appText)
            }
            
            VStack(alignment: .center, spacing: 24) {
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(getSliderColor().opacity(0.15))
                            .frame(width: 70, height: 70)
                        
                        Text(currentEmoji)
                            .font(.system(size: 42))
                            .scaleEffect(animateSelection ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentEmoji)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack {
                            Text(previousEmojiLabel)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.appSecondaryText)
                                .opacity(labelOffset != 0 ? 0.3 : 0)
                                .offset(y: labelOffset)
                            
                            Text(currentEmojiLabel)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.appSecondaryText)
                                .offset(y: labelOffset)
                        }
                        .frame(height: 20)
                        .clipped()
                        
                        Text(currentEmojiDescription)
                            .font(.system(size: 14))
                            .foregroundColor(Color.appSecondaryText)
                        
                        HStack(spacing: 6) {
                            ForEach(0..<5) { index in
                                Image(systemName: index <= Int(sliderValue.rounded()) ? "star.fill" : "star")
                                    .foregroundColor(index <= Int(sliderValue.rounded()) ? getSliderColor() : Color.appSecondaryText.opacity(0.3))
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Kötü")
                            .font(.system(size: 12))
                            .foregroundColor(Color.appSecondaryText)
                        
                        Spacer()
                        
                        Text("Mükemmel")
                            .font(.system(size: 12))
                            .foregroundColor(Color.appSecondaryText)
                    }
                    .padding(.horizontal, 4)
                    
                    // Star rating seçimi için butonlar ve kaydırıcı
                    ZStack {
                        // Etkileşimli olan gerçek slider
                        Slider(value: $sliderValue, in: 0...4, step: 1)
                            .accentColor(getSliderColor())
                            .padding(.vertical, 20) // Slider'ın dokunma alanını genişlet
                            .onChange(of: sliderValue) { newValue in
                                // Haptic feedback
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                
                                // Etiket animasyonu için
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
                    .frame(height: 60) // Düğme alanını genişlet
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground"))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .padding(.horizontal)
        }
        .padding(.top, 8)
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
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        datePickerSection
                        blockSelectionSection
                        
                        if selectedBlock != nil {
                            qualitySection
                        }
                        
                        // Kaydet butonu
                        if selectedBlock != nil {
                            SaveButton(isEnabled: isValidEntry())
                                .padding(.horizontal)
                                .padding(.top, 8)
                                .padding(.bottom, 24)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                    .animation(.spring(response: 0.3), value: selectedBlock != nil)
                }
            }
            .navigationTitle(NSLocalizedString("sleepEntry.add", tableName: "AddSleepEntrySheet", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("general.cancel", tableName: "AddSleepEntrySheet", comment: "")) {
                        dismiss()
                    }
                    .foregroundColor(Color.appPrimary)
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
                    .foregroundColor(Color.appPrimary)
                }
            }
            .alert(isPresented: $showBlockError) {
                Alert(
                    title: Text("sleepEntry.error.title", tableName: "AddSleepEntrySheet"),
                    message: Text(LocalizedStringKey(blockErrorMessage), tableName: "AddSleepEntrySheet"),
                    dismissButton: .default(Text("general.ok", tableName: "AddSleepEntrySheet"))
                )
            }
        }
    }
    
    // Büyük kaydet butonu
    private func SaveButton(isEnabled: Bool) -> some View {
        Button(action: {
            if isEnabled {
                saveSleepEntry()
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                dismiss()
            }
        }) {
            HStack {
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.headline)
                Text(NSLocalizedString("general.save", tableName: "AddSleepEntrySheet", comment: ""))
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isEnabled ? 
                         LinearGradient(gradient: Gradient(colors: [Color.appPrimary, Color.appPrimary.opacity(0.8)]), 
                                      startPoint: .topLeading, 
                                      endPoint: .bottomTrailing) :
                         LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)]), 
                                      startPoint: .topLeading, 
                                      endPoint: .bottomTrailing))
                    .shadow(color: isEnabled ? Color.appPrimary.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
            )
            .foregroundColor(.white)
        }
        .disabled(!isEnabled)
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
