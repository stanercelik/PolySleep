// WelcomeView.swift
// polysleep
//
// Created by Taner Çelik on 27.12.2024.

import SwiftUI

struct WelcomeView: View {
    @StateObject private var viewModel = WelcomeViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @State private var buttonCenter: CGPoint = .zero
    @State private var circleDiameter: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
                    ZStack {
                        // 1) Main Content
                        mainContent
                            .opacity(viewModel.isOnboardingPresented ? 0 : 1)
                        
                        // 2) First Circle
                        Circle()
                            .fill(Color.appPrimary)
                            .frame(width: circleDiameter, height: circleDiameter)
                            .scaleEffect(viewModel.isPrimaryCircleExpanded ? 2 : 0.01, anchor: .center)
                            .position(buttonCenter)
                            .opacity(viewModel.isPrimaryCircleExpanded ? 1 : 0)
                        
                        // 3) Second Circle
                        Circle()
                            .fill(Color.appBackground)
                            .frame(width: circleDiameter, height: circleDiameter)
                            .scaleEffect(viewModel.isBackgroundCircleExpanded ? 2 : 0.01, anchor: .center)
                            .position(buttonCenter)
                            .opacity(viewModel.isBackgroundCircleExpanded ? 1 : 0)
                        
                        // 4) Onboarding View
                        if viewModel.isOnboardingPresented {
                            OnboardingView()
                                .transition(.opacity)
                                .zIndex(1)
                        }
                    }
                    .onAppear {
                        let screenWidth = geo.size.width
                        let screenHeight = geo.size.height
                        circleDiameter = max(screenWidth, screenHeight) * 2
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
                .ignoresSafeArea()
    }
    
    private var mainContent: some View {
        VStack(alignment: .leading) {
            progressBar
            welcomeText
            Spacer()
            infoPages
            Spacer()
            continueButton
        }
        .padding(.top, 72)
        .padding(.bottom, 64)
        .padding(.horizontal, 16)
    }
    
    private var progressBar: some View {
        HStack(spacing: 3) {
            ForEach(0..<viewModel.totalPages, id: \.self) { index in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.appSecondaryText.opacity(0.25))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.appPrimary)
                            .frame(width: geo.size.width * viewModel.progressValues[index])
                    }
                }
                .frame(height: 3)
            }
        }
    }
    
    private var welcomeText: some View {
        HStack(spacing: 12) {
            Image("OnboardingAppLogo")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(width: 32, height: 32)
            
            Text("welcomeTitle", tableName: "Welcome")
                .font(.headline)
                .foregroundColor(Color.appSecondaryText)
        }
        .padding(.top, 8)
    }
    
    private var infoPages: some View {
        TabView(selection: $viewModel.currentPageIndex) {
            ForEach(0..<viewModel.totalPages, id: \.self) { index in
                WelcomePageView(
                    pageIndex: index,
                    showTitle: $viewModel.showTitle,
                    showDescription: $viewModel.showDescription,
                    showImage: $viewModel.showImage
                )
                .tag(index)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    let screenWidth = UIScreen.main.bounds.width
                    if location.x < screenWidth * 0.3 {
                        viewModel.previousPage()
                    } else if location.x > screenWidth * 0.7 {
                        viewModel.nextPage()
                    }
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onChange(of: viewModel.currentPageIndex) { _ in
            viewModel.fadeOutAnimations()
        }
        .padding(.horizontal, 8)
        .padding(.top, 36)
    }
    
    private var continueButton: some View {
        Button(action: {
            viewModel.animateAndPresentOnboarding()
        }) {
            Text("continue", tableName: "Welcome")
                .font(.title2)
                .foregroundColor(Color.appText)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.appPrimary)
                .cornerRadius(28)
        }
        .padding(.bottom, 16)
        .opacity(viewModel.isContinueButtonVisible ? 1 : 0)
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
            }
        )
    }
}

#Preview {
    WelcomeView()
}
