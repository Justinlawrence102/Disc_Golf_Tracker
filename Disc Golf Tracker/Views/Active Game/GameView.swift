//
//  GameView.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 9/3/23.
//

import SwiftUI
import SwiftData
import MapKit

struct GameView: View {
    @Environment(\.modelContext) private var modelContext

//    @Query private var games: [Game]
//    var game: Game! { games.first }
    
    @State var game: Game

    @Query var scores: [PlayerScore]
    @State var showingAddTeeAlert = false
    @State var showingAddBasketAlert = false
    
    @State var showingScoreSheet = true
    @State private var selectedDetent = PresentationDetent.full
    @State var sheetIsUp = true //this is used for the animation of the hole, par, distance popover
    
    @EnvironmentObject var locationManager: LocationManager
        
    var body: some View {
        ZStack {
            if let basket = game.currentBasket {
                BasketDetailsView(basket: basket, game: game, sheetIsUp: $sheetIsUp, showingAddTeeAlert: showingAddTeeAlert, showingAddBasketAlert: showingAddBasketAlert)
            }else {
                ResultsView(game: game, context: modelContext)
            }
            
            VStack {
                BasketPickerView(game: game, showingScoreSheet: $showingScoreSheet)
                Spacer()
            }
        }
        .frame(maxHeight: .infinity)
        .navigationTitle(game.course?.name ?? "Course")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(){
            print("Inital set map")
            game.updateMapCamera(locationManager: locationManager)
        }
        .sheet(isPresented: $showingScoreSheet, content: {
                        Button(action: {
                            if playerScore.score == 0, let currentBasket = game.currentBasket, let par = Int(currentBasket.par) {
                                playerScore.score = par
                            }else {
                                playerScore.score += 1
                            }
                            print("Increment")
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
            PlayerScoresListView(game: game)
                .presentationDetents([.height(400), .height(120)], selection: $selectedDetent)
                .presentationBackgroundInteraction(
                    .enabled
                )
                .interactiveDismissDisabled()
                .onChange(of: selectedDetent) { newValue in
                    withAnimation(.spring()) {
                        sheetIsUp.toggle()
                    }
                }
                .alert("How would you like to add a new tee?", isPresented: $showingAddTeeAlert) {
                    Button("Add Tee") {
                        game.currentBasket!.saveTeeLocation(holeNumber: game.currentHoleIndex, locationManager: locationManager)
                    }
                    Button("Replace Exisiting Tees", role: .destructive) {
                        game.currentBasket!.teeLatitudes.removeAll()
                        game.currentBasket!.teeLongitudes.removeAll()
                        game.currentBasket!.saveTeeLocation(holeNumber: game.currentHoleIndex, locationManager: locationManager)
                    }
                    Button("Cancel", role: .cancel) { }
                }
                .alert("How would you like to add a new basket?", isPresented: $showingAddBasketAlert) {
                    Button("Add Basket") {
                        game.currentBasket!.saveBasketLocation(holeNumber: game.currentHoleIndex, locationManager: locationManager)
                    }
                    Button("Replace Exisiting Baskets", role: .destructive) {
                        game.currentBasket!.basketLatitudes.removeAll()
                        game.currentBasket!.basketLongitudes.removeAll()
                        game.currentBasket!.saveBasketLocation(holeNumber: game.currentHoleIndex, locationManager: locationManager)
                    }
                    Button("Cancel", role: .cancel) { }
                }
                .sheet(isPresented: $isActivitySharingSheetPresented) {
                    ActivitySharingViewController(activity: SharePlayActivity())
                }
        })
    }
}

struct CurrentBasketInfoView: View {
    
    var basket: Basket
    var alignment: HorizontalAlignment
    var body: some View {
        VStack(alignment: alignment, spacing: 0.0) {
            Text("Hole \(basket.number ?? 0)")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color("Teal"))
            Text("Par \(basket.par)")
                .font(.body)
                .foregroundStyle(Color("Pink"))
            HStack(spacing: 4.0) {
                Image(systemName: "location.fill")
                Text("\(basket.distance) Yards")
            }
            .font(.subheadline)
            .foregroundStyle(Color("Navy"))
        }
    }
}

struct BasketDetailsView: View {
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.modelContext) private var modelContext
    @Namespace private var animation
    var basket: Basket

