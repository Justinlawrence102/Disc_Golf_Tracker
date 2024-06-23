//
//  ScoreSheetView.swift
//  OneDisc
//
//  Created by Justin Lawrence on 6/23/24.
//

import SwiftUI
import SwiftData


struct ScoreSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var game: Game
    
//    @Query  var games: [Game]
//    var game: Game {
//        return games.first!
//    }
//    init(game: Game) {
//        _games = Query(filter: #Predicate<Game> {$0.uuid == "1234"})
//    }
    
    var body: some View {
        VStack {
            Text(game.course?.name ?? "")
                .font(.headline)
                .foregroundStyle(Color("Navy"))
            Text(game.formattedStartDate)
                .font(.subheadline)
                .foregroundStyle(Color("Navy"))
                .padding(.bottom, 8)
            HStack(spacing: 12) {
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color("Pink"))
                        .frame(width: 20)
                    Text("Above Par")
                        .foregroundStyle(Color("Navy"))
                }
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color("Navy"))
                        .frame(width: 20)
                    Text("Par")
                        .foregroundStyle(Color("Navy"))
                }
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color("Lime"))
                        .frame(width: 20)
                    Text("Below Par")
                        .foregroundStyle(Color("Navy"))
                }
            }
            .padding(.trailing)
            .font(.caption)
            ScrollView([.horizontal, .vertical]) {
                Grid(verticalSpacing: 16) {
                    GridRow{
                        Text("")
                            .frame(width: 25)
                        Text("Par")
                            .foregroundStyle(Color("Pink"))
                            .frame(width: 40)
                        ForEach(game.players) {
                            player in
                            Text(player.name)
                                .lineLimit(1)
                                .font(.headline)
                                .foregroundStyle(Color("Navy"))
                                .frame(width: 60)
                        }
                        Spacer()
                    }
                    Divider()
                    if let playerScores = game.playerScores {
                        ForEach((game.course?.baskets ?? []).sorted(by: {$0.number ?? 0 < $1.number ?? 0})) {
                            basket in
                            GridRow {
                                Text(String(basket.number ?? 0))
                                    .font(.title3)
                                    .foregroundStyle(Color("Teal"))
                                    .frame(width: 25)
                                Text(basket.par)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 40)
                                ForEach(game.players) {
                                    player in
                                    ScoreCell(playerScores: playerScores, player: player, basket: basket)
                                        .frame(width: 60)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(.thinMaterial)
                .cornerRadius(12)
                .padding([.bottom, .horizontal])
            }
        }
        .padding(.top)
        .overlay(alignment: .topTrailing) {
            Button(action: {
                dismiss.callAsFunction()
            }, label: {
                ZStack {
                    Image(systemName: "xmark")
                }
                .frame(width: 33, height: 33)
                .background(Color.gray.opacity(0.2))
                .font(Font.callout.weight(.semibold))
                .foregroundStyle(Color.gray)
                .cornerRadius(20)
                .padding([.top, .trailing], 8)
            })
        }
    }
}

#Preview {
    ScoreSheetView(game: Game())
        .modelContainer(GamesPreviewContainer)
}

struct ScoreCell: View {
    let playerScores: [PlayerScore]
    let player: Player
    let basket: Basket
    var body: some View {
        if let score = playerScores.first(where: {$0.basket?.uuid == basket.uuid && $0.player?.uuid == player.uuid}) {
            if score.score != 0 {
                Text("\(score.score)")
                    .font(.headline)
                    .foregroundStyle(score.isAbovePar ? Color("Pink") : score.isBelowPar ? Color("Lime") : Color("Navy"))
            }else {
                Text("-")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
