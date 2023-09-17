//
//  CreateGameView.swift
//  Disc Golf Tracker Watch Watch App
//
//  Created by Justin Lawrence on 9/14/23.
//

import SwiftUI
import SwiftData

struct SelectCourseView: View {
    @Query(sort: \Course.name) private var courses: [Course]
    @Binding var showCreateGameSheet: Bool
    @Binding var selectedGame: Game?

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
            List(courses) {
                course in
                NavigationLink(destination: {
                    SelectPlayersView(selectedCourse: course, showCreateGameSheet: $showCreateGameSheet, selectedGame: $selectedGame)
                }, label: {
                    VStack(alignment: .leading) {
                        Text(course.name)
                            .font(.body)
                        Text(course.lastPlayedString)
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
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

    var selectedCourse: Course
    @Binding var showCreateGameSheet: Bool
    @Binding var selectedGame: Game?

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
                    newGame.createGame(course: selectedCourse, players: selectedPlayers, modelContext: modelContext)
                    showCreateGameSheet = false
                    selectedGame = newGame
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
