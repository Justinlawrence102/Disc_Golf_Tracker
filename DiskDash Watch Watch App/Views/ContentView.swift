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

    @ObservedObject var stateManager = StateManager()
    
    
    @Query(sort: [SortDescriptor(\Game.startDate, order: .reverse)]) private var games: [Game]
    
    
    var body: some View {
        if games.isEmpty {
            VStack {
                Image(systemName: "figure.disc.sports")
                    .foregroundColor(Color("Lime"))
                    .font(.title)
                Text("No Games found!")
                Button(action: {
                    stateManager.showCreateGameSheet.toggle()
                }, label: {
                    Text("Start Game")
                })
            }
            .sheet(isPresented: $stateManager.showCreateGameSheet) {
                SelectCourseView()
            }
        }else {
            NavigationStack {
                List(games, selection: $stateManager.selectedGame) {
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
                            stateManager.showCreateGameSheet.toggle()
                        }, label: {
                            Image(systemName: "plus")
                        })
                    }
                }
                .navigationDestination(item: $stateManager.selectedGame) { game in
                    GoToNextBasketView(game: game, nextBasketNumber: 1)
                        .environmentObject(stateManager)
                }
            }
            .sheet(isPresented: $stateManager.showCreateGameSheet) {
                SelectCourseView()
                    .environmentObject(stateManager)
                
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    stateManager.selectedGame = games.first
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(GamesPreviewContainer)
}
