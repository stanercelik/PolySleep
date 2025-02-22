import SwiftUI

struct MainTabBarView: View {
    @State private var selectedTab = 0
    @StateObject private var mainScreenViewModel = MainScreenViewModel()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MainScreenView(viewModel: mainScreenViewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Ana Sayfa")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("Geçmiş")
                }
                .tag(1)
            
            ProfileScreenView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profil")
                }
                .tag(2)
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
