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
                        RecommendedBadge()
                    }
                }
                HStack(spacing: 8) {
                    Text(Locale.current.language.languageCode?.identifier == "tr" ? schedule.description.tr : schedule.description.en)
                        .font(.body)
                        .foregroundColor(Color.appTextSecondary)
                    Spacer()
                }
                ScheduleDetails(schedule: schedule)
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
    
    private var cardBackgroundColor: Color {
        schedule.id == selectedSchedule.id ? Color.appCardBackground : Color.appCardBackground.opacity(0.5)
    }
    
    private var borderColor: Color {
        schedule.id == selectedSchedule.id ? Color.appPrimary : Color.clear
    }
}

struct RecommendedBadge: View {
    var body: some View {
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
}

struct ScheduleDetails: View {
    let schedule: SleepScheduleModel
    var body: some View {
        VStack(spacing: 12) {
            ScheduleInfoRow(
                icon: "bed.double.fill",
                title: NSLocalizedString("sleepSchedule.totalSleep", tableName: "Onboarding", comment: ""),
                value: String(format: "%.1f h", schedule.totalSleepHours)
            )
            ScheduleInfoRow(
                icon: "powersleep",
                title: NSLocalizedString("sleepSchedule.naps",tableName: "Onboarding", comment: ""),
                value: "\(schedule.schedule.filter { !$0.isCore }.count)"
            )
        }
    }
}

struct ScheduleInfoRow: View {
    let icon: String, title: String, value: String
    var body: some View {
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
                .foregroundColor(Color.appTextSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    let schedule = SleepScheduleModel(
        id: "monophasic",
        name: "Monophasic",
        description: LocalizedDescription(
            en: "Traditional single sleep period during the night",
            tr: "Tek parça gece uykusu"
        ),
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
