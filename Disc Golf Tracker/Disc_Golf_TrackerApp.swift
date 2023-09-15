//
//  Disc_Golf_TrackerApp.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 8/23/23.
//

import SwiftUI
import SwiftData
import MapKit

@main
struct Disc_Golf_TrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Game.self //Basket.self, Course.self, Player.self, 
        ])
        var modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .private("iCloud.justinlawrence.discGolfTracker"))
        //, cloudKitDatabase: .private("iCloud.justinlawrence.discGolfTracker")

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    @Environment(\.undoManager) var undoManager
//    @Environment(\.modelContext) private var modelContext

    var locationManager = LocationManager()
    var sharedActivityManager = SharedActivityManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(sharedActivityManager)
                .navigationBarColor(text: UIColor(named: "Pink")!)
                .task {
                    for await session in SharePlayActivity.sessions() {
                        print("SharePlay exp started")
                        sharedActivityManager.configureGroupSession(session) //, modelContext: modelContext
                    }
                }
        }
//        .modelContainer(for: [
//            Course.self,
//            Player.self,
//            Basket.self,
//            Game.self
//        ], isUndoEnabled: true)
        .modelContainer(sharedModelContainer)
    }
    
//    init() {
//        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(named: "Pink")!]
//        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(named: "Pink")!]
//    }
    
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
////        .modelContainer(for: [Player.self, Course.self])
//        .modelContainer(for: Player.self)
//    }
}

struct NavigationBarColor: ViewModifier {

  init(tintColor: UIColor) {
    let coloredAppearance = UINavigationBarAppearance()
    coloredAppearance.titleTextAttributes = [.foregroundColor: tintColor]
    coloredAppearance.largeTitleTextAttributes = [.foregroundColor: tintColor]
                   
    UINavigationBar.appearance().standardAppearance = coloredAppearance
    UINavigationBar.appearance().tintColor = tintColor
  }

  func body(content: Content) -> some View {
    content
  }
}

extension View {
  func navigationBarColor(text: UIColor) -> some View {
    self.modifier(NavigationBarColor(tintColor: text))
  }
}
