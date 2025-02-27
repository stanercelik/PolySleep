//
//  OnboardingPageView.swift
//  polysleep
//
//  Created by Taner Çelik on 27.12.2024.
//

import SwiftUI

struct WelcomePageView: View {
    let pageIndex: Int
    @Binding var showTitle: Bool
    @Binding var showDescription: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 42) {
            if showTitle {
                Text(pageTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.appText)
                    .transition(.opacity)
            }
            
            if showDescription {
                Text(pageDescription)
                    .foregroundColor(Color.appSecondaryText)
                    .font(.headline)
                    .transition(.opacity)
            }
            
            Spacer()
        }
    }
    
    private var pageTitle: String {
        switch pageIndex {
        case 0: return NSLocalizedString("firstPageTitle", tableName: "Welcome", comment: "")
        case 1: return NSLocalizedString("secondPageTitle", tableName: "Welcome", comment: "")
        case 2: return NSLocalizedString("thirdPageTitle", tableName: "Welcome", comment: "")
        default: return NSLocalizedString("fourthPageTitle", tableName: "Welcome", comment: "")
        }
    }
    
    private var pageDescription: String {
        switch pageIndex {
        case 0: return NSLocalizedString("firstPageDesc", tableName: "Welcome", comment: "")
        case 1: return NSLocalizedString("secondPageDesc", tableName: "Welcome", comment: "")
        case 2: return NSLocalizedString("thirdPageDesc", tableName: "Welcome", comment: "")
        default: return NSLocalizedString("fourthPageDesc", tableName: "Welcome", comment: "")
        }
    }
}

#Preview {
    @Previewable @State var showTitle: Bool = true
    @Previewable @State var showDescription: Bool = true
    WelcomePageView(pageIndex: 0,showTitle: $showTitle ,showDescription: $showDescription)
}
