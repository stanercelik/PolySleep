import SwiftUI
import Foundation

// MARK: - Sleep Adjustment Badge Component
struct SleepAdjustmentBadge: View {
    let adjustmentType: SleepAdjustmentType
    let adjustmentMinutes: Int?
    let isCompact: Bool
    
    init(adjustmentType: SleepAdjustmentType, adjustmentMinutes: Int? = nil, isCompact: Bool = false) {
        self.adjustmentType = adjustmentType
        self.adjustmentMinutes = adjustmentMinutes
        self.isCompact = isCompact
    }
    
    // MARK: - Badge Configuration
    private var badgeConfig: BadgeConfiguration {
        switch adjustmentType {
        case .asScheduled:
            return BadgeConfiguration(
                text: isCompact ? "" : "As Scheduled",
                icon: "checkmark.circle.fill",
                color: .green,
                showInCompact: false
            )
        case .differentTime:
            let minutes = adjustmentMinutes ?? 0
            // Only show if there's an actual difference
            if abs(minutes) <= 5 {
                return BadgeConfiguration(
                    text: "",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    showInCompact: false
                )
            } else {
                let sign = minutes >= 0 ? "+" : ""
                return BadgeConfiguration(
                    text: "\(sign)\(minutes)m",
                    icon: minutes >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                    color: minutes >= 0 ? .blue : .orange,
                    showInCompact: true
                )
            }
        case .custom:
            return BadgeConfiguration(
                text: isCompact ? "" : "Custom",
                icon: "slider.horizontal.3",
                color: .purple,
                showInCompact: true
            )
        case .skipped:
            return BadgeConfiguration(
                text: isCompact ? "" : "SKIPPED",
                icon: "xmark.circle.fill",
                color: .red,
                showInCompact: true
            )
        }
    }
    
    var body: some View {
        let config = badgeConfig
        
        if isCompact {
            // Compact view optimized for single-line layout
            if config.showInCompact {
                if adjustmentType == .differentTime && !config.text.isEmpty {
                    // Show time difference in ultra-compact format
                    Text(config.text)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(config.color)
                        )
                        .lineLimit(1)
                        .accessibilityLabel(accessibilityLabel)
                } else if adjustmentType == .skipped {
                    // Show "SKIP" text for skipped entries
                    Text("SKIP")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 2)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(config.color)
                        )
                        .lineLimit(1)
                        .accessibilityLabel(accessibilityLabel)
                } else {
                    // Show small dot for other types
                    Circle()
                        .fill(config.color)
                        .frame(width: 5, height: 5)
                        .accessibilityLabel(accessibilityLabel)
                }
            } else {
                EmptyView()
            }
        } else {
            // Full badge view
            HStack(spacing: PSSpacing.xs) {
                Image(systemName: config.icon)
                    .font(.caption2)
                    .foregroundColor(config.color)
                
                Text(config.text)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(config.color)
            }
            .padding(.horizontal, PSSpacing.xs)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: PSCornerRadius.small)
                    .fill(config.color.opacity(0.1))
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
        }
    }
    
    // MARK: - Accessibility
    private var accessibilityLabel: String {
        switch adjustmentType {
        case .asScheduled:
            return "Slept as scheduled"
        case .differentTime:
            let minutes = adjustmentMinutes ?? 0
            if minutes > 0 {
                return "Slept \(minutes) minutes longer than scheduled"
            } else {
                return "Slept \(abs(minutes)) minutes shorter than scheduled"
            }
        case .custom:
            return "Custom sleep time"
        case .skipped:
            return "Skipped sleep block"
        }
    }
}

// MARK: - Badge Configuration Helper
private struct BadgeConfiguration {
    let text: String
    let icon: String
    let color: Color
    let showInCompact: Bool
}

// MARK: - Skipped Sleep Entry Card
struct SkippedSleepEntryCard: View {
    let originalStartTime: Date
    let originalEndTime: Date
    let blockType: String
    let emoji: String
    
    var body: some View {
        PSCard {
            HStack(spacing: PSSpacing.md) {
                // Emoji and Type
                VStack(spacing: PSSpacing.xs) {
                    Text(emoji)
                        .font(.title2)
                    
                    Text(blockType)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.appTextSecondary)
                }
                
                // Time and Status
                VStack(alignment: .leading, spacing: PSSpacing.xs) {
                    HStack {
                        Text(timeRangeText)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.appText)
                        
                        Spacer()
                        
                        SleepAdjustmentBadge(
                            adjustmentType: .skipped,
                            isCompact: false
                        )
                    }
                    
                    Text("Scheduled duration: \(scheduledDurationText)")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
            }
        }
        .opacity(0.6) // Dimmed to indicate skipped
    }
    
    // MARK: - Computed Properties
    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: originalStartTime)) - \(formatter.string(from: originalEndTime))"
    }
    
    private var scheduledDurationText: String {
        let duration = Int(originalEndTime.timeIntervalSince(originalStartTime) / 60)
        let hours = duration / 60
        let minutes = duration % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - SleepEntry Extension for Adjustment Info
extension SleepEntry {
    var hasAdjustment: Bool {
        adjustmentInfo != nil && adjustmentInfo != .asScheduled
    }
    
    var adjustmentBadge: some View {
        Group {
            if let adjustmentType = adjustmentInfo {
                SleepAdjustmentBadge(
                    adjustmentType: adjustmentType,
                    adjustmentMinutes: adjustmentMinutes,
                    isCompact: false
                )
            } else {
                EmptyView()
            }
        }
    }
    
    var compactAdjustmentIndicator: some View {
        Group {
            if let adjustmentType = adjustmentInfo {
                SleepAdjustmentBadge(
                    adjustmentType: adjustmentType,
                    adjustmentMinutes: adjustmentMinutes,
                    isCompact: true
                )
            } else {
                EmptyView()
            }
        }
    }
    
    // For skipped entries, show original scheduled time
    var displayTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if adjustmentInfo == .skipped,
           let originalStart = originalScheduledStartTime,
           let originalEnd = originalScheduledEndTime {
            return "\(formatter.string(from: originalStart)) - \(formatter.string(from: originalEnd))"
        } else {
            return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
        }
    }
    
    // Whether to show rating (hide for skipped entries)
    var shouldShowRating: Bool {
        adjustmentInfo != .skipped
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: PSSpacing.md) {
        // Different Time Badges
        HStack {
            SleepAdjustmentBadge(adjustmentType: .differentTime, adjustmentMinutes: 15)
            SleepAdjustmentBadge(adjustmentType: .differentTime, adjustmentMinutes: -10)
        }
        
        // Other Badges
        HStack {
            SleepAdjustmentBadge(adjustmentType: .custom)
            SleepAdjustmentBadge(adjustmentType: .skipped)
            SleepAdjustmentBadge(adjustmentType: .asScheduled)
        }
        
        // Compact Indicators
        HStack {
            Text("Compact: ")
            SleepAdjustmentBadge(adjustmentType: .differentTime, adjustmentMinutes: 5, isCompact: true)
            SleepAdjustmentBadge(adjustmentType: .custom, isCompact: true)
            SleepAdjustmentBadge(adjustmentType: .skipped, isCompact: true)
        }
        
        // Skipped Entry Card
        SkippedSleepEntryCard(
            originalStartTime: Date(),
            originalEndTime: Date().addingTimeInterval(7200), // 2 hours later
            blockType: "Core Sleep",
            emoji: "🌙"
        )
    }
    .padding()
}