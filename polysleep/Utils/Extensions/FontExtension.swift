//
//  FontExtension.swift
//  polysleep
//
//  Created by Taner Çelik on 27.12.2024.
//

import SwiftUICore

extension Font {
    static func inter(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        return .custom("Inter", size: size).weight(weight)
    }
}
