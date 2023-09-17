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

//If I don't use this and go straight to BasketDetailsTabView(), it recurisvly calls the init on that view any time the increment/decrement buttons are pressed. If I go through this temp view in the middle, it only calls init once
struct TempBasketView: View {
    var game: Game
    var nextBasketNumber: Int

    var body: some View {
        VStack {
            BasketDetailsTabView(game: game, nextBasketNumber: nextBasketNumber)
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
            let _ = Self._printChanges()
            Map(position: $game.cameraPosition) {
                ForEach(currentBasket.teeCoordinates, id: \.self) {
                    teeCoordinate in
                    Marker("", systemImage: "star.square.fill", coordinate: teeCoordinate)
                        .tint(Color("Teal"))
                }
                ForEach(currentBasket.basketCoordinates, id: \.self) {
                    basketCoordinate in
                    Marker("", systemImage: "arrow.up.bin.fill", coordinate: basketCoordinate)
                        .tint(Color("Pink"))
                }
                UserAnnotation()
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .moveDisabled(true)
            .scrollDisabled(true)
            .disabled(true)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    VStack {
                        Text("Par \(currentBasket.par)")
                            .foregroundStyle(Color("Pink"))
                            .font(.body)
                        Text("\(currentBasket.distance) Yds")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
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
                        if let par = Int(currentBasket.par) {
                            WKInterfaceDevice.current().play(.click)
                            playerScore.incrementScore(par: par)
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
                    Map(position: $game.cameraPosition)
                        .mapStyle(.standard(pointsOfInterest: .excludingAll))
                    
                    Rectangle()
                        .foregroundStyle(.ultraThinMaterial)
                }
            }
        }
        .tabViewStyle(.verticalPage)
        .onAppear {
            print("Appear?")
            game.updateMapCamera(basketNumber: currentBasket.number ?? 1, zoom: 0.0001)
        }
        .navigationTitle("Hole \(currentBasket.number ?? -1)")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink(destination: {
                    if let currNum = currentBasket.number, (game.course?.baskets ?? []).count >= currNum + 1 {
                        TempBasketView(game: game, nextBasketNumber: currNum + 1)
                            .environmentObject(stateManager)

                    }else {
                        ResultsView(game: game)
                            .navigationTitle("Results")
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

#Preview {
    ContentView()
        .modelContainer(GamesPreviewContainer)
}
