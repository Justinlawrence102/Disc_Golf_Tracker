//
//  GameView.swift
//  Disc Golf Tracker Watch Watch App
//
//  Created by Justin Lawrence on 9/14/23.
//

import Foundation
import SwiftUI
import SwiftData
import MapKit
import WidgetKit

//If I don't use this and go straight to BasketDetailsTabView(), it recurisvly calls the init on that view any time the increment/decrement buttons are pressed. If I go through this temp view in the middle, it only calls init once
struct GoToNextBasketView: View {
    var game: Game
    var nextBasketNumber: Int

    var body: some View {
        if (game.course?.baskets ?? []).count >= nextBasketNumber {
            BasketDetailsTabView(game: game, nextBasketNumber: nextBasketNumber)
                .onAppear {
                    game.currentHoleIndex = nextBasketNumber - 1
                    WidgetCenter.shared.reloadTimelines(ofKind: "scoreCard-widget")
                    print("Up here on appear")
                }
        }else {
            ResultsView(game: game)
                .navigationTitle("Results")
                .onAppear {
                    if game.endDate == nil {
                        game.endDate = Date()
                    }
                }
//                .environmentObject(stateManager)
        }

    }
}


struct BasketDetailsTabView: View {
    @State var game: Game
    @Query var scores: [PlayerScore]
    
    @Query private var basket: [Basket]
    var currentBasket: Basket! { basket.first }
    @State private var isAnimateCountDown = false

    @EnvironmentObject var stateManager: StateManager