    @State var game: Game
    @Binding var sheetIsUp: Bool //this is used for the animation of the hole, par, distance popover
    @State var showingAddTeeAlert: Bool
    @State var showingAddBasketAlert: Bool
        
    var body: some View {
        VStack(spacing: -0.0) {
            //                    Map {
            Map(position: $game.cameraPosition) {
                ForEach(basket.teeCoordinates, id: \.self) {
                    teeCoordinate in
                    Marker("", systemImage: "star.square.fill", coordinate: teeCoordinate)
                        .tint(Color("Teal"))
                }
                ForEach(basket.basketCoordinates, id: \.self) {
                    basketCoordinate in
                    Marker("", systemImage: "arrow.up.bin.fill", coordinate: basketCoordinate)
                        .tint(Color("Pink"))
                }
                UserAnnotation()
            }
            VStack(spacing: -90.0) {
                Rectangle()
                    .padding(.top, -45.0)
                    .frame(height: 90)
                    .blur(radius: 20)
                    .foregroundStyle(Color("Lime_W_Dark"))
                
                VStack(spacing: 12.0) {
                    if !sheetIsUp {
                        CurrentBasketInfoView(basket: basket, alignment: .center)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(.thickMaterial)
                            .cornerRadius(12)
                            .padding(.horizontal, 12)
                            .matchedGeometryEffect(id: "CurrentHoleView", in: animation)
                    }
                    
                    HStack(alignment: .top, spacing: 12.0) {
                        if let highScore = basket.getHighScore(modelContext: modelContext) {
                            VStack(alignment: .leading, spacing: 0.0) {
                                HStack {
//                                    Circle()
                                    if highScore.indices.contains(2), let player = highScore[2] as? Player {
                                        PlayerProfileCircleView(player: player, size: 30)
                                    }
                                    Text(highScore[0] as? String ?? "")
                                        .font(.title)
                                        .fontWeight(.semibold)
                                        .fontDesign(.rounded)
                                        .foregroundStyle(Color("Pink"))
                                    Spacer()
                                }
                                Text("Best Score")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color("Navy"))
                                Text(highScore[1] as? String ?? "")
                                    .font(.caption)
                                    .foregroundStyle(Color("Navy"))
                            }
                            .padding(8)
                            .background(.thickMaterial)
                            .cornerRadius(12)
                        }
                        if let averageScore = basket.getAverageScore(modelContext: modelContext) {
                            VStack(alignment: .leading, spacing: 0.0) {
                                HStack {
                                    Text(averageScore)
                                        .font(.title)
                                        .fontWeight(.semibold)
                                        .fontDesign(.rounded)
                                        .foregroundStyle(Color("Pink"))
                                    Spacer()
                                }
                                Text("Average Score")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color("Navy"))
                            }
                            .padding(8)
                            .background(.thickMaterial)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 12)
                    HStack{
                        Button(action: {
                            if basket.teeCoordinates.isEmpty {
                                basket.saveTeeLocation(holeNumber: game.currentHoleIndex, locationManager: locationManager)
                            }else {
                                showingAddTeeAlert.toggle()
                            }
                            print("Save Tee")
                        }, label: {
                            Label("Tee", systemImage: "mappin")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color("Teal"))
                                .foregroundStyle(Color.white)
                                .cornerRadius(20)
                        })
                        Spacer()
                        Button(action: {
                            print("Save Basket")
                            if basket.basketCoordinates.isEmpty {
                                basket.saveBasketLocation(holeNumber: game.currentHoleIndex, locationManager: locationManager)
                            }else {
                                showingAddBasketAlert.toggle()
                            }
                        }, label: {
                            Label("Basket", systemImage: "mappin")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color("Teal"))
                                .foregroundStyle(Color.white)
                                .cornerRadius(20)
                        })
                    }
                    .padding(.horizontal, 12)
                    Spacer()
                }
            }
            .background(Color("Lime_W_Dark"))
            .frame(height: 300)
        }
        //            }
        //            if let basket = game.currentBasket {
        VStack() {
            Spacer()
            HStack {
                if sheetIsUp {
                    CurrentBasketInfoView(basket: basket, alignment: .leading)
                        .padding(8)
                        .background(.regularMaterial)
                        .cornerRadius(12)
                        .matchedGeometryEffect(id: "CurrentHoleView", in: animation)
                }
                Spacer()
            }
            .padding(.leading, 8.0)
            Spacer()
                .frame(height: 448)
        }
        .ignoresSafeArea()
    }
}

