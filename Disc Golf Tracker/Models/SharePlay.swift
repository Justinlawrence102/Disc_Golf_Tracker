//
//  SharePlay.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 9/13/23.
//

import Foundation

struct SharedGame: Codable {
    var baskets: [SharedBasket]
    var currentBasketIndex: Int
    var uuid: String = UUID().uuidString
    var courseName: String
//    var courseImage: Data?
    
    var players: [SharedPlayer]
    
    init(game: Game) {
        baskets = []
        players = []
        for basket in game.course?.baskets ?? [] {
            var playerScore = [SharedPlayerScore]()
            for score in basket.playerScores ?? [] {
                if let player = score.player {
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
//        self.courseImage = game.course?.image
    }
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
//    var image: Data?
}
