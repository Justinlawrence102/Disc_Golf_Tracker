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
                }
        }else {
            ResultsView(game: game)
                .navigationTitle("Results")
//                .environmentObject(stateManager)
        }

    }
}


struct BasketDetailsTabView: View {
    @State var game: Game
    @Query var scores: [PlayerScore]
    
    @Query private var basket: [Basket]
    var currentBasket: Basket! { basket.first }

    @EnvironmentObject var stateManager: StateManager

    init(game: Game, nextBasketNumber: Int) {
        let gameUUID = game.uuid
        let courseUUID = game.course?.uuid
        _scores = Query(filter: #Predicate<PlayerScore> {  $0.basket?.number  == nextBasketNumber && $0.game?.uuid == gameUUID },
                        sort: \PlayerScore.player?.name)
        
        _basket =  Query(filter: #Predicate<Basket> {  $0.number  == nextBasketNumber && $0.course?.uuid == courseUUID })
        _game = .init(initialValue: game)
        
        print("init")
    }
    
    var body: some View {
        TabView(selection: $stateManager.tabSelection) {
            //            let _ = Self._printChanges()
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
                            VStack {
                                if currentBasket.par != "" {
                                    Text("Par \(currentBasket.par)")
                                        .foregroundStyle(Color("Lime"))
                                        .font(.body)
                                }
                                if currentBasket.distance != "" {
                                    Text("\(currentBasket.distance) Yds")
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
            List(scores) { playerScore in
                HStack {
                    Text(playerScore.player?.name ?? "N/A")
                    Spacer()
                    Button(action: {
                        WKInterfaceDevice.current().play(.click)
                        playerScore.decrementScore()
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
                    Button(action: {
                        WKInterfaceDevice.current().play(.click)
                        WidgetCenter.shared.reloadTimelines(ofKind: "scoreCard-widget")
                        if let par = Int(currentBasket.par) {
                            playerScore.incrementScore(par: par)
                        }else {
                            playerScore.score += 1
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
            .tag(2)
            .containerBackground(for: .tabView, alignment: .center) {
                ZStack {
                    BasketMapView(basket: currentBasket, includeMarkers: false)

                    Rectangle()
                        .foregroundStyle(.ultraThinMaterial)
                }
            }
        }
        .tabViewStyle(.verticalPage)
        .onAppear {
            print("Appear?")
            currentBasket.updateMapCamera(zoom: 0.0001)
            WidgetCenter.shared.reloadTimelines(ofKind: "scoreCard-widget")
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
    var includeMarkers = true
    var body: some View {
        Map(position: $basket.cameraPosition) {
            if includeMarkers {
                ForEach(basket.teeCoordinates, id: \.self) {
                    teeCoordinate in
                    Marker("", systemImage: "star.square.fill", coordinate: teeCoordinate)
                        .tint(Color("Teal"))
                }
                ForEach(basket.basketCoordinates, id: \.self) {
                    basketCoordinate in
                    Marker("", systemImage: "arrow.up.bin.fill", coordinate: basketCoordinate)
                        .tint(Color("Pink"))
                }
                UserAnnotation()
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .moveDisabled(true)
        .scrollDisabled(true)
        .disabled(true)
    }
}
#Preview {
    ContentView()
        .modelContainer(GamesPreviewContainer)
}
