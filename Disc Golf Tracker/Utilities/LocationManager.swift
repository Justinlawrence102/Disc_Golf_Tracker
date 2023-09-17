//
//  LocationManager.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 8/31/23.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let locationManager = CLLocationManager()
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var lastLocation: CLLocation?
    var locationContinuation: CheckedContinuation<CLLocation?, Error>?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestLocation()
//        locationManager.startUpdatingLocation()
    }
    
    func askPermission() {
        if locationManager.authorizationStatus == .notDetermined{
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func requestLocation() {
        if locationManager.authorizationStatus == .notDetermined{
            askPermission()
        }
//        Task {
//            let location = try await withCheckedThrowingContinuation { continuation in
//                locationContinuation = continuation
                locationManager.requestLocation()
//            }
//            self.lastLocation = location
//        }
//        locationManager.requestLocation()
    }
   
    
    var statusString: String {
        guard let status = locationStatus else {
            return "unknown"
        }
        
        switch status {
        case .notDetermined: return "notDetermined"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        case .authorizedAlways: return "authorizedAlways"
        case .restricted: return "restricted"
        case .denied: return "denied"
        default: return "unknown"
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatus = status
//        print(#function, statusString)
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed! \(error.localizedDescription)")
        // Handle failure to get a user’s location
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
//        print(#function, location)
    }
}
