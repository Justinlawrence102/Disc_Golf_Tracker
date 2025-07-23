//
//  CreateGameView.swift
//  Disc Golf Tracker Watch Watch App
//
//  Created by Justin Lawrence on 9/14/23.
//

import SwiftUI
import SwiftData
import WidgetKit

struct SelectCourseView: View {
    @Query(sort: \Course.name) private var courses: [Course]
    @Environment(LocationManager.self) var locationManager

    var body: some View {
        NavigationStack {
            if courses.isEmpty {
                VStack {
                    Image(systemName: "iphone.gen3")
                        .font(.title)
                    Text("No Courses Yet")
                        .font(.headline)
                    Text("Create a course on your iPhone first")
                        .lineLimit(3)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
            }
            List(courses.sorted(by: {$1.getDistance(locationManager: locationManager) ?? 0 > $0.getDistance(locationManager: locationManager) ?? 0})) {
                course in
                NavigationLink(destination: {
                    SelectPlayersView(selectedCourse: course)
                }, label: {
                    VStack(alignment: .leading) {
                        Text(course.name)
                            .font(.body)
                        Text(course.lastPlayedString)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                })
                
            }
        }
        
    }
}
struct SelectPlayersView: View {
    @Query(sort: \Player.name) private var players: [Player]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var stateManager: StateManager

    var selectedCourse: Course

    var body: some View {
        List(players) {
            player in
            Button {
                print("Clicked Player")
                player.isSelected.toggle()
            } label: {
                HStack {
                    PlayerProfileCircleView(player: player, size: 30)
                    Text(player.name)
                        .font(.body)
                    Spacer()
                    Image(systemName: player.isSelected ? "checkmark.circle.fill":"circle")
                        .font(.title2)
                        .foregroundStyle(Color("Teal"))
                }
            }
            .buttonStyle(.plain)
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: {
                    let selectedPlayers = players.filter({$0.isSelected})
                    let newGame = Game()
//                    modelContext.insert(newGame)
//                    newGame.startDate = Date()
//                    newGame.playerScores = []
//                    
//                    selectedCourse.games?.append(newGame)
//                    newGame.course = selectedCourse
//                    
//                    for player in selectedPlayers {
//                        for basket in newGame.course?.baskets ?? [] {
//                            let playerScore = PlayerScore(player: player, game: newGame, basket: basket)
//                            modelContext.insert(playerScore)
//                        }
//                        let playerResult = PlayerScore(player: player, resultsGame: newGame)
//                        modelContext.insert(playerResult)
//                    }
                    newGame.createGame(course: selectedCourse, players: selectedPlayers, modelContext: modelContext)
                    stateManager.showCreateGameSheet = false
                    stateManager.selectedGame = newGame
                    WidgetCenter.shared.reloadTimelines(ofKind: "scoreCard-widget")
                }, label: {
                    Text("Start")
                        .foregroundStyle(Color("Lime"))
                })
            }
        }
        
    }
}

//#Preview {
//    SelectCourseView()
//        .modelContainer(GamesPreviewContainer)
//}
