//
//  Disc_Golf_TrackerApp.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 8/23/23.
//

import SwiftUI
import SwiftData

@main
struct Disc_Golf_TrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Basket.self, Course.self, Player.self, Game.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    @Environment(\.undoManager) var undoManager
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Course.self,
            Player.self,
            Basket.self,
            Game.self
        ], isUndoEnabled: true)
//        .modelContainer(sharedModelContainer)
    }
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(named: "Pink")!]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(named: "Pink")!]
    }
//    
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
////        .modelContainer(for: [Player.self, Course.self])
//        .modelContainer(for: Player.self)
//    }
}

extension UIColor{
    convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        let start = hex.index(hex.startIndex, offsetBy: 0)
        let hexColor = String(hex[start...])
        
        if hexColor.count == 6 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            
            if scanner.scanHexInt64(&hexNumber) {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                b = CGFloat((hexNumber & 0x0000ff)) / 255
                a = 1.0
                self.init(red: r, green: g, blue: b, alpha: a)
                return
            }
        }
        return nil
    }
}
