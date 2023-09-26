//
//  Item.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 8/23/23.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Player {

    var uuid: String = UUID().uuidString
    
    var name: String = ""
    
    @Attribute(.externalStorage)
    var image: Data?
    var lastPlay: Date?
    var color: String = "C7F465"
    var isSharedGame: Bool = false
    
    @Relationship(deleteRule: .cascade, inverse: \PlayerScore.player)
    var scores: [PlayerScore]?
    
//    @Transient update doesn't propagate to view, so .ephemeral seems to be working instead https://developer.apple.com/forums/thread/731651
    
    @Attribute(.ephemeral) var isSelected: Bool = false
    
    var numBasketsPlayed: Int {
        do {
            let container = try ModelContainer(for: Game.self)
            let context = ModelContext(container)
            let playerID = self.uuid
            let scoresPredicate = #Predicate<PlayerScore> {
                $0.player?.uuid == playerID
            }
            let descriptor = FetchDescriptor<PlayerScore>(predicate: scoresPredicate)
            let scores = try context.fetch(descriptor)
            return scores.count
        }catch {
            print("Error getting baskets played")
        }
        return 0
    }
    
    var numGamesPlayed: Int {
        do {
            let container = try ModelContainer(for: Game.self)
            let context = ModelContext(container)
            let playerID = self.uuid
            let scoresPredicate = #Predicate<PlayerScore> {
                $0.player?.uuid == playerID
            }
            
            let descriptor = FetchDescriptor<PlayerScore>(predicate: scoresPredicate)
            let scores = try context.fetch(descriptor)
            let flattedByGame = scores.map({$0.game?.uuid})
            let unique = Array(Set(flattedByGame))
            return unique.count
        }catch {
            print("Error getting baskets played")
        }
        return 0
    }
    
    var coursesPlayed: [Course] {
        do {
            let container = try ModelContainer(for: Game.self)
            let context = ModelContext(container)
            let playerID = self.uuid
            let scoresPredicate = #Predicate<PlayerScore> {
                $0.player?.uuid == playerID
            }
            
            let descriptor = FetchDescriptor<PlayerScore>(predicate: scoresPredicate)
            let scores = try context.fetch(descriptor)
            let flattedByCourse = scores.map({$0.game?.course ?? Course()})
            let unique = Array(Set(flattedByCourse))
            return unique
        }catch {
            print("Error getting baskets played")
        }
        return []
    }
    
    var numThrows: Int {
        do {
            let container = try ModelContainer(for: Game.self)
            let context = ModelContext(container)
            let playerID = self.uuid
            let scoresPredicate = #Predicate<PlayerScore> {
                $0.player?.uuid == playerID
            }
            
            let descriptor = FetchDescriptor<PlayerScore>(predicate: scoresPredicate)
            let scores = try context.fetch(descriptor)
            var numThrows = 0
            for score in scores {
                numThrows += score.score
            }
            return numThrows
        }catch {
            print("Error getting baskets played")
        }
        return 0
    }
    
    var TopScorePerCourse: [TopRoundCourse] {
        var topGames = [TopRoundCourse]()
//        topGames.append(TopRoundCourse(courseName: "Test", date: Date(), score: 12))
//        topGames.append(TopRoundCourse(courseName: "Test2", date: Date(), score: 43))

        do {
            let container = try ModelContainer(for: Game.self)
            let context = ModelContext(container)
            let playerID = self.uuid
            let scoresPredicate = #Predicate<PlayerScore> {
                $0.player?.uuid == playerID
            }
            
            let descriptor = FetchDescriptor<PlayerScore>(predicate: scoresPredicate, sortBy: [SortDescriptor(\.game?.course?.uuid)])
            let scores = try context.fetch(descriptor)
            
            let flattedByGame = scores.map({$0.game ?? Game()})
            var allGames = Array(Set(flattedByGame))
            allGames = allGames.sorted(by: {$0.course?.uuid ?? "" > $1.course?.uuid ?? ""})
            
            
            var previousCourseUUID = ""
            
            for game in allGames {
                if game.course?.uuid != previousCourseUUID{
                    if let gameResult = game.getResults(forPlayer: self.uuid).first {
                        topGames.append(TopRoundCourse(courseName: game.course?.name ?? "", date: game.startDate, score: gameResult.score, image: game.course?.image))
                    }
                    previousCourseUUID = game.course?.uuid ?? ""
                }else if topGames.indices.contains(topGames.count-1), let gameResult = game.getResults(forPlayer: self.uuid).first, gameResult.score < topGames[topGames.count-1].score  {
                    topGames[topGames.count-1].score = gameResult.score
                }
            }

        }catch {
            print("Error getting baskets played")
        }
        
        return topGames
    }
    
    var scoreBreakdown: [ScoreBreakdown] {
        var scores = [ScoreBreakdown(diffFromPar: -2, title: "Eagles", number: 0, color: Color("Navy")), ScoreBreakdown(diffFromPar: -1, title: "Birdies", number: 0, color: Color("Teal")), ScoreBreakdown(diffFromPar: 0, title: "Par", number: 0, color: Color("Lime")), ScoreBreakdown(diffFromPar: 1, title: "Bogey", number: 0, color: Color("LightPink")), ScoreBreakdown(diffFromPar: 2, title: "Double Bogey", number: 0, color: Color("Pink")), ScoreBreakdown(diffFromPar: 3, title: "Triple Bogey", number: 0, color: Color.red)]
        do {
            let container = try ModelContainer(for: Game.self)
            let context = ModelContext(container)
            let playerID = self.uuid
            let scoresPredicate = #Predicate<PlayerScore> {
                $0.player?.uuid == playerID
            }
            let descriptor = FetchDescriptor<PlayerScore>(predicate: scoresPredicate)
            let playerScores = try context.fetch(descriptor)
            
            for score in playerScores {
                if let parStr = score.basket?.par, let par = Int(parStr){
                    let diffFromPar = score.score - par
                    if let index = scores.firstIndex(where: {$0.diffFromPar == diffFromPar}) {
                        scores[index].number += 1
                    }
                }
            }
        }catch {
            print("Error getting baskets played")
        }
        
        return scores
    }
    init() {
        name = ""
        color = "C7F465"
    }
    init(name: String, color: String) {
        self.name = name
        self.color = color
    }
    init(name: String, color: String, image: Data?) {
        self.name = name
        self.color = color
        self.image = image
    }
    
    func getColor()-> Color {
        return Color(UIColor(hex: color) ?? UIColor(named: "Pink")!)
    }
}

struct ScoreBreakdown: Identifiable {
    var id = UUID()
    var diffFromPar: Int
    var title: String
    var number: Int
    var color: Color
}

struct TopRoundCourse: Identifiable {
    var id = UUID()
    var courseName: String
    var date: Date
    var score: Int
    var image: Data?
    
    var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium //.long
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)

    }
}
