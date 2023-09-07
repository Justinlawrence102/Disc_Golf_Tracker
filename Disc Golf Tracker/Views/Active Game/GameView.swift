//
//  GameView.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 9/3/23.
//

import SwiftUI
import SwiftData
import MapKit

struct GameView: View {

//    @Query private var games: [Game]
//    var game: Game! { games.first }
    
    @State var game: Game
//    let game: Game

    @Query var scores: [PlayerScore]
    @State private var showingAddTeeAlert = false
    @State private var showingAddBasketAlert = false
//    @Environment (LocationManager.self) private var locationManager
//    @Environment var locationManager
    
    @EnvironmentObject var locationManager: LocationManager
    
    init(game: Game) {
//        let games = [game]
        let currentBasket = game.currentBasket?.number
        let gameUUID = game.uuid
        _scores = Query(filter: #Predicate<PlayerScore> {  $0.basket?.number  == currentBasket && $0.game?.uuid == gameUUID },
                        sort: \PlayerScore.player?.name)
        
        _game = .init(initialValue: game)
    }
    
    var body: some View {
        VStack {
            if let basket = game.currentBasket {
                VStack(alignment: .leading) {
                    if let number = basket.number {
                        Text("Hole \(number)")
                            .font(.headline)
                            .foregroundStyle(Color("Navy"))
                    }
                    Text("Par \(basket.par)")
                        .font(.caption)
                        .foregroundStyle(Color("Navy"))
                    Label("\(basket.distance) Yards", systemImage: "location.fill")
                        .font(.caption)
                        .foregroundStyle(Color("Teal"))
                    Map(position: $game.cameraPosition) {
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
                    .frame(height: 150)
                    .cornerRadius(12)
                    HStack{
                        Button(action: {
                            if basket.teeCoordinates.isEmpty {
                                basket.saveTeeLocation(holeNumber: game.currentHoleIndex, locationManager: locationManager)
                            }else {
                                showingAddTeeAlert.toggle()
                            }
                            print("Save Tee")
                        }, label: {
                            Label("Tee", systemImage: "mappin")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color("Teal"))
                                .foregroundStyle(Color.white)
                                .cornerRadius(20)
                        })
                        .alert("How could you like to add a new tee?", isPresented: $showingAddTeeAlert) {
                            Button("Add Tee") {
                                basket.saveTeeLocation(holeNumber: game.currentHoleIndex, locationManager: locationManager)
                            }
                            Button("Replace Exisiting Tees", role: .destructive) {
                                basket.teeLatitudes.removeAll()
                                basket.teeLongitudes.removeAll()
                                basket.saveTeeLocation(holeNumber: game.currentHoleIndex, locationManager: locationManager)
                            }
                            Button("Cancel", role: .cancel) { }
                        }
                        Spacer()
                        Button(action: {
                            print("Save Basket")
                            if basket.basketCoordinates.isEmpty {
                                basket.saveBasketLocation(holeNumber: game.currentHoleIndex, locationManager: locationManager)
                            }else {
                                showingAddBasketAlert.toggle()
                            }
                        }, label: {
                            Label("Basket", systemImage: "mappin")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color("Teal"))
                                .foregroundStyle(Color.white)
                                .cornerRadius(20)
                        })
                        .alert("How could you like to add a new basket?", isPresented: $showingAddBasketAlert) {
                            Button("Add Basket") {
                                basket.saveBasketLocation(holeNumber: game.currentHoleIndex, locationManager: locationManager)
                            }
                            Button("Replace Exisiting Baskets", role: .destructive) {
                                basket.basketLatitudes.removeAll()
                                basket.basketLongitudes.removeAll()
                                basket.saveBasketLocation(holeNumber: game.currentHoleIndex, locationManager: locationManager)
                            }
                            Button("Cancel", role: .cancel) { }
                        }
                    }
                }
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
                .padding(12)
            }
//            List(game.playerScores ?? []) {
            List(scores) {
                playerScore in
                HStack {
                    if let player = playerScore.player {
                        PlayerProfileCircleView(player: player, size: 53)
                        Text(player.name)
                            .font(.headline)
                            .foregroundStyle(Color("Navy"))
//                        Text(playerScore.game?.course?.name ?? "")
//                        Text(String(playerScore.basket?.number ?? 0))
                        Spacer()
                        Button(action: {
                            playerScore.score -= 1
                        }, label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                                .foregroundStyle(Color("Pink"))
                        })
                        .buttonStyle(.plain)
                        .disabled(playerScore.score == 0)
                        Text("\(playerScore.score)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .fontDesign(.rounded)
                            .foregroundStyle(Color("Navy"))

                        Button(action: {
                            if playerScore.score == 0, let currentBasket = game.currentBasket, let par = Int(currentBasket.par) {
                                playerScore.score = par
                            }else {
                                playerScore.score += 1
                            }
                            print("Increment")
                        }, label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundStyle(Color("Lime"))
                        })
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
            Spacer()
            ScrollView(.horizontal) {
                HStack {
                    ForEach(game.course?.sortedBaskets ?? []) {
                        basket in
                        if let number = basket.number {
                            Button(action: {
                                withAnimation(.easeInOut, {
                                    game.currentHoleIndex = number - 1
                                    game.updateMapCamera(locationManager: locationManager)
                                })
                            }, label: {
                                Text(String(number))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .fontDesign(.rounded)
                                    .foregroundStyle(game.currentHoleIndex + 1 == number ? Color.white : Color("Navy"))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 35)
                                    .background(game.currentHoleIndex + 1 == number ? Color("Teal") : game.currentHoleIndex < number ? Color(uiColor: .systemBackground) : Color("Lime"))
                                    .cornerRadius(12)
                            })
                        }
                    }
                    Button(action: {
                        game.currentHoleIndex = game.course?.baskets?.count ?? 0
                    }, label: {
                        Text("Results")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .fontDesign(.rounded)
                            .foregroundStyle(game.currentHoleIndex  == game.course?.baskets?.count ?? 0 ? Color.white : Color("Navy"))
                            .padding(8)
                            .background(game.currentHoleIndex == game.course?.baskets?.count ? Color("Teal") : Color(uiColor: .systemBackground))
                            .cornerRadius(12)
                    })
                }
            }
            .padding(8)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(12)
            .padding(12)
        }
        .navigationTitle(game.course?.name ?? "Course")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(){
            print("Inital set map")
            game.updateMapCamera(locationManager: locationManager)
        }
    }
}
//#Preview {
//    GameView(game: game)
//        .modelContainer(GamesPreviewContainer)
//}
