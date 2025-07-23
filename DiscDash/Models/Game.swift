//
//  Game.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 8/29/23.
//

import Foundation
import SwiftData
import UIKit
import SwiftUI
import MapKit
//import GroupActivities

@Model
class Game {
    
    @Relationship(deleteRule: .noAction, inverse: \Course.games)
    var course: Course?
    
    @Relationship(deleteRule: .cascade)
    var playerScores: [PlayerScore]?
    
    var uuid: String = UUID().uuidString
    
    var startDate: Date = Date()
    var endDate: Date?
    var photo: Data?
    var currentHoleIndex: Int = 0
    
    @Relationship(deleteRule: .cascade)
    var results: [PlayerScore]?
    
    var players: [Player] {
        if let results = results {
            return results.map { $0.player ?? Player() }
        }
        return []
    }
    
//    @Transient
    var currentBasket: Basket? {
        if let course = course, course.sortedBaskets.indices.contains(currentHoleIndex) {
            return course.sortedBaskets[currentHoleIndex]
        }
        return nil
    }
    var formattedStartDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium //.long
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: startDate)

    }
    var gameDuration: String? {
        if let endDate = endDate {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.day, .hour, .minute]
            formatter.unitsStyle = .short
            return formatter.string(from: startDate, to: endDate)
        }
        return nil
    }
    init(id: String) {
        self.uuid = id
        startDate = Date()
    }
    init() {
        startDate = Date()
    }
    
    func createGame(course: Course, players: [Player], modelContext: ModelContext) {
        modelContext.insert(self)
        self.startDate = Date()
        self.playerScores = []
        
        course.games?.append(self)
        self.course = course
        
        for player in players {
            for basket in self.course?.baskets ?? [] {
                let playerScore = PlayerScore(player: player, game: self, basket: basket)
                modelContext.insert(playerScore)
            }
            let playerResult = PlayerScore(player: player, resultsGame: self)
            modelContext.insert(playerResult)
        }
        
    }
    func getImage()->UIImage? {
        if let gameImage = photo {
            return UIImage(data: gameImage)
        }else if let courseIamge = course?.image {
            return UIImage(data: courseIamge)
        }
        return nil
    }
    func markPlayerNotFinish(playerId: String) {
        if let resultPlayer = results?.firstIndex(where: {$0.player?.uuid == playerId}) {
            results?.remove(at: resultPlayer)
            calculateResults()
        }
    }
    
    
    func updateFromShareplay(sharedGame: SharedGame) {
        for playerScore in playerScores ?? [] {
            if let scoreBasket = sharedGame.baskets.first(where: {$0.basketId == playerScore.basket?.uuid}) {
                if let score = scoreBasket.playerScores.first(where: {$0.player.playerUuid == playerScore.player?.uuid}) {
                    playerScore.score = score.score
                    if playerScore.basket?.number == 2 && playerScore.player?.name == "Karen" {
                        print("New Score \(score.score)")
                    }
                }
            }
        }
        for basket in course?.baskets ?? []{
            if let sharedBasket = sharedGame.baskets.first(where: {$0.basketId == basket.uuid}) {
                basket.basketLatitudes = sharedBasket.basketsLatitudes
                basket.basketLongitudes = sharedBasket.basketsLongitudes
                basket.teeLatitudes = sharedBasket.teeLatitudes
                basket.teeLongitudes = sharedBasket.teeLongitudes
            }
        }
    }
    func calculateResults(context: ModelContext? = nil) {
    
        let gameId = self.uuid
        let scoresPredicate = #Predicate<PlayerScore> {
            $0.game?.uuid == gameId
        }
        
        do {
            var scores = [PlayerScore]()
            let descriptor = FetchDescriptor<PlayerScore>(predicate: scoresPredicate)
            
            if context == nil {
                let tempContext = ModelContext(PersistantData.container)
                scores = try tempContext.fetch(descriptor)
            }else {
                scores = try context!.fetch(descriptor)
            }
            //reset scores
            for resultsPlayer in results ?? [] {
                resultsPlayer.score = 0
            }
            
            for score in scores {
                if let player = score.player, score.basket != nil, let resultPlayer = results?.first(where: {$0.player?.uuid == player.uuid}) {
                    resultPlayer.score += score.score
                }
            }
        }catch {
            print("Could not create results")
        }
    }
    func resetScores() {
        results?.removeAll()
    }
    func getResults(limit3: Bool = false, forPlayer: String? = nil, context: ModelContext? = nil) -> [ResultScores] {
        //migrate data and create playerResult object
        if (results ?? []).isEmpty {
            if var legacyPlayers = playerScores?.map({ $0.player }) {
                legacyPlayers = Array(Set(legacyPlayers)).sorted(by: {$0?.name ?? "" < $1?.name ?? ""})
                for player in legacyPlayers {
                    if let player = player {
                        let playerResult = PlayerScore(player: player, resultsGame: self)
                        context?.insert(playerResult)
                    }
                }
                print("Running migration...this shouldn't happen often. Only once")
                calculateResults()
            }
        }
        
        if let forPlayer = forPlayer {
            if let results = results?.first(where: {$0.player?.uuid == forPlayer}), let player = results.player {
                return [ResultScores(player: player, totalScore: results.score, date: startDate)]
            }
        }

//        print("getting results \(results?.count ?? 0)")
        if var scoreResults = results?.map({
            ResultScores(player: $0.player ?? Player(), totalScore: $0.score, date: startDate)}) {
            scoreResults.sort(by: {$1.score > $0.score})
            if limit3 {
                scoreResults = Array(scoreResults.prefix(3))
            }
            for i in 0..<scoreResults.count {
                scoreResults[i].place = i+1
            }
            return scoreResults
        }
        return []
    }
}

