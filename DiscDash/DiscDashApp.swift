//
//  DiscDashApp.swift
//  DiscDash
//
//  Created by Justin Lawrence on 9/23/23.
//

import SwiftUI
import SwiftData

@main
struct DiscDashApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Game.self
        ])
        var modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .private("iCloud.justinlawrence.disc-dash"))
        //, cloudKitDatabase: .private("iCloud.justinlawrence.discGolfTracker")

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    @Environment(\.undoManager) var undoManager
    var locationManager = LocationManager()
    var sharedActivityManager = SharedActivityManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(sharedActivityManager)
                .onAppear {
                    locationManager.requestLocation()
                }
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
}

struct NavigationBarColor: ViewModifier {

  init(tintColor: UIColor) {
    let coloredAppearance = UINavigationBarAppearance()
    coloredAppearance.titleTextAttributes = [.foregroundColor: tintColor]
    coloredAppearance.largeTitleTextAttributes = [.foregroundColor: tintColor]
                   
    UINavigationBar.appearance().standardAppearance = coloredAppearance
    UINavigationBar.appearance().tintColor = tintColor
      
    UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(named: "Teal")
    UIPageControl.appearance().pageIndicatorTintColor = UIColor.black.withAlphaComponent(0.2)
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
