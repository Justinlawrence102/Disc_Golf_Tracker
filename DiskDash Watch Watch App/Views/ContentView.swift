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
    
    @State var showJumpToBasketAlert = false
    @State var tempSelectedGame: Game?
    
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
                List(games) { //, selection: $stateManager.selectedGame
                    game in
                    Button(action: {
                        if game.currentHoleIndex > 0 && game.currentHoleIndex != game.course?.baskets?.count ?? 0 {
                            tempSelectedGame = game
                            showJumpToBasketAlert.toggle()
                        }else {
                            stateManager.selectedGame = game
                        }
                    }, label: {
                        HStack(spacing: 8) {
                            if let image = game.getImage() {
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .aspectRatio(1, contentMode: .fill)
                                    .background(Color.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            VStack(alignment: .leading) {
                                if let course = game.course {
                                    Text(course.name)
                                        .font(.headline)
                                        .lineLimit(1)
                                }
                                Text(game.formattedStartDate)
                                    .foregroundStyle(Color("Teal"))
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 16.0)
                        }
                    })
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
                            Color("Teal")
                            Rectangle()
                                .foregroundStyle(.regularMaterial)
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
                    //game.currentHoleIndex+1
                    GoToNextBasketView(game: game, nextBasketNumber: stateManager.jumpToBasket)
                        .environmentObject(stateManager)
                }
            }
            .alert("Continue game?", isPresented: $showJumpToBasketAlert) {
                Button("Basket \((tempSelectedGame?.currentHoleIndex ?? -1)+1)") {
                    stateManager.jumpToBasket = (tempSelectedGame?.currentHoleIndex ?? 0) + 1
                    stateManager.selectedGame = tempSelectedGame
                }
                Button("Basket 1", role: .cancel) {
                    stateManager.jumpToBasket = 1
                    stateManager.selectedGame = tempSelectedGame
                }
            } message: {
            Text("This game is already in progress. Would you like to jump to basket \((tempSelectedGame?.currentHoleIndex ?? -1)+1) or start from the begining?")
        }
            .sheet(isPresented: $stateManager.showCreateGameSheet) {
                SelectCourseView()
                    .environmentObject(stateManager)
                
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let game = games.first, Calendar.current.startOfDay(for: Date()) == Calendar.current.startOfDay(for: game.startDate) {
                        if game.currentHoleIndex > 0 && game.currentHoleIndex != game.course?.baskets?.count ?? 0 {
                            tempSelectedGame = game
                            showJumpToBasketAlert.toggle()
                        }else {
                            stateManager.selectedGame = game
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(GamesPreviewContainer)
        .environment(LocationManager())
}
