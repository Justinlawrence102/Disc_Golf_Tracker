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
    @State private var showCreateNewGame = false
    @State private var showSettingsPage = false

    @State var newCourseDetent: PresentationDetent = .medium
    
//    @Query(sort: [SortDescriptor(\.startDate, comparator: .localized)]) private var games: [Game]
    @Query(sort: [SortDescriptor(\Game.startDate)]) private var games: [Game]

    var body: some View {
        NavigationStack {
            List(games, id: \.self) { game in
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
            .navigationDestination(for: Game.self) { game in
//                let _ = Self._printChanges()
                // 4
                VStack {
                    Text("Num Players: \(game.playerScores?.count ?? 0)")

                    ForEach(game.playerScores ?? []) {
                        playerScore in
                        Text("\(playerScore.player?.name ?? "N/A")")
                    }
                    Text("Num Baskets: \(game.course?.baskets?.count ?? 0)")
                }                        .navigationTitle(game.course?.name ?? "Course")
                    .navigationBarTitleDisplayMode(.inline)
                
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
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        showSettingsPage.toggle()
                    }) {
                        Label("New Game", systemImage: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showCreateNewGame, content: {
                SelectCourseView()
                    .presentationDetents([.medium])
            })
            .sheet(isPresented: $showSettingsPage, content: {
                VStack{
                    Image("AppIcon")
                        .resizable()
                        .frame(width: 90, height: 90)
                        .background(Color("Lime"))
                        .cornerRadius(12)
                    Text("Disc Golf Tracker")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("Pink"))
                    Text("Version 1.0")
                        .font(.caption)
                        .foregroundStyle(Color("Navy"))
                    Spacer()
                    Button(action: {
                        let locationManager = LocationManager()
                        locationManager.askPermission()

                    }, label: {
                        Label("Location", systemImage: "location.fill")
                    })
                    .frame(width: 350, height: 50)
                    .background(Color("Teal"))
                    .foregroundStyle(Color.white)
                    .cornerRadius(50)
                }.padding(40)
            })
        }
        .tint(Color("Teal"))
    }
}
#Preview {
    GameSelectionView()
        .modelContainer(GamesPreviewContainer)
}
