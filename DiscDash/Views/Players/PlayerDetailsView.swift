//
//  PlayerDetailsView.swift
//  OneDisc
//
//  Created by Justin Lawrence on 9/24/23.
//

import SwiftUI
import SwiftData
import Charts
import MapKit
import TipKit

struct PlayerDetailsView: View {
    @Namespace private var animation
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

//    @Query private var players: [Player]
//    var player: Player! { players.first }
    @State var player: Player
    @State var playerStats: PlayerStats
    
    @State private var selectedTabView = 0
    @State private var profileViewState = 0
    @State private var selectedFilter: Int = 0
    @State private var showEditPlayerSheet = false
    
    @State var playerToDelete: Player?
    @State var showDeletePlayerAlert = false
    
    init(player: Player) {
//    init() {
        playerStats = PlayerStats(player: player)
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
                BasketsOverview(playerStats: playerStats)
                    .tag(0)
                StatsOverview(playerStats: playerStats)
                    .tag(1)
                TopRoundsPerCourse(playerStats: playerStats)
                    .tag(2)
                Map() {
                    ForEach(playerStats.coursesPlayed, id: \.self) {
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
                            Text("\(playerStats.coursesPlayed.count) Courses Played")
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
        .onAppear{
            playerStats.reloadFilter(modelContext: modelContext)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: {
                        showEditPlayerSheet.toggle()
                    }) {
                        Label("Edit", systemImage: "pencil")
                            .foregroundColor(.red)
                    }
                    if let image = player.image, let playerImage = UIImage(data: image) {
                        ShareLink(item: player, preview: SharePreview(player.name, image: Image(uiImage: playerImage))){
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }else {
                        ShareLink(item: player, preview: SharePreview(player.name)) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                    Button(role: .destructive, action: {
                        playerToDelete = player
                        showDeletePlayerAlert = true
                    }, label: {
                        Label("Delete Player", systemImage: "trash.fill")
                    })
                    Section(header: Text("Filter")) {
                        
                        Picker(selection: $selectedFilter, label: Text("Sorting options")) {
                            Label("Lifetime", systemImage: "chart.bar.fill")
                                .tag(0)
                            
                            Label("Today", systemImage: "calendar")
                                .tag(1)
                            
                            Label("Last 30 Days", systemImage: "calendar")
                                .tag(2)
                            
                            Label("This Year", systemImage: "calendar")
                                .tag(3)
                        }.onChange(of: selectedFilter){
                            switch selectedFilter {
                            case 0:
                                playerStats.statFilter = .lifetime
                            case 1:
                                playerStats.statFilter = .today
                            case 2:
                                playerStats.statFilter = .lastMonth
                            case 3:
                                playerStats.statFilter = .thisYear
                            default:
                                playerStats.statFilter = .lifetime
                            }
                            playerStats.reloadFilter(modelContext: modelContext)
                        }
                    }
                }
            label: {
                Label("Info", systemImage: "ellipsis.circle")
            }
                //                .popoverTip(SharePlayerTip())
            }
        }
        .sheet(isPresented: $showEditPlayerSheet) {
            CreatePlayerView(player: player, isNewPerson: false)
        }
        .overlay(alignment: .bottom) {
            if player.isSharedPlayer {
                Button {
                    player.isSharedPlayer = false
                    print("test")
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save Shared Player")
                    }
                    .foregroundColor(.white)
                    .frame(width: 350, height: 50)
                    .background(Color("Teal"))
                    .cornerRadius(25)
                    .padding(.bottom, 65)
                }
            }
        }
        .alert("Delete Player", isPresented: $showDeletePlayerAlert) {
            Button("Delete", role: .destructive) {
                if let player = playerToDelete {
                    modelContext.delete(player)
                    dismiss.callAsFunction()
                }
            }
            Button("Cancel", role: .cancel) { }
        }message: {
            Text("Are you sure you want to delete \(playerToDelete?.name ?? "this player")?")
        }
    }
}

struct BasketsOverview: View {
    @State var playerStats: PlayerStats
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Text("\(playerStats.numBasketsPlayed) Baskets Played")
                        .font(.headline)
                        .foregroundStyle(Color("Pink"))
                    ForEach(playerStats.scoreBreakdown) {
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
                
                Chart(playerStats.scoreBreakdown, id: \.diffFromPar) { element in
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
    @State var playerStats: PlayerStats

    var body: some View {
        VStack(spacing: -40.0) {
            HStack {
                VStack {
                    Text("\(playerStats.numGamesPlayed)")
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
                    Text("\(playerStats.numBasketsPlayed)")
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
                    Text("\(playerStats.numThrows)")
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
    @State var playerStats: PlayerStats

    var body: some View {
        VStack {
            ScrollView {
                Spacer()
                    .frame(height: 120)
                ForEach(playerStats.TopScoresPerCourse) {
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

#Preview {
    PlayerDetailsView(player: Player(name: "test", color: "343232"))
        .modelContainer(GamesPreviewContainer)
}

struct SharePlayerTip: Tip {
    
    var title: Text {
        Text("Share Player and Change Filter")
            .foregroundStyle(Color("Teal"))
    }
    
    var message: Text? {
        Text("Share your Player with friends and filter your stats by day, month, or year")
    }
    var image: Image? {
        Image(systemName: "square.and.arrow.up")
    }
    
}

struct SearchTip: Tip {
    var title: Text {
        Text("Add a new game")
    }
    
    var message: Text? {
        Text("Search for new games to play via IGDB.")
    }
    
    var asset: Image? {
        Image(systemName: "magnifyingglass")
    }
}
