import SwiftUI

struct SleepQualityRatingView: View {
    let startTime: Date
    let endTime: Date
    @Binding var isPresented: Bool
    @State private var selectedRating: Int = 2 // Default to middle (Good)
    @State private var isDeferredRating = false
    @State private var showSnackbar = false
    @StateObject private var notificationManager = SleepQualityNotificationManager.shared
    
    private let emojis = ["😩", "😪", "😐", "😊", "😄"]
    private let ratingKeys = [
        "sleepQuality.rating.bad",
        "sleepQuality.rating.poor",
        "sleepQuality.rating.good",
        "sleepQuality.rating.veryGood",
        "sleepQuality.rating.excellent"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text(LocalizedStringKey("sleepQuality.question \(startTime.formatted(date: .omitted, time: .shortened)) \(endTime.formatted(date: .omitted, time: .shortened))"))
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Custom Emoji Slider
            CustomEmojiSlider(
                selectedRating: $selectedRating,
                emojis: emojis,
                labels: ratingKeys
            )
            .padding(.vertical)
            
            // Action Buttons
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        showSnackbar = true
                        notificationManager.addPendingRating(startTime: startTime, endTime: endTime)
                        
                        // Snackbar gösterildikten sonra view'ı kapat
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                isPresented = false
                            }
                        }
                    }
                }) {
                    Text(LocalizedStringKey("sleepQuality.later"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        saveSleepQuality()
                        isPresented = false
                    }
                }) {
                    Text(LocalizedStringKey("sleepQuality.save"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color("CardBackground"))
        .cornerRadius(12)
        .shadow(radius: 8)
        .snackbar(isPresented: $showSnackbar, message: NSLocalizedString("sleepQuality.snackbar.message", comment: ""))
    }
    
    private func saveSleepQuality() {
        // TODO: Implement save functionality
        print("Sleep quality saved: \(selectedRating)")
        notificationManager.removePendingRating(startTime: startTime, endTime: endTime)
    }
}

struct CustomEmojiSlider: View {
    @Binding var selectedRating: Int
    let emojis: [String]
    let labels: [String]
    
    @GestureState private var dragLocation: CGFloat = 0
    @State private var previousRating: Int = 0
    
    var body: some View {
        VStack(spacing: 12) {
            // Emojis
            HStack(spacing: 0) {
                ForEach(0..<emojis.count, id: \.self) { index in
                    Text(emojis[index])
                        .font(.system(size: 32))
                        .frame(maxWidth: .infinity)
                        .scaleEffect(selectedRating == index ? 1.2 : 0.8)
                        .animation(.spring(response: 0.3), value: selectedRating)
                }
            }
            
            // Custom Slider Track
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background Track
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    // Filled Track
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("AccentColor"))
                        .frame(width: sliderPosition(in: geometry.size.width), height: 8)
                    
                    // Thumb
                    Circle()
                        .fill(Color("AccentColor"))
                        .frame(width: 24, height: 24)
                        .offset(x: sliderPosition(in: geometry.size.width) - 12)
                        .shadow(radius: 4)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .updating($dragLocation) { value, state, _ in
                            state = value.location.x
                        }
                        .onChanged { value in
                            updateSelection(at: value.location.x, in: geometry.size.width)
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.3)) {
                                updateSelection(at: value.location.x, in: geometry.size.width)
                            }
                            // Haptic feedback
                            if previousRating != selectedRating {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                previousRating = selectedRating
                            }
                        }
                )
            }
            .frame(height: 24)
            .padding(.horizontal)
            
            // Labels
            HStack(spacing: 0) {
                ForEach(0..<labels.count, id: \.self) { index in
                    Text(LocalizedStringKey(labels[index]))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .opacity(selectedRating == index ? 1 : 0.6)
                }
            }
        }
    }
    
    private func sliderPosition(in width: CGFloat) -> CGFloat {
        let segmentWidth = width / CGFloat(emojis.count - 1)
        return CGFloat(selectedRating) * segmentWidth
    }
    
    private func updateSelection(at position: CGFloat, in width: CGFloat) {
        let segmentWidth = width / CGFloat(emojis.count - 1)
        var newRating = Int(round(position / segmentWidth))
        newRating = min(max(newRating, 0), emojis.count - 1)
        
        if newRating != selectedRating {
            selectedRating = newRating
        }
    }
}
