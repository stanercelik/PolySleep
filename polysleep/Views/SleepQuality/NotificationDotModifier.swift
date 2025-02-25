import SwiftUI

struct NotificationDotModifier: ViewModifier {
    let isShowing: Bool
    
    func body(content: Content) -> some View {
        ZStack(alignment: .topTrailing) {
            content
            
            if isShowing {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .offset(x: 4, y: -4)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: isShowing)
    }
}

extension View {
    func notificationDot(isShowing: Bool) -> some View {
        modifier(NotificationDotModifier(isShowing: isShowing))
    }
}
