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
    
    //    @Query private var games: [Game]
    //    var game: Game! { games.first }
    
    //        private let playerScores: [ResultScores] = []
    @State private var scoreResults: [ResultScores] = []
    @State var game: Game
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
                            .contentShape(Rectangle())
                            .contextMenu(menuItems: {
                                Group {
                                    Button(action: {
                                        game.markPlayerNotFinish(playerId: score.playerId)
                                        scoreResults = game.getResults(context: modelContext)
                                    }, label: {
                                        Label("Did Not Finish", systemImage: "person.slash.fill")
                                    })
                                }
                            })
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
                    ShareLink(item: SharedGame(game: game), preview: SharePreview("\(game.course?.name ?? "") on \(game.formattedStartDate)")) {
                        Label("Export", systemImage: "square.and.arrow.up")
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.systemGroupedBackground))
                            .cornerRadius(12)
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color("Teal"))
                            .padding(.horizontal)
                    }
                }
            }
        }
        .onAppear {
            game.calculateResults(context: modelContext)
            scoreResults = game.getResults(context: modelContext)
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
