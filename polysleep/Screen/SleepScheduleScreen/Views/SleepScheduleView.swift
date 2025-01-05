import SwiftUI

struct SleepScheduleView: View {
    @StateObject private var viewModel = SleepScheduleViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) { 
                Text(String(localized: "sleepSchedule.recommendedPattern"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 32)
                
                CircularSleepChart(schedule: viewModel.schedule)
                    .padding(.horizontal, 16)
                    .padding(.top, 64)
                    .frame(maxWidth: .infinity, maxHeight: 400) 
                    

                scheduleInfoCard
                
                /*if !viewModel.schedule.schedule.isEmpty {
                    warningsSection
                    sleepAnalysisSection
                }*/
                
                Spacer(minLength: 16)
            }
        }
        .background(Color("BackgroundColor"))
        .navigationTitle(String(localized: "sleepSchedule.title"))
    }
    
    private var scheduleInfoCard: some View {
        VStack(spacing: 16) {
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("CardBackground"))
                .shadow(radius: 5, x: 0, y: 2)
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
                .foregroundColor(Color("PrimaryTextColor"))
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
