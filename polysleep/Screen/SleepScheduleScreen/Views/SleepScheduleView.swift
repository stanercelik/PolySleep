import SwiftUI
import SwiftData

struct SleepScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = SleepScheduleViewModel()
    @Query private var userPreferences: [UserPreferences]
    @State private var navigateToMainScreen = false
    @State private var scrollOffset: CGFloat = 0
    @State private var animatedProgress: CGFloat = 0
    
    private let headerHeight: CGFloat = 80
    private let chartHeight: CGFloat = UIScreen.main.bounds.height * 0.4

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                TrackableScrollView(offset: $scrollOffset) {
                    VStack(spacing: 24) {
                        headerSection
                            .opacity(1 - animatedProgress)
                            .animation(.easeInOut(duration: 0.3), value: animatedProgress)
                        
                        CircularSleepChart(
                            schedule: viewModel.schedule, textOpacity: 1 - animatedProgress
                        )
                        .frame(
                            width: animatedProgress > 0.3 ? 120 : UIScreen.main.bounds.width * 0.8,
                            height: animatedProgress > 0.3 ? 120 : chartHeight
                        )
                        .padding(.leading, 34)
                        
                        if let recommendedSchedule = viewModel.recommendedSchedule {
                            if animatedProgress < 0.3 {
                                SleepScheduleDescriptionCard(
                                    schedule: recommendedSchedule,
                                    isRecommended: true,
                                    selectedSchedule: .constant(recommendedSchedule)
                                )
                                .padding(.horizontal)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.3), value: animatedProgress)
                            }
                        }
                        
                        scheduleTimeRanges
                            .padding(.horizontal)
                        
                        NavigationLink(destination: MainTabBarView(), isActive: $navigateToMainScreen) {
                            EmptyView()
                        }
                        
                        Button(action: {
                            if let preferences = userPreferences.first {
                                preferences.hasCompletedOnboarding = true
                                navigateToMainScreen = true
                            }
                        }) {
                            Text("onboarding.startUsingApp", tableName: "Onboarding")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.accentColor)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        Spacer(minLength: 24)
                    }
                    .padding()
                }
                .coordinateSpace(name: "scrollView")
            }
            .navigationTitle(viewModel.schedule.name)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
            .onChange(of: scrollOffset) { oldValue, newValue in
                let newProgress = min(max(-newValue / (headerHeight + chartHeight), 0), 1)
                withAnimation(.easeInOut(duration: 0.2)) {
                    animatedProgress = newProgress
                }
            }
            .onChange(of: viewModel.recommendedSchedule) { oldValue, newValue in
                if let schedule = newValue {
                    // Save the recommended schedule to the store
                    let store = SleepScheduleStore(
                        scheduleId: schedule.id,
                        name: schedule.name,
                        scheduleDescription: schedule.description,
                        totalSleepHours: schedule.totalSleepHours,
                        schedule: schedule.schedule
                    )
                    modelContext.insert(store)
                    try? modelContext.save()
                }
            }
        }
    }
    
    private var headerSection: some View {
            HStack {
                Text(viewModel.schedule.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.appPrimary)
                    .accessibility(addTraits: .isHeader)
                Spacer()
                shareButton
            }
            .padding(.horizontal, 8)

    }
    
    private var scheduleTimeRanges: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("sleepSchedule.timeRanges", tableName: "Onboarding")
                .font(.headline)
                .foregroundColor(Color.appText)
            
            ForEach(viewModel.schedule.schedule) { block in
                HStack {
                    Text("\(block.startTime) - \(block.endTime)")
                        .font(.body)
                        .foregroundColor(Color.appText)
                    
                    Spacer()
                    
                    let hours = block.duration / 60
                    let minutes = block.duration % 60
                    Text(hours > 0
                         ? minutes > 0
                           ? "\(hours)h \(minutes)m"
                           : "\(hours)h"
                         : "\(minutes)m"
                    )
                    .font(.body)
                    .foregroundColor(Color.appSecondaryText)
                    
                    Text("・")
                        .foregroundColor(Color.appSecondaryText)
                    
                    Text(block.isCore ? NSLocalizedString("sleepSchedule.core", tableName: "Onboarding", comment: "") : NSLocalizedString("sleepSchedule.nap", tableName: "Onboarding", comment: ""))
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
    
    private var shareButton: some View {
        Button(action: {
            viewModel.shareSchedule()
        }) {
            Image(systemName: "square.and.arrow.up")
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.appPrimary)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.1), radius: 10)
        }
    }
}

struct SleepScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        // SwiftData Preview
        do {
            let schema = Schema([UserFactor.self])
            let config = ModelConfiguration(schema: schema)
            let container = try ModelContainer(for: schema, configurations: [config])
            return AnyView(
                SleepScheduleView()
                    .modelContainer(container)
            )
        } catch {
            return AnyView(
                Text("Preview Error: \(error.localizedDescription)")
            )
        }
    }
}
