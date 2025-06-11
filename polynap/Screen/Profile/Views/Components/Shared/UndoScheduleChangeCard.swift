import SwiftUI

// MARK: - Schedule Change Undo Banner
struct UndoScheduleChangeCard: View {
    @ObservedObject var viewModel: ProfileScreenViewModel
    @State private var isUndoing = false
    @State private var undoError: String? = nil
    
    // Computed properties for alert binding
    private var isShowingUndoError: Binding<Bool> {
        Binding(
            get: { undoError != nil },
            set: { if !$0 { undoError = nil } }
        )
    }
    
    private var undoErrorMessage: String {
        undoError ?? L("general.unknownError", table: "Profile")
    }
    
    // Extracted background view to fix compiler error
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: PSCornerRadius.large)
            .fill(Color.orange.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: PSCornerRadius.large)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
    }

    var body: some View {
        PSCard {
            VStack(spacing: PSSpacing.md) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: PSIconSize.medium))
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: PSSpacing.xs) {
                        Text(L("profile.scheduleChange.undo.title", table: "Profile"))
                            .font(PSTypography.headline)
                            .foregroundColor(.appText)
                        
                        Text(L("profile.scheduleChange.undo.message", table: "Profile"))
                            .font(PSTypography.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    Spacer()
                }
                
                Button(action: {
                    undoScheduleChange()
                }) {
                    HStack {
                        if isUndoing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: PSIconSize.small))
                        }
                        
                        Text(L("profile.scheduleChange.undo.button", table: "Profile"))
                            .font(PSTypography.body)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, PSSpacing.lg)
                    .padding(.vertical, PSSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                            .fill(Color.orange)
                    )
                }
                .disabled(isUndoing)
            }
        }
        .background(cardBackground)
        .alert(
            L("general.error", table: "Profile"),
            isPresented: isShowingUndoError
        ) {
            Button(L("general.ok", table: "Profile"), role: .cancel) {
                undoError = nil
            }
        } message: {
            Text(undoErrorMessage)
        }
    }
    
    private func undoScheduleChange() {
        isUndoing = true
        
        Task {
            do {
                try await viewModel.undoScheduleChange()
                await MainActor.run {
                    isUndoing = false
                }
            } catch {
                await MainActor.run {
                    undoError = error.localizedDescription
                    isUndoing = false
                }
            }
        }
    }
} 