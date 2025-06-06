import SwiftUI
import RevenueCat
import RevenueCatUI

/// A view modifier that presents a paywall sheet when a non-premium user tries to interact with the content.
/// It overlays a tappable clear view if the user is not subscribed to the "premium" entitlement.
struct RequirePremiumViewModifier: ViewModifier {
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @State private var isPaywallPresented = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if revenueCatManager.userState != .premium {
                        // This clear rectangle sits on top of the content and intercepts taps
                        // if the user is not premium.
                        Rectangle()
                            .foregroundColor(.clear)
                            .contentShape(Rectangle()) // Make the whole area tappable
                            .onTapGesture {
                                isPaywallPresented.toggle()
                            }
                    }
                }
            )
            .sheet(isPresented: $isPaywallPresented) {
                PaywallView()
            }
    }
}

extension View {
    /// A view modifier that restricts interaction with a view to premium users.
    ///
    /// If a non-premium user taps on the view, a paywall is presented.
    /// Premium users can interact with the view as normal.
    func requiresPremium() -> some View {
        modifier(RequirePremiumViewModifier())
    }
}