@Model
class PlayerScore {
    
    @Relationship(deleteRule: .noAction)
    var player: Player?
        
    @Relationship(inverse: \Basket.playerScores)
    var basket: Basket?
    
    var score: Int = 0

    @Relationship(inverse: \Game.results)
    var resultsGame: Game?
    
    @Relationship(inverse: \Game.playerScores)
    var game: Game?
        
    var isBelowPar: Bool {
        if let basket = basket, let par = Int(basket.par) {
            return score < par
        }
        return false
    }
    var isAbovePar: Bool {
        if let basket = basket, let par = Int(basket.par) {
            return score > par
        }
        return false
    }
    
    init(player: Player, game: Game? = nil, resultsGame: Game? = nil, basket: Basket? = nil) {
        player.scores?.append(self)
        self.player = player
        
        if let game = game {
            game.playerScores?.append(self)
            self.game = game
        }
        if let resultsGame = resultsGame {
            resultsGame.playerScores?.append(self)
            self.resultsGame = resultsGame
        }
        if let basket = basket {
            basket.playerScores?.append(self)
            self.basket = basket
        }
    }
    func incrementScore(par: Int) {
        if score == 0 {
            score = par
        }else {
            score += 1
        }
        print("Increment in here?")
    }
    func decrementScore() {
        
        if score != 0 {
            score -= 1
        }
    }
//    func addPlayersToPlayerScore(player: Player) {
//        do {
//            let container =  try ModelContainer(for: Game.self)
//            let modelContext = ModelContext(container)
//            modelContext.insert(player)
//            self.player?.scores?.append(self)
//            self.player = player
//        }catch {
//            print("Error")
//            self.player = player
//        }
//    }
}


struct ResultScores: Identifiable {
    var id = UUID()
    
    let name: String
    var playerId: String
    var score: Int
//    var id: String { name }
    let image: Data?
    var color: String
    var place: Int?
    var date: Date
    
    var player: Player?
    
    var placeString: String {
        if let place = place {
            if place == 1 {
                return "\(place)st"
            }else if place == 2 {
                return "\(place)nd"
            }else if place == 3 {
                return "\(place)rd"
            }else {
                return "\(place)th"
            }
        }
        return ""
    }
    
    init(player: Player, totalScore: Int, date: Date) {
        self.name = player.name
        self.playerId = player.uuid
        self.score = totalScore
        self.image = player.image
        self.color = player.color
        self.date = date
        self.player = player
    }

    func getParDiff(course: Course?) -> String {
        var parTotal = 0
        for basket in course?.baskets ?? [] {
            parTotal += Int(basket.par) ?? 0
        }
        let parDiff = score - parTotal
        if parDiff > 0 {
            return "+\(parDiff)"
        }
        return String(parDiff)
    }
    func getColor()-> Color {
        return Color(UIColor(hex: color) ?? UIColor(named: "Pink")!)
    }
    var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium //.long
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)
    }
}
