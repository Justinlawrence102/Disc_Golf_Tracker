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

    var body: some View {
        List(games) {
            game in
            NavigationLink(destination: {
                NavigationLazyView(GameView(game: game))
            }, label: {
                GameRowView(game: game)

            })
        }
    }
}

#Preview {
    ListAllGamesView()
        .modelContainer(GamesPreviewContainer)
}
