//
//  WelcomeView.swift
//  polysleep
//
//  Created by Taner Çelik on 27.12.2024.
//

import SwiftUI

struct WelcomeView: View {
    @StateObject private var viewModel = WelcomeViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack (alignment: .leading) {
            progressBar
            welcomeText
            Spacer()
            infoPages
            Spacer()
            continueButton
        }
    }
    
    var progressBar: some View {
        HStack(spacing: 3) {
            ForEach(0..<viewModel.totalPages, id: \.self) { index in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color("SecondaryTextColor").opacity(0.25))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color("PrimaryColor"))
                            .frame(width: geo.size.width * viewModel.progressValues[index])
                    }
                }
                .frame(height: 3)
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
    }
    var welcomeText: some View {
        HStack (spacing: 12) {
            Image("OnboardingAppLogo")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(width: 32, height: 32)
                .padding(.leading, 16)
            
            Text(NSLocalizedString("welcomeTitle", comment: ""))
                .font(.headline)
                .foregroundColor(Color("SecondaryTextColor"))
        }
        .padding(.top, 8)
    }
    var infoPages: some View {
        TabView(selection: $viewModel.currentPageIndex) {
            ForEach(0..<viewModel.totalPages, id: \.self) { index in
                WelcomePageView(pageIndex: index, showTitle: $viewModel.showTitle, showDescription: $viewModel.showDescription)
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
    
    
    var continueButton : some View {
        Button(action: {
            // Continue to onboarding
        }) {
            Text(NSLocalizedString("continue", comment: ""))
                .font(.title2)
                .foregroundColor(Color("TextColor"))
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color("PrimaryColor"))
                .cornerRadius(28)
        }
        .padding(16)
    }
    
    var authButtons: some View {
        
        HStack(spacing: 16) {
            Button(action: {
                // Login action
            }) {
                Text(NSLocalizedString("login", comment: ""))
                    .font(.headline)
                    .foregroundColor(Color("TextColor"))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color("PrimaryColor"), lineWidth: 2)
                    )
                    .cornerRadius(28)
            }
            
            Button(action: {
                // Register action
            }) {
                Text(NSLocalizedString("register", comment: ""))
                    .font(.headline)
                    .foregroundColor(Color("TextColor"))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("PrimaryColor"))
                    .cornerRadius(28)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 48)
    }
}

#Preview {
    WelcomeView()
}
