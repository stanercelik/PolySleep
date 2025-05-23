import SwiftUI
import SwiftData

struct AddSleepEntrySheet: View {
    @ObservedObject var viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var selectedEmoji = "😊"
    @State private var sliderValue: Double = 3 // 1-5 rating için (0-4 slider) -> Başlangıçta "😊" (rating 4)
    @State private var selectedDate: Date
    @State private var selectedBlockFromSchedule: SleepBlock?
    @State private var showBlockError = false
    @State private var blockErrorMessage = ""
    @State private var previousEmojiDescription: String = ""
    @State private var labelOffset: CGFloat = 0
    @State private var animateSelection: Bool = false
    
    // MainScreenViewModel'den aktif uyku programını almak için
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
    
    // Kullanıcının seçtiği emojiler
    private var coreEmoji: String {
        UserDefaults.standard.string(forKey: "selectedCoreEmoji") ?? "🌙"
    }
    
    private var napEmoji: String {
        UserDefaults.standard.string(forKey: "selectedNapEmoji") ?? "⚡"
    }
    
    // MainViewModel'in aktif programından uyku bloklarını alır
    private var availableBlocksFromSchedule: [SleepBlock] {
        mainViewModel.model.schedule.schedule
    }
    
    // Seçilen tarih bugün veya geçmişte mi?
    private var isDateValidForNewEntry: Bool {
        Calendar.current.compare(selectedDate, to: Date(), toGranularity: .day) != .orderedDescending
    }
    
    // Belirli bir SleepBlock (struct) için, seçilen tarihte zaten SleepEntry var mı?
    private func isBlockAlreadyAdded(_ block: SleepBlock) -> Bool {
        guard let modelContext = viewModel.modelContext else { return false }
        let calendar = Calendar.current
        let targetDayStart = calendar.startOfDay(for: selectedDate)
        
        guard let blockStartComponents = TimeFormatter.time(from: block.startTime) else { return false }
        
        var dateComponentsForBlockStart = calendar.dateComponents([.year, .month, .day], from: targetDayStart)
        dateComponentsForBlockStart.hour = blockStartComponents.hour
        dateComponentsForBlockStart.minute = blockStartComponents.minute
        guard let exactBlockStartTime = calendar.date(from: dateComponentsForBlockStart) else { return false }

        // Calculate nextDayStart outside the predicate
        guard let nextDayStart = calendar.date(byAdding: .day, value: 1, to: targetDayStart) else {
            print("Error calculating nextDayStart in isBlockAlreadyAdded")
            return false
        }

        // Fetch SleepEntry items for the target day first
        let dayStartPredicate = #Predicate<SleepEntry> { entry in
            entry.date >= targetDayStart && entry.date < nextDayStart // Use the pre-calculated nextDayStart
        }
        let descriptorForDay = FetchDescriptor(predicate: dayStartPredicate)

