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
    @State private var scoreResults: [ResultScores] = []
    @State var game: Game
    @State var showDeleteGameAlert = false
    @State var showScoresheet = false

    init(game: Game) {
        _game = .init(initialValue: game)
    }
    var body: some View {
        ZStack {
            VStack {
                Rectangle()
                    .padding(.top, -100.0)
                    .frame(height: 220)
//                    .blur(radius: 20)
                    .foregroundStyle(Gradient(colors: [Color("Lime_W_Dark"), Color("Lime_W_Dark").opacity(0)]))
                Spacer()
            }
            VStack(spacing: 12) {
                ScrollView {
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
                                    Text(score.getParDiff(course: game.course))
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
                    Button(action: {
                        print("Score Sheet")
                        showScoresheet.toggle()
                    }, label: {
                        Label("Score Sheet", systemImage: "rectangle.and.pencil.and.ellipsis")
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color("Teal"))
                            .cornerRadius(12)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal)
                    })
                }
                ShareLink(item: SharedGame(game: game), preview: SharePreview("\(game.course?.name ?? "") on \(game.formattedStartDate)")) {
                    Label("Share", systemImage: "square.and.arrow.up.fill")
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color("Teal"))
                        .padding(.horizontal)
                }
                
                Button(action: {
                    print("Delete")
                    showDeleteGameAlert.toggle()
                }, label: {
                    Label("Delete Game", systemImage: "trash.fill")
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                })
            }
        }
        .onAppear {
            scoreResults = game.getResults(context: modelContext)
        }
        .alert("Delete Game", isPresented: $showDeleteGameAlert) {
            Button("Delete", role: .destructive) {
                let gameId = game.uuid
                do {
//                    if game.isSharedGame, let course = game.course { //if it is a shared game, also delete the course!
//                        let courseId = course.uuid
////                        try modelContext.delete(model: Course.self, where: #Predicate<Course> { $0.uuid == courseId}, includeSubclasses: false)
////                        try modelContext.delete(model: Player.self, where: #Predicate<Player> { $0.isSharedPlayer}, includeSubclasses: false)
//                    }
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
        .sheet(isPresented: $showScoresheet) {
            ScoreSheetView(game: game)
        }
    }
}
#Preview {
    ResultsView(game: Game())
        .modelContainer(GamesPreviewContainer)
}
