import SwiftUI
import Lottie

// MARK: - Celebration Overlay
struct CelebrationOverlay: View {
    @Binding var isShowing: Bool
    let title: String
    let subtitle: String
    @State private var opacity: Double = 0
    @State private var animationCompleted: Bool = false
    
    var body: some View {
        if isShowing {
            ZStack {
                // Şeffaf arka plan - sadece animasyon için
                Color.clear
                    .ignoresSafeArea(.all)
                
                // Tüm ekranı kaplayan Confetti Lottie Animasyonu
                LottieView(animation: .named("celebration"))
                    .playing(loopMode: .playOnce)
                    .ignoresSafeArea(.all)
                    .opacity(opacity)
                    .onAppear {
                        // Animasyon süresini hesaplayarak otomatik kapanma sağla
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { // Tipik confetti animasyon süresi
                            if !animationCompleted {
                                animationCompleted = true
                                withAnimation(.easeOut(duration: 0.3)) {
                                    isShowing = false
                                }
                            }
                        }
                    }
            }
            .onAppear {
                withAnimation(.easeIn(duration: 0.2)) {
                    opacity = 1.0
                }
            }
            .onTapGesture {
                // Manuel olarak kapatma seçeneği
                animationCompleted = true
                withAnimation(.easeOut(duration: 0.3)) {
                    isShowing = false
                }
            }
        }
    }
}

#Preview {
    CelebrationOverlay(
        isShowing: .constant(true),
        title: "Tebrikler!",
        subtitle: "Adaptasyon tamamlandı!"
    )
} 
