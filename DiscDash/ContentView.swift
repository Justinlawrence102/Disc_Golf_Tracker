//
//  ContentView.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 8/23/23.
//

import SwiftUI
import SwiftData

struct ContentView: View {
        
    
    var body: some View {
        TabView {
            GameSelectionView()
            .tabItem {
                Label("Games", systemImage: "figure.disc.sports")
            }
            PlayerListView()
                .tabItem {
                    Label("Players", systemImage: "person.3.fill")
                }
            Text("Stats")
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
        }
        .tint(Color("Pink"))
    }

}

#Preview {
    ContentView()
        .modelContainer(for: Player.self, inMemory: true)
}
