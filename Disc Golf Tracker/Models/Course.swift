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
    
    @Attribute(.unique)
    var name: String
    
    @Relationship(deleteRule: .cascade)
    var baskets: [Basket]? 
    
    @Relationship(inverse: \Game.course)
    var games: [Game]?
    
    var latitude: Double?
    var longitude: Double?
    var image: Data?
    var cityState: String?
    
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
    
//    func lookUpCurrentLocation(completionHandler: @escaping (String?) -> Void ) {
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
//                    completionHandler("\(placemark.locality ?? ""), \(placemark.administrativeArea ?? "")")
                }
//                completionHandler(nil)
            })
        }else {
//            completionHandler(nil)
        }
    }
}

@Model
class Basket {
//    @Relationship(deleteRule: .nullify, inverse: \Course.holes)
    @Relationship(inverse: \Course.baskets)
    var course: Course?
    
    @Attribute(.unique)
    var id: UUID = UUID()
    
    var number: Int
    var par: String
    var distance: String
    
    init(number: Int, course: Course) {
        self.number = number
        par = ""
        distance = ""
        self.course = course
    }
}
