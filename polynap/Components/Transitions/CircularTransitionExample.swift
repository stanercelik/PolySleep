// CircularTransitionExample.swift
// polynap
//
// Created by Claude on 21.01.2025.

import SwiftUI

// MARK: - Usage Examples

/// Example 1: Using CircularTransitionView directly
struct DirectTransitionExample: View {
    @State private var transitionView: CircularTransitionView<AnyView, AnyView>?
    @State private var buttonCenter: CGPoint = .zero
    
    var body: some View {
        ZStack {
            if let transition = transitionView {
                transition
            } else {
                originalContent
            }
        }
    }
    
    private var originalContent: some View {
        VStack(spacing: 20) {
            Text("Original Screen")
                .font(.largeTitle)
                .padding()
            
            PSPrimaryButton("Start Transition") {
                startTransition()
            }
            .overlay(
                GeometryReader { proxy in
                    Color.clear.onAppear {
                        let frame = proxy.frame(in: .global)
                        buttonCenter = CGPoint(x: frame.midX, y: frame.midY)
                    }
                }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
    
    private func startTransition() {
        let config = CircularTransitionConfig.withStartPosition(buttonCenter)
        
        transitionView = CircularTransitionView(
            config: config,
            sourceContent: { AnyView(originalContent) },
            destinationContent: { AnyView(destinationContent) }
        )
        
        // Start the transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            transitionView?.startTransition {
                print("Transition completed!")
            }
        }
    }
    
    private var destinationContent: some View {
        VStack(spacing: 20) {
            Text("Destination Screen")
                .font(.largeTitle)
                .padding()
            
            Text("Transition completed successfully!")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

/// Example 2: Using View extension
struct ExtensionTransitionExample: View {
    @State private var showDestination = false
    @State private var buttonCenter: CGPoint = .zero
    
    var body: some View {
        originalContent
            .circularTransitionWithConfig(
                to: destinationContent,
                config: CircularTransitionConfig.withStartPosition(buttonCenter),
                isActive: $showDestination
            )
    }
    
    private var originalContent: some View {
        VStack(spacing: 20) {
            Text("Source Screen")
                .font(.largeTitle)
                .padding()
            
            PSPrimaryButton("Transition with Extension") {
                showDestination = true
            }
            .overlay(
                GeometryReader { proxy in
                    Color.clear.onAppear {
                        let frame = proxy.frame(in: .global)
                        buttonCenter = CGPoint(x: frame.midX, y: frame.midY)
                    }
                }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blue.opacity(0.1))
    }
    
    private var destinationContent: some View {
        VStack(spacing: 20) {
            Text("Extension Destination")
                .font(.largeTitle)
                .padding()
            
            PSSecondaryButton("Go Back") {
                showDestination = false
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.green.opacity(0.1))
    }
}

/// Example 3: Custom transition configurations
struct CustomConfigExample: View {
    @State private var showTransition = false
    @State private var buttonCenter: CGPoint = .zero
    
    // Custom configuration with different timing and colors
    private var customConfig: CircularTransitionConfig {
        CircularTransitionConfig(
            startPosition: buttonCenter,
            primaryColor: .red,
            backgroundColor: .black,
            buttonFadeOutDuration: 0.5,
            primaryCircleDelay: 0.1,
            primaryCircleAnimationDuration: 1.0,
            backgroundCircleDelay: 0.6,
            backgroundCircleAnimationDuration: 1.0,
            destinationFadeInDelay: 1.5,
            destinationFadeInDuration: 0.8
        )
    }
    
    var body: some View {
        ZStack {
            if showTransition {
                CircularTransitionView(
                    config: customConfig,
                    sourceContent: { sourceView },
                    destinationContent: { destinationView }
                )
                .onAppear {
                    // Auto-start when view appears
                }
            } else {
                sourceView
            }
        }
    }
    
    private var sourceView: some View {
        VStack(spacing: 20) {
            Text("Custom Config Example")
                .font(.largeTitle)
                .padding()
            
            Text("This uses red primary circle and black background")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding()
            
            PSPrimaryButton("Start Custom Transition") {
                showTransition = true
            }
            .overlay(
                GeometryReader { proxy in
                    Color.clear.onAppear {
                        let frame = proxy.frame(in: .global)
                        buttonCenter = CGPoint(x: frame.midX, y: frame.midY)
                    }
                }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.yellow.opacity(0.1))
    }
    
    private var destinationView: some View {
        VStack(spacing: 20) {
            Text("Custom Destination")
                .font(.largeTitle)
                .foregroundColor(.white)
                .padding()
            
            Text("Different timing and colors!")
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Usage in existing screens

/// Example: How to modify WelcomeView to use the new component
struct WelcomeViewWithTransition: View {
    @StateObject private var viewModel = WelcomeViewModel()
    @State private var buttonCenter: CGPoint = .zero
    @State private var showTransition: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if showTransition {
                    CircularTransitionView(
                        config: CircularTransitionConfig.withStartPosition(buttonCenter),
                        sourceContent: { mainContent },
                        destinationContent: { OnboardingView() }
                    )
                    .onAppear {
                        // This would replace the animateAndPresentOnboarding() logic
                        // The transition starts automatically
                    }
                } else {
                    mainContent
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private var mainContent: some View {
        VStack {
            // ... existing welcome content
            
            PSPrimaryButton("Get Started") {
                // Replace the complex animation logic with simple state change
                showTransition = true
            }
            .overlay(
                GeometryReader { proxy in
                    Color.clear.onAppear {
                        let frame = proxy.frame(in: .global)
                        buttonCenter = CGPoint(x: frame.midX, y: frame.midY)
                    }
                }
            )
        }
    }
}

// MARK: - Preview
#Preview("Direct Transition") {
    DirectTransitionExample()
}

#Preview("Extension Transition") {
    ExtensionTransitionExample()
}

#Preview("Custom Config") {
    CustomConfigExample()
}