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
    
//    @Attribute(.unique)
    var uuid: String = UUID().uuidString
    
//    @Attribute(.unique)
    var name: String = ""

    @Relationship(deleteRule: .cascade)
    var baskets:  [Basket]? 
    
    var sortedBaskets: [Basket] {
        if let baskets = baskets {
            return baskets.sorted(by: {$1.number ?? 0 > $0.number ?? 0})
        }
        return []
    }
    
    @Attribute(.externalStorage)
    var image: Data?
    
    var latitude: Double?
    var longitude: Double?
    var cityState: String?
    
    @Relationship(deleteRule: .cascade) // inverse: \Game.course deleteRule: .cascade,
    var games: [Game]?
    
    
    var coordinate: CLLocationCoordinate2D? {
        if let latitude = latitude, let longitude = longitude {
            return CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        }
        return nil
    }
    
    var lastPlayedString: String {
        let games = games?.sorted(by: {$0.startDate > $1.startDate})
        if let mostRecentGame = games?.first?.formattedStartDate {
            return "Last Played \(mostRecentGame)"
        }
        return "Never Played"
    }
    func getImage()->UIImage? {
        if let courseIamge = self.image {
            return UIImage(data: courseIamge)
        }
        return nil
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
    
    func getDistance(locationManager: LocationManager) ->Double? {
        if let userClLocation = locationManager.lastLocation?.coordinate, let latitude = latitude, let longitude = longitude {
            let userCoordinates = CLLocation(latitude: userClLocation.latitude, longitude: userClLocation.longitude)
            let courseCoordinates = CLLocation(latitude: latitude, longitude: longitude)

            let distanceKiloMeters = (userCoordinates.distance(from: courseCoordinates))/1000
            return distanceKiloMeters*0.6213712
        }
        return nil
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
    func getTopScores(modelContext: ModelContext) -> [ResultScores]?{
        var results = [ResultScores]()
        if let allGames = self.games {
            for game in allGames {
                results += game.getResults(context: modelContext)
            }
            results.sort(by: {$0.score < $1.score})
            return Array(results.prefix(5))
        }else {
            return nil
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
    
    @Transient
    var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion())
    
    var basketCoordinates: [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D]()
        for i in 0..<basketLatitudes.count {
            coordinates.append(CLLocationCoordinate2D(latitude: CLLocationDegrees(basketLatitudes[i]), longitude: CLLocationDegrees(basketLongitudes[i])))
        }
        return coordinates
    }
    
    var basketCoordinatesWithOffset: [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D]()
        for i in 0..<basketLatitudes.count {
            coordinates.append(CLLocationCoordinate2D(latitude: CLLocationDegrees(basketLatitudes[i]-0.0004), longitude: CLLocationDegrees(basketLongitudes[i])))
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
    
    var teeCoordinatesWithOffset: [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D]()
        for i in 0..<teeLatitudes.count {
            coordinates.append(CLLocationCoordinate2D(latitude: CLLocationDegrees(teeLatitudes[i]-0.0004), longitude: CLLocationDegrees(teeLongitudes[i])))
        }
        return coordinates
    }
    
    init(number: Int, course: Course) {
        self.number = number
        par = ""
        distance = ""
        self.course = course
        self.uuid = course.uuid+"_=\(number)"
    }
    
    func getHighScore(modelContext: ModelContext) -> [Any]? {
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
            if let player = sortedScores.first?.player {
                return [String(topScore ?? 0), dateFormatter.string(from: scoreDate ?? Date()), player]
            }
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
    func updateMapCamera(locationManager: LocationManager? = nil, zoom: Double = 0.001) {
        var coordinateRegion = MKCoordinateRegion()
        if !basketCoordinates.isEmpty || !teeCoordinates.isEmpty {
            coordinateRegion = Utilities().getCenterOfCoordiantes(coordinates: basketCoordinates+teeCoordinates, zoom: zoom)
        }else if let currentLocation = locationManager?.lastLocation?.coordinate {
            coordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: currentLocation.latitude, longitude: currentLocation.longitude), span: MKCoordinateSpan(latitudeDelta: CLLocationDegrees(floatLiteral: zoom), longitudeDelta: CLLocationDegrees(floatLiteral: zoom)))
        }else {
            coordinateRegion = course!.getInitailMapPosition()
            
        }
        cameraPosition = .region(coordinateRegion)
    }
}

class ImprtedCoursesResponse: Decodable {
    var courses: [ImportedCourses] = []
    
    enum CodingKeys: String, CodingKey {
        case courses = "courses"
    }
}

class ImportedCourses: Decodable, Identifiable {
    var uuid: String
    var name: String
    var city: String
    var state: String
    var numHoles: Int
    var latitude: Double
    var longitude: Double
    
    enum CodingKeys: String, CodingKey {
        case uuid = "uuid"
        case name = "name"
        case city = "city"
        case state = "state"
        case numHoles = "numHoles"
        case latitude = "latitude"
        case longitude = "longitude"
    }
    
    init(uuid: String, name: String, city: String, state: String, numHoles: Int, latitude: Double, longitude: Double) {
        self.uuid = uuid
        self.name = name
        self.city = city
        self.state = state
        self.numHoles = numHoles
        self.latitude = latitude
        self.longitude = longitude
    }
    
    func getDistance(locationManager: LocationManager) ->Double? {
        if let userClLocation = locationManager.lastLocation?.coordinate {
            let userCoordinates = CLLocation(latitude: userClLocation.latitude, longitude: userClLocation.longitude)
            let courseCoordinates = CLLocation(latitude: latitude, longitude: longitude)

            let distanceKiloMeters = (userCoordinates.distance(from: courseCoordinates))/1000
            return distanceKiloMeters*0.6213712
        }
        return nil
    }
    
    func saveNewCourse(modelContext: ModelContext)->Course {
        
        do {
            let coursesPredicate = #Predicate<Course> {
                $0.uuid == uuid
            }
            let descriptor = FetchDescriptor<Course>(predicate: coursesPredicate)
            let courses = try modelContext.fetch(descriptor)
            if !courses.isEmpty {
                return courses[0]
            }
        }catch {
            print("Error")
        }
    
        let newCourse = Course(name: name)
        newCourse.uuid = uuid
        newCourse.latitude = latitude
        newCourse.longitude = longitude
        newCourse.lookUpCurrentLocation()
        modelContext.insert(newCourse)
        newCourse.baskets = []
        for i in 0..<numHoles {
            let basket = Basket(number: i+1, course: newCourse)
            modelContext.insert(basket)
        }
        newCourse.games = []
        
        return newCourse
    }
}
