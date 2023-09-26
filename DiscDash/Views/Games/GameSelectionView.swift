//
//  GameSelectionView.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 8/23/23.
//

import SwiftUI
import SwiftData
import CoreLocation
import CoreLocationUI

struct GameSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var sharePlayManager: SharedActivityManager

    @State private var showCreateNewGame = false
    
    @Query(sort: [SortDescriptor(\Game.startDate, order: .reverse)]) private var games: [Game]
    
    private var filteredGames: [Game] {
        return games.filter({
            if sharePlayManager.gameSelectionPickerStatus == 0 {
                return !$0.isSharedGame
            }else {
                return $0.isSharedGame
            }
        })
    }
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Game Type", selection: $sharePlayManager.gameSelectionPickerStatus) {
                    Text("My Games").tag(0)
                    Text("Shared Games").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 8)
                if sharePlayManager.gameSelectionPickerStatus == 1 && filteredGames.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "shareplay")
                            .foregroundStyle(Color("Teal"))
                            .font(.system(size: 35))
                        Text("Games shared to you via SharePlay will appear here")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color("Navy"))
                        Spacer()
                    }
                }else {
                    List(filteredGames, id: \.self) { game in
                        ZStack {
                            NavigationLink(value: game) { EmptyView() }.opacity(0.0)
                            VStack {
                                if let image = game.getImage() {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 80)
                                }else {
                                    Image(systemName: "figure.disc.sports")
                                        .frame(height: 80)
                                        .foregroundStyle(Color("Teal"))
                                        .font(.title)
                                }
                                HStack(alignment: .bottom) {
                                    VStack(alignment: .leading) {
                                        Text(game.course?.name ?? "NONE")
                                            .font(.headline)
                                        Text(game.formattedStartDate)
                                            .font(.subheadline)
                                    }
                                    .foregroundStyle(Color("Navy"))
                                    Spacer()
                                    if let cityState = game.course?.cityState {
                                        HStack(spacing: 2.0) {
                                            Image(systemName: "location.fill")
                                            Text(cityState)
                                        }
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color("Teal"))
                                        .shadow(radius: 3)
                                    }
                                }
                                .padding(8.0)
                                .background(.thinMaterial)
                            }
                            .background(Color("Lime"))
                            .cornerRadius(12)
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationDestination(for: Game.self) { game in
                GameView(game: game)
//                GameView()
            }
            .navigationDestination(isPresented: $sharePlayManager.isDeepLinkingToGame) {
                if let game = sharePlayManager.gameModel {
                    GameView(game: game)
                    
                }
            }
            .navigationTitle("Games")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showCreateNewGame.toggle()
                    }) {
                        Label("New Game", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateNewGame, content: {
                SelectCourseView()
                    .presentationDetents([.medium])
            })
        }
        .tint(Color("Teal"))
    }
}
#Preview {
    GameSelectionView()
        .modelContainer(GamesPreviewContainer)
}
