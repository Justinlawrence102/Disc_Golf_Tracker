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
    
    @Relationship(deleteRule: .noAction)
    var course: Course?
    
    @Relationship(deleteRule: .cascade)
    var playerScores: [PlayerScore]?
    
    var uuid: String = UUID().uuidString
    
    var startDate: Date = Date()
    var endDate: Date?
    var photo: Data?
    var currentHoleIndex: Int = 0
    var isSharedGame: Bool = false
    
    @Transient
    var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion())
    
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
        
        self.course = course
        course.games?.append(self)
    
        for player in players {
            for basket in self.course?.baskets ?? [] {
                let playerScore = PlayerScore(player: player, game: self, basket: basket)
                modelContext.insert(playerScore)
            }
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
    
    func updateMapCamera(locationManager: LocationManager? = nil, zoom: Double = 0.001) {
        var coordinateRegion = MKCoordinateRegion()
        if let currentBasket = currentBasket {
            if !currentBasket.basketCoordinates.isEmpty || !currentBasket.teeCoordinates.isEmpty {
                coordinateRegion = Utilities().getCenterOfCoordiantes(coordinates: currentBasket.basketCoordinates+currentBasket.teeCoordinates)
            }else if let currentLocation = locationManager?.lastLocation?.coordinate {
                coordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: currentLocation.latitude, longitude: currentLocation.longitude), span: MKCoordinateSpan(latitudeDelta: CLLocationDegrees(floatLiteral: zoom), longitudeDelta: CLLocationDegrees(floatLiteral: zoom)))
            }else {
                coordinateRegion = course!.getInitailMapPosition()
                
            }
        }
        cameraPosition = .region(coordinateRegion)
    }
    
    func updateMapCamera(basketNumber: Int, locationManager: LocationManager? = nil, zoom: Double = 0.001) {
        var coordinateRegion = MKCoordinateRegion()
        if let currentBasket = course?.baskets?.first(where: {$0.number == basketNumber}) {
            if !currentBasket.basketCoordinates.isEmpty || !currentBasket.teeCoordinates.isEmpty {
                coordinateRegion = Utilities().getCenterOfCoordiantes(coordinates: currentBasket.basketCoordinates+currentBasket.teeCoordinates)
            }else if let currentLocation = locationManager?.lastLocation?.coordinate {
                coordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: currentLocation.latitude, longitude: currentLocation.longitude), span: MKCoordinateSpan(latitudeDelta: CLLocationDegrees(floatLiteral: zoom), longitudeDelta: CLLocationDegrees(floatLiteral: zoom)))
            }else {
                coordinateRegion = course!.getInitailMapPosition()
                
            }
        }
        cameraPosition = .region(coordinateRegion)
    }
    
    func updateFromShareplay(sharedGame: SharedGame) {
        for playerScore in playerScores ?? [] {
            if let scoreBasket = sharedGame.baskets.first(where: {$0.basketId == playerScore.basket?.uuid}) {
                if let score = scoreBasket.playerScores.first(where: {$0.player.playerUuid == playerScore.player?.uuid}) {
                    playerScore.score = score.score
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
}

@Model
class PlayerScore {
    
    @Relationship(deleteRule: .noAction)
    var player: Player?
        
    @Relationship(inverse: \Basket.playerScores)
    var basket: Basket?
    
    var score: Int = 0
        
    @Relationship(inverse: \Game.playerScores)
    var game: Game?
    
    init(player: Player, game: Game, basket: Basket) {
            player.scores?.append(self)
            self.player = player
            
            game.playerScores?.append(self)
            self.game = game
            
            basket.playerScores?.append(self)
            self.basket = basket
    }
    func incrementScore(par: Int) {
        if score == 0 {
            score = par
        }else {
            score += 1
        }
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
    let name: String
    var score: Int
    var id: String { name }
    let image: Data?
    var color: String
    
    init(player: Player, totalScore: Int, image: Data?, color: String) {
        self.name = player.name
        self.score = totalScore
        self.image = image
        self.color = color
    }
    func getParDiff(game: Game) -> String {
        var parTotal = 0
        for basket in game.course?.baskets ?? [] {
            parTotal += Int(basket.par) ?? 0
        }
        let parDiff = score - parTotal
        if parDiff > 0 {
            return "+\(parDiff)"
        }
        return String(parDiff)
    }
}
