import SwiftUI

struct SleepScheduleDescriptionCard: View {
    let schedule: SleepScheduleModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(schedule.name)
                .font(.title2)
                .bold()
                .foregroundColor(Color("TextColor"))
                .accessibilityAddTraits(.isHeader)
            
            Text(schedule.description.localized())
                .font(.body)
                .foregroundColor(Color("SecondaryTextColor"))
            
            scheduleSection
            
            totalSleepSection
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("BackgroundColor"))
                .shadow(radius: 5)
        )
        .padding(.horizontal)
    }
    
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(schedule.schedule, id: \.startTime) { block in
                HStack(spacing: 12) {
                    Image(systemName: block.isCore ? "moon.fill" : "sun.min.fill")
                        .foregroundColor(Color("PrimaryColor"))
                    
                    VStack(alignment: .leading) {
                        Text(block.isCore ? 
                            NSLocalizedString("sleepSchedule.core", comment: "") :
                            NSLocalizedString("sleepSchedule.nap", comment: ""))
                            .font(.subheadline)
                            .foregroundColor(Color("TextColor"))
                        
                        Text("\(block.startTime) (\(block.formattedDuration))")
                            .font(.caption)
                            .foregroundColor(Color("SecondaryTextColor"))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("SecondaryColor").opacity(0.5))
        )
    }
    
    private var totalSleepSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "bed.double.fill")
                .foregroundColor(Color("AccentColor"))
            
            Text(String(format: NSLocalizedString("sleepSchedule.totalSleep", comment: ""),
                       String(format: "%.1f", schedule.totalSleepHours)))
                .font(.subheadline)
                .foregroundColor(Color("TextColor"))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("SecondaryColor").opacity(0.5))
        )
    }
}

#Preview {
    // Sample data for preview
    let sampleSchedule = SleepScheduleModel(
        id: "biphasic",
        name: "Biphasic Sleep",
        description: .init(
            en: "A sleep pattern with one core sleep period and one nap",
            tr: "Bir ana uyku ve bir şekerleme içeren uyku düzeni"
        ),
        totalSleepHours: 6.5,
        schedule: [
            .init(type: "core", startTime: "23:00", duration: 360),
            .init(type: "nap", startTime: "14:00", duration: 30)
        ]
    )
    
    return SleepScheduleDescriptionCard(schedule: sampleSchedule)
        .preferredColorScheme(.light)
}
