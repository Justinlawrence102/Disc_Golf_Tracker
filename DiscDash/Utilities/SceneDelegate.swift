//
//  SceneDelegate.swift
//  OneDisc
//
//  Created by Justin Lawrence on 9/29/23.
//

import Foundation
import UIKit
import SwiftData

class FSSceneDelegate: NSObject, UIWindowSceneDelegate, ObservableObject {
    @Published var importedGame: SharedGame?
    
  func sceneWillEnterForeground(_ scene: UIScene) {
    // ...
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    // ...
  }

  func sceneWillResignActive(_ scene: UIScene) {
    // ...
  }
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = FSSceneDelegate.self // 👈🏻
        return sceneConfig
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
                        print("Try to decode as gmae....")
                        do {
                            let game = (try JSONDecoder().decode(SharedGame.self, from: data))
                            print(game.baskets.count)
                            print("Found data!")
//                            presentImportWizard = true
                            importedGame = game
//                            let context = ModelContext(PersistantData.container)
//                            
//                            _ = game.saveGame(context: context)
                        }catch {
                            print("could not decode data \(error)")
                        }
                    }
                }
            }
        }
    }
}
