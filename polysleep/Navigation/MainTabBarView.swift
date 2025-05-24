import SwiftUI
import SwiftData

struct MainTabBarView: View {
    @State private var selectedTab = 0
    @StateObject private var mainScreenViewModel: MainScreenViewModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    
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
        .onAppear {
            mainScreenViewModel.setModelContext(modelContext)
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
