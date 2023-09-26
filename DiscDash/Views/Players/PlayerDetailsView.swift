//
//  PlayerDetailsView.swift
//  DiscDash
//
//  Created by Justin Lawrence on 9/24/23.
//

import SwiftUI
import SwiftData
import Charts
import MapKit

struct PlayerDetailsView: View {
    @Namespace private var animation
    
//    @Query private var players: [Player]
//    var player: Player! { players.first }
    var player: Player
    
    @State private var selectedTabView = 0
    @State private var profileViewState = 0
    init(player: Player) {
//    init() {
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(named: "Teal")
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.black.withAlphaComponent(0.2)
        self.player = player
    }
    
    var body: some View {
        ZStack {
            if profileViewState == 1 {
                Rectangle()
                    .foregroundStyle(.thinMaterial)
                    .cornerRadius(24)
                    .padding()
                    .matchedGeometryEffect(id: "PlayerProfileBackground", in: animation)
            }else if profileViewState > 1 {
                VStack {
                    Rectangle()
                        .foregroundStyle(.thinMaterial)
                        .frame(height: 100)
                        .cornerRadius(12)
                        .padding()
                        .matchedGeometryEffect(id: "PlayerProfileBackground", in: animation)
                    Spacer()
                }
            }
            TabView(selection: $selectedTabView) {
                BasketsOverview(player: player)
                    .tag(0)
                StatsOverview(player: player)
                    .tag(1)
                TopRoundsPerCourse(player: player)
                    .tag(2)
                Map() {
                    ForEach(player.coursesPlayed, id: \.self) {
                        courses in
                        if let coordinate = courses.coordinate {
                            Marker("", systemImage: "flag.circle.fill", coordinate: coordinate)
                        }
//                        Marker("", systemImage: "star.square.fill", coordinate: teeCoordinate)
//                            .tint(Color("Teal"))
                    }
                }
                .disabled(true)
                .cornerRadius(28)
                .padding(.top, 120)
                .tag(3)
            }
            .tabViewStyle(.page)
            .padding(.all)
            .onChange(of: selectedTabView) { newValue in
                withAnimation() {
                    profileViewState = newValue
                }
            }
            VStack {
                if profileViewState == 0 {
                    PlayerProfileCircleView(player: player, size: 120)
                        .padding(.top, 25.0)
                        .matchedGeometryEffect(id: "PlayerProfilePhoto", in: animation)
                }else {
                    HStack {
                        PlayerProfileCircleView(player: player, size: 75)
                         .padding([.top, .leading, .bottom], 12)
                            .matchedGeometryEffect(id: "PlayerProfilePhoto", in: animation)
                        VStack(alignment: .leading) {
                            Text("\(player.coursesPlayed.count) Courses Played")
                                .font(.headline)
                                .foregroundStyle(Color("Pink"))
                            Text(profileViewState == 1 ? "Stats" : profileViewState == 2 ? "Best Scores" : "Countries")
                                .font(.subheadline)
                                .foregroundStyle(Color("Teal"))
                        }
                        Spacer()
                    }
                    .background(content: {
                        if profileViewState > 1 {
                            Rectangle()
                                .foregroundStyle(.regularMaterial)
                                .cornerRadius(12)
                        }
                    })
                    .padding(14)
                }
                Spacer()
            }
        }
        .toolbar {
            Button(action: {
                print("Change Fiter")
            }) {
                Label("Filter", systemImage: "line.3.horizontal.decrease.circle.fill")
            }
        }
    }
}

struct BasketsOverview: View {
    var player: Player
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Text("\(player.numBasketsPlayed) Baskets Played")
                        .font(.headline)
                        .foregroundStyle(Color("Pink"))
                    ForEach(player.scoreBreakdown) {
                        score in
                        HStack {
                            Circle()
                                .frame(width: 20)
                            Text(score.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(score.number)")
                                .font(.headline)
                                .fontDesign(.rounded)
                        }
                        .foregroundStyle(score.color)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .frame(maxWidth: .infinity)
                .background(.thickMaterial)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 140)
                
                Chart(player.scoreBreakdown, id: \.diffFromPar) { element in
                    SectorMark(
                        angle: .value("Count", element.number),
                        innerRadius: .ratio(0.6),
                        angularInset: 3
                    )
                    .cornerRadius(8)
                    .foregroundStyle(element.color)
                }
                .frame(width: 250, height: 250)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Gradient(colors: [Color("Lime"), Color("Lime").opacity(0.3)]))
        .cornerRadius(24)
    }
}

struct StatsOverview: View {
    var player: Player

    var body: some View {
        VStack(spacing: -40.0) {
            HStack {
                VStack {
                    Text("\(player.numGamesPlayed)")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                    Text("Games")
                        .font(.body)
                }
                .foregroundStyle(Color("Navy"))
                .frame(width: 180, height: 180)
                .background(Color("Teal"))
                .cornerRadius(90)
                Spacer()
            }
            HStack {
                Spacer()
                VStack {
                    Text("\(player.numBasketsPlayed)")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                    Text("Baskets")
                        .font(.body)
                }
                .foregroundStyle(Color("Navy"))
                .frame(width: 190, height: 190)
                .background(Color("Lime"))
                .cornerRadius(95)
                
            }
            HStack {
                VStack {
                    Text("\(player.numThrows)")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                    Text("Throws")
                        .font(.body)
                }
                .foregroundStyle(Color("Navy"))
                .frame(width: 175, height: 175)
                .background(Color("LightPink"))
                .cornerRadius(87.5)
                Spacer()
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 140)
//        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(24)
    }
}

struct TopRoundsPerCourse: View {
    var player: Player
    
    var body: some View {
        VStack {
            ScrollView {
                Spacer()
                    .frame(height: 120)
                ForEach(player.TopScorePerCourse) {
                    topScore in
                    HStack {
                        if let courseImage = topScore.image, let image = UIImage(data: courseImage) {
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
                            Text(topScore.courseName)
                                .font(.headline)
                            Text(topScore.formattedDate)
                                .font(.subheadline)
                        }
                        .foregroundStyle(Color("Navy"))
                        Spacer()
                    }
                    .overlay(alignment: .bottomTrailing, content: {
                        Text("Best Score: \(topScore.score)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color("Teal"))
                            .padding(4)
                            .background(.thickMaterial)
                            .cornerRadius(8)
                    })
                    .padding(.all, 8.0)
                    .background(content: {
                        ZStack {
                            if let courseImage = topScore.image, let image = UIImage(data: courseImage) {
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
                                .foregroundStyle(.thinMaterial)
                        }
                        .clipped()
                        .cornerRadius(12)
                    })
                }
            }
        }
    }
}

//#Preview {
//    PlayerDetailsView()
//        .modelContainer(GamesPreviewContainer)
//}
