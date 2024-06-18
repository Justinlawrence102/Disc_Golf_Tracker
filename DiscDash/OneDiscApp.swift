//
//  OneDiscApp.swift
//  OneDisc
//
//  Created by Justin Lawrence on 9/23/23.
//

import SwiftUI
import SwiftData
import TipKit

@main
struct OneDiscApp: App {
    @UIApplicationDelegateAdaptor var delegate: FSAppDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Game.self
        ])
        var modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .private("iCloud.justinlawrence.disc-dash"))

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
   
    var body: some Scene {
        WindowGroup {
            //Fix for background crash https://stackoverflow.com/questions/78265564/background-crash-swiftdata-swiftui-one-time-initialization-function-for-empty
            ContentView(container: sharedModelContainer)
        }
    }
}

struct ContentView: View {
    let container: ModelContainer
    var locationManager = LocationManager()
    var sharedActivityManager = SharedActivityManager()
    
    var body: some View {
        HomeView()
            .modelContainer(container)
            .environment(locationManager)
            .environmentObject(sharedActivityManager)
            .task {
                try?  Tips.configure([
                    .displayFrequency(.immediate),
                    .datastoreLocation(.applicationDefault)
                ])
                
            }
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

struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}
