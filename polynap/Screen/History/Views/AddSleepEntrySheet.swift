import SwiftUI
import SwiftData

struct AddSleepEntrySheet: View {
    @ObservedObject var viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var languageManager: LanguageManager
    
    // Analytics
    private let analyticsManager = AnalyticsManager.shared
    @State private var selectedEmoji = "😊"
    @State private var sliderValue: Double = 3 // 1-5 rating için (0-4 slider) -> Başlangıçta "😊" (rating 4)
    @State private var selectedDate: Date
    @State private var selectedBlockFromSchedule: SleepBlock?
    @State private var showBlockError = false
    @State private var blockErrorMessage = ""
    @State private var previousEmojiDescription: String = ""
    @State private var labelOffset: CGFloat = 0
    @State private var animateSelection: Bool = false
    @State private var showDateWarning = false
    @State private var dateWarningMessage = ""
    
    // Schedule bilgisini dışarıdan alacak şekilde değiştirdik
    let availableBlocks: [SleepBlock]
    
    // İlk tarih değerini ve schedule'ı dışarıdan alacak şekilde init
    init(viewModel: HistoryViewModel, availableBlocks: [SleepBlock], initialDate: Date? = nil) {
        self.viewModel = viewModel
        self.availableBlocks = availableBlocks
        _selectedDate = State(initialValue: initialDate ?? Date())
    }
    
    private let emojis = ["😩", "😪", "😐", "😊", "😄"]
    private let emojiDescriptions = [
        "😩": "sleep.quality.veryBad",
        "😪": "sleep.quality.bad",
        "😐": "sleep.quality.okay",
        "😊": "sleep.quality.good",
        "😄": "sleep.quality.veryGood"
    ]
    
    // Kullanıcının seçtiği emojiler
    private var coreEmoji: String {
        UserDefaults.standard.string(forKey: "selectedCoreEmoji") ?? "🌙"
    }
    
private var napEmoji: String {
    UserDefaults.standard.string(forKey: "selectedNapEmoji") ?? "💤"
}
    
    // Schedule bilgisini property olarak aldığımız için artık gerekmez
    // ancak kod değişikliğini minimize etmek için alias oluşturuyoruz
    private var availableBlocksFromSchedule: [SleepBlock] {
        availableBlocks
    }
    
    // Seçilen tarih bugün veya geçmişte mi?
    private var isDateValidForNewEntry: Bool {
        Calendar.current.compare(selectedDate, to: Date(), toGranularity: .day) != .orderedDescending
    }
    
    // Belirli bir SleepBlock (struct) için, seçilen tarihte zaten SleepEntry var mı veya henüz bitmemiş mi?
    private func isBlockAlreadyAdded(_ block: SleepBlock) -> Bool {
        guard let modelContext = viewModel.modelContext else { return false }
        let calendar = Calendar.current
        let targetDayStart = calendar.startOfDay(for: selectedDate)
        
        guard let blockStartComponents = TimeFormatter.time(from: block.startTime),
              let blockEndComponents = TimeFormatter.time(from: block.endTime) else { return false }
        
        var dateComponentsForBlockStart = calendar.dateComponents([.year, .month, .day], from: targetDayStart)
        dateComponentsForBlockStart.hour = blockStartComponents.hour
        dateComponentsForBlockStart.minute = blockStartComponents.minute
        guard let exactBlockStartTime = calendar.date(from: dateComponentsForBlockStart) else { return false }
        
        var dateComponentsForBlockEnd = calendar.dateComponents([.year, .month, .day], from: targetDayStart)
        dateComponentsForBlockEnd.hour = blockEndComponents.hour
        dateComponentsForBlockEnd.minute = blockEndComponents.minute
        var exactBlockEndTime = calendar.date(from: dateComponentsForBlockEnd)
        
        // Eğer bitiş zamanı başlangıçtan önce ise, ertesi güne kaydır
        if let endTime = exactBlockEndTime, endTime <= exactBlockStartTime {
            exactBlockEndTime = calendar.date(byAdding: .day, value: 1, to: endTime)
        }
        
        guard let finalBlockEndTime = exactBlockEndTime else { return false }
        
        // Bugün seçilmişse ve blok henüz bitmemişse engelle
        if calendar.isDateInToday(selectedDate) {
            let now = Date()
            if finalBlockEndTime > now {
                return true // Henüz bitmemiş blok olarak işaretle
            }
        }

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
        let index = min(Int(sliderValue.rounded()), emojis.count - 1)
        return emojis[index]
    }
    
    // Slider değerine göre emoji açıklaması
    private var currentEmojiDescription: String {
        return L(emojiDescriptions[currentEmoji] ?? "", table: "AddSleepEntrySheet")
    }
    
    // MARK: - View Components
    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(Color.appPrimary)
                    .font(.title2)
                
                Text(L("sleepEntry.date", table: "AddSleepEntrySheet"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appText)
                
                Spacer()
            }
            
