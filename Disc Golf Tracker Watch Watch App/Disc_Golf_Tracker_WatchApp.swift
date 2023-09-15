//
//  Disc_Golf_Tracker_WatchApp.swift
//  Disc Golf Tracker Watch Watch App
//
//  Created by Justin Lawrence on 9/13/23.
//

import SwiftUI
import SwiftData

@main
struct Disc_Golf_Tracker_Watch_Watch_AppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Game.self
        ])
        var modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .private("iCloud.justinlawrence.discGolfTracker"))
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