    init(game: Game, nextBasketNumber: Int) {
        let gameUUID = game.uuid
        let courseUUID = game.course?.uuid
        _scores = Query(filter: #Predicate<PlayerScore> {  $0.basket?.number  == nextBasketNumber && $0.game?.uuid == gameUUID })
        
        _basket =  Query(filter: #Predicate<Basket> {  $0.number  == nextBasketNumber && $0.course?.uuid == courseUUID })
        _game = .init(initialValue: game)
    }
    
    var body: some View {
        TabView(selection: $stateManager.tabSelection) {
            //            let _ = Self._printChanges()
            if (!currentBasket.basketCoordinates.isEmpty && !currentBasket.teeCoordinates.isEmpty) {
                BasketMapView(basket: currentBasket)
                    .toolbar {
                        ToolbarItemGroup(placement: .bottomBar) {
                            if currentBasket.number != 1 {
                                Button {
                                    print("Go back")
                                    stateManager.selectedGame = nil
                                } label: {
                                    Image(systemName: "list.bullet")
                                        .foregroundStyle(Color("Lime"))
                                }
                            }else {
                                Spacer()
                            }
                            if currentBasket.par != "" || currentBasket.distance != "" {
                                VStack(spacing: 0) {
                                    if currentBasket.par != "" {
                                        Text("Par \(currentBasket.par)")
                                            .foregroundStyle(Color("Pink"))
                                            .font(.body)
                                    }
                                    if currentBasket.distance != "" {
                                        Text("\(currentBasket.distance) Ft")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.secondary)
                                    }
                                }
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(20)
                                .padding(.bottom, 8)
                            }else {
                                Spacer()
                            }
                        }
                    }
                    .tag(1)
            }
            List {
                if currentBasket.par != "" || currentBasket.distance != "" {
                    HStack {
                        if (currentBasket.par != "") {
                            VStack(alignment: .leading) {
                                Text(currentBasket.par)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Color("Pink"))
                                Text("Par")
                            }
                        }
                        Spacer()
                        if (currentBasket.distance != "") {
                            VStack(alignment: .leading) {
                                Text("\(currentBasket.distance) ft")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Color("Pink"))
                                Text("Distance")
                            }
                        }
                    }
                }
                ForEach(scores.sorted(by: {$1.player?.name ?? "" > $0.player?.name ?? ""})) { playerScore in
                    HStack {
                        Text(playerScore.player?.name ?? "N/A")
                        Spacer()
                        Button(action: {
                            WKInterfaceDevice.current().play(.click)
                            isAnimateCountDown = true
                            withAnimation {
                                playerScore.decrementScore()
                            }
                            WidgetCenter.shared.reloadTimelines(ofKind: "scoreCard-widget")
                        }, label: {
                            ZStack {
                                Rectangle()
                                    .foregroundStyle(.ultraThinMaterial)
                                    .cornerRadius(17.5)
                                Image(systemName: "minus")
                                    .foregroundStyle(Color("Pink"))
                                    .font(.system(size: 15))
                                    .fontWeight(.semibold)
                            }
                            .frame(width: 35, height: 35)
                        })
                        .buttonStyle(.plain)
                        .disabled(playerScore.score == 0)
                        Text(String(playerScore.score))
                            .fontDesign(.rounded)
                            .fontWeight(.semibold)
                            .contentTransition(.numericText(countsDown: isAnimateCountDown))
                        Button(action: {
                            WKInterfaceDevice.current().play(.click)
                            WidgetCenter.shared.reloadTimelines(ofKind: "scoreCard-widget")
                            isAnimateCountDown = false
                            withAnimation {
                                if let par = Int(currentBasket.par) {
                                    playerScore.incrementScore(par: par)
                                }else {
                                    playerScore.score += 1
                                }
                            }
                            
                        }, label: {
                            ZStack {
                                Rectangle()
                                    .foregroundStyle(.ultraThinMaterial)
                                    .cornerRadius(17.5)
                                Image(systemName: "plus")
                                    .foregroundStyle(Color("Lime"))
                                    .font(.system(size: 15))
                                    .fontWeight(.semibold)
                            }
                            .frame(width: 35, height: 35)
                        })
                        .buttonStyle(.plain)
                    }
                }
            }
            .tag(2)
            .containerBackground(for: .tabView, alignment: .center) {
                Rectangle()
                    .foregroundStyle(Gradient(colors: [Color("Teal").opacity(0.5), Color("Teal").opacity(0)]))
                
                //                ZStack {
                //                    BasketMapView(basket: currentBasket, includeMarkers: false)
                //
                //                    Rectangle()
                //                        .foregroundStyle(.ultraThinMaterial)
                //                }
            }
        }
        .tabViewStyle(.verticalPage)
        .onAppear {
            print("Appear?")
            currentBasket.updateMapCamera(zoom: 0.0005)
        }
        .navigationTitle("Hole \(currentBasket.number ?? -1)")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink(destination: {
                    if let currNum = currentBasket.number{
                        GoToNextBasketView(game: game, nextBasketNumber: currNum + 1)
                            .environmentObject(stateManager)

                    }
                }, label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color("Teal"))
                })
            }
        }
    }
}

struct BasketMapView: View {
    @State var basket: Basket
    @State private var heading: Double = 0
    @Environment(LocationManager.self) var locationManager

    var includeMarkers = true
    var body: some View {
        Map(position: $basket.cameraPosition) {
            if includeMarkers {
                ForEach(basket.teeCoordinates, id: \.self) {
                    teeCoordinate in
                    Marker("", systemImage: "\(basket.number ?? 0).square.fill", coordinate: teeCoordinate)
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
                UserAnnotation(content: {
                    CurrentLocationPinView(heading: $heading, locationManager: locationManager)
                })
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .onMapCameraChange(frequency: .continuous) { context in
            withAnimation {
                heading = context.camera.heading
            }
        }
        .moveDisabled(true)
        .scrollDisabled(true)
        .disabled(true)
        .onAppear{
            if includeMarkers {
                print("Start heading")
                locationManager.startTrackingHeading()
            }
        }
        .onDisappear {
            if includeMarkers {
                print("Stop heading")
                locationManager.stopTrackingHeading()
            }
        }
    }
}
#Preview {
    ContentView()
        .modelContainer(GamesPreviewContainer)
        .environment(LocationManager())
}