        do {
            let entriesForDay = try modelContext.fetch(descriptorForDay)
            // Now filter these entries in memory for the exact start time match
            for entry in entriesForDay {
                if calendar.isDate(entry.startTime, equalTo: exactBlockStartTime, toGranularity: .minute) {
                    return true // Found an existing entry for this block and date
                }
            }
            return false // No entry matched the exact start time for this block
        } catch {
            print("isBlockAlreadyAdded fetch descriptorForDay kontrolünde hata: \(error)")
            return false
        }
    }
    
    // Slider değerine göre emoji seçimi
    private var currentEmoji: String {
        let index = 4 - min(Int(sliderValue.rounded()), emojis.count - 1)
        return emojis[index]
    }
    
    // Slider değerine göre emoji açıklaması
    private var currentEmojiDescription: String {
        return L(emojiDescriptions[currentEmoji] ?? "", table: "AddSleepEntrySheet")
    }
    
    // MARK: - View Components
    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Color.appPrimary)
                    .font(.system(size: 18, weight: .medium))
                
                Text(L("sleepEntry.date", table: "AddSleepEntrySheet"))
                    .font(.headline)
                    .foregroundColor(Color.appText)
            }
            
            DatePicker(
                L("sleepEntry.selectDate", table: "AddSleepEntrySheet"),
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
            .tint(Color.appPrimary)
            .onChange(of: selectedDate) { _ in
                selectedBlockFromSchedule = nil
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
                
                Text(L("sleepEntry.selectBlock", table: "AddSleepEntrySheet"))
                    .font(.headline)
                    .foregroundColor(Color.appText)
            }
            
            if availableBlocksFromSchedule.isEmpty {
                EmptyBlocksView()
            } else {
                BlocksListViewFromSchedule()
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
                
                Text(L("sleepEntry.noBlocks", table: "AddSleepEntrySheet"))
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
    
    private func BlocksListViewFromSchedule() -> some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(availableBlocksFromSchedule, id: \.id) { block in
                    let alreadyAdded = isBlockAlreadyAdded(block)
                    
                    BlockSelectionButton(
                        block: block,
                        isSelected: selectedBlockFromSchedule?.id == block.id,
                        isAlreadyAdded: alreadyAdded,
                        onTap: {
                            if alreadyAdded {
                                blockErrorMessage = "sleepEntry.error.alreadyAdded"
                                showBlockError = true
                            } else {
                                withAnimation(.spring(duration: 0.3)) {
                                    selectedBlockFromSchedule = block
                                    animateSelection = true
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    animateSelection = false
                                }
                                
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
                Text(block.isCore ? coreEmoji : napEmoji)
                    .font(.system(size: 20))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(block.isCore ? Color.appPrimary.opacity(0.2) : Color.appSecondary.opacity(0.2))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(block.isCore ? L("sleep.type.core", table: "DayDetail") : L("sleep.type.nap", table: "DayDetail"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isAlreadyAdded ? Color.appText.opacity(0.6) : Color.appText)
                    
                    Text("\(block.startTime) - \(block.endTime)")
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
                
                Text(L("sleepEntry.quality", table: "AddSleepEntrySheet"))
                    .font(.headline)
                    .foregroundColor(Color.appText)
            }
            .padding(.horizontal)
            
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
                            Text(previousEmojiDescription)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.appSecondaryText)
                                .opacity(labelOffset != 0 ? 0.3 : 0)
                                .offset(y: labelOffset)
                            
                            Text(currentEmojiDescription)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.appSecondaryText)
                                .offset(y: labelOffset)
                        }
                        .frame(height: 20)
                        .clipped()
                        
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
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(L("sleepEntry.quality.bad", table: "AddSleepEntrySheet"))
                            .font(.system(size: 12))
                            .foregroundColor(Color.appSecondaryText)
                        
                        Spacer()
                        
                        Text(L("sleepEntry.quality.excellent", table: "AddSleepEntrySheet"))
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
                                    previousEmojiDescription = currentEmojiDescription
                                    
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
                        
                        if selectedBlockFromSchedule != nil {
                            qualitySection
                        }
                        
                        // Kaydet butonu
                        if selectedBlockFromSchedule != nil {
                            SaveButton(isEnabled: isValidEntry())
                                .padding(.horizontal)
                                .padding(.top, 8)
                                .padding(.bottom, 24)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                    .animation(.spring(response: 0.3), value: selectedBlockFromSchedule != nil)
                }
            }
            .navigationTitle(L("sleepEntry.add", table: "AddSleepEntrySheet"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("general.cancel", table: "AddSleepEntrySheet")) {
                        dismiss()
                    }
                    .foregroundColor(Color.appPrimary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("general.save", table: "AddSleepEntrySheet")) {
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
                    title: Text(L("sleepEntry.error.title", table: "AddSleepEntrySheet")),
                    message: Text(L(blockErrorMessage, table: "AddSleepEntrySheet")),
                    dismissButton: .default(Text(L("general.ok", table: "AddSleepEntrySheet")))
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
                Text(L("general.save", table: "AddSleepEntrySheet"))
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
        return selectedBlockFromSchedule != nil && isDateValidForNewEntry
    }
    
    private func saveSleepEntry() {
        guard let scheduledBlock = selectedBlockFromSchedule else { return }
        
        let calendar = Calendar.current
        
        // Başlangıç ve bitiş zamanlarını Date nesnelerine çevir
        guard let scheduleStartTimeComponents = TimeFormatter.time(from: scheduledBlock.startTime),
              let scheduleEndTimeComponents = TimeFormatter.time(from: scheduledBlock.endTime)
        else {
            print("Hata: Zaman formatı geçersiz.")
            return
        }
        
        var startComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        startComponents.hour = scheduleStartTimeComponents.hour
        startComponents.minute = scheduleStartTimeComponents.minute
        
        var endComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        endComponents.hour = scheduleEndTimeComponents.hour
        endComponents.minute = scheduleEndTimeComponents.minute
        
        guard let finalStartTime = calendar.date(from: startComponents),
              var finalEndTime = calendar.date(from: endComponents)
        else {
            print("Hata: Tarih bileşenlerinden Date oluşturulamadı.")
            return
        }
        
        // Bitiş zamanı başlangıçtan önceyse, ertesi güne kaydır
        if finalEndTime <= finalStartTime {
            finalEndTime = calendar.date(byAdding: .day, value: 1, to: finalEndTime)!
        }
        
        let durationMinutes = Int(finalEndTime.timeIntervalSince(finalStartTime) / 60)
        let ratingValue = 5 - Int(sliderValue.rounded()) // Slider 0(iyi)-4(kötü) -> Rating 5(iyi)-1(kötü)
        
        // Yeni SleepEntry @Model nesnesi oluştur
        let newEntry = SleepEntry(
            date: calendar.startOfDay(for: selectedDate), // Bloğun ait olduğu gün
            startTime: finalStartTime,
            endTime: finalEndTime,
            durationMinutes: durationMinutes,
            isCore: scheduledBlock.isCore, // MainViewModel'deki SleepBlock'tan alınır
            blockId: scheduledBlock.id.uuidString, // MainViewModel'deki SleepBlock'tan ID
            emoji: currentEmoji, // Slider'dan gelen emoji
            rating: ratingValue  // Slider'dan gelen rating
        )
        
        // ViewModel aracılığıyla kaydet
        viewModel.addSleepEntry(newEntry)
    }
}

#Preview {
    AddSleepEntrySheet(viewModel: HistoryViewModel())
}
