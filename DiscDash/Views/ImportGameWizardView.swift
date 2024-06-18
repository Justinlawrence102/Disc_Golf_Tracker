//
//  ImportGameWizardView.swift
//  OneDisc
//
//  Created by Justin Lawrence on 6/16/24.
//

import SwiftUI
import SwiftData

struct ImportGameWizardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State var importedGame: SharedGame
    @State var showGameExisitsAlert = false
    @Query(sort: [SortDescriptor(\Player.name)]) private var players: [Player]
    
    @Query(sort: [SortDescriptor(\Course.name)]) private var courses: [Course]
        
    var body: some View {
        NavigationStack {
            Form {
                Section("Course", content: {
                    CourseRow(courses: courses, importedGame: importedGame, selectedCourse: importedGame.courseId)
                    HStack {
                        Text("Game Date")
                        Spacer()
                        Text(importedGame.formattedStartDate)
                            .foregroundStyle(Color("Navy"))
                    }
                })
                Section("Players", content: {
                    ForEach(importedGame.players, id: \.playerUuid) {
                        player in
                        PlayerRow(player: player, players: players, importedGame: importedGame)
                    }
                })
            }
            .navigationTitle("Import Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .cancel, action: {
                        dismiss.callAsFunction()
                    }, label: {
                        Text("Cancel")
                    })
                }
                ToolbarItem{
                    Button(action: {
                        print("Import")
                        importedGame.saveGame(context: modelContext, completion: {
                            game, success in
                            if !success {
                                print("Present Alert!")
                                showGameExisitsAlert.toggle()
                            }else {
                                dismiss.callAsFunction()
                            }
                            
                        })
                    }, label: {
                        Text("Import")
                    })
                }
                
                
            }
            .alert("Game Already Exists", isPresented: $showGameExisitsAlert){
                Button(role: .cancel, action: {
                    showGameExisitsAlert.toggle()
                    dismiss.callAsFunction()
                }, label: {
                    Text("Ok")
                })
            }message: {
                Text("This game could not be imported because you already have the game saved.")
            }
        }
    }
}

#Preview {
    ImportGameWizardView(importedGame: SharedGame(courseId: "1234", courseName: "Test Course", players: [SharedPlayer(name: "Justin", color: "Teal", playerUuid: "1234"), SharedPlayer(name: "Mark", color: "Pink", playerUuid: "54321"), SharedPlayer(name: "Allison", color: "Lime", playerUuid: "09887")]))
        .modelContainer(GamesPreviewContainer)

}

private struct PlayerRow: View {
    @State var player: SharedPlayer
    var players: [Player]
    var importedGame: SharedGame
    var body: some View {
        HStack {
            Text(player.name)
            Spacer()
            Menu {
                Button(action: {
                    player.playerUuid = UUID().uuidString
                    importedGame.changePlayerId(oldId: player.playerUuid, newId: UUID().uuidString)
                }) {
                    Label("Create New Course", systemImage: "plus")
                }
                ForEach(players) {
                    _player in
                    Button(action: {
                        print("Select Player")
                        player.newNameFromImport = _player.name
                        importedGame.changePlayerId(oldId: player.playerUuid, newId: _player.uuid)
                        player.playerUuid = _player.uuid
                    }) {
                        Text(_player.name)
                    }
                }
            } label: {
                Text(players.first(where: { $0.uuid == player.playerUuid})?.name ?? "Create New")
            }
        }
    }
}

private struct CourseRow: View {
    var courses: [Course]
    var importedGame: SharedGame
    @State var selectedCourse: String
    var body: some View {
        HStack {
            Text(importedGame.courseName)
            Spacer()
            Menu {
                Button(action: {
                    importedGame.courseId = UUID().uuidString
                    selectedCourse = UUID().uuidString
                }) {
                    Label("Create New Course", systemImage: "plus")
                }
                ForEach(courses) {
                    course in
                    Button(action: {
                        print("Select course")
                        importedGame.courseId = course.uuid
                        selectedCourse = course.uuid
                    }) {
                        Text(course.name)
                    }
                }
            } label: {
                Text(courses.first(where: { $0.uuid == selectedCourse})?.name ?? "Create New")
            }
            
        }
    }
}
