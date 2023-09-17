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

struct BasketNavigationView: View {
    @State var game: Game
    var body: some View {
        if let currentBasket = game.currentBasket {
            BasketDetailsTabView(game: game)
                .navigationTitle("Hole \(currentBasket.number ?? -1)")
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button(action: {
                            WKInterfaceDevice.current().play(.start)
                            game.currentHoleIndex -= 1
                            withAnimation {
                                game.updateMapCamera(zoom: 0.0001)
                            }
                        }, label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(Color("Teal"))
                        })
                        .disabled(game.currentHoleIndex == 0 )
                        
                        Button(action: {
                            WKInterfaceDevice.current().play(.start)
                            game.currentHoleIndex += 1
                            withAnimation {
                                game.updateMapCamera(zoom: 0.0001)
                            }
                        }, label: {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color("Teal"))
                        })
                        
                    }
                }
                .onAppear {
                    game.updateMapCamera(zoom: 0.0001)
                }
        } else {
            ResultsView(game: game)
                .navigationTitle("Results")
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button(action: {
                            WKInterfaceDevice.current().play(.start)
                            if game.currentHoleIndex != 0 {
                                game.currentHoleIndex -= 1
                            }
                            game.updateMapCamera()
                        }, label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(Color("Teal"))
                        })
                        
                        Button(action: {}, label: {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color("Teal"))
                        })
                        .disabled(true)
                        
                    }
                }
        }
    }
}

struct BasketDetailsTabView: View {
    @State var game: Game
    @Query var scores: [PlayerScore]
        
    init(game: Game) {
        let currentBasket = game.currentBasket?.number
        let gameUUID = game.uuid
        _scores = Query(filter: #Predicate<PlayerScore> {  $0.basket?.number  == currentBasket && $0.game?.uuid == gameUUID },
                        sort: \PlayerScore.player?.name)
        _game = .init(initialValue: game)
    }
    
    var body: some View {
//        TabView(selection: .constant(tabSection), content:  {
        TabView {
            ZStack {
                Map(position: $game.cameraPosition) {
                    if let basket = game.currentBasket {
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
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        VStack {
                            if let currentBasket = game.currentBasket {
                                Text("Par \(currentBasket.par)")
                                    .foregroundStyle(Color("Pink"))
                                    .font(.body)
                                Text("\(currentBasket.distance) Yds")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
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
                        if let currentBasket = game.currentBasket, let par = Int(currentBasket.par) {
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
    }
}

#Preview {
    ContentView()
        .modelContainer(GamesPreviewContainer)
}
