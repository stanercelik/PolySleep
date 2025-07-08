//
//  PolyNap_Watch_Extension.swift
//  PolyNap Watch Extension
//
//  Created by Taner Çelik on 5.07.2025.
//

import AppIntents

struct PolyNap_Watch_Extension: AppIntent {
    static var title: LocalizedStringResource { "PolyNap Watch Extension" }
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
