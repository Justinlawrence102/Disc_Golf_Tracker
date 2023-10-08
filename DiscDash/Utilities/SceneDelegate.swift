//
//  SceneDelegate.swift
//  OneDisc
//
//  Created by Justin Lawrence on 9/29/23.
//

import Foundation
import UIKit
import SwiftData

class FSSceneDelegate: NSObject, UIWindowSceneDelegate {
  func sceneWillEnterForeground(_ scene: UIScene) {
    // ...
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    // ...
  }

  func sceneWillResignActive(_ scene: UIScene) {
    // ...
  }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        print("Opened via Share Sheet \(URLContexts.count)")
        if !URLContexts.isEmpty {
            if let item = URLContexts.first {
                if let data  = try? Data(contentsOf: item.url, options: .uncached) {
                    do {
                        var player = (try JSONDecoder().decode(Player.self, from: data))
                        print("Found data!")
                        print(player.name)
                        let context = ModelContext(PersistantData.container)
                        do {
                            let playerPredicate = #Predicate<Player> {
                                $0.uuid == player.uuid
                            }
                            let descriptor = FetchDescriptor<Player>(predicate: playerPredicate)
                            let player = try context.fetch(descriptor)
                            if !player.isEmpty {
                                print("We already have this player!")
                                return
                            }
                        }catch {
                            print("Error")
                        }
                        
                        let newPlayer = Player(name: player.name, color: player.color, image: player.image)
                        newPlayer.uuid = player.uuid
                        newPlayer.scores = []
                        context.insert(newPlayer)
                        print("Inserted Player!")
                        
                    }catch {
                        print("could not decode data \(error)")
                    }
                }
            }
        }
    }
}
