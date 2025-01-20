import SwiftUI
import SwiftData

struct SleepScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = SleepScheduleViewModel()
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    CircularSleepChart(schedule: viewModel.schedule)
                        .frame(height: UIScreen.main.bounds.height * 0.4)
                        .padding(.horizontal)
                    
                    if let recommendedSchedule = viewModel.recommendedSchedule {
                        SleepScheduleDescriptionCard(
                            schedule: recommendedSchedule,
                            isRecommended: true,
                            selectedSchedule: $viewModel.schedule
                        )
                        .padding(.horizontal)
                    }
                    
                    scheduleTimeRanges
                        .padding(.horizontal)
                    
                    Spacer(minLength: 24)
                }
                .padding()
            }
        }
        .onAppear {
            print("\nSleepScheduleView appeared, updating recommendations...")
            viewModel.setModelContext(modelContext)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(String(localized: "sleepSchedule.recommendedPattern"))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.appText)
                    .accessibility(addTraits: .isHeader)
                    .lineLimit(1)
                Spacer()
                shareButton
            }
            
            Text(viewModel.schedule.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.appPrimary)
                .accessibility(addTraits: .isHeader)
        }
        .padding(.horizontal)
    }
    
    private var scheduleTimeRanges: some View {
        VStack(alignment: .center, spacing: 16) {
            Text(String(localized: "sleepSchedule.timeRanges"))
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
            return SleepScheduleView()
                .modelContainer(container)
        } catch {
            return Text("Preview Error: \(error.localizedDescription)")
        }
    }
}
