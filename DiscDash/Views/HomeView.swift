//
//  HomeView.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 8/23/23.
//

import SwiftUI
import SwiftData
import CoreLocation
import CoreLocationUI
import _MapKit_SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var sharePlayManager: SharedActivityManager
    
    @State private var showCreateNewGame = false
    @State private var showCreateNewPlayer = false
    @State private var showCreateNewCourse = false
    @State private var showAllGames = false
//    @State var createdNewCourse: Course?
    
    @Query var games: [Game]
    @Query(sort: [SortDescriptor(\Player.name)]) private var players: [Player]
    
    @Query(sort: [SortDescriptor(\Course.name)]) private var courses: [Course]

    init() {
        var descriptor = FetchDescriptor<Game>()
        descriptor.fetchLimit = 6
        descriptor.sortBy = [SortDescriptor(\Game.startDate, order: .reverse)]
        _games = Query(descriptor)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Spacer()
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Gradient(colors: [Color("Lime_W_Dark"), Color(UIColor.systemBackground)]))
                    Spacer()
                }
                ScrollView {
                    VStack(spacing: 8.0) {
                        Button(action: {
                            showAllGames.toggle()
                            print("View All Courses")
                        }, label: {
                            HStack(alignment: .center, spacing: 6) {
                                Text("Games")
                                    .font(.title3.weight(.semibold))
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Color.gray)
                                Spacer()
                            }
                            .foregroundStyle(Color("Navy"))
                            .padding(.bottom, -4)
                        })
                        if games.isEmpty {
                            VStack{
                                Image(systemName: "figure.disc.sports")
                                    .font(.largeTitle)
                                    .foregroundStyle(Color("Teal"))
                                Text("Tap the Plus to create a new game")
                                    .foregroundStyle(Color("Navy"))
                            }
                        }else {
                            ForEach(games, id: \.self) { game in
                                NavigationLink(value: game, label: {
                                    GameRowView(game: game)
                                })
                                .padding(12)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                                .listRowSeparator(.hidden)
                            }
                            .listStyle(.plain)
                        }
                        HStack(alignment: .center, spacing: 6) {
                            Text("Players")
                                .font(.title3.weight(.semibold))
//                            Button(action: {
//                                print("View All Players")
//                            }, label: {
//                                    Text("Players")
//                                        .font(.title3.weight(.semibold))
//                                    Image(systemName: "chevron.right")
//                                        .foregroundStyle(Color.gray)
//                            })
                            Spacer()
                            Button(action: {
                                showCreateNewPlayer.toggle()
                            }, label: {
                                Image(systemName: "plus")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Color("Teal"))
                            })
                        }
                        .foregroundStyle(Color("Navy"))
                        .padding(.bottom, -4)
                        .padding(.top)
                        
                        ScrollView(.horizontal) {
                            HStack(spacing: 12) {
                                ForEach(players, id: \.self) {
                                    player in
                                    NavigationLink(value: player, label: {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                PlayerProfileCircleView(player: player, size: 40)
                                                Text(player.name)
                                                    .font(.body.weight(.semibold))
                                                    .lineLimit(1)
                                                Text("\(player.getNumGames()) Games")
                                                    .foregroundStyle(.secondary)
                                                    .font(.subheadline.weight(.medium))
                                            }
                                            Spacer()
                                        }
                                    })
                                    .foregroundStyle(Color("Navy"))
                                    .padding(8)
                                    .frame(width: 160)
                                    .background(player.getColor())
                                    .cornerRadius(12)
                                }
                                Spacer()
                            }
                        }
                        
                        HStack(alignment: .center, spacing: 6) {
                            Text("Courses")
                                .font(.title3.weight(.semibold))
                            Spacer()
                            Button(action: {
//                                let newCourse = Course()
//                                modelContext.insert(newCourse)
//                                newCourse.baskets = []
//                                newCourse.games = []
//                                createdNewCourse = newCourse
                                showCreateNewCourse.toggle()
                            }, label: {
                                Image(systemName: "plus")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Color("Teal"))
                            })
                        }
                        .foregroundStyle(Color("Navy"))
                        .padding(.bottom, -4)
                        .padding(.top)

                        ScrollView(.horizontal) {
                            HStack(spacing: 12) {
                                ForEach(courses, id: \.self) {
                                    course in
                                    NavigationLink(value: course, label: {
                                        VStack(alignment: .leading) {
                                            if let courseImage = course.image, let image = UIImage(data: courseImage) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 174, height: 120)
                                                    .cornerRadius(8)
                                            }else {
                                                Image(systemName: "figure.disc.sports")
                                                    .frame(width: 174, height: 120)
                                                    .foregroundStyle(Color("Teal"))
                                                    .font(.title)
                                                    .background(Color("Lime"))
                                                    .cornerRadius(8)
                                            }
                                            Text(course.name)
                                                .lineLimit(1)
                                                .font(.headline)
                                            Label(course.cityState ?? "", systemImage: "location.fill")
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(Color("Pink"))
                                        }
                                    })
                                    .foregroundStyle(Color("Navy"))
                                    .padding(8)
                                    .frame(width: 190)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(12)
                                }
                                Spacer()
                            }
                        }
                    }
                    .safeAreaPadding(.horizontal)
                    .navigationDestination(for: Game.self) { game in
                        GameView(game: game)
                    }
                    .navigationDestination(for: Player.self) { player in
                        PlayerDetailsView(player: player)
                            .navigationTitle(player.name)
                            .navigationBarTitleDisplayMode(.inline)
                        
                    }
                    .navigationDestination(for: Course.self) { course in
                        CreateCourseDetailsView(course: course, isNewCourse: false)
                            .navigationBarTitleDisplayMode(.inline)
                        
                    }
                }
                .navigationDestination(isPresented: $sharePlayManager.isDeepLinkingToGame) {
                    if let game = sharePlayManager.gameModel {
                        GameView(game: game)
                        
                    }
                }
                .navigationDestination(isPresented: $showAllGames){
                    ListAllGamesView()
                        .navigationTitle("All Games")
                        .navigationBarTitleDisplayMode(.inline)
                }
            
                .navigationTitle("OneDisc")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            showCreateNewGame.toggle()
                        }) {
                            HStack(alignment: .center, spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.caption.weight(.semibold))
                                Text("New Game")
                            }
                            .font(.subheadline.weight(.semibold))
                            .padding(6)
                            .background(.thinMaterial)
                            .cornerRadius(24)
                        }
                    }
                }
                .sheet(isPresented: $showCreateNewGame, content: {
                    SelectCourseView(showCreateNewGameSheet: $showCreateNewGame)
                        .presentationDetents([.medium])
                })
                .sheet(isPresented: $showCreateNewPlayer, content: {
                    CreatePlayerView(player: Player(), isNewPerson: true)
                        .presentationDetents([.medium])
                        .interactiveDismissDisabled()
                })
                .sheet(isPresented: $showCreateNewCourse, content: {
                    NavigationStack {
                        CreateCourseDetailsView(course: Course(), isNewCourse: true)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction, content: {
                                    Button(action: {
                                        showCreateNewCourse.toggle()
                                    }, label: {
                                        Text("Cancel")
                                    })
                                })
                            }
                    }
                    .tint(Color("Teal"))
                })
                
            }
        }
        .tint(Color("Teal"))
    }
}
//#Preview {
//    HomeView()
//        .modelContainer(GamesPreviewContainer)
//}

