//
//  ResultsView.swift
//  Disc Golf Tracker Watch Watch App
//
//  Created by Justin Lawrence on 9/17/23.
//

import SwiftUI

//
//  BasketDetailsView.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 9/6/23.
//

import SwiftUI
import SwiftData

struct ResultsView: View {
    @Environment(\.modelContext) private var modelContext
    private var scoreResults: [ResultScores] = []
    @State var game: Game?
    @EnvironmentObject var stateManager: StateManager

    init(game: Game) {
        scoreResults = game.getResults(context: modelContext)
        _game = .init(initialValue: game)
    }
    
    var body: some View {
        List(scoreResults) {
            score in
            HStack {
                PlayerProfileCircleView(player: Player(name: score.name, color: score.color, image: score.image), size: 30)
                Text(score.name)
                    .font(.body)
                Spacer()
                HStack(alignment: .bottom, spacing: 4) {
                    Text(String(score.score))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .foregroundStyle(Color("Teal"))
                    if let game = game {
                        Text(score.getParDiff(game: game))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .fontDesign(.rounded)
                            .foregroundStyle(Color("Pink"))
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: {
                    stateManager.selectedGame = nil
                }, label: {
                    Image(systemName: "list.bullet")
                        .foregroundStyle(Color("Lime"))
                })
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(GamesPreviewContainer)
}
