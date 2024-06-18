//
//  SharePlay.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 9/13/23.
//

import Foundation
import SwiftUI
import SwiftData
import MapKit

class SharedGame: Codable, Identifiable {
//    var id = UUID()
    
    var id: String { return uuid }
    
    var baskets: [SharedBasket]
    var currentBasketIndex: Int
    var uuid: String = UUID().uuidString
    var courseId: String
    var courseName: String
    var newCourseFromImport: String?

    var courseLatitude: Double?
    var courseLongitude: Double?
    var startDate: Date?
    var endDate: Date?
    
    var formattedStartDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium //.long
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: startDate ?? Date())

    }
//    var courseImage: Data?
    
    var players: [SharedPlayer]
    
    init(courseId: String, courseName: String, players: [SharedPlayer]) {
        self.baskets = []
        self.courseId = courseId
        self.courseName = courseName
        courseLatitude = nil
        courseLongitude = nil
        startDate = Date()
        endDate = nil
        currentBasketIndex = 0
        self.players = players
    }
    init(game: Game) {
        baskets = []
        players = []
        for basket in game.course?.baskets ?? [] {
            var playerScore = [SharedPlayerScore]()
            for score in basket.playerScores ?? [] {
                if let player = score.player, game.uuid == score.game?.uuid {
                    playerScore.append(SharedPlayerScore(player: SharedPlayer(name: player.name, color: player.color, playerUuid: player.uuid), score: score.score))
                }
            }
            let sharedBasket = SharedBasket(number: basket.number ?? 0, par: basket.par, distance: basket.distance, basketId: basket.uuid, playerScores: playerScore, basketsLatitudes: basket.basketLatitudes, basketsLongitudes: basket.basketLongitudes, teeLatitudes: basket.teeLatitudes, teeLongitudes: basket.teeLongitudes)
            baskets.append(sharedBasket)
        }
        let uniquePlayers_ = (game.playerScores ?? []).map { $0.player }
        let uniquePlayers = Array(Set(uniquePlayers_))
        for player in uniquePlayers {
            if let player = player {
                players.append(SharedPlayer(name: player.name, color: player.color, playerUuid: player.uuid))//, image: player.image
            }
        }
        self.currentBasketIndex = game.currentHoleIndex
        self.uuid = game.uuid
        self.courseName = game.course?.name ?? "Shared Course"
        self.courseId = game.course?.uuid ?? UUID().uuidString
        self.courseLatitude = game.course?.latitude
        self.courseLongitude = game.course?.longitude
        self.startDate = game.startDate
        self.endDate = game.endDate
//        self.courseImage = game.course?.image
    }
    
    func changePlayerId(oldId: String, newId: String) {
        if let playerIndex = players.firstIndex(where: {$0.playerUuid == oldId}) {
            players[playerIndex].playerUuid = newId
        }
        
        for i in 0..<baskets.count {
            if let playerIndex = baskets[i].playerScores.firstIndex(where: {$0.player.playerUuid == oldId}) {
                baskets[i].playerScores[playerIndex].player.playerUuid = newId
            }
        }
    }
    
    func saveGame(context: ModelContext, existingGameModel: Game? = nil, completion: @escaping (Game?, Bool) -> ()){
        do {
            //check if you already have the game
            let gamePredicate = #Predicate<Game> {
                $0.uuid == self.uuid
            }
            let gameDescriptor = FetchDescriptor<Game>(predicate: gamePredicate)
            let testGame = try context.fetch(gameDescriptor)
            if !testGame.isEmpty {
//                existingGameModel = testGame.first!
                completion(testGame.first!, false)
                return
            }
            
            //check if you already have the course
            let coursePredicate = #Predicate<Course> {
                $0.uuid == self.courseId
            }
            let descriptor = FetchDescriptor<Course>(predicate: coursePredicate)
            let testCourse = try context.fetch(descriptor)
            
            var course = Course()
            var needToSaveBaskets = false
            if testCourse.isEmpty || (testCourse.first?.baskets?.count != self.baskets.count){
                course = Course(name: self.courseName)
                course.isSharedGame = true
                course.uuid = self.courseId
                course.latitude = self.courseLatitude
                course.longitude = self.courseLongitude
                course.lookUpCurrentLocation() //get city/state
                course.baskets = []
                context.insert(course)
                needToSaveBaskets = true
            }else {
                course = testCourse.first!
            }
            
            let newGame = Game()
            newGame.uuid = self.uuid
            newGame.startDate = Date()
            newGame.isSharedGame = true
            newGame.course = course
            newGame.startDate = startDate ?? Date()
            newGame.endDate = endDate
            context.insert(newGame)

            var newBaskets = [Basket]()
            if needToSaveBaskets {
                print("Saving Baskets...")
                for basket in self.baskets {
                    let newBasket = Basket(number: basket.number, course: course)
                    newBasket.par = basket.par
                    newBasket.distance = basket.distance
                    newBasket.uuid = basket.basketId
                    newBasket.teeLatitudes = basket.teeLatitudes
                    newBasket.teeLongitudes = basket.teeLongitudes
                    newBasket.basketLatitudes = basket.basketsLatitudes
                    newBasket.basketLongitudes = basket.basketsLongitudes
                    context.insert(newBasket)
                    newBaskets.append(newBasket)
                }
            }else {
                print("Already have baskets...")
                newBaskets = course.baskets ?? []
            }
            
            var newPlayers = [Player]()
            for player in self.players {
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
                    let sharedBasket = self.baskets.first(where: {$0.number == basket_.number})
                    if let score = sharedBasket?.playerScores.first(where: {$0.player.playerUuid == player_.uuid}) {
                        playerScore.score = score.score
                    }
                    context.insert(playerScore)
                }
            }
            completion(newGame, true)
            return
        }catch { }
        completion(nil, false)
        return
    }
}

extension SharedGame: Transferable {
    static  var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .game)
            .suggestedFileName { session in session.suggestedFileName }
    }
    var suggestedFileName: String { "\(courseName) on \(formattedStartDate).game" }
    
}
struct SharedBasket: Codable {
    var number: Int
    var par: String
    var distance: String
    var basketId: String
    var playerScores: [SharedPlayerScore]
    var basketsLatitudes: [Double]
    var basketsLongitudes: [Double]
    var teeLatitudes: [Double]
    var teeLongitudes: [Double]
    
}
struct SharedPlayerScore: Codable {
    var player: SharedPlayer
    var score: Int
}

struct SharedPlayer: Codable {
    var name: String
    var color: String
    var playerUuid: String = UUID().uuidString
    var newNameFromImport: String?
//    var image: Data?
}

