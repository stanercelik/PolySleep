import SwiftUI

struct SleepScheduleView: View {
    @StateObject private var viewModel = SleepScheduleViewModel()
    
    var body: some View {
        ScrollView() {
            VStack(spacing: 24) {
                
                VStack(alignment: .leading){
                    HStack(){
                        Text(String(localized: "sleepSchedule.recommendedPattern"))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color("TextColor"))
                            .accessibility(addTraits: .isHeader)
                        
                        Spacer()
                    }
                    
                    Text(viewModel.schedule.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color("PrimaryColor"))
                        .accessibility(addTraits: .isHeader)
                }
                .padding(.horizontal)
                .padding(.bottom, 42)
                .padding(.top, 24)
                    
                        CircularSleepChart(schedule: viewModel.schedule)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                
                                .fill(Color("CardBackground").opacity(0.8))
                                .frame(height: UIScreen.main.bounds.height * 0.4)
                                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 0)
                        )

                        
                        .padding(.horizontal)
                        .padding(.bottom, 46)

                        scheduleDescription
                            .padding(.horizontal)
                            

                        scheduleTimeRanges
                            .padding(.horizontal)
                            
                        
                        scheduleInfoCard

                        Spacer(minLength: 24)
                    }
            .frame(maxWidth: UIScreen.main.bounds.width, alignment: .center)
                }
        
                .scrollIndicators(.hidden)
                .background(Color("BackgroundColor"))
    }
    
    private var scheduleInfoCard: some View {
        VStack(spacing: 20) {
            InfoRow(
                title: String(localized: "sleepSchedule.totalSleep"),
                value: String(format: "%.1f", viewModel.schedule.totalSleepHours),
                icon: "bed.double.fill"
            )
            InfoRow(
                title: String(localized: "sleepSchedule.naps"),
                value: "\(viewModel.schedule.schedule.filter { $0.type != "core" }.count)",
                icon: "powersleep"
            )
            InfoRow(
                title: String(localized: "sleepSchedule.scheduleType"),
                value: viewModel.schedule.name,
                icon: "clock.fill"
            )
            InfoRow(
                title: String(localized: "sleepSchedule.adaptation"),
                value: String(format: String(localized: "sleepSchedule.adaptationDays"), viewModel.adaptationPeriod),
                icon: "calendar"
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground").opacity(0.8))
                .shadow(color: Color.black.opacity(0.1), radius: 20)
        )
        .padding(.horizontal)
    }
    
    private var sleepAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "sleepSchedule.sleepAnalysis"))
                .font(.headline)
                .padding(.horizontal)
            
            if let analysis = viewModel.sleepAnalysis {
                Text(analysis)
                    .font(.body)
                    .foregroundColor(Color("SecondaryTextColor"))
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var warningsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.warnings, id: \.messageKey) { warning in
                WarningRow(warning: warning)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var scheduleTimeRanges: some View {
        VStack(alignment: .center, spacing: 16) {
            Text(String(localized: "sleepSchedule.timeRanges"))
                .font(.headline)
                .foregroundColor(Color("TextColor"))
                .accessibility(addTraits: .isHeader)
                .padding(.top, 12)
            
            VStack(alignment: .center, spacing: 16) {
                ForEach(viewModel.schedule.schedule.indices, id: \.self) { index in
                    let block = viewModel.schedule.schedule[index]
                    SleepBlockRow(block: block)
                        
                }
            }
            .padding(.bottom)
            
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("CardBackground"))
                .shadow(color: Color.black.opacity(0.1), radius: 20)
        )
    }
    
    private var scheduleDescription: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.schedule.name + ":")
                .font(.headline)
                .foregroundColor(Color("TextColor"))
                .accessibility(addTraits: .isHeader)
            
            Text(viewModel.schedule.description.localized())
                .font(.body)
                .foregroundColor(Color("SecondaryTextColor"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground").opacity(0.8))
                .shadow(color: Color.black.opacity(0.1), radius: 20)
        )
    }
    
    private struct SleepBlockRow: View {
        let block: SleepScheduleModel.SleepBlock
        
        var body: some View {
            HStack() {
                Spacer()
                // Time range
                HStack() {
                    Text(block.startTime)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Text("-")
                    Text(block.endTime)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }
                .foregroundColor(Color("TextColor"))
                
                Spacer()
                
                // Duration with icon
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                    Text(block.formattedDuration)
                        .fontWeight(.medium)
                }
                .foregroundColor(Color("SecondaryTextColor"))
                
                Spacer()
                
                // Block type with icon
                HStack(spacing: 4) {
                    Image(systemName: block.isCore ? "bed.double.fill" : "powersleep")
                        .font(.caption)
                    Text(block.isCore ? 
                         String(localized: "sleepBlock.core") : 
                         String(localized: "sleepBlock.nap"))
                        .fontWeight(.regular)
                }
                .foregroundColor(block.isCore ? Color("PrimaryColor") : Color("SecondaryColor"))
                
                Spacer()
            }
            .font(.body)
            
        }
    }
    
    private struct WarningRow: View {
        let warning: SleepScheduleRecommendation.Warning
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                warningIcon
                warningText
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("CardBackground"))
                    .shadow(radius: 2)
            )
            .padding(.horizontal)
        }
        
        private var warningIcon: some View {
            let iconName: String
            let iconColor: Color
            
            switch warning.severity {
            case .critical:
                iconName = "exclamationmark.triangle.fill"
                iconColor = .red
            case .warning:
                iconName = "exclamationmark.circle.fill"
                iconColor = .orange
            case .info:
                iconName = "info.circle.fill"
                iconColor = .blue
            }
            
            return Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.title3)
        }
        
        private var warningText: some View {
            Text(LocalizedStringKey(warning.messageKey))
                .font(.subheadline)
                .foregroundColor(Color("TextColor"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color("AccentColor"))
                .frame(width: 30, height: 30)
            
            Text(title)
                .foregroundColor(Color("SecondaryTextColor"))
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
    }
}

struct SleepScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SleepScheduleView()
        }
    }
}
