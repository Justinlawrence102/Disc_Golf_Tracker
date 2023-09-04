//
//  Game.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 8/29/23.
//

import Foundation
import SwiftData
import UIKit

@Model
class Game {
    @Relationship(deleteRule: .noAction)
    var course: Course?
    
    @Relationship(deleteRule: .cascade)
    var playerScores: [PlayerScore]?
    
    @Attribute(.unique)
    var id: UUID = UUID()
    
    var startDate: Date
    var endDate: Date?
    var photo: Data?
    var currentHoleIndex: Int = 0
    
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
    init() {
        startDate = Date()
    }
    
//    init(sample: Bool) {
//        startDate = Date()
//        course = Course(name: "Sample Course")
//        let basket = Basket(number: 1, course: course!)
//        course?.baskets = []
//        course?.baskets?.append(basket)
//        let player = Player(name: "Player 1", color: "C7F465")
//        playerScores = []
//        playerScores?.append(PlayerScore(player: player))
//    }
    func createGame(course: Course, players: [Player], modelContext: ModelContext) {
        modelContext.insert(self)
//                    newGame.course = selectedCourse
//                    selectedCourse.games?.append(newGame)
        self.startDate = Date()
        self.playerScores = []
        
        self.course = course
        course.games?.append(self)
        

        
//            course.games?.append(self)
//            self.course = course
//            modelContext.insert(course)
        for player in players {
            let playerScore = PlayerScore(player: player)
            modelContext.insert(playerScore)
            self.playerScores?.append(playerScore)
            playerScore.game = self
//                modelContext.insert(playerScore)
////                playerScore.addPlayersToPlayerScore(player: player)
////                self.playerScores.append(playerScore)
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
}

@Model
class PlayerScore {
    @Relationship(deleteRule: .noAction)
    var player: Player?
    
//    var name: String
    
    var scores: [Int] = []
    
    @Relationship(inverse: \Game.playerScores)
    var game: Game?
    
    init(player: Player) {
        player.scores?.append(self)
        self.player = player
//        self.name = name
//        self.game = game
       // player = Player()
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
