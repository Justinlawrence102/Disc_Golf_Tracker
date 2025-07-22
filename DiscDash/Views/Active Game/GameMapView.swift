//
//  GameMapView.swift
//  OneDisc
//
//  Created by Justin Lawrence on 7/22/25.
//

import SwiftUI
import MapKit

struct GameMapView: View {
    @Namespace private var mapScope
    @Environment(LocationManager.self) var locationManager

    @Binding var cameraPosition: MapCameraPosition
    var showFullMapToggle: Bool
    @State private var heading: Double = 0

    var sortedBasketsList: [Basket]
    var basket: Basket
    
    var body: some View {
        Map(position: $cameraPosition, scope: mapScope) {
            //                    Map(scope: mapScope) {
            //                    Map(position: $position) {
            if showFullMapToggle {
                ForEach(sortedBasketsList) {
                    hole in
                    ForEach(hole.teeCoordinates, id: \.self) {
                        teeCoordinate in
                        Marker("", systemImage: "\(hole.number ?? 1).square.fill", coordinate: teeCoordinate)
                            .tint(Color("Teal"))
                        ForEach(hole.basketCoordinates, id: \.self) {
                            basketCoordiante in
                            if let currentNumber = basket.number, let holeHumber = hole.number {
                                if currentNumber == holeHumber {
                                    MapPolyline(points: [MKMapPoint(basketCoordiante), MKMapPoint(teeCoordinate)])
                                        .stroke(Color("LightPink"), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                } else {
                                    MapPolyline(points: [MKMapPoint(basketCoordiante), MKMapPoint(teeCoordinate)])
                                        .stroke(.tertiary, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                }
                            }
                        }
                    }
                    ForEach(hole.basketCoordinates, id: \.self) {
                        basketCoordinate in
                        Marker("", systemImage: "arrow.up.bin.fill", coordinate: basketCoordinate)
                            .tint(Color("Pink"))
                    }
                    if let index = sortedBasketsList.firstIndex(of: hole), sortedBasketsList.indices.contains(index+1){
                        if let currentBasket = hole.basketCoordinates.first, let nextTee = sortedBasketsList[index+1].teeCoordinates.first {
                            MapPolyline(points: [MKMapPoint(currentBasket), MKMapPoint(nextTee)])
                                .stroke(.secondary, style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [3, 5]))
                        }
                    }
                }
            }else {
                ForEach(basket.teeCoordinates, id: \.self) {
                    teeCoordinate in
                    Marker("", systemImage: "\(basket.number ?? 1).square.fill", coordinate: teeCoordinate)
                        .tint(Color("Teal"))
                    ForEach(basket.basketCoordinates, id: \.self) {
                        basketCoordiante in
                        MapPolyline(points: [MKMapPoint(basketCoordiante), MKMapPoint(teeCoordinate)])
                            .stroke(Color("LightPink"), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    }
                }
                ForEach(basket.basketCoordinates, id: \.self) {
                    basketCoordinate in
                    Marker("", systemImage: "arrow.up.bin.fill", coordinate: basketCoordinate)
                        .tint(Color("Pink"))
                }
            }
            UserAnnotation(content: {
                CurrentLocationPinView(heading: $heading, locationManager: locationManager)
            })
            
        }
        .overlay(alignment: .bottomTrailing) {
            VStack {
                MapCompass(scope: mapScope)
                    .mapControlVisibility(.automatic)
                Spacer()
                    .frame(height: 110)
            }
            .padding(.trailing, 8)
        }
        .mapControlVisibility(.hidden)
        .onMapCameraChange(frequency: .continuous) { context in
            withAnimation {
                heading = context.camera.heading
            }
        }
        .mapScope(mapScope)
    }
}

struct GameMapView_Previews: PreviewProvider {

    static var previews: some View {
        @State var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion())
        GameMapView(cameraPosition: $cameraPosition, showFullMapToggle: false, sortedBasketsList: [Basket(number: 1, course: Course())], basket: Basket(number: 1, course: Course()))
                .environment(LocationManager())
    }
}
