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

    var body: some View {
        VStack {
            if let basket = game.currentBasket {
                VStack(alignment: .leading) {
                    Text("Hole \(basket.number)")
                        .font(.headline)
                        .foregroundStyle(Color("Navy"))
                    Text("Par \(basket.par)")
                        .font(.caption)
                        .foregroundStyle(Color("Navy"))
                    Label("\(basket.distance) Yards", systemImage: "location.fill")
                        .font(.caption)
                        .foregroundStyle(Color("Teal"))
//                    Map(shows)
                    Map() {
                        UserAnnotation()
                    }
                        .frame(height: 150)
                        .cornerRadius(12)
                    HStack{
                        Button(action: {
                            print("Save Tee")
                        }, label: {
                            Label("Tee", systemImage: "mappin")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color("Teal"))
                                .foregroundStyle(Color.white)
                                .cornerRadius(20)
                        })
                        Spacer()
                        Button(action: {
                            print("Save Tee")
                        }, label: {
                            Label("Basket", systemImage: "mappin")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color("Teal"))
                                .foregroundStyle(Color.white)
                                .cornerRadius(20)
                        })
                    }
                }
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
                .padding(12)
            }
            List(game.playerScores ?? []) {
                playerScore in
                HStack {
                    if let player = playerScore.player {
                        PlayerProfileCircleView(player: player, size: 53)
                        Text(player.name)
                            .font(.headline)
                            .foregroundStyle(Color("Navy"))
                        Spacer()
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color("Pink"))
                        Text("0")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .fontDesign(.rounded)
                            .foregroundStyle(Color("Navy"))

                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color("Lime"))
                        //                        //                    Text(String(playerScore.scores[game.currentHoleIndex]))
                    }
                }
            }
            .listStyle(.plain)
            Spacer()
            ScrollView(.horizontal) {
                HStack {
                    ForEach(game.course?.sortedBaskets ?? []) {
                        basket in
                        Button(action: {
                            game.currentHoleIndex = basket.number - 1
                        }, label: {
                            Text(String(basket.number))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .fontDesign(.rounded)
                                .foregroundStyle(game.currentHoleIndex + 1 == basket.number ? Color.white : Color("Navy"))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 35)
                                .background(game.currentHoleIndex + 1 == basket.number ? Color("Teal") : Color("Lime"))
                                .cornerRadius(12)
                        })
                    }
                }
            }
            .padding(8)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(12)
            .padding(12)
        }
    }
}
//#Preview {
//    GameView()
//        .modelContainer(GamesPreviewContainer)
//}
