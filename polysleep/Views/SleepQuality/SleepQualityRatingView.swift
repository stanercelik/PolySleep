import SwiftUI
import SwiftData

struct SleepQualityRatingView: View {
    let startTime: Date
    let endTime: Date
    @Binding var isPresented: Bool
    @State private var sliderValue: Double = 2 // 0-4 arası değer (5 emoji için)
    @State private var isDeferredRating = false
    @State private var showSnackbar = false
    @State private var previousEmojiLabel: String = ""
    @State private var labelOffset: CGFloat = 0
    @StateObject private var notificationManager = SleepQualityNotificationManager.shared
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var emoji: String = "😐" // Varsayılan emoji
    
    private let emojis = ["😩", "😪", "😐", "😊", "😄"]
    private let emojiLabels = [
        "😩": "awful",
        "😪": "bad", 
        "😐": "okay",
        "😊": "good",
        "😄": "great"
    ]
    
    // Slider değerine göre emoji seçimi
    private var currentEmoji: String {
        let index = min(Int(sliderValue.rounded()), emojis.count - 1)
        return emojis[index]
    }
    
    // Slider değerine göre emoji etiketi
    private var currentEmojiLabel: String {
        return emojiLabels[currentEmoji] ?? ""
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // Header - History ile uyumlu
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Uykunuzu Değerlendirin")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color("TextColor"))
                    
                    Text("Uyku kaliteniz nasıldı?")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryTextColor"))
                }
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                    // X butonuna basıldığında rating vermiş gibi işaretleme
                    // Sadece modal'ı kapat
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("SecondaryTextColor").opacity(0.6))
                }
            }
            
            // Rating Section - History ile uyumlu design
            VStack(spacing: 12) {
                // Emoji ve açıklama
                VStack(spacing: 6) {
                    Text(currentEmoji)
                        .font(.system(size: 50))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentEmoji)
                    
                    Text(currentEmojiLabel)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("SecondaryTextColor"))
                        .animation(.easeInOut(duration: 0.2), value: currentEmojiLabel)
                }
                
                // Yıldız Puanlama - History ile uyumlu
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        Image(systemName: index <= Int(sliderValue.rounded()) ? "star.fill" : "star")
                            .foregroundColor(index <= Int(sliderValue.rounded()) ? getSliderColor() : Color("SecondaryTextColor").opacity(0.3))
                            .font(.title2)
                    }
                }
                
                // Slider
                VStack(spacing: 8) {
                    Slider(value: $sliderValue, in: 0...4, step: 1)
                        .tint(getSliderColor())
                        .onChange(of: sliderValue) { newValue in
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            emoji = currentEmoji
                        }
                    
                    // Slider Labels
                    HStack {
                        Text("Kötü")
                            .font(.caption)
                            .foregroundColor(Color("SecondaryTextColor"))
                        
                        Spacer()
                        
                        Text("Mükemmel")
                            .font(.caption)
                            .foregroundColor(Color("SecondaryTextColor"))
                    }
                }
            }
            .padding(.vertical, 8)
            
            // Action Buttons - History ile uyumlu
            HStack(spacing: 16) {
                Button(action: {
                    viewModel.deferSleepQualityRating()
                    isPresented = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.spring(response: 0.3)) {
                            showSnackbar = true
                            notificationManager.addPendingRating(startTime: startTime, endTime: endTime)
                        }
                    }
                }) {
                    Text("Daha Sonra")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("CardBackground"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color("SecondaryTextColor").opacity(0.3), lineWidth: 1)
                                )
                        )
                        .foregroundColor(Color("TextColor"))
                }
                
                Button(action: {
                    viewModel.markSleepQualityRatingAsCompleted()
                    isPresented = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        saveSleepQuality()
                    }
                }) {
                    Text("Kaydet")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("AccentColor"))
                        )
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CardBackground"))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private func saveSleepQuality() {
        guard let lastBlock = viewModel.lastSleepBlock else {
            print("❌ Son uyku bloğu bulunamadı")
            return
        }
        
        let rating = Int(sliderValue.rounded()) + 1 // 1-5 arası puanlama
        print("💾 Uyku kalitesi kaydediliyor: \(rating)")
        
        // SleepEntry oluştur - History ile uyumlu
        let calendar = Calendar.current
        let entryDate = calendar.startOfDay(for: startTime)
        
        // Süreyi hesapla
        let durationMinutes = Int(endTime.timeIntervalSince(startTime) / 60)
        
        let newEntry = SleepEntry(
            date: entryDate,
            startTime: startTime,
            endTime: endTime,
            durationMinutes: durationMinutes,
            isCore: lastBlock.isCore,
            blockId: lastBlock.id.uuidString,
            emoji: currentEmoji,
            rating: rating
        )
        
        // ModelContext kullanarak kaydet
        let context = modelContext
        
        do {
            // HistoryModel'i bul veya oluştur
            let predicate = #Predicate<HistoryModel> { $0.date == entryDate }
            let descriptor = FetchDescriptor(predicate: predicate)
            
            var historyModel = try context.fetch(descriptor).first
            
            if historyModel == nil {
                historyModel = HistoryModel(date: entryDate)
                context.insert(historyModel!)
                print("✅ Yeni HistoryModel oluşturuldu: \(entryDate)")
            }
            
            // SleepEntry'yi ekle
            newEntry.historyDay = historyModel
            historyModel?.sleepEntries?.append(newEntry)
            context.insert(newEntry)
            
            try context.save()
            print("✅ Uyku girdisi başarıyla kaydedildi - Rating: \(rating), Emoji: \(currentEmoji)")
            
            // Repository'ye de kaydet (senkronizasyon için)
            Task {
                do {
                    _ = try await Repository.shared.addSleepEntry(
                        blockId: lastBlock.id.uuidString,
                        emoji: currentEmoji,
                        rating: rating,
                        date: startTime
                    )
                    print("✅ Repository'ye de kaydedildi")
                } catch {
                    print("❌ Repository'ye kaydederken hata: \(error.localizedDescription)")
                }
            }
            
        } catch {
            print("❌ SleepEntry kaydedilirken hata: \(error.localizedDescription)")
        }
        
        // Bekleyen bildirimi kaldır
        notificationManager.removePendingRating(startTime: startTime, endTime: endTime)
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
}
