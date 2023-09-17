//
//  ContentView.swift
//  Disc Golf Tracker Watch Watch App
//
//  Created by Justin Lawrence on 9/13/23.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var locationManager: LocationManager

    @Query(filter: #Predicate<Game> { !$0.isSharedGame} ,sort: [SortDescriptor(\Game.startDate, order: .reverse)]) private var games: [Game]

    
    @State var showCreateGameSheet = false
    @State var selectedGame: Game?
    
    var body: some View {
        if games.isEmpty {
            VStack {
                Image(systemName: "figure.disc.sports")
                    .foregroundColor(Color("Lime"))
                    .font(.title)
                Text("No Games found!")
                Text("Last coodinates: \(locationManager.lastLocation?.coordinate.latitude ?? 0), \(locationManager.lastLocation?.coordinate.longitude ?? 0)")
                Button(action: {
                    showCreateGameSheet.toggle()
                }, label: {
                    Text("Start Game")
                })
            }
            .sheet(isPresented: $showCreateGameSheet) {
                    SelectCourseView(showCreateGameSheet: $showCreateGameSheet, selectedGame: $selectedGame)
            }
        }else {
            NavigationSplitView {
                List(games, selection: $selectedGame) {
                    game in
                    NavigationLink(value: game) {
                        VStack(alignment: .leading) {
                            if let course = game.course {
                                Text(course.name)
                                    .font(.headline)
                            }
                            Text(game.formattedStartDate)
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 16.0)
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            modelContext.delete(game)
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .tint(.red)
                        }
                    }
                    .listRowBackground(
                        ZStack {
                            if let image = game.getImage() {
                                Rectangle()
                                    .overlay {
                                        ZStack {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                        }
                                    }
                                    .clipShape(.containerRelative)
                                
                            }else {
                                Color("Lime")
                            }
                            Rectangle()
                                .foregroundStyle(.ultraThinMaterial)
                        }
                            .clipped()
                            .cornerRadius(12)
                    )
                }
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button(action: {
                            showCreateGameSheet.toggle()
                        }, label: {
                            Image(systemName: "plus")
                        })
                    }
                }
            } detail: {
                if let game = selectedGame {
                    BasketNavigationView(game: game)
                }else {
                    Text("Could not load game")
                }
            }
            .sheet(isPresented: $showCreateGameSheet) {
                    SelectCourseView(showCreateGameSheet: $showCreateGameSheet, selectedGame: $selectedGame)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedGame = games.first
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(GamesPreviewContainer)
}
