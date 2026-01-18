//
//  ContentView.swift
//  iPadScannerApp
//
//  Created by Marc Schneider-Handrup on 26.05.25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .accessibilityLabel("Globe icon")
                .accessibilityIdentifier("globeIcon")
            Text("Hello, world!")
                .accessibilityLabel("Hello, world!")
                .accessibilityIdentifier("welcomeText")
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("contentView")
    }
}

#Preview {
    ContentView()
}
