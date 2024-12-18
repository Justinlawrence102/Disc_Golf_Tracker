//
//  CoursesMapView.swift
//  OneDisc
//
//  Created by Justin Lawrence on 6/18/24.
//

import SwiftUI
import MapKit
import SwiftData

struct CoursesMapView: View {
//    @Query(filter: #Predicate<Basket> { $0.course != nil && $0.playerScores != nil}, sort: [SortDescriptor(\Basket.course?.uuid), SortDescriptor(\Basket.number)]) private var baskets: [Basket]
    @Query(sort: [SortDescriptor(\Basket.number)]) private var baskets: [Basket]

    
    @Query var courses: [Course]
    
    var body: some View {
        Map() {
            UserAnnotation()
            
            ForEach(courses) {
                course in
                if let coordiate = course.coordinate {
                    Marker(course.name, systemImage: "flag.fill", coordinate: coordiate)
                        .tint(Color("Lime"))
                }
            }
            
            ForEach(baskets) {
                hole in
                ForEach(hole.teeCoordinates, id: \.self) {
                    teeCoordinate in
                    Marker("", systemImage: "\(hole.number ?? 1).square.fill", coordinate: teeCoordinate)
                        .tint(Color("Teal"))
                    ForEach(hole.basketCoordinates, id: \.self) {
                        basketCoordiante in
                        MapPolyline(points: [MKMapPoint(basketCoordiante), MKMapPoint(teeCoordinate)])
                            .stroke(.tertiary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    }
                }
                ForEach(hole.basketCoordinates, id: \.self) {
                    basketCoordinate in
                    Marker("", systemImage: "arrow.up.bin.fill", coordinate: basketCoordinate)
                        .tint(Color("Pink"))
                }
//                if let index = baskets.firstIndex(of: hole), baskets.indices.contains(index+1){
//                    if let currentBasket = hole.basketCoordinates.first, let nextTee = baskets[index+1].teeCoordinates.first, hole.course?.uuid == baskets[index+1].course?.uuid {
//                        MapPolyline(points: [MKMapPoint(currentBasket), MKMapPoint(nextTee)])
//                            .stroke(.secondary, style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [3, 5]))
//                    }
//                }
            }
        }
    }
}

#Preview {
    CoursesMapView()
        .modelContainer(GamesPreviewContainer)
}
