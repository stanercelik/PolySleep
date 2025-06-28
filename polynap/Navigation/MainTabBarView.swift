import SwiftUI
import SwiftData

struct MainTabBarView: View {
    @State private var selectedTab = 0
    @StateObject private var mainScreenViewModel: MainScreenViewModel
    @StateObject private var paywallManager = PaywallManager.shared
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var alarmManager: AlarmManager
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    
    @State private var hasCheckedOnboardingPaywall = false
    
    init() {
        self._mainScreenViewModel = StateObject(wrappedValue: MainScreenViewModel(languageManager: LanguageManager.shared))
    }
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
                
            TabView(selection: $selectedTab) {
                MainScreenView(viewModel: mainScreenViewModel)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text(L("tabbar.schedule", table: "Common"))
                    }
                    .tag(0)
                
                HistoryView()
                    .tabItem {
                        Image(systemName: "clock.fill")
                        Text(L("tabbar.history", table: "Common"))
                    }
                    .tag(1)
                
                AnalyticsView()
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text(L("tabbar.analytics", table: "Common"))
                    }
                    .tag(2)
                
                ProfileScreenView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text(L("tabbar.profile", table: "Common"))
                    }
                    .tag(3)
            }
            .accentColor(Color("AccentColor"))
        }
        .managePaywalls() // PaywallManager ile otomatik paywall yönetimi
        .onAppear {
            mainScreenViewModel.setModelContext(modelContext)
            checkAndTriggerOnboardingPaywall()
        }
        .onChange(of: revenueCatManager.userState) { _, _ in
            // User state değiştiğinde tekrar kontrol et
            if !hasCheckedOnboardingPaywall {
                checkAndTriggerOnboardingPaywall()
            }
        }
    }
    
    private func checkAndTriggerOnboardingPaywall() {
        // UserDefaults'ta onboarding paywall'ının tetiklenip tetiklenmediğini kontrol et
        let hasTriggeredOnboardingPaywall = UserDefaults.standard.bool(forKey: "has_triggered_onboarding_paywall")
        
        // Eğer daha önce tetiklendiyse, tekrar tetikleme
        guard !hasTriggeredOnboardingPaywall else {
            print("📱 MainTabBarView: Onboarding paywall daha önce tetiklendi, tekrar tetiklenmiyor")
            hasCheckedOnboardingPaywall = true
            return
        }
        
        // Sadece bir kez kontrol et (memory flag)
        guard !hasCheckedOnboardingPaywall else { 
            print("�� MainTabBarView: Bu session'da zaten kontrol edildi")
            return 
        }
        
        // UserPreferences'ı kontrol et
        let fetchDescriptor = FetchDescriptor<UserPreferences>()
        do {
            let userPreferences = try modelContext.fetch(fetchDescriptor)
            
            // Onboarding tamamlandıysa ve kullanıcı premium değilse paywall tetikle
            if let preferences = userPreferences.first,
               preferences.hasCompletedOnboarding,
               revenueCatManager.userState != .premium {
                
                print("📱 MainTabBarView: Onboarding tamamlandı, premium değil - paywall tetikleniyor")
                
                // UserDefaults'ta flag'i işaretle (kalıcı)
                UserDefaults.standard.set(true, forKey: "has_triggered_onboarding_paywall")
                
                // Kısa bir delay ile paywall tetikle (UI'nin yerleşmesini bekle)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    paywallManager.presentPaywall(trigger: .onboardingComplete)
                }
            } else {
                print("📱 MainTabBarView: Onboarding tamamlanmamış veya kullanıcı premium")
            }
            
            hasCheckedOnboardingPaywall = true
            
        } catch {
            print("❌ MainTabBarView: UserPreferences kontrol edilirken hata: \(error)")
            hasCheckedOnboardingPaywall = true
        }
    }
}

struct MainTabBarView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabBarView()
            .modelContainer(for: SleepScheduleStore.self)
            .environmentObject(LanguageManager.shared)
    }
}
