import SwiftUI

struct SleepScheduleDescriptionCard: View {
    let schedule: SleepScheduleModel
    let isRecommended: Bool
    @Binding var selectedSchedule: SleepScheduleModel
    
    var body: some View {
        Button(action: {
            withAnimation {
                selectedSchedule = schedule
            }
        }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(schedule.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.appText)
                    
                    Spacer()
                    
                    if isRecommended {
                        recommendedBadge
                    }
                }
                
                Text(schedule.description.localized())
                    .font(.body)
                    .foregroundColor(Color.appSecondaryText)
                
                scheduleDetails
                
                if schedule.id == selectedSchedule.id {
                    selectedIndicator
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: schedule.id == selectedSchedule.id ? 2 : 0)
            )
        }
    }
    
    private var recommendedBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption)
            Text("Recommended")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.appPrimary)
        )
    }
    
    private var scheduleDetails: some View {
        VStack(spacing: 12) {
            scheduleInfoRow(
                icon: "bed.double.fill",
                title: "Total Sleep",
                value: String(format: "%.1f hours", schedule.totalSleepHours)
            )
            
            scheduleInfoRow(
                icon: "powersleep",
                title: "Naps",
                value: "\(schedule.schedule.filter { !$0.isCore }.count)"
            )
        }
    }
    
    private var selectedIndicator: some View {
        HStack {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color.appPrimary)
                .font(.title3)
        }
    }
    
    private func scheduleInfoRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color.appPrimary)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color.appSecondaryText)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(Color.appText)
        }
    }
    
    private var cardBackgroundColor: Color {
        schedule.id == selectedSchedule.id ? Color.appCardBackground : Color.appCardBackground.opacity(0.5)
    }
    
    private var borderColor: Color {
        schedule.id == selectedSchedule.id ? Color.appPrimary : Color.clear
    }
}

#Preview {
    let schedule = SleepScheduleModel(
        id: "monophasic",
        name: "Monophasic",
        description: LocalizedDescription(en: "Traditional single sleep period during the night", tr: "Geleneksel tek parça gece uykusu"),
        totalSleepHours: 8.0,
        schedule: [
            SleepBlock(
                startTime: "23:00",
                duration: 480,
                type: "core",
                isCore: true
            )
        ]
    )
    
    SleepScheduleDescriptionCard(
        schedule: schedule,
        isRecommended: true,
        selectedSchedule: .constant(schedule)
    )
}
