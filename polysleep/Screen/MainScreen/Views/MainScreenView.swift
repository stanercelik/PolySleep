import SwiftUI
import SwiftData

struct MainScreenView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = MainScreenViewModel()
    @State private var scrollOffset: CGFloat = 0

    private let headerHeight: CGFloat = 80
    private let chartHeight: CGFloat = UIScreen.main.bounds.height * 0.4

    /// Scroll ilerlemesine göre (0...1) ilerleme değeri
    /// (Scroll offset değeri yeterince yüksek olduğunda progress 1’e yaklaşır.)
    private var progress: CGFloat {
        let maxOffset: CGFloat = headerHeight + chartHeight
        // progress değeri 0 (hiç scroll yok) ile 1 (tam scroll) arasında hesaplanır.
        return min(max(-scrollOffset / maxOffset, 0), 1)
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.appBackground
                    .ignoresSafeArea()
                
                TrackableScrollView(offset: $scrollOffset) {
                    VStack(spacing: 32) {
                        // Chart ve açıklama bölümü (diğer öğeler sabit kalıyor)
                        VStack(spacing: 16) {
                            HStack {
                                // Chart’ın boyutunu scaleEffect ile %30 küçültüyoruz:
                                CircularSleepChart(
                                    schedule: viewModel.model.schedule.toSleepScheduleModel,
                                    textOpacity: 1 - progress
                                )
                                
                                .scaleEffect(1 - 0.3 * progress)
                                .animation(.easeInOut(duration: 0.3), value: progress)
                            }
                            .frame(alignment: .center)
                            .padding(.horizontal)
                            .padding(.top, 50)
                        }
                        
                        // Yeterince scroll yapılabilmesi için ek içerik (örneğin, zaman blokları)
                        TimeBlocksSection(viewModel: viewModel)
                            .padding(.horizontal)
                        TimeBlocksSection(viewModel: viewModel)
                            .padding(.horizontal)
                        TimeBlocksSection(viewModel: viewModel)
                            .padding(.horizontal)
                    }
                }
            }
            .navigationTitle(viewModel.model.schedule.name)
            .navigationBarTitleDisplayMode(.automatic)
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }
}

// MARK: - Alt View’lar (MainScreenView içinde kullanılan yardımcı view’lar)

struct TimeBlocksSection: View {
    let viewModel: MainScreenViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text(String(localized: "sleepSchedule.timeRanges"))
                .font(.headline)
                .foregroundColor(Color.appText)
            ForEach(viewModel.model.schedule.schedule) { block in
                HStack {
                    Text("\(block.startTime) - \(block.endTime)")
                        .font(.body)
                        .foregroundColor(Color.appText)
                    Spacer()
                    let hours = block.duration / 60
                    let minutes = block.duration % 60
                    Text(hours > 0 ? (minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h") : "\(minutes)m")
                        .font(.body)
                        .foregroundColor(Color.appSecondaryText)
                    Text("・")
                        .foregroundColor(Color.appSecondaryText)
                    Text(block.isCore ? String(localized: "sleepSchedule.core") : String(localized: "sleepSchedule.nap"))
                        .font(.body)
                        .foregroundColor(block.isCore ? Color.appPrimary : Color.appSecondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appCardBackground)
                )
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration()
    let container = try! ModelContainer(for: SleepScheduleStore.self, configurations: config)
    
    MainScreenView()
        .modelContainer(container)
}
