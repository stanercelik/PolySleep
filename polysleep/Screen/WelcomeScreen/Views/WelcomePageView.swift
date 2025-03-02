//
//  WelcomePageView.swift
//  polysleep
//
//  Created by Taner Çelik on 27.12.2024.
//

import SwiftUI

struct WelcomePageView: View {
    let pageIndex: Int
    @Binding var showTitle: Bool
    @Binding var showDescription: Bool
    @Binding var showImage: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
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
            
            if showImage {
                pageImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
                    .padding(.top, 32)
                    .transition(.opacity)
                    .accessibilityLabel(Text(pageImageAccessibilityLabel))
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
    
    private var pageImage: Image {
        
        if colorScheme == .dark {
            switch pageIndex {
            case 0: return Image("exhausted_man_dark")
            case 1: return Image("alarm_girl_dark")
            case 2: return Image("healing_man_dark")
            default: return Image("alarm_boy_dark")
            }
        } else {
            switch pageIndex {
            case 0: return Image("exhausted_man_light")
            case 1: return Image("alarm_girl_light")
            case 2: return Image("healing_man_light")
            default: return Image("alarm_boy_light")
            }
        }
        
       
    }
    
    private var pageImageAccessibilityLabel: String {
        switch pageIndex {
        case 0: return NSLocalizedString("firstPageImage", tableName: "Welcome", comment: "")
        case 1: return NSLocalizedString("secondPageImage", tableName: "Welcome", comment: "")
        case 2: return NSLocalizedString("thirdPageImage", tableName: "Welcome", comment: "")
        default: return NSLocalizedString("fourthPageImage", tableName: "Welcome", comment: "")
        }
    }
}

#Preview {
    @Previewable @State var showTitle: Bool = true
    @Previewable @State var showDescription: Bool = true
    @Previewable @State var showImage: Bool = true
    
    WelcomePageView(pageIndex: 0,showTitle: $showTitle ,showDescription: $showDescription, showImage: $showImage)
}
