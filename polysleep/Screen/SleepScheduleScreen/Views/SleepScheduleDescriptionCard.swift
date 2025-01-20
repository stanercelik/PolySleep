import SwiftUI
import SwiftData

struct SleepScheduleDescriptionCard: View {
    let schedule: SleepScheduleModel
    let isRecommended: Bool
    @Binding var selectedSchedule: SleepScheduleModel
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Button(action: {
            withAnimation {
                selectedSchedule = schedule
                let store = SleepScheduleStore(scheduleId: schedule.id)
                modelContext.insert(store)
                do {
                    try modelContext.save()
                } catch {
                    print("Error saving schedule: \(error)")
                }
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
                
                
                    HStack(spacing: 8) {
                        Text(Locale.current.language.languageCode?.identifier == "tr" ? schedule.description.tr : schedule.description.en
                        )
                            .font(.body)
                            .foregroundColor(Color.appSecondaryText)
                        
                        Spacer()
                }
                
                
                scheduleDetails
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
            Text(String(localized: "Recommended"))
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
                title: String(localized: "sleepSchedule.totalSleep"),
                value: String(format: "%.1f h", schedule.totalSleepHours)
            )
            
            scheduleInfoRow(
                icon: "powersleep",
                title: String(localized: "sleepSchedule.naps"),
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
                .foregroundColor(Color.appAccent)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color.appText)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(Color.appSecondaryText)
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
        description: LocalizedDescription(en: "Traditional single sleep period during the night", tr: "Geleaslkdlaksjdlkasjdkasjlkdajsşdad adk sa oda op dkapodk opak dapod o aod a a janeksel tek parça gece uykusu"),
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