#Preview {
    MainActor.assumeIsolated {
        return HomeView()
            .modelContainer(GamesPreviewContainer)
            .environment(LocationManager())
            .environmentObject(SharedActivityManager())
    }
}


struct GameRowView: View {
    let game: Game

    @Environment(\.modelContext) private var modelContext
    var body: some View {
        HStack {
            if let image = game.getImage() {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            }else {
                Image(systemName: "figure.disc.sports")
                    .frame(width: 60, height: 60)
                    .foregroundStyle(Color("Teal"))
                    .font(.title)
                    .background(Color("Lime"))
                    .cornerRadius(8)
            }
            VStack(alignment: .leading) {
                Text(game.course?.name ?? "")
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Text(game.formattedStartDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(Color("Navy"))
            Spacer()
            if game.endDate == nil {
                Text("In Progress")
                    .font(.headline)
                    .foregroundStyle(Color("Pink"))
            }else {
                VStack(alignment: .leading, spacing: 4.0) {
                    ForEach(game.getResults(limit3: true, context: modelContext)) {
                        score in
                        HStack {
                            PlayerProfileCircleView(player: Player(name: score.name, color: score.color, image: score.image), size: 18)
                            Text(score.getPlaceString())
                                .foregroundStyle(score.place ?? 0 == 1 ? Color("Pink") : Color("Navy"))
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                }
            }
        }
    }
}
