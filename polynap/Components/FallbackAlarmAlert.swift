import SwiftUI
import AVFoundation

struct FallbackAlarmAlert: View {
    let blockId: UUID
    let onDismiss: () -> Void
    let onSnooze: () -> Void
    
    @State private var isAnimating = false
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        ZStack {
            // Tam ekran overlay
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Alarm ikonu
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.red.opacity(0.8),
                                    Color.orange.opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 16) {
                    Text("⏰ UYKU ALARMI")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Uyku bloğunuz sona erdi!\nUyanma zamanı!")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                    
                    Text("Bildirim izni olmadığı için bu uyarı gösteriliyor")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                
                VStack(spacing: 16) {
                    // Ana durdur butonu
                    Button(action: {
                        stopAlarmSound()
                        onDismiss()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "stop.circle.fill")
                                .font(.title2)
                            Text("⏹️ Kapat")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.red,
                                    Color.red.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Erteleme butonu
                    Button(action: {
                        stopAlarmSound()
                        onSnooze()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title3)
                            Text("⏰ Ertele (5dk)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            Color.white.opacity(0.2)
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 24)
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            isAnimating = true
            playAlarmSound()
        }
        .onDisappear {
            stopAlarmSound()
        }
    }
    
    private func playAlarmSound() {
        // Alarm sesi çal
        guard let soundURL = Bundle.main.url(forResource: "Alarm 1", withExtension: "caf") else {
            // Fallback olarak sistem sesi kullan
            AudioServicesPlaySystemSound(1005) // Sistem alarm sesi
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1 // Sonsuz döngü
            audioPlayer?.volume = 0.8
            audioPlayer?.play()
        } catch {
            print("PolyNap Debug: Alarm sesi çalınamadı: \(error)")
            // Fallback sistem sesi
            AudioServicesPlaySystemSound(1005)
        }
    }
    
    private func stopAlarmSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}

#Preview {
    FallbackAlarmAlert(
        blockId: UUID(),
        onDismiss: { print("Alarm durduruldu") },
        onSnooze: { print("Alarm ertelendi") }
    )
} 
 