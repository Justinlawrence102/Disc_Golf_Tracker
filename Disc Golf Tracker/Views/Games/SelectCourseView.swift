//
//  SelectCourseView.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 8/29/23.
//

import Foundation
import SwiftUI
import SwiftData
struct SelectCourseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @Query private var courses: [Course]
    
    @State var selectedItem: Course?
    @State private var isCreatingNewCourse = true
    
    var body: some View {
        NavigationStack {
            List(courses.sorted(by: {$1.distance > $0.distance})) { course in
                NavigationLink(value: course) {
                    HStack {
                        if let courseImage = course.image, let image = UIImage(data: courseImage) {
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: 64, height: 64)
                                .background(Color("Lime"))
                                .cornerRadius(10)
                        }else {
                            Image(systemName: "figure.disc.sports")
                                .frame(width: 64, height: 64)
                                .background(Color("Lime"))
                                .cornerRadius(10)
                                .foregroundStyle(Color("Teal"))
                                .font(.title3)
                        }
                        VStack(alignment: .leading) {
                            Text(String(course.name))
                                .font(.headline)
                                .foregroundStyle(Color("Navy"))
                            Text(course.lastPlayedString)
                                .font(.subheadline)
                                .foregroundStyle(Color("Navy"))
                            HStack(spacing: 0.0) {
                                Image(systemName: "location.fill")
                                Text("\(String(format: "%.1f", course.distance)) mi away")
                            }
                            .font(.caption)
                            .foregroundStyle(Color("Teal"))
                        }
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        isCreatingNewCourse = false
                        selectedItem = course
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button {
                        modelContext.delete(course)
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .tint(.red)
                    }
                }
            }
            .tint(Color("Teal"))
            .navigationTitle("Select Course")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Course.self) { course in
                SelectPlayerView(selectedCourse: course)
//                Text("Players Select")
                    .navigationTitle("Select Players")
                    .navigationBarTitleDisplayMode(.inline)
                
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        isCreatingNewCourse = true
                        selectedItem = Course()
                    }, label: {
                        Image(systemName: "plus")
                    })
                }
                ToolbarItem(placement: .cancellationAction, content: {
                    Button(action: {
                        dismiss.callAsFunction()
                    }, label: {
                        Text("Cancel")
                    })
                })
            }
        }
        .sheet(item: $selectedItem) { item in
            CreateCourseDetailsView(course: item, isNewCourse: isCreatingNewCourse)
        }
    }
}

struct SelectPlayerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query private var players: [Player]
    var selectedCourse: Course
    
    var body: some View {
        List(players, id: \.self) {
            player in
            Button(action: {
                player.isSelected.toggle()
                print("Tapped \(player.name), \(player.isSelected)")
            }, label: {
                HStack {
                    PlayerProfileCircleView(player: player, size: 50)
                    Text(player.name)
                        .font(.headline)
                        .foregroundStyle(Color("Navy"))
                    Spacer()
                    Image(systemName: player.isSelected ? "checkmark.circle.fill":"circle")
                        .font(.title2)
                        .foregroundStyle(Color("Teal"))
                }
            })
            .buttonStyle(.plain)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    let selectedPlayers = players.filter({$0.isSelected})
                    let newGame = Game()
                    newGame.createGame(course: selectedCourse, players: selectedPlayers, modelContext: modelContext)
                    print("Start Game!")
                }, label: {
                    Text("Start Game")
                })
            }
        }
        
    }
}
#Preview {
    SelectPlayerView(selectedCourse: Course(name: "Test"))
        .modelContainer(previewContainer)
}
