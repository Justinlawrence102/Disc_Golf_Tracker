//
//  MapManager.swift
//  OneDisc
//
//  Created by Justin Lawrence on 6/14/24.
//

import SwiftUI
import MapKit

@Observable class MapManager {
    var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion())

    
    func updateMapCamera(currentBasket: Basket?, locationManager: LocationManager? = nil, zoom: Double = 0.001) {
        var coordinateRegion = MKCoordinateRegion()
        if let currentBasket = currentBasket {
            if !currentBasket.basketCoordinates.isEmpty || !currentBasket.teeCoordinates.isEmpty {
                coordinateRegion = Utilities().getCenterOfCoordiantes(coordinates: currentBasket.basketCoordinatesWithOffset+currentBasket.teeCoordinatesWithOffset, zoom: zoom)
            }else if let currentLocation = locationManager?.lastLocation?.coordinate {
                coordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: currentLocation.latitude-0.0004, longitude: currentLocation.longitude), span: MKCoordinateSpan(latitudeDelta: CLLocationDegrees(floatLiteral: zoom), longitudeDelta: CLLocationDegrees(floatLiteral: zoom)))
            }else {
                if let course = currentBasket.course{
                    coordinateRegion = course.getInitailMapPosition()
                }
            }
        }
        print("Set camera Position here")
        cameraPosition = .region(coordinateRegion)
    }
    
    func updateMapCamera(basketNumber: Int, course: Course, locationManager: LocationManager? = nil, zoom: Double = 0.001) {
        var coordinateRegion = MKCoordinateRegion()
        if let currentBasket = course.baskets?.first(where: {$0.number == basketNumber}) {
            if !currentBasket.basketCoordinates.isEmpty || !currentBasket.teeCoordinates.isEmpty {
                coordinateRegion = Utilities().getCenterOfCoordiantes(coordinates: currentBasket.basketCoordinates+currentBasket.teeCoordinates, zoom: zoom)
            }else if let currentLocation = locationManager?.lastLocation?.coordinate {
                coordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: currentLocation.latitude, longitude: currentLocation.longitude), span: MKCoordinateSpan(latitudeDelta: CLLocationDegrees(floatLiteral: zoom), longitudeDelta: CLLocationDegrees(floatLiteral: zoom)))
            }else {
                coordinateRegion = course.getInitailMapPosition()
                
            }
        }
        print("Set camera Position below")
        cameraPosition = .region(coordinateRegion)
    }
    
}
