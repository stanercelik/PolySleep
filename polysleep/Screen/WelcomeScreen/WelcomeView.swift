//
//  WelcomeView.swift
//  polysleep
//
//  Created by Taner Çelik on 27.12.2024.
//

import SwiftUI

struct WelcomeView: View {
    @StateObject private var viewModel = WelcomeViewModel()
    
    var body: some View {
        ZStack {
            TabView(selection: $viewModel.currentPageIndex) {
                ForEach(0..<viewModel.totalPages, id: \.self) { index in
                    OnboardingPageView(pageIndex: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            VStack {
                // Story progress bar
                VStack (alignment: .leading) {
                    HStack(spacing: 4) {
                        ForEach(0..<viewModel.totalPages, id: \.self) { index in
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color("SecondaryTextColor").opacity(0.3))
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color(Color.white))
                                        .frame(width: geo.size.width * viewModel.progressValues[index])
                                }
                            }
                            .frame(height: 4)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                    
                    
                    
                    HStack (alignment: .center){
                        Image("OnboardingAppLogo")
                            .resizable()
                            .frame(width: 32, height: 32, alignment: .leading)
                            .padding(.leading, 16)
                            .padding(.trailing, 8)
                            
                        
                        Text(NSLocalizedString("welcomeTitle", comment: ""))
                            .font(.custom("Inter", size: 18))
                            .foregroundColor(Color("TextColor"))
                            .fontWeight(.bold)
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
                
                
                // Login And Register Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        // login action
                    }) {
                        Text(NSLocalizedString("login", comment: ""))
                            .font(.custom("Inter", size: 16))
                            .foregroundColor(Color("AccentColor"))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("SecondaryColor"))
                            .cornerRadius(28)
                    }
                    
                    Button(action: {
                        // register action
                    }) {
                        Text(NSLocalizedString("register", comment: ""))
                            .font(.custom("Inter", size: 16))
                            .foregroundColor(Color("BackgroundColor"))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("PrimaryColor"))
                            .cornerRadius(28)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
                
            }
            
        }
    }
}

#Preview {
    WelcomeView()
}
