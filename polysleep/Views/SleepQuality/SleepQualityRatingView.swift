import SwiftUI
import SwiftData

struct SleepQualityRatingView: View {
    let startTime: Date
    let endTime: Date
    @Binding var isPresented: Bool
    @State private var selectedRating: Int = 2 // Default to middle (Good)
    @State private var sliderValue: Double = 2 // 0-4 arası değer (5 emoji için)
    @State private var isDeferredRating = false
    @State private var showSnackbar = false
    @State private var previousEmojiLabel: String = ""
    @State private var labelOffset: CGFloat = 0
    @StateObject private var notificationManager = SleepQualityNotificationManager.shared
    // ViewModel'e erişim için ObservedObject ekleyelim
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
        VStack(spacing: 16) {
            Text(LocalizedStringKey("sleepQuality.question \(startTime.formatted(date: .omitted, time: .shortened)) \(endTime.formatted(date: .omitted, time: .shortened))"), tableName: "MainScreen")
                .font(.headline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Kompakt Emoji ve Yıldız Puanlama
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
                
                Slider(value: $sliderValue, in: 0...4, step: 1)
                    .tint(getSliderColor())
                    .onChange(of: sliderValue) { newValue in
                        // Haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        
                        // Emoji güncelle
                        emoji = currentEmoji
                        
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
            .padding(.horizontal)
            
            // Action Buttons
            HStack(spacing: 16) {
                Button(action: {
                    // Önce isPresented'ı false yaparak görünümü kapat
                    isPresented = false
                    
                    // Uyku kalitesi değerlendirmesinin tamamlandığını işaretle
                    viewModel.markSleepQualityRatingAsCompleted()
                    
                    // Sonra snackbar göster ve bildirim ekle
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.spring(response: 0.3)) {
                            showSnackbar = true
                            notificationManager.addPendingRating(startTime: startTime, endTime: endTime)
                        }
                    }
                }) {
                    Text(LocalizedStringKey("sleepQuality.later"), tableName: "MainScreen")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    // Önce isPresented'ı false yaparak görünümü kapat
                    isPresented = false
                    
                    // Uyku kalitesi değerlendirmesinin tamamlandığını işaretle
                    viewModel.markSleepQualityRatingAsCompleted()
                    
                    // Sonra uyku kalitesini kaydet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        saveSleepQuality()
                    }
                }) {
                    Text(LocalizedStringKey("sleepQuality.save"), tableName: "MainScreen")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color("CardBackground"))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
    
    private func saveSleepQuality() {
        // Seçilen puanı al (0-4 arası) ve 1-5 ölçeğine dönüştür
        let rating = Int(sliderValue.rounded()) + 1 // 1-5 arası puanlama
        print("Sleep quality saved: \(rating)")
        
        // Benzersiz blockId oluştur veya belirli bir formatta tanımla
        let blockId = UUID().uuidString
        
        // Repository kullanarak uyku girdisini kaydet
        Task {
            do {
                _ = try await Repository.shared.addSleepEntry(
                    blockId: blockId,
                    emoji: emoji,
                    rating: rating,
                    date: startTime // Uyku bloğunun başlangıç saati
                )
                print("✅ Uyku girdisi başarıyla kaydedildi")
            } catch {
                print("❌ Uyku girdisi kaydedilirken hata: \(error.localizedDescription)")
            }
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
