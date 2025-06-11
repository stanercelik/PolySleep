import SwiftUI

// MARK: - Adaptation Debug Card
struct AdaptationDebugCard: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    @State private var debugDay: Int = 1
    @State private var showResetAlert: Bool = false
    
    private var currentDay: Int {
        viewModel.completedAdaptationDays
    }
    
    private var totalDays: Int {
        viewModel.adaptationDuration
    }
    
    private var adaptationStartDate: String {
        if let startDate = viewModel.activeSchedule?.updatedAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: startDate)
        }
        return "N/A"
    }
    
    var body: some View {
        VStack(spacing: PSSpacing.lg) {
            // Header
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text(L("profile.adaptation.debug.title", table: "Profile"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
                
                Spacer()
                
                Button(action: {
                    showResetAlert = true
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            // Debug Description
            Text(L("profile.adaptation.debug.description", table: "Profile"))
                .font(.caption)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.leading)
            
            // Current State Info
            VStack(spacing: PSSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("profile.adaptation.debug.currentDay", table: "Profile"))
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                        
                        Text("\(currentDay)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.appPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(L("profile.adaptation.debug.totalDays", table: "Profile"))
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                        
                        Text("\(totalDays)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.appPrimary)
                    }
                }
                
                // Start Date
                HStack {
                    Text(L("profile.adaptation.debug.startDate", table: "Profile"))
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                    
                    Spacer()
                    
                    Text(adaptationStartDate)
                        .font(.caption)
                        .foregroundColor(.appText)
                }
            }
            .padding(PSSpacing.md)
            .background(Color.appTextSecondary.opacity(0.05))
            .cornerRadius(PSCornerRadius.medium)
            
            // Debug Controls
            VStack(spacing: PSSpacing.md) {
                HStack {
                    Text(L("profile.adaptation.debug.setDay", table: "Profile"))
                        .font(.subheadline)
                        .foregroundColor(.appText)
                    
                    Spacer()
                    
                    Stepper(
                        value: $debugDay,
                        in: 1...max(totalDays, 28),
                        step: 1
                    ) {
                        Text("\(debugDay)")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.orange)
                            .frame(minWidth: 40)
                    }
                    .accentColor(.orange)
                }
                
                Button(action: {
                    applyDebugDay()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        
                        Text(L("profile.adaptation.debug.apply", table: "Profile"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, PSSpacing.lg)
                    .padding(.vertical, PSSpacing.md)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange.opacity(0.8), .orange]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(PSCornerRadius.medium)
                }
                .disabled(debugDay == currentDay)
                
                // Reset Button
                Button(action: {
                    showResetAlert = true
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title3)
                        
                        Text(L("profile.adaptation.debug.reset", table: "Profile"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, PSSpacing.lg)
                    .padding(.vertical, PSSpacing.md)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(PSCornerRadius.medium)
                }
            }
        }
        .padding(PSSpacing.lg)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.orange.opacity(0.05),
                    Color.orange.opacity(0.02)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(PSCornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: PSCornerRadius.large)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .appBorder.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            debugDay = currentDay
        }
        .alert(
            L("profile.adaptation.debug.resetAlert.title", table: "Profile"),
            isPresented: $showResetAlert
        ) {
            Button(L("general.cancel", table: "Profile"), role: .cancel) {
                showResetAlert = false
            }
            Button(L("profile.adaptation.debug.resetAlert.confirm", table: "Profile"), role: .destructive) {
                resetAdaptation()
            }
        } message: {
            Text(L("profile.adaptation.debug.resetAlert.message", table: "Profile"))
        }
    }
    
    private func applyDebugDay() {
        // Debug day functionality
        if debugDay != currentDay {
            Task {
                do {
                    try await viewModel.setAdaptationDebugDay(debugDay)
                } catch {
                    print("Debug day set error: \(error)")
                }
            }
        }
    }
    
    private func resetAdaptation() {
        Task {
            do {
                try await viewModel.resetAdaptationPhase()
                debugDay = 1
            } catch {
                print("Reset adaptation error: \(error)")
            }
        }
    }
} 