import SwiftUI

struct LoadingRecommendationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    @Binding var progress: Double
    @Binding var statusMessage: String
    @Binding var isComplete: Bool
    @Binding var navigateToMainScreen: Bool
    
    // Animasyon için
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.7
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                LocalizedText("onboarding.loading.preparingProgram", tableName: "Onboarding")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.appText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)
                
                // Yüzde göstergesi
                ZStack {
                    // Arka plan gölgesi
                    Circle()
                        .fill(Color.appPrimary.opacity(0.1))
                        .frame(width: 220, height: 220)
                        .shadow(color: Color.appPrimary.opacity(0.2), radius: 10, x: 0, y: 0)
                    
                    // Pasif arka plan halkası
                    Circle()
                        .stroke(Color.appTextSecondary.opacity(0.2), lineWidth: 15)
                        .frame(width: 200, height: 200)
                    
                    // Aktif ilerleme halkası
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.appPrimary.opacity(0.7), Color.appPrimary]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 15, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                    
                    // Parlama efekti
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(Color.appPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .blur(radius: 4)
                        .opacity(glowOpacity)
                    
                    // Yüzde ve durum
                    VStack(spacing: 8) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.appText)
                            .contentTransition(.numericText())
                        
                        if isComplete {
                            LocalizedText("onboarding.loading.ready", tableName: "Onboarding")
                                .font(.headline)
                                .foregroundColor(.appText)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .scaleEffect(scale)
                }
                .overlay(
                    // Dairesel hareket eden indikatör
                    Circle()
                        .trim(from: 0.0, to: 0.2)
                        .stroke(Color.appPrimary.opacity(0.8), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 240, height: 240)
                        .rotationEffect(.degrees(rotation))
                        .opacity(isComplete ? 0 : 1)
                )
                
                Text(statusMessage)
                    .font(.headline)
                    .foregroundColor(.appText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .transition(.opacity)
                    .id(statusMessage) // Mesaj değiştiğinde geçiş efekti için
                
                Spacer()
                
                if isComplete {
                    Button(action: {
                        print("🚀 LoadingRecommendationView: START USING APP butonuna basıldı!")
                        print("🚀 navigateToMainScreen mevcut değeri: \(navigateToMainScreen)")
                        
                        // WelcomeView'dan gelen animasyonla benzer bir animasyon ile ana ekrana git
                        withAnimation(.easeInOut(duration: 0.5)) {
                            // Ana ekrana geçmek için önce bu ekranı kapatıyoruz
                            print("🚀 LoadingRecommendationView: dismiss() çağrılıyor...")
                            dismiss()
                            
                            // navigateToMainScreen'i doğrudan değiştirmek yerine, 
                            // dismiss işleminden sonra yapılacak
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                print("🚀 LoadingRecommendationView: navigateToMainScreen = true yapılıyor...")
                                navigateToMainScreen = true
                                print("🚀 LoadingRecommendationView: navigateToMainScreen yeni değeri: \(navigateToMainScreen)")
                            }
                        }
                    }) {
                        LocalizedText("onboarding.startUsingApp", tableName: "Onboarding")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.appPrimary, Color.appPrimary.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .shadow(color: Color.appPrimary.opacity(0.3), radius: 5, x: 0, y: 2)
                            )
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding()
        }
        .onAppear {
            // Dairesel dönüş animasyonu
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
            // Nabız animasyonu
            withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
                scale = 1.03
                glowOpacity = 0.4
            }
        }
        .onChange(of: isComplete) { newValue in
            if newValue {
                // Yükleme tamamlandığında ek animasyon
                withAnimation(.spring(duration: 0.6)) {
                    scale = 1.1
                }
                
                // Sonra normale dön
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring(duration: 0.4)) {
                        scale = 1.0
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var progress: Double = 0.65
    @Previewable @State var statusMessage: String = "Bilgiler alındı ve hesaplama yapılıyor..."
    @Previewable @State var isComplete: Bool = false
    @Previewable @State var navigateToMainScreen: Bool = false
    
    return LoadingRecommendationView(
        progress: $progress,
        statusMessage: $statusMessage,
        isComplete: $isComplete,
        navigateToMainScreen: $navigateToMainScreen
    )
} 
