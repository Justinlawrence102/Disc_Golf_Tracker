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
//        var test2 = course.baskets?[currentHoleIndex].cameraPosition
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
            for basket in self.course?.baskets ?? [] {
                let playerScore = PlayerScore(player: player, game: self, basket: basket)
                modelContext.insert(playerScore)
            }
//            self.playerScores?.append(playerScore)
//            playerScore.game = self
            
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
    
    func updateMapCamera(locationManager: LocationManager) {
        //    var cameraPosition: MapCameraPosition {
        var coordinateRegion = MKCoordinateRegion()
        if let currentBasket = currentBasket {
            if !currentBasket.basketCoordinates.isEmpty || !currentBasket.teeCoordinates.isEmpty {
                coordinateRegion = getCenterOfCoordiantes(coordinates: currentBasket.basketCoordinates+currentBasket.teeCoordinates)
            }else if let currentLocation = locationManager.lastLocation?.coordinate {
                coordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: currentLocation.latitude, longitude: currentLocation.longitude), span: MKCoordinateSpan(latitudeDelta: CLLocationDegrees(floatLiteral: 0.001), longitudeDelta: CLLocationDegrees(floatLiteral: 0.001)))
            }else {
                coordinateRegion = course!.getInitailMapPosition()
                
            }
        }
        cameraPosition = .region(coordinateRegion)
        //        return .region(coordinateRegion)
        //    }
    }
    private func getCenterOfCoordiantes(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        var latitude = 0.0
        var longitude = 0.0
        
        var smallestLat = 1000.0
        var largestLat = -1000.0
        var smallestLong = 1000.0
        var largestLong = -1000.0
        for coordinate in coordinates {
            latitude += coordinate.latitude
            longitude += coordinate.longitude
            if coordinate.latitude > largestLat {
                largestLat = coordinate.latitude
            }else if coordinate.latitude < smallestLat {
                smallestLat = coordinate.latitude
            }
            
            if coordinate.longitude > largestLong {
                largestLong = coordinate.longitude
            }else if coordinate.longitude < smallestLong {
                smallestLong = coordinate.longitude
            }
        }
        latitude = latitude/Double(coordinates.count)
        longitude = longitude/Double(coordinates.count)
        
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), span: MKCoordinateSpan(latitudeDelta: CLLocationDegrees(floatLiteral: largestLat-smallestLat+0.0005), longitudeDelta: CLLocationDegrees(floatLiteral: largestLong-smallestLong+0.0005)))
    }
}

@Model
class PlayerScore {
    @Relationship(deleteRule: .noAction)
    var player: Player?
        
    @Relationship(inverse: \Basket.playerScores)
    var basket: Basket?
    
    var score: Int = 0
    
//    var scores: [Int] = []
    
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
