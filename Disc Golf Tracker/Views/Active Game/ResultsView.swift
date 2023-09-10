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
    @Environment(\.dismiss) var dismiss

    //    @Query private var games: [Game]
    //    var game: Game! { games.first }
    
//        private let playerScores: [ResultScores] = []
    private var scoreResults: [ResultScores] = []
    @State var game: Game
    
    init(game: Game, context: ModelContext) {
        let gameId = game.uuid
        let scoresPredicate = #Predicate<PlayerScore> {
            $0.game?.uuid == gameId
        }
        do {
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
            //            _playerScores = .init(initialValue: scores)
            
        }catch {
            print("Error")
        }
        _game = .init(initialValue: game)
    }
    var body: some View {
        ZStack {
            VStack {
                Rectangle()
                    .padding(.top, -100.0)
                    .frame(height: 220)
                    .blur(radius: 20)
                    .foregroundStyle(Color("Lime_W_Dark"))
                Spacer()
            }
            ScrollView {
                VStack {
                    VStack {
                        ForEach(scoreResults) { score in
                            HStack {
                                PlayerProfileCircleView(player: Player(name: score.name, color: score.color, image: score.image), size: 35)
                                Text(score.name)
                                    .font(.headline)
                                    .foregroundStyle(Color("Navy"))
                                Spacer()
                                HStack(alignment: .bottom, spacing: 4) {
                                    Text(String(score.score))
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .fontDesign(.rounded)
                                        .foregroundStyle(Color("Teal"))
                                    Text(score.getParDiff(game: game))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .fontDesign(.rounded)
                                        .foregroundStyle(Color("Pink"))
                                }
                            }
                            .padding()
                        }
                        .background(.regularMaterial)
                        .cornerRadius(12)
                        .padding(.horizontal, 12)
                        .padding(.top, 100.0)
                        .listStyle(.plain)
                        Spacer()
                        
                        Button(action: {
                            print("Delete")
                            modelContext.delete(game)
                            dismiss.callAsFunction()
                        }, label: {
                            Label("Delete Game", systemImage: "trash.fill")
                                .foregroundColor(.white)
                                .frame(width: 350, height: 50)
                                .background(Color("Pink"))
                                .cornerRadius(12)
                        })
                        .padding(.top, 16)
                    }
                }
            }
        }
    }
}
//#Preview {
//    ResultsView()
//        .modelContainer(GamesPreviewContainer)
//}
