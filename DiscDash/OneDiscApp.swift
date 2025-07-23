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
            .environment(sharedActivityManager)
            .task {
                try?  Tips.configure([
                    .displayFrequency(.immediate),
                    .datastoreLocation(.applicationDefault)
                ])
                
            }
            .onAppear {
                locationManager.requestLocation()
                if !UserDefaults.standard.bool(forKey: "hasCompressedImages") {
                    let context = ModelContext(container)
                    var descriptor = FetchDescriptor<Player>()
                    do {
                        let players = try context.fetch(descriptor)
                        for player in players {
                            print("Player: \(player.name)")
                            if let data = player.image, let uiImage = UIImage(data: data) {
                                print("Org size \(data.count)")
                                if let compressed = resizeImage(image: uiImage, maxSize: 150) {
                                    let compressedData = compressed.pngData()!
                                    print("new size \(compressedData.count)")
                                    player.image = compressedData
                                }
                            }
                        }
                    }catch(let error) {
                        print(error)
                    }
                }
                UserDefaults.standard.set(true, forKey: "hasCompressedImages")
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

func resizeImage(image: UIImage, maxSize: CGFloat) -> UIImage? {
    let aspectRatio = image.size.width / image.size.height

    var newSize: CGSize
    if aspectRatio > 1 {
        newSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
    } else {
        newSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
    }

    let renderer = UIGraphicsImageRenderer(size: newSize)
    return renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: newSize))
    }
}
