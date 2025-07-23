//
//  ListAllGamesView.swift
//  OneDisc
//
//  Created by Justin Lawrence on 6/14/24.
//

import SwiftUI
import SwiftData
import _MapKit_SwiftUI

struct ListAllGamesView: View {
    @Query(sort: [SortDescriptor(\Game.startDate, order: .reverse)]) private var games: [Game]
    
    @State private var selectedGame: Game?
    var body: some View {
//        let _ = Self._printChanges()
        List(games) {
            game in
            Button(action: {
                selectedGame = game
            }, label: {
                GameRowView(game: game)
            })
        }
        .navigationDestination(item: $selectedGame, destination: { game in
            GameView(game: game, selectedGame: $selectedGame)
        })
    }
}

//#Preview {
//    ListAllGamesView()
//        .modelContainer(GamesPreviewContainer)
//}
