//
//  ContentView.swift
//  PolyNap Watch App
//
//  Created by Taner Çelik on 5.07.2025.
//

import SwiftUI

// Not: MainWatchView PolyNap Watch Extension'da tanımlı
// Watch Extension'dan view'lere erişim sağlanması gerekiyor

struct ContentView: View {
    var body: some View {
        VStack {
            Text("PolyNap")
                .font(.title2)
                .padding()
            
            Text("Watch bağlantısı kurulurken...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