struct BasketPickerView: View {
    @EnvironmentObject var locationManager: LocationManager

    var game: Game
    
    @Binding var showingScoreSheet: Bool

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(game.course?.sortedBaskets ?? []) {
                    basket in
                    if let number = basket.number {
                        Button(action: {
                            withAnimation(.easeInOut, {
                                game.currentHoleIndex = number - 1
                                game.updateMapCamera(locationManager: locationManager)
                            })
                            showingScoreSheet = true
                        }, label: {
                            Text(String(number))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .fontDesign(.rounded)
                                .foregroundStyle(game.currentHoleIndex + 1 == number ? Color.white : Color("Navy"))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 35)
                                .background(game.currentHoleIndex + 1 == number ? Color("Teal") : game.currentHoleIndex < number ? Color(uiColor: .systemBackground) : Color("Lime"))
                                .cornerRadius(12)
                        })
                    }
                }
                Button(action: {
                    game.currentHoleIndex = game.course?.baskets?.count ?? 0
                    showingScoreSheet = false
                }, label: {
                    Text("Results")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .foregroundStyle(game.currentHoleIndex  == game.course?.baskets?.count ?? 0 ? Color.white : Color("Navy"))
                        .padding(8)
                        .background(game.currentHoleIndex == game.course?.baskets?.count ? Color("Teal") : Color(uiColor: .systemBackground))
                        .cornerRadius(12)
                })
            }
        }
        .padding(8)
        .background(.regularMaterial)
//                .shadow(radius: 12)
        .cornerRadius(12)
        .padding(12)
    }
}
struct PlayerScoresListView: View {
    @Query var scores: [PlayerScore]
    var game: Game
    
    init(game: Game) {
        let currentBasket = game.currentBasket?.number
        let gameUUID = game.uuid
        _scores = Query(filter: #Predicate<PlayerScore> {  $0.basket?.number  == currentBasket && $0.game?.uuid == gameUUID },
                        sort: \PlayerScore.player?.name)
        
        self.game = game //.init(initialValue: game)
    }
    
    var body: some View {
        List(scores) {
            playerScore in
            HStack {
                if let player = playerScore.player {
                    PlayerProfileCircleView(player: player, size: 53)
                    Text(player.name)
                        .font(.headline)
                        .foregroundStyle(Color("Navy"))
                    Spacer()
                    Button(action: {
                        playerScore.score -= 1
                        game.send()
                    }, label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color("Pink"))
                    })
                    .buttonStyle(.plain)
                    .disabled(playerScore.score == 0)
                    Text("\(playerScore.score)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .foregroundStyle(Color("Navy"))
                    
                    Button(action: {
                        if playerScore.score == 0, let currentBasket = game.currentBasket, let par = Int(currentBasket.par) {
                            playerScore.score = par
                        }else {
                            playerScore.score += 1
                        }
                        game.send()
                        print("Increment")
                    }, label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color("Lime"))
                    })
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.plain)
    }
}
//#Preview {
//    GameView()
//        .modelContainer(GamesPreviewContainer)
//}


extension PresentationDetent {
    static let full = Self.height(400)
    static let dismissed = Self.height(120)
}