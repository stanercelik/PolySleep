// CircularTransitionModifier.swift
// polynap
//
// Created by Claude on 21.01.2025.

import SwiftUI

// MARK: - CircularTransitionState
enum CircularTransitionState {
    case idle
    case transitioning
    case completed
}

// MARK: - CircularTransitionModifier
struct CircularTransitionModifier<Destination: View>: ViewModifier {
    let destination: Destination
    let config: CircularTransitionConfig
    @Binding var isActive: Bool
    @State private var transitionState: CircularTransitionState = .idle
    @StateObject private var transitionManager = CircularTransitionManager()
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ZStack {
                // Source content
                content
                    .opacity(transitionManager.isDestinationPresented ? 0 : 1)
                    .disabled(transitionState == .transitioning)
                
                // Transition circles
                if transitionState == .transitioning {
                    transitionCircles(geometry: geometry)
                }
                
                // Destination content
                destination
                    .opacity(transitionManager.isDestinationPresented ? 1 : 0)
                    .zIndex(1)
            }
        }
        .onChange(of: isActive) { newValue in
            if newValue && transitionState == .idle {
                startTransition()
            } else if !newValue {
                resetTransition()
            }
        }
        .onAppear {
            transitionManager.updateConfig(config)
        }
    }
    
    @ViewBuilder
    private func transitionCircles(geometry: GeometryProxy) -> some View {
        let circleDiameter = max(geometry.size.width, geometry.size.height) * 2
        let screenCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        
        // Primary circle
        Circle()
            .fill(config.primaryColor)
            .frame(width: circleDiameter, height: circleDiameter)
            .scaleEffect(transitionManager.isPrimaryCircleExpanded ? 1.5 : 0, anchor: .center)
            .position(config.startPosition)
            .opacity(transitionManager.isPrimaryCircleExpanded ? 1 : 0)
        
        // Background circle
        Circle()
            .fill(config.backgroundColor)
            .frame(width: circleDiameter, height: circleDiameter)
            .scaleEffect(transitionManager.isBackgroundCircleExpanded ? 1.5 : 0, anchor: .center)
            .position(screenCenter)
            .opacity(transitionManager.isBackgroundCircleExpanded ? 1 : 0)
    }
    
    private func startTransition() {
        transitionState = .transitioning
        transitionManager.startTransition {
            transitionState = .completed
        }
    }
    
    private func resetTransition() {
        transitionState = .idle
        transitionManager.resetStates()
    }
}

// MARK: - Enhanced View Extensions
extension View {
    /// Adds a circular transition to another view with custom start position
    func circularTransition<Destination: View>(
        to destination: Destination,
        startPosition: CGPoint,
        isActive: Binding<Bool>,
        primaryColor: Color = .appPrimary,
        backgroundColor: Color = .appBackground
    ) -> some View {
        let config = CircularTransitionConfig.withStartPosition(startPosition)
        
        return self.modifier(
            CircularTransitionModifier(
                destination: destination,
                config: config,
                isActive: isActive
            )
        )
    }
    
    /// More flexible circular transition with custom configuration
    func circularTransitionWithConfig<Destination: View>(
        to destination: Destination,
        config: CircularTransitionConfig,
        isActive: Binding<Bool>
    ) -> some View {
        self.modifier(
            CircularTransitionModifier(
                destination: destination,
                config: config,
                isActive: isActive
            )
        )
    }
}

// MARK: - IntegratedCircularTransitionButton with integrated transition
struct IntegratedCircularTransitionButton<Label: View, Destination: View>: View {
    let destination: Destination
    let label: Label
    let action: (() -> Void)?
    
    @State private var buttonCenter: CGPoint = .zero
    @State private var isTransitioning: Bool = false
    @State private var circleDiameter: CGFloat = 0
    @StateObject private var transitionManager = CircularTransitionManager()
    
    private let config: CircularTransitionConfig
    
    init(
        primaryColor: Color = .appPrimary,
        backgroundColor: Color = .appBackground,
        action: (() -> Void)? = nil,
        @ViewBuilder label: () -> Label,
        @ViewBuilder destination: () -> Destination
    ) {
        self.action = action
        self.label = label()
        self.destination = destination()
        self.config = CircularTransitionConfig(
            startPosition: .zero, // Will be updated
            primaryColor: primaryColor,
            backgroundColor: backgroundColor,
            buttonFadeOutDuration: 0.3,
            primaryCircleDelay: 0.2,
            primaryCircleAnimationDuration: 0.7,
            backgroundCircleDelay: 0.8,
            backgroundCircleAnimationDuration: 0.7,
            destinationFadeInDelay: 1.4,
            destinationFadeInDuration: 0.6
        )
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Original button and content
                if !transitionManager.isDestinationPresented {
                    VStack {
                        Spacer()
                        
                        button
                            .opacity(transitionManager.isButtonVisible ? 1 : 0)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Transition circles
                if isTransitioning {
                    transitionCircles(geometry: geometry)
                }
                
                // Destination
                destination
                    .opacity(transitionManager.isDestinationPresented ? 1 : 0)
                    .zIndex(1)
            }
        }
        .onAppear {
            setupGeometry()
        }
    }
    
    private var button: some View {
        label
            .overlay(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            let frame = proxy.frame(in: .global)
                            buttonCenter = CGPoint(
                                x: frame.midX,
                                y: frame.midY
                            )
                        }
                        .onChange(of: proxy.frame(in: .global)) { frame in
                            buttonCenter = CGPoint(
                                x: frame.midX,
                                y: frame.midY
                            )
                        }
                }
            )
            .onTapGesture {
                startTransition()
            }
    }
    
    @ViewBuilder
    private func transitionCircles(geometry: GeometryProxy) -> some View {
        let screenCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        
        // Primary circle
        Circle()
            .fill(config.primaryColor)
            .frame(width: circleDiameter, height: circleDiameter)
            .scaleEffect(transitionManager.isPrimaryCircleExpanded ? 1.5 : 0, anchor: .center)
            .position(buttonCenter)
            .opacity(transitionManager.isPrimaryCircleExpanded ? 1 : 0)
        
        // Background circle
        Circle()
            .fill(config.backgroundColor)
            .frame(width: circleDiameter, height: circleDiameter)
            .scaleEffect(transitionManager.isBackgroundCircleExpanded ? 1.5 : 0, anchor: .center)
            .position(screenCenter)
            .opacity(transitionManager.isBackgroundCircleExpanded ? 1 : 0)
    }
    
    private func startTransition() {
        action?()
        isTransitioning = true
        
        let updatedConfig = CircularTransitionConfig(
            startPosition: buttonCenter,
            primaryColor: config.primaryColor,
            backgroundColor: config.backgroundColor,
            buttonFadeOutDuration: config.buttonFadeOutDuration,
            primaryCircleDelay: config.primaryCircleDelay,
            primaryCircleAnimationDuration: config.primaryCircleAnimationDuration,
            backgroundCircleDelay: config.backgroundCircleDelay,
            backgroundCircleAnimationDuration: config.backgroundCircleAnimationDuration,
            destinationFadeInDelay: config.destinationFadeInDelay,
            destinationFadeInDuration: config.destinationFadeInDuration
        )
        
        transitionManager.updateConfig(updatedConfig)
        transitionManager.startTransition {
            // Transition completed
        }
    }
    
    private func setupGeometry() {
        // Set initial circle diameter for screen size
        DispatchQueue.main.async {
            let screenBounds = UIScreen.main.bounds
            circleDiameter = max(screenBounds.width, screenBounds.height) * 2
        }
    }
}

// MARK: - Convenience Initializers
extension IntegratedCircularTransitionButton where Label == Text {
    init(
        _ title: String,
        primaryColor: Color = .appPrimary,
        backgroundColor: Color = .appBackground,
        action: (() -> Void)? = nil,
        @ViewBuilder destination: () -> Destination
    ) {
        self.init(
            primaryColor: primaryColor,
            backgroundColor: backgroundColor,
            action: action,
            label: { Text(title) },
            destination: destination
        )
    }
}

extension IntegratedCircularTransitionButton where Label == PSPrimaryButton {
    init(
        buttonTitle: String,
        primaryColor: Color = .appPrimary,
        backgroundColor: Color = .appBackground,
        action: (() -> Void)? = nil,
        @ViewBuilder destination: () -> Destination
    ) {
        self.init(
            primaryColor: primaryColor,
            backgroundColor: backgroundColor,
            action: action,
            label: { PSPrimaryButton(buttonTitle) {} },
            destination: destination
        )
    }
}