//
//  OnboardingPageView.swift
//  polysleep
//
//  Created by Taner Çelik on 27.12.2024.
//

import SwiftUI

struct OnboardingPageView: View {
    let pageIndex: Int
    
    var body: some View {
        switch pageIndex {
        case 0:
            page1
        case 1:
            page2
        case 2:
            page3
        default:
            page4
        }
    }
    
    private var page1: some View {
        ZStack {
            Color("PrimaryColor").ignoresSafeArea()
            VStack(spacing: 8) {
                Text("asd")
                    .font(.custom("Inter", size: 24))
                    .foregroundColor(Color("TextColor"))
                Text("asda")
                    .font(.custom("Inter", size: 16))
                    .foregroundColor(Color("SecondaryTextColor"))
            }
        }
    }
    
    private var page2: some View {
        ZStack {
            Color("SecondaryColor").ignoresSafeArea()
            VStack(spacing: 8) {
                Text("LocalizedStrings.page2Title")
                    .font(.custom("Inter", size: 24))
                    .foregroundColor(Color("TextColor"))
                Text("LocalizedStrings.page2Subtitle")
                    .font(.custom("Inter", size: 16))
                    .foregroundColor(Color("SecondaryTextColor"))
            }
        }
    }
    
    private var page3: some View {
        ZStack {
            Color("AccentColor").ignoresSafeArea()
            VStack(spacing: 8) {
                Text("LocalizedStrings.page3Title")
                    .font(.custom("Inter", size: 24))
                    .foregroundColor(Color("TextColor"))
                Text("LocalizedStrings.page3Subtitle")
                    .font(.custom("Inter", size: 16))
                    .foregroundColor(Color("SecondaryTextColor"))
            }
        }
    }
    
    private var page4: some View {
        ZStack {
            Color(Color.purple).ignoresSafeArea()
            VStack(spacing: 8) {
                Text("LocalizedStrings.page4Title")
                    .font(.custom("Inter", size: 24))
                    .foregroundColor(Color("TextColor"))
                Text("LocalizedStrings.page4Subtitle")
                    .font(.custom("Inter", size: 16))
                    .foregroundColor(Color("SecondaryTextColor"))
            }
        }
    }
}

#Preview {
    OnboardingPageView(pageIndex: 0)
}
