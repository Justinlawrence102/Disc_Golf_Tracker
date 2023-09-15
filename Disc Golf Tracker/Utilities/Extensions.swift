//
//  Extensions.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 9/13/23.
//

import Foundation
import UIKit
import SwiftUI
import MapKit

extension UIColor{
    convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        let start = hex.index(hex.startIndex, offsetBy: 0)
        let hexColor = String(hex[start...])
        
        if hexColor.count == 6 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            
            if scanner.scanHexInt64(&hexNumber) {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                b = CGFloat((hexNumber & 0x0000ff)) / 255
                a = 1.0
                self.init(red: r, green: g, blue: b, alpha: a)
                return
            }
        }
        return nil
    }
}

extension CLLocationCoordinate2D: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}

class Utilities {
    func getCenterOfCoordiantes(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
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
        
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), span: MKCoordinateSpan(latitudeDelta: CLLocationDegrees(floatLiteral: largestLat-smallestLat+0.001), longitudeDelta: CLLocationDegrees(floatLiteral: largestLong-smallestLong+0.001)))
    }
}

struct PlayerProfileCircleView: View {
    var player: Player
    var size: CGFloat
    var body: some View {
        if let playerImage = player.image, let image = UIImage(data: playerImage) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .background(player.getColor())
                .cornerRadius(size/2)
        }else {
            Image(systemName: "figure.disc.sports")
                .frame(width: size, height: size)
                .background(player.getColor())
                .cornerRadius(size/2)
                .foregroundStyle(Color("Teal"))
                .font(.title3)
        }
    }
}
