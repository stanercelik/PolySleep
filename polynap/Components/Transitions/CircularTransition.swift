// CircularTransition.swift
// polynap
//
// Created by Claude on 21.01.2025.

import SwiftUI

// MARK: - CircularTransition Configuration
struct CircularTransitionConfig {
    let startPosition: CGPoint
    let primaryColor: Color
    let backgroundColor: Color
    let buttonFadeOutDuration: TimeInterval
    let primaryCircleDelay: TimeInterval
    let primaryCircleAnimationDuration: TimeInterval
    let backgroundCircleDelay: TimeInterval
    let backgroundCircleAnimationDuration: TimeInterval
    let destinationFadeInDelay: TimeInterval
    let destinationFadeInDuration: TimeInterval
    
    static let `default` = CircularTransitionConfig(
        startPosition: .zero,
        primaryColor: .appPrimary,
        backgroundColor: .appBackground,
        buttonFadeOutDuration: 0.3,
        primaryCircleDelay: 0.2,
        primaryCircleAnimationDuration: 0.7,
        backgroundCircleDelay: 0.8,
        backgroundCircleAnimationDuration: 0.7,
        destinationFadeInDelay: 1.4,
        destinationFadeInDuration: 0.6
    )
    
    /// Creates a configuration with custom start position and default timing
    static func withStartPosition(_ position: CGPoint) -> CircularTransitionConfig {
        return CircularTransitionConfig(
            startPosition: position,
            primaryColor: .appPrimary,
            backgroundColor: .appBackground,
            buttonFadeOutDuration: 0.3,
            primaryCircleDelay: 0.2,
            primaryCircleAnimationDuration: 0.7,
            backgroundCircleDelay: 0.8,
            backgroundCircleAnimationDuration: 0.7,
            destinationFadeInDelay: 1.4,
            destinationFadeInDuration: 0.6
        )
    }
}

// MARK: - CircularTransitionManager
@MainActor
class CircularTransitionManager: ObservableObject {
    @Published var isButtonVisible: Bool = true
    @Published var isPrimaryCircleExpanded: Bool = false
    @Published var isBackgroundCircleExpanded: Bool = false
    @Published var isDestinationPresented: Bool = false
    
    private var config: CircularTransitionConfig
    private var onTransitionComplete: (() -> Void)?
    
    init(config: CircularTransitionConfig = .default) {
        self.config = config
    }
    
    /// Updates the configuration
    func updateConfig(_ newConfig: CircularTransitionConfig) {
        self.config = newConfig
    }
    
    /// Starts the circular transition animation
    func startTransition(onComplete: (() -> Void)? = nil) {
        self.onTransitionComplete = onComplete
        
        // Reset all states
        resetStates()
        
        // 1) Button fade out
        withAnimation(.easeInOut(duration: config.buttonFadeOutDuration)) {
            isButtonVisible = false
        }
        
        // 2) Primary circle expansion (starts from button position)
        DispatchQueue.main.asyncAfter(deadline: .now() + config.primaryCircleDelay) {
            withAnimation(.easeInOut(duration: self.config.primaryCircleAnimationDuration)) {
                self.isPrimaryCircleExpanded = true
            }
        }
        
        // 3) Background circle expansion (starts from center)
        DispatchQueue.main.asyncAfter(deadline: .now() + config.backgroundCircleDelay) {
            withAnimation(.easeInOut(duration: self.config.backgroundCircleAnimationDuration)) {
                self.isBackgroundCircleExpanded = true
            }
        }
        
        // 4) Destination view fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + config.destinationFadeInDelay) {
            withAnimation(.easeInOut(duration: self.config.destinationFadeInDuration)) {
                self.isDestinationPresented = true
            }
            
            // Call completion handler
            self.onTransitionComplete?()
        }
    }
    
    /// Resets all animation states
    func resetStates() {
        isButtonVisible = true
        isPrimaryCircleExpanded = false
        isBackgroundCircleExpanded = false
        isDestinationPresented = false
    }
}

// MARK: - CircularTransitionView
struct CircularTransitionView<SourceContent: View, DestinationContent: View>: View {
    let sourceContent: SourceContent
    let destinationContent: DestinationContent
    @StateObject private var transitionManager: CircularTransitionManager
    
    @State private var circleDiameter: CGFloat = 0
    @State private var screenCenter: CGPoint = .zero
    
    private var config: CircularTransitionConfig
    private var shouldAutoStart: Bool
    
    init(
        config: CircularTransitionConfig = .default,
        autoStart: Bool = false,
        @ViewBuilder sourceContent: () -> SourceContent,
        @ViewBuilder destinationContent: () -> DestinationContent
    ) {
        self.config = config
        self.shouldAutoStart = autoStart
        self.sourceContent = sourceContent()
        self.destinationContent = destinationContent()
        self._transitionManager = StateObject(wrappedValue: CircularTransitionManager(config: config))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1) Source Content (fades out when destination appears)
                sourceContent
                    .opacity(transitionManager.isDestinationPresented ? 0 : 1)
                
                // 2) Primary Circle (expands from start position)
                Circle()
                    .fill(config.primaryColor)
                    .frame(width: circleDiameter, height: circleDiameter)
                    .scaleEffect(transitionManager.isPrimaryCircleExpanded ? 1.5 : 0, anchor: .center)
                    .position(config.startPosition)
                    .opacity(transitionManager.isPrimaryCircleExpanded ? 1 : 0)
                
                // 3) Background Circle (expands from center)
                Circle()
                    .fill(config.backgroundColor)
                    .frame(width: circleDiameter, height: circleDiameter)
                    .scaleEffect(transitionManager.isBackgroundCircleExpanded ? 1.5 : 0, anchor: .center)
                    .position(screenCenter)
                    .opacity(transitionManager.isBackgroundCircleExpanded ? 1 : 0)
                
                // 4) Destination Content (fades in)
                destinationContent
                    .opacity(transitionManager.isDestinationPresented ? 1 : 0)
                    .zIndex(1)
            }
            .onAppear {
                setupGeometry(geometry)
                if shouldAutoStart {
                    startTransitionAutomatically()
                }
            }
            .onChange(of: geometry.size) { _ in
                setupGeometry(geometry)
            }
            .onChange(of: transitionManager.isDestinationPresented) { _ in
                // This triggers when transition should start
            }
        }
        .ignoresSafeArea()
    }
    
    private func setupGeometry(_ geometry: GeometryProxy) {
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height
        circleDiameter = max(screenWidth, screenHeight) * 2
        screenCenter = CGPoint(x: screenWidth / 2, y: screenHeight / 2)
        
        // Update config with correct dimensions if needed
        transitionManager.updateConfig(config)
    }
    
    /// Triggers the transition animation
    func startTransition(onComplete: (() -> Void)? = nil) {
        transitionManager.startTransition(onComplete: onComplete)
    }
    
    /// Triggers transition automatically when view appears
    private func startTransitionAutomatically() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            transitionManager.startTransition()
        }
    }
}

// MARK: - CircularTransitionTrigger Protocol
protocol CircularTransitionTrigger {
    func startCircularTransition(onComplete: (() -> Void)?)
}

// MARK: - Basic View Extension for Circular Transition
extension View {
    /// Basic circular transition capability - simple wrapper around CircularTransitionView
    func basicCircularTransition<Destination: View>(
        to destination: Destination,
        config: CircularTransitionConfig,
        isActive: Binding<Bool>
    ) -> some View {
        ZStack {
            if isActive.wrappedValue {
                CircularTransitionView(
                    config: config,
                    sourceContent: { self },
                    destinationContent: { destination }
                )
            } else {
                self
            }
        }
    }
}