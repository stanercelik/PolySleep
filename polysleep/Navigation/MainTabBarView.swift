import SwiftUI
import SwiftData

struct MainTabBarView: View {
    @State private var selectedTab = 0
    @StateObject private var mainScreenViewModel = MainScreenViewModel()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MainScreenView(viewModel: mainScreenViewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("tabbar.schedule", tableName: "Common")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("tabbar.history", tableName: "Common")
                }
                .tag(1)
            
            AnalyticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("tabbar.analytics", tableName: "Common")
                }
                .tag(2)
            
            ProfileScreenView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("tabbar.profile", tableName: "Common")
                }
                .tag(3)
        }
        .accentColor(Color("AccentColor"))
        .onAppear {
            mainScreenViewModel.setModelContext(modelContext)
        }
    }
}

struct MainTabBarView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabBarView()
            .modelContainer(for: SleepScheduleStore.self)
    }
}
