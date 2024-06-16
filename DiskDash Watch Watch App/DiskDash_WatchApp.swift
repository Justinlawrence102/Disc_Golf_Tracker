//
//  DiskDash_WatchApp.swift
//  DiskDash Watch Watch App
//
//  Created by Justin Lawrence on 9/23/23.
//

import SwiftUI
import SwiftData

@main
struct DiskDash_Watch_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor var appDelegate: WatchAppDelegate

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

    var locationManager = LocationManager()
    var isActive = NotificationCenter.default.publisher(for: .applicationIsActive)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(locationManager)
                .onReceive(isActive) {_ in
                    print("Check location")
                    Task {
                        do {
                            locationManager.requestLocation()
                        }
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
