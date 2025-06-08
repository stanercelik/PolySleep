import SwiftUI
import SwiftData

struct AlarmFiringView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @Environment(\.modelContext) private var modelContext
    @Query private var alarmSettings: [AlarmSettings]
    
    @State private var isAnimating = false
    @State private var pulseAnimation = false
    @State private var timeString = ""
    @State private var timer: Timer?
    
    private var snoozeDuration: Int {
        alarmSettings.first?.snoozeDurationMinutes ?? 5
    }
    
    var body: some View {
        ZStack {
            backgroundView
            contentView
        }
        .onAppear {
            setupView()
        }
        .onDisappear {
            cleanupView()
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            backgroundGradient
            animatedCircles
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.appPrimary.opacity(0.8),
                Color.appPrimary.opacity(0.4),
                Color.appBackground
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    private var animatedCircles: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 300, height: 300)
                .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                .animation(
                    Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: pulseAnimation
                )
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 200, height: 200)
                .scaleEffect(pulseAnimation ? 0.8 : 1.2)
                .animation(
                    Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: pulseAnimation
                )
                .offset(x: 120, y: 100)
        }
    }
    
    // MARK: - Content View
    private var contentView: some View {
        VStack(spacing: 0) {
            Spacer()
            alarmCard
            Spacer()
            actionButtons
        }
    }
    
    private var alarmCard: some View {
        VStack(spacing: PSSpacing.xl) {
            animatedAlarmIcon
            titleSection
            timeDisplayCard
        }
        .padding(PSSpacing.xxl)
        .background(alarmCardBackground)
        .padding(.horizontal, PSSpacing.lg)
    }
    
    private var alarmCardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.black.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    private var animatedAlarmIcon: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 120, height: 120)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
            
            Image(systemName: "alarm.fill")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(isAnimating ? 5 : -5))
        }
        .animation(
            Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
            value: isAnimating
        )
    }
    
    private var titleSection: some View {
        VStack(spacing: PSSpacing.sm) {
            Text("🚨 UYANMA ALARMI!")
                .font(PSTypography.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            Text("Uyanma zamanınız geldi!")
                .font(PSTypography.title3)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
        }
    }
    
    private var timeDisplayCard: some View {
        VStack(spacing: PSSpacing.xs) {
            Text("Şu An")
                .font(PSTypography.caption)
                .foregroundColor(.white.opacity(0.7))
                .textCase(.uppercase)
                .tracking(1)
            
            Text(timeString)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .padding(PSSpacing.lg)
        .background(timeCardBackground)
    }
    
    private var timeCardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.black.opacity(0.4))
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: PSSpacing.md) {
            snoozeButton
            stopButton
            hintText
        }
        .padding(.horizontal, PSSpacing.lg)
        .padding(.bottom, PSSpacing.xl)
    }
    
    private var snoozeButton: some View {
        Button(action: {
            Task {
                await alarmManager.snoozeAlarm()
            }
        }) {
            HStack(spacing: PSSpacing.sm) {
                Image(systemName: "clock.badge.plus")
                    .font(.system(size: 20, weight: .semibold))
                
                Text("\(snoozeDuration) Dakika Ertele")
                    .font(PSTypography.body)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, PSSpacing.md)
            .background(snoozeButtonBackground)
        }
        .buttonStyle(BouncyButtonStyle())
    }
    
    private var snoozeButtonBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.orange.opacity(0.8),
                        Color.orange.opacity(0.6)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private var stopButton: some View {
        Button(action: {
            alarmManager.stopAlarm()
        }) {
            HStack(spacing: PSSpacing.sm) {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                
                Text("Alarmı Kapat")
                    .font(PSTypography.body)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, PSSpacing.md)
            .background(stopButtonBackground)
        }
        .buttonStyle(BouncyButtonStyle())
    }
    
    private var stopButtonBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.red.opacity(0.8),
                        Color.red.opacity(0.6)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private var hintText: some View {
        Text("Alarmı kapatmak için yukarıdaki butona dokunun")
            .font(PSTypography.caption)
            .foregroundColor(.white.opacity(0.6))
            .multilineTextAlignment(.center)
            .padding(.top, PSSpacing.xs)
    }
    
    // MARK: - Setup Methods
    private func setupView() {
        print("🔧 AlarmFiringView: Setup başlatıldı")
        alarmManager.setModelContext(modelContext)
        isAnimating = true
        pulseAnimation = true
        updateTime()
        
        // AlarmFiringView açıldığında ses çalmaya başla
        if !alarmManager.isAlarmFiring {
            print("🎵 AlarmFiringView: AlarmManager firing=false, manuel başlatılıyor")
            // Manuel olarak alarmı başlat
            let soundName = alarmSettings.first?.soundName ?? "alarm.caf"
            NotificationCenter.default.post(
                name: .startAlarm,
                object: nil,
                userInfo: ["soundName": soundName]
            )
        } else {
            print("🎵 AlarmFiringView: AlarmManager zaten firing=true durumda")
        }
        
        // Timer başlat
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateTime()
        }
        print("⏰ AlarmFiringView: Zaman güncelleme timer'ı başlatıldı")
    }
    
    private func cleanupView() {
        print("🧹 AlarmFiringView: Cleanup başlatıldı")
        timer?.invalidate()
        timer = nil
        print("⏰ AlarmFiringView: Timer durduruldu")
    }
    
    private func updateTime() {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        timeString = formatter.string(from: Date())
    }
}

// MARK: - Supporting Views and Styles
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func backdrop(effect: UIBlurEffect.Style) -> some View {
        self.background(BackdropView(effect: effect))
    }
}

struct BackdropView: UIViewRepresentable {
    let effect: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: effect))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct AlarmFiringView_Previews: PreviewProvider {
    static var previews: some View {
        AlarmFiringView()
            .environmentObject(AlarmManager())
            .modelContainer(for: [AlarmSettings.self])
    }
} 
