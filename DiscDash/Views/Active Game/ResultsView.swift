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
    @State var showDeleteGameAlert = false

    init(game: Game) {
        scoreResults = game.getResults()
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
                    VStack(spacing: 8) {
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
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            Divider()
                        }
                    }
                    .background(.regularMaterial)
                    .cornerRadius(12)
                    .padding(.horizontal, 12)
                    .padding(.top, 100.0)
                    .listStyle(.plain)
                    if let duration = game.gameDuration {
                        HStack {
                            Spacer()
                            Text(duration)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.trailing)
                        }
                    }
                    Spacer()
                    
                    Button(action: {
                        print("Delete")
                        showDeleteGameAlert.toggle()
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
        .alert("Delete Game", isPresented: $showDeleteGameAlert) {
            Button("Delete", role: .destructive) {
                let gameId = game.uuid
                do {
                    if game.isSharedGame, let course = game.course { //if it is a shared game, also delete the course!
                        let courseId = course.uuid
//                        try modelContext.delete(model: Course.self, where: #Predicate<Course> { $0.uuid == courseId}, includeSubclasses: false)
                        try modelContext.delete(model: Player.self, where: #Predicate<Player> { $0.isSharedPlayer}, includeSubclasses: false)
                    }
                    try modelContext.delete(model: Game.self, where: #Predicate<Game> { $0.uuid == gameId}, includeSubclasses: false)
                    dismiss.callAsFunction()
                }catch {
                    print("Could not delete!")
                }
            }
            Button("Cancel", role: .cancel) { }
        }message: {
            Text("Are you sure you want to delete this game from \(game.formattedStartDate)?")
        }
    }
}
//#Preview {
//    ResultsView()
//        .modelContainer(GamesPreviewContainer)
//}
