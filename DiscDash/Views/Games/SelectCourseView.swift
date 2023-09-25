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
    @Query(filter: #Predicate<Course> { !$0.isSharedGame }) private var courses: [Course]
//    @Query private var courses: [Course]
    
    @State var selectedItem: Course?
    @State private var isCreatingNewCourse = true
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        NavigationStack {
            List(courses.sorted(by: {$1.getDistance(locationManager: locationManager) > $0.getDistance(locationManager: locationManager)})) { course in
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
                                Text("\(String(format: "%.1f", course.getDistance(locationManager: locationManager))) mi away")
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
//                        modelContext.delete(course)
                        let courseId = course.uuid
                        do {
                            try modelContext.delete(model: Course.self, where: #Predicate<Course> { $0.uuid == courseId}, includeSubclasses: false)
                        }catch {
                            print("Could not delete!")
                        }
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
                        let newCourse = Course()
                        modelContext.insert(newCourse)
                        newCourse.baskets = []
                        newCourse.games = []
                        isCreatingNewCourse = true
                        selectedItem = newCourse
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
                    newGame.createGame(course: selectedCourse, players: selectedPlayers)
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
