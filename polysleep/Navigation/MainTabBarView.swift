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
            
            ProfileScreenView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profil")
                }
                .tag(1)
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
