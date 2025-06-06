//
//  TrackableScrollView.swift
//  polynap
//
//  Created by Taner Çelik on 1.02.2025.
//
// Utils/TrackableScrollView.swift
import SwiftUI

public struct TrackableScrollView<Content: View>: View {
    @Binding var offset: CGFloat
    let content: Content

    public init(offset: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
        self._offset = offset
        self.content = content()
    }

    public var body: some View {
        ScrollView {
            // GeometryReader ile scroll offset’i takip ediyoruz.
            GeometryReader { proxy in
                Color.clear
                    .preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: proxy.frame(in: .named("scrollView")).minY
                    )
            }
            .frame(height: 0)
            
            content
        }
        .coordinateSpace(name: "scrollView")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            print("TrackableScrollView offset:", value)
            offset = value
        }
    }
}

public struct ScrollOffsetPreferenceKey: PreferenceKey {
    public static var defaultValue: CGFloat = 0

    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
