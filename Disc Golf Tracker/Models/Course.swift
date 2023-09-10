//
//  Course.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 8/24/23.
//

import Foundation
import SwiftData
import SwiftUI
import MapKit

@Model
class Course: Identifiable {
    var id: UUID = UUID()
    
//    @Attribute(.unique)
    var name: String = ""

    @Relationship(deleteRule: .cascade)
    var baskets: [Basket]? 
    
    var sortedBaskets: [Basket] {
        if let baskets = baskets {
            return baskets.sorted(by: {$1.number ?? 0 > $0.number ?? 0})
        }
        return []
    }
    
    @Relationship(inverse: \Game.course)
    var games: [Game]?
    
    @Attribute(.externalStorage)
    var image: Data?
    
    var latitude: Double?
    var longitude: Double?
    var cityState: String?


    var lastPlayedString: String {
        let games = games?.sorted(by: {$0.startDate > $1.startDate})
        if let mostRecentGame = games?.first?.formattedStartDate {
            return "Last Played \(mostRecentGame)"
        }
        return "Never Played"
    }
    
//    var distance: Double {
//        let userClLocation = locationManager.lastLocation?.coordinate
//        let userCoordinates = CLLocation(latitude: userClLocation?.latitude ?? 0.0, longitude: userClLocation?.longitude ?? 0.0)
//        let courseCoordinates = CLLocation(latitude: latitude ?? 0.0, longitude: longitude ?? 0.0)
//
//        let distanceKiloMeters = (userCoordinates.distance(from: courseCoordinates))/1000
//        return distanceKiloMeters*0.6213712
//    }
    
    init() {
        name = ""
    }
    
    init(name: String) {
        self.name = name
        baskets = []
        games = []
    }
    func getInitailMapPosition()->MKCoordinateRegion {
        if let latitude = latitude, let longitude = longitude {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), span: MKCoordinateSpan(latitudeDelta: CLLocationDegrees(floatLiteral: 0.01), longitudeDelta: CLLocationDegrees(floatLiteral: 0.01)))
        }
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 29, longitude: -82), span: MKCoordinateSpan(latitudeDelta: CLLocationDegrees(floatLiteral: 20), longitudeDelta: CLLocationDegrees(floatLiteral: 20)))
    }
    
    func getDistance(locationManager: LocationManager) ->Double {
        if let userClLocation = locationManager.lastLocation?.coordinate, let latitude = latitude, let longitude = longitude {
            let userCoordinates = CLLocation(latitude: userClLocation.latitude, longitude: userClLocation.longitude)
            let courseCoordinates = CLLocation(latitude: latitude, longitude: longitude)

            let distanceKiloMeters = (userCoordinates.distance(from: courseCoordinates))/1000
            return distanceKiloMeters*0.6213712
        }
        return 0
    }
    
    func lookUpCurrentLocation() {
        if let latitude = latitude, let longitude = longitude {
            let location = CLLocation(latitude: latitude, longitude: longitude)
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
                guard let placemarks = placemarks else {
                    print("Error:", error ?? "nil")
                    return
                }
                if let placemark = placemarks.first {
                    self.cityState = "\(placemark.locality ?? ""), \(placemark.administrativeArea ?? "")"
                }
            })
        }
    }
}

@Model
class Basket {
    @Relationship(inverse: \Course.baskets)
    var course: Course?
    
    @Relationship(deleteRule: .noAction)
    var playerScores: [PlayerScore]?
    
    //var uuid: UUID = UUID()
    var uuid: String = UUID().uuidString
    
    var number: Int?
    var par: String = ""
    var distance: String = ""
    
    var basketLatitudes: [Double] = []
    var basketLongitudes: [Double] = []
    
    var teeLatitudes: [Double] = []
    var teeLongitudes: [Double] = []
    
    var basketCoordinates: [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D]()
        for i in 0..<basketLatitudes.count {
            coordinates.append(CLLocationCoordinate2D(latitude: CLLocationDegrees(basketLatitudes[i]), longitude: CLLocationDegrees(basketLongitudes[i])))
        }
        return coordinates
    }
    
    var teeCoordinates: [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D]()
        for i in 0..<teeLatitudes.count {
            coordinates.append(CLLocationCoordinate2D(latitude: CLLocationDegrees(teeLatitudes[i]), longitude: CLLocationDegrees(teeLongitudes[i])))
        }
        return coordinates
    }
    
    init(number: Int, course: Course) {
        self.number = number
        par = ""
        distance = ""
        self.course = course
    }
    
    func saveTeeLocation(holeNumber: Int, locationManager: LocationManager) {
        locationManager.requestLocation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let currentLocation = locationManager.lastLocation?.coordinate {
                self.teeLatitudes.append(currentLocation.latitude)
                self.teeLongitudes.append(currentLocation.longitude)
            }
        }
    }
    
    func saveBasketLocation(holeNumber: Int, locationManager: LocationManager) {
        locationManager.requestLocation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let currentLocation = locationManager.lastLocation?.coordinate {
                self.basketLatitudes.append(currentLocation.latitude)
                self.basketLongitudes.append(currentLocation.longitude)
            }
        }
    }
    func getHighScore(modelContext: ModelContext) -> [String]? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium //.long
        dateFormatter.timeStyle = .none
        
        let uuid = self.uuid
        let scoresPredicate = #Predicate<PlayerScore> {
            $0.basket?.uuid == uuid && $0.score != 0
        }
        do {
            let descriptor = FetchDescriptor<PlayerScore>(predicate: scoresPredicate)
            let scores = try modelContext.fetch(descriptor)
            if scores.isEmpty {return nil}
            let sortedScores = scores.sorted(by: {$1.score > $0.score})
            let topScore = sortedScores.first?.score
            let scoreDate = sortedScores.first?.game?.startDate
            return [String(topScore ?? 0), dateFormatter.string(from: scoreDate ?? Date())]
        }catch {
            print("Error")
            return nil
        }
    }
    func getAverageScore(modelContext: ModelContext) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium //.long
        dateFormatter.timeStyle = .none
        
        let uuid = self.uuid
        let scoresPredicate = #Predicate<PlayerScore> {
            $0.basket?.uuid == uuid && $0.score != 0
        }
        do {
            let descriptor = FetchDescriptor<PlayerScore>(predicate: scoresPredicate)
            let scores = try modelContext.fetch(descriptor)
            if scores.isEmpty {return nil}
            var scoreSum = 0
            for score in scores {
                scoreSum += score.score
            }
            return String(format: "%.1f", Double(scoreSum)/Double(scores.count))
        }catch {
            print("Error")
            return nil
        }
    }
}
