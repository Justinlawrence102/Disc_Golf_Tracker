//
//  Item.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 8/23/23.
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

@Model
final class Player: Codable {
    
    var uuid: String = UUID().uuidString
    
    var name: String = ""
    
    @Attribute(.externalStorage)
    var image: Data?
    var lastPlay: Date?
    var color: String = "C7F465"
    var isSharedPlayer: Bool = false
    
    @Relationship(deleteRule: .cascade, inverse: \PlayerScore.player)
    var scores: [PlayerScore]?
    
//    @Transient update doesn't propagate to view, so .ephemeral seems to be working instead https://developer.apple.com/forums/thread/731651
    
    @Attribute(.ephemeral) var isSelected: Bool = false
    
    enum CodingKeys: CodingKey {
        case uuid, name, color, image
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decode(String.self, forKey: .uuid)
        name = try container.decode(String.self, forKey: .name)
        color = try container.decode(String.self, forKey: .color)
        image = try container.decode(Data.self, forKey: .image)


    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(color, forKey: .color)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(name, forKey: .name)
        try container.encode(image, forKey: .image)
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
    func getNumGames() -> Int {
        let gameIDs = (scores ?? []).map { $0.game?.id }
        let uniqueGames = Array(Set(gameIDs))
        return uniqueGames.count
    }
}
extension Player: Transferable {
    static  var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .player)
    }
//    static  var transferRepresentation: some TransferRepresentation {
//        CodableRepresentation(contentType: .commaSeparatedText) {
//            archive in
//            try archive.convertToCSV()
//        } importing { data in
//            try Player(c)
//        }
//    }
}
extension UTType {
    static var player: UTType =
    {
        UTType(exportedAs: "com.justinlawrence.discDash.player")
    }()
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

@Observable class PlayerStats {
    
    var player: Player

    var statFilter: StatFilter = .lifetime
    
    var startDateFilter: Date {
        switch statFilter{
        case .today:
            return Calendar.current.startOfDay(for: Date())
        case .lastMonth:
            return Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        case .thisYear:
            return Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        default:
            return Date.distantPast
        }
    }
    var endDateFilter: Date {
        switch statFilter{
        case .today:
            return Date()
        default:
            return Date.distantFuture
        }
    }
    var numBasketsPlayed = 0
    var numGamesPlayed = 0
    var coursesPlayed = [Course]()
    var numThrows = 0
    var TopScoresPerCourse = [TopRoundCourse]()
    var scoreBreakdown = [ScoreBreakdown]()
    
    init(player: Player) {
        self.player = player
//        reloadFilter()
    }
    
    func reloadFilter(modelContext: ModelContext) {
        do {
            let playerID = player.uuid
            let scoresPredicate = #Predicate<PlayerScore> {
                $0.player?.uuid == playerID
            }
            let descriptor = FetchDescriptor<PlayerScore>(predicate: scoresPredicate)
            var scores = try modelContext.fetch(descriptor)
            scores = scores.filter({$0.game?.startDate ?? Date() > startDateFilter && $0.game?.startDate ?? Date() <= endDateFilter})
            
            numBasketsPlayed = scores.count
            
            let flattedByGameId = scores.map({$0.game?.uuid})
            let uniqueGamesIds = Array(Set(flattedByGameId))
            numGamesPlayed = uniqueGamesIds.count
            
            let flattedByCourse = scores.map({$0.game?.course ?? Course()})
            let uniqueCourses = Array(Set(flattedByCourse))
            coursesPlayed = uniqueCourses
            
            var numThrows = 0
            for score in scores {
                numThrows += score.score
            }
            self.numThrows = numThrows
            
            let flattedByGame = scores.map({$0.game ?? Game()})
            var allGames = Array(Set(flattedByGame))
            allGames = allGames.sorted(by: {$0.course?.uuid ?? "" > $1.course?.uuid ?? ""})
            
            var topGames = [TopRoundCourse]()
            var previousCourseUUID = ""
            for game in allGames {
                if game.course?.uuid != previousCourseUUID{
                    if let gameResult = game.getResults(forPlayer: player.uuid, context: modelContext).first {
                        topGames.append(TopRoundCourse(courseName: game.course?.name ?? "", date: game.startDate, score: gameResult.score, image: game.course?.image))
                    }
                    previousCourseUUID = game.course?.uuid ?? ""
                }else if topGames.indices.contains(topGames.count-1), let gameResult = game.getResults(forPlayer: player.uuid, context: modelContext).first, gameResult.score < topGames[topGames.count-1].score  {
                    topGames[topGames.count-1].score = gameResult.score
                }
            }
            TopScoresPerCourse = topGames
            
            var returnedStats = [ScoreBreakdown(diffFromPar: -2, title: "Eagles", number: 0, color: Color("Navy")), ScoreBreakdown(diffFromPar: -1, title: "Birdies", number: 0, color: Color("Teal")), ScoreBreakdown(diffFromPar: 0, title: "Par", number: 0, color: Color("Lime")), ScoreBreakdown(diffFromPar: 1, title: "Bogey", number: 0, color: Color("LightPink")), ScoreBreakdown(diffFromPar: 2, title: "Double Bogey", number: 0, color: Color("Pink")), ScoreBreakdown(diffFromPar: 3, title: "Triple Bogey", number: 0, color: Color.red)]
            for score in scores {
                if let parStr = score.basket?.par, let par = Int(parStr){
                    let diffFromPar = score.score - par
                    if let index = returnedStats.firstIndex(where: {$0.diffFromPar == diffFromPar}) {
                        returnedStats[index].number += 1
                    }
                }
            }
            scoreBreakdown = returnedStats
        }catch {
            print("Error getting baskets played")
        }
    }
}
enum StatFilter {
    case lifetime
    case today
    case lastMonth
    case thisYear
}
