//
//  SharePlayActivity.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 9/10/23.
//

import Foundation
import GroupActivities
import SwiftUI
import SwiftData
import MapKit

struct SharePlayActivity: GroupActivity {
    static let activityIdentifier = "com.justinLawrence.discGolf.shareScoreCard"
    
    var metadata: GroupActivityMetadata {
        var meta = GroupActivityMetadata()
        meta.title = "Share Scorecard"
        meta.type = .generic
//        meta.previewImage =
        return meta
    }
}

class SharedActivityManager: ObservableObject {
    var tasks = Set<Task<Void, Never>>()
    var messenger: GroupSessionMessenger?
    var modelContext: ModelContext?
    @Published var gameModel: Game?
    @Published var isDeepLinkingToGame = false
//    @Published var gameSelectionPickerStatus = 0
    @Published var session: GroupSession<SharePlayActivity>?
    //    var test: Int {
    //
    //        return 0
    //    }
    
    @Published var numActiveParticipants = 0
    
    func startSharing(game: Game) {
        Task {
            do {
                DispatchQueue.main.async{
                    self.gameModel = game
                }
                _ = try await SharePlayActivity().activate()
            }catch {
                print("Unable to start SharePlay: \(error.localizedDescription)")
            }
        }
    }
    func configureGroupSession(_ session: GroupSession<SharePlayActivity>) { //, modelContext: ModelContext
        let messenger = GroupSessionMessenger(session: session)
        self.messenger = messenger
        let context = ModelContext(PersistantData.container)
        self.modelContext = context
        self.gameModel = nil //reset game model
        
        let task = Task {
            for await (sharePlayModel, _) in messenger.messages(of: SharedGame.self) {
                handle(sharePlayModel)
                //                DispatchQueue.main.async{
                //                    numActiveParticipants = session.activeParticipants.count
                //                }
                //                let event = GroupSessionEvent(originator: Participant, action: ., url: <#T##URL?#>)
                //                session.showNotice(<#T##event: GroupSessionEvent##GroupSessionEvent#>)
            }
        }
        tasks.insert(task)
        session.join()
        self.session = session
    }
    func addGameToSharedActivity(game: Game) {
        DispatchQueue.main.async{
            if self.gameModel == nil {
                self.gameModel = game
            }
        }
    }
    func handle(_ model: SharedGame) {
        //for some reason the view is 1 update behind, but when I delay the update, it works correctly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if self.gameModel == nil {
                print("Is nil...check if it exists and then navigate...otherwise create new game")
                if let context = self.modelContext {
                    do {
                        let gamePredicate = #Predicate<Game> {
                            $0.uuid == model.uuid
                        }
                        let descriptor = FetchDescriptor<Game>(predicate: gamePredicate)
                        let game = try context.fetch(descriptor)
                        if !game.isEmpty {
                            self.gameModel = game[0]
                            self.isDeepLinkingToGame = true
//                            self.gameSelectionPickerStatus = 1
                        }
                    }catch {
                        print("Error fetching current game")
                    }
                }else {
                    print("NO CONTEXT")
                }
            }
            if self.gameModel?.uuid != model.uuid { //self.gameModel?.uuid
                print("IN DIFFERENT GAME, NAVIGATE/MAKE NEW IF NEEDED!")
                if let context = self.modelContext {
                    _ = self.createGame(context: context, model: model)
                    //                    self.gameModel = newGame
                    //                    self.isDeepLinkingToGame = true
//                    self.gameSelectionPickerStatus = 1
                }
            }
            withAnimation {
                self.gameModel?.currentHoleIndex = model.currentBasketIndex
                self.gameModel?.updateFromShareplay(sharedGame: model)
//                self.gameModel?.updateMapCamera()
            }
        }
    }
    
    //    func send(_ model: Game) {
    func send(_ model: Game) {
        if let session = session, session.state == .joined {
            Task {
                do {
                    let sharedGame = SharedGame(game: model)
                    if sharedGame.uuid == self.gameModel?.uuid {
                        try await messenger?.send(sharedGame)
                    }else {
                        print("You're looking at the wrong game!")
                    }
                    //                messenger.info
                }catch {
                    print("Failed sending data: \(error)")
                }
            }
        }
    }
    func createGame(context: ModelContext, model: SharedGame) -> Game? {
        do {
            //check if you already have the game
            let gamePredicate = #Predicate<Game> {
                $0.uuid == model.uuid
            }
            let gameDescriptor = FetchDescriptor<Game>(predicate: gamePredicate)
            let testGame = try context.fetch(gameDescriptor)
            if !testGame.isEmpty {
                self.gameModel = testGame.first!
                return testGame.first!
            }
            
            //check if you already have the course
            let coursePredicate = #Predicate<Course> {
                $0.uuid == model.courseId
            }
            let descriptor = FetchDescriptor<Course>(predicate: coursePredicate)
            let testCourse = try context.fetch(descriptor)
            
            var course = Course()
            var needToSaveBaskets = false
            if testCourse.isEmpty || (testCourse.first?.baskets?.count != model.baskets.count){
                course = Course(name: model.courseName)
                course.isSharedGame = true
                course.uuid = model.courseId
                course.latitude = model.courseLatitude
                course.longitude = model.courseLongitude
                course.lookUpCurrentLocation() //get city/state
                course.baskets = []
                context.insert(course)
                needToSaveBaskets = true
            }else {
                course = testCourse.first!
            }
            
            let newGame = Game()
            newGame.uuid = model.uuid
            newGame.startDate = Date()
            newGame.isSharedGame = true
            newGame.course = course
            context.insert(newGame)

            var newBaskets = [Basket]()
            if needToSaveBaskets {
                for basket in model.baskets {
                    let newBasket = Basket(number: basket.number, course: course)
                    newBasket.par = basket.par
                    newBasket.distance = basket.distance
                    newBasket.uuid = basket.basketId
                    context.insert(newBasket)
                    newBaskets.append(newBasket)
                }
            }else {
                newBaskets = course.baskets ?? []
            }
            
            var newPlayers = [Player]()
            for player in model.players {
                let playerPredicate = #Predicate<Player> {
                    $0.uuid == player.playerUuid
                }
                let descriptor = FetchDescriptor<Player>(predicate: playerPredicate)
                let testPlayer = try context.fetch(descriptor)
                if testPlayer.isEmpty {
                    let newPlayer = Player(name: player.name, color: player.color)
                    newPlayer.uuid = player.playerUuid
                    //            newPlayer.image = player.image
                    newPlayer.isSharedPlayer = true
                    context.insert(newPlayer)
                    newPlayers.append(newPlayer)
                }else {
                    newPlayers.append(testPlayer.first!)
                }
            }
            
            for basket_ in newBaskets {
                for player_ in newPlayers {
                    let playerScore = PlayerScore(player: player_, game: newGame, basket: basket_)
                    let sharedBasket = model.baskets.first(where: {$0.basketId == basket_.uuid})
                    if let score = sharedBasket?.playerScores.first(where: {$0.player.playerUuid == player_.uuid}) {
                        playerScore.score = score.score
                    }
                    context.insert(playerScore)
                }
            }
            return newGame
        }catch { }
        return nil
    }
}