            DatePicker(
                L("sleepEntry.selectDate", table: "AddSleepEntrySheet"),
                selection: $selectedDate,
                in: ...Date(), // Sadece bugüne kadar olan tarihler seçilebilir
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
            .tint(Color.appPrimary)
            .onChange(of: selectedDate) { newDate in
                selectedBlockFromSchedule = nil
                
                // Gelecek tarih kontrolü
                if Calendar.current.compare(newDate, to: Date(), toGranularity: .day) == .orderedDescending {
                    dateWarningMessage = "sleepEntry.error.futureDate"
                    showDateWarning = true
                    // Tarihi bugüne geri al
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        selectedDate = Date()
                    }
                } else {
                                         let generator = UIImpactFeedbackGenerator(style: .light)
                     generator.impactOccurred()
                 }
             }
             
             // Bilgi notu
             HStack(spacing: 8) {
                 Image(systemName: "info.circle.fill")
                     .font(.caption)
                     .foregroundColor(.blue.opacity(0.7))
                 
                 Text(L("sleepEntry.dateInfo", table: "AddSleepEntrySheet"))
                     .font(.caption)
                     .foregroundColor(.appTextSecondary)
             }
             .padding(.top, 4)
         }
         .padding(20)
         .background(
             RoundedRectangle(cornerRadius: 20)
                 .fill(Color.appCardBackground)
                 .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
         )
    }
    
    private var blockSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.circle.fill")
                    .foregroundColor(Color.appSecondary)
                    .font(.title2)
                
                Text(L("sleepEntry.selectBlock", table: "AddSleepEntrySheet"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appText)
                
                Spacer()
            }
            
            if availableBlocksFromSchedule.isEmpty {
                EmptyBlocksView()
            } else {
                BlocksListViewFromSchedule()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private func EmptyBlocksView() -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.appTextSecondary.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "moon.zzz")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(Color.appTextSecondary.opacity(0.6))
            }
            
            VStack(spacing: 8) {
                Text(L("sleepEntry.noBlocks", table: "AddSleepEntrySheet"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appText)
                    .multilineTextAlignment(.center)
                
                Text("Create a sleep schedule first to add entries")
                    .font(.body)
                    .foregroundColor(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appTextSecondary.opacity(0.05))
        )
    }
    
    private func BlocksListViewFromSchedule() -> some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(availableBlocksFromSchedule, id: \.id) { block in
                    let alreadyAdded = isBlockAlreadyAdded(block)
                    
                    BlockSelectionButton(
                        block: block,
                        isSelected: selectedBlockFromSchedule?.id == block.id,
                        isAlreadyAdded: alreadyAdded,
                        onTap: {
                            if alreadyAdded {
                                // Bugün seçilmişse ve blok henüz bitmemişse farklı mesaj göster
                                if Calendar.current.isDateInToday(selectedDate) {
                                    let calendar = Calendar.current
                                    if let blockEndComponents = TimeFormatter.time(from: block.endTime) {
                                        var dateComponentsForBlockEnd = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                                        dateComponentsForBlockEnd.hour = blockEndComponents.hour
                                        dateComponentsForBlockEnd.minute = blockEndComponents.minute
                                        
                                        if let exactBlockEndTime = calendar.date(from: dateComponentsForBlockEnd) {
                                            var finalBlockEndTime = exactBlockEndTime
                                            
                                            // Eğer bitiş zamanı başlangıçtan önce ise, ertesi güne kaydır
                                            if let blockStartComponents = TimeFormatter.time(from: block.startTime) {
                                                var startComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                                                startComponents.hour = blockStartComponents.hour
                                                startComponents.minute = blockStartComponents.minute
                                                
                                                if let startTime = calendar.date(from: startComponents), exactBlockEndTime <= startTime {
                                                    finalBlockEndTime = calendar.date(byAdding: .day, value: 1, to: exactBlockEndTime) ?? exactBlockEndTime
                                                }
                                            }
                                            
                                            if finalBlockEndTime > Date() {
                                                blockErrorMessage = "sleepEntry.error.notFinished"
                                            } else {
                                                blockErrorMessage = "sleepEntry.error.alreadyAdded"
                                            }
                                        } else {
                                            blockErrorMessage = "sleepEntry.error.alreadyAdded"
                                        }
                                    } else {
                                        blockErrorMessage = "sleepEntry.error.alreadyAdded"
                                    }
                                } else {
                                    blockErrorMessage = "sleepEntry.error.alreadyAdded"
                                }
                                showBlockError = true
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
            .padding(.vertical, 8)
        }
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appTextSecondary.opacity(0.05))
        )
    }
    
    private func BlockSelectionButton(block: SleepBlock, isSelected: Bool, isAlreadyAdded: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Kişiselleştirilmiş emoji kullan
                Text(block.isCore ? coreEmoji : napEmoji)
                    .font(.system(size: 18))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(block.isCore ? Color.appPrimary : Color.appSecondary)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(block.isCore ? L("sleep.type.core", table: "DayDetail") : L("sleep.type.nap", table: "DayDetail"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isAlreadyAdded ? Color.appText.opacity(0.6) : Color.appText)
                    
                    Text("\(block.startTime) - \(block.endTime)")
                        .font(.caption)
                        .foregroundColor(isAlreadyAdded ? Color.appTextSecondary.opacity(0.6) : Color.appTextSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.appPrimary)
                        .scaleEffect(animateSelection ? 1.2 : 1.0)
                } else if isAlreadyAdded {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.gray.opacity(0.6))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected ? Color.appPrimary.opacity(0.1) : 
                        isAlreadyAdded ? Color.gray.opacity(0.05) : Color.appCardBackground
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.appPrimary : 
                                isAlreadyAdded ? Color.gray.opacity(0.3) : Color.appTextSecondary.opacity(0.1), 
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isSelected ? Color.appPrimary.opacity(0.1) : Color.clear,
                        radius: isSelected ? 4 : 0,
                        x: 0,
                        y: isSelected ? 2 : 0
                    )
            )
            .opacity(isAlreadyAdded ? 0.7 : 1.0)
        }
        .disabled(isAlreadyAdded)
    }
    
    private var qualitySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(Color.appAccent)
                    .font(.title2)
                
                Text(L("sleepEntry.quality", table: "AddSleepEntrySheet"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appText)
                
                Spacer()
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
                            Text(previousEmojiDescription)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.appTextSecondary)
                                .opacity(labelOffset != 0 ? 0.3 : 0)
                                .offset(y: labelOffset)
                            
                            Text(currentEmojiDescription)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.appTextSecondary)
                                .offset(y: labelOffset)
                        }
                        .frame(height: 20)
                        .clipped()
                        
                        HStack(spacing: 6) {
                            ForEach(0..<5) { index in
                                Image(systemName: index <= Int(sliderValue.rounded()) ? "star.fill" : "star")
                                    .foregroundColor(index <= Int(sliderValue.rounded()) ? getSliderColor() : Color.appTextSecondary.opacity(0.3))
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
                            .foregroundColor(Color.appTextSecondary)
                        
                        Spacer()
                        
                        Text(L("sleepEntry.quality.excellent", table: "AddSleepEntrySheet"))
                            .font(.system(size: 12))
                            .foregroundColor(Color.appTextSecondary)
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
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private func getSliderColor() -> Color {
        let index = Int(sliderValue.rounded())
        switch index {
        case 0:
            return Color.red        // 😩 - Very bad
        case 1:
            return Color.orange     // 😪 - Bad
        case 2:
            return Color.yellow     // 😐 - Okay
        case 3:
            return Color.appPrimary // 😊 - Good
        case 4:
            return Color.green      // 😄 - Very good
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
                    VStack(spacing: 20) {
                        datePickerSection
                        blockSelectionSection
                        
                        if selectedBlockFromSchedule != nil {
                            qualitySection
                        }
                        
                        // Kaydet butonu
                        if selectedBlockFromSchedule != nil {
                            SaveButton(isEnabled: isValidEntry())
                                .padding(.horizontal, 16)
                                .padding(.bottom, 24)
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedBlockFromSchedule != nil)
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
            .alert(isPresented: $showDateWarning) {
                Alert(
                    title: Text(L("sleepEntry.error.title", table: "AddSleepEntrySheet")),
                    message: Text(L(dateWarningMessage, table: "AddSleepEntrySheet")),
                    dismissButton: .default(Text(L("general.ok", table: "AddSleepEntrySheet")))
                )
            }
            .onAppear {
                // Analytics: Add Sleep Entry sheet görüntüleme
                analyticsManager.logScreenView(
                    screenName: "add_sleep_entry_sheet",
                    screenClass: "AddSleepEntrySheet"
                )
            }
        }
    }
    
    // Büyük kaydet butonu
    private func SaveButton(isEnabled: Bool) -> some View {
        Button(action: {
            if isEnabled {
                saveSleepEntry()
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                dismiss()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.headline)
                Text(L("general.save", table: "AddSleepEntrySheet"))
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isEnabled ? Color.appPrimary : Color.gray.opacity(0.3))
                    .shadow(
                        color: isEnabled ? Color.appPrimary.opacity(0.3) : Color.clear, 
                        radius: isEnabled ? 8 : 0, 
                        x: 0, 
                        y: isEnabled ? 4 : 0
                    )
            )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
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
        let ratingValue = Int(sliderValue.rounded()) + 1 // Slider 0(kötü)-4(iyi) -> Rating 1(kötü)-5(iyi)
        
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
        
        // Analytics: Manual sleep entry ekleme
        analyticsManager.logSleepEntryAdded(
            sleepType: scheduledBlock.isCore ? "core" : "nap",
            duration: durationMinutes,
            quality: ratingValue,
            isFirstEntry: false
        )
        
        // Analytics: Sleep quality rating
        analyticsManager.logSleepQualityRated(
            rating: ratingValue,
            sleepType: scheduledBlock.isCore ? "core" : "nap"
        )
        
        // ViewModel aracılığıyla kaydet
        viewModel.addSleepEntry(newEntry)
        
        // HealthKit'e de kaydet
        Task {
            let sleepType: SleepType = scheduledBlock.isCore ? .core : .powerNap
            await ScheduleManager.shared.saveSleepSessionToHealthKit(
                startDate: finalStartTime,
                endDate: finalEndTime,
                sleepType: sleepType
            )
        }
    }
}
