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
    private var scoreResults: [ResultScores] = []
    @State var game: Game?
    @EnvironmentObject var stateManager: StateManager

    init(game: Game) {
        let gameId = game.uuid
        let scoresPredicate = #Predicate<PlayerScore> {
            $0.game?.uuid == gameId
        }
        do {
            let container = try ModelContainer(for: Game.self)
            let context = ModelContext(container)
            
            let descriptor = FetchDescriptor<PlayerScore>(predicate: scoresPredicate, sortBy: [SortDescriptor(\.player?.name)])
            let scores = try context.fetch(descriptor)
            var prevName = ""
            for score in scores {
                if let player = score.player, prevName != player.name {
                    scoreResults.append(ResultScores(player: player, totalScore: score.score, image: player.image, color: player.color))
                    prevName = player.name
                }else if scoreResults.indices.contains(scoreResults.count-1){
                    scoreResults[scoreResults.count-1].score += score.score
                }
            }
            scoreResults.sort(by: {$1.score > $0.score})
            
        }catch {
            print("Error")
        }
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
                    Text("End")
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
