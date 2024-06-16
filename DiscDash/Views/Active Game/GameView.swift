//
//  GameView.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 9/3/23.
//

import SwiftUI
import SwiftData
import MapKit
import GroupActivities
import TipKit

struct GameView: View {
    @Environment(\.modelContext) private var modelContext
    @Namespace private var animation
    @Namespace private var mapScope

//    @Query private var games: [Game]
//    var game: Game! { games.first }
    
    @State var game: Game
    @State var mapManager = MapManager()
    
    @Query var scores: [PlayerScore]
    @State var showingAddTeeAlert = false
    @State var showingAddBasketAlert = false
    @State var showingEditBasketInfoSheet = false

    @State var showingScoreSheet = true
    @State private var selectedDetent = PresentationDetent.full
    @State var sheetIsUp = true //this is used for the animation of the hole, par, distance popover
    @State var isActivitySharingSheetPresented = false
    @StateObject var groupStateObserver = GroupStateObserver()
    @State private var showFullMapToggle = false

    @State var scrollPosition = 0
    @State private var heading: Double = 0
    
    var sortedBasketsList: [Basket] {
      return (game.course?.baskets ?? []).sorted(by: {$1.number ?? 0 > $0.number ?? 0})
    }

    @Environment(LocationManager.self) var locationManager
    @EnvironmentObject var sharePlayManager: SharedActivityManager
    var body: some View {
        ZStack {
            if let basket = game.currentBasket {
                VStack(spacing: -0.0) {
//                    Map {
                    Map(position: $mapManager.cameraPosition, scope: mapScope) {
                        //                    Map(scope: mapScope) {
                        //                    Map(position: $position) {
                        if showFullMapToggle {
                            ForEach(sortedBasketsList) {
                                hole in
                                ForEach(hole.teeCoordinates, id: \.self) {
                                    teeCoordinate in
                                    Marker("", systemImage: "\(hole.number ?? 1).square.fill", coordinate: teeCoordinate)
                                        .tint(Color("Teal"))
                                    ForEach(hole.basketCoordinates, id: \.self) {
                                        basketCoordiante in
                                        if let currentNumber = basket.number, let holeHumber = hole.number {
                                            if currentNumber == holeHumber {
                                                MapPolyline(points: [MKMapPoint(basketCoordiante), MKMapPoint(teeCoordinate)])
                                                    .stroke(Color("LightPink"), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                            } else {
                                                MapPolyline(points: [MKMapPoint(basketCoordiante), MKMapPoint(teeCoordinate)])
                                                    .stroke(.tertiary, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                            }
                                        }
                                    }
                                }
                                ForEach(hole.basketCoordinates, id: \.self) {
                                    basketCoordinate in
                                    Marker("", systemImage: "arrow.up.bin.fill", coordinate: basketCoordinate)
                                        .tint(Color("Pink"))
                                }
                                if let index = sortedBasketsList.firstIndex(of: hole), sortedBasketsList.indices.contains(index+1){
                                    if let currentBasket = hole.basketCoordinates.first, let nextTee = sortedBasketsList[index+1].teeCoordinates.first {
                                        MapPolyline(points: [MKMapPoint(currentBasket), MKMapPoint(nextTee)])
                                            .stroke(.secondary, style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [3, 5]))
                                    }
                                }
                            }
                        }else {
                            ForEach(basket.teeCoordinates, id: \.self) {
                                teeCoordinate in
                                Marker("", systemImage: "\(basket.number ?? 1).square.fill", coordinate: teeCoordinate)
                                    .tint(Color("Teal"))
                                ForEach(basket.basketCoordinates, id: \.self) {
                                    basketCoordiante in
                                    MapPolyline(points: [MKMapPoint(basketCoordiante), MKMapPoint(teeCoordinate)])
                                        .stroke(Color("LightPink"), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                }
                            }
                            ForEach(basket.basketCoordinates, id: \.self) {
                                basketCoordinate in
                                Marker("", systemImage: "arrow.up.bin.fill", coordinate: basketCoordinate)
                                    .tint(Color("Pink"))
                            }
                        }
                        UserAnnotation(content: {
                            CurrentLocationPinView(heading: $heading, locationManager: locationManager)
                        })
                        
                    }
                    .overlay(alignment: .bottomTrailing) {
                        VStack {
                            MapCompass(scope: mapScope)
                                .mapControlVisibility(.automatic)
                            Spacer()
                                .frame(height: 110)
                        }
                        .padding(.trailing, 8)
                    }
                    .mapControlVisibility(.hidden)
                    .onMapCameraChange(frequency: .continuous) { context in
                        withAnimation {
                            heading = context.camera.heading
                        }
                    }
                    .mapScope(mapScope)

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
                                    AddBasketAndTeeTip.hasAddedALocation = true
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
//                                if (basket.par == "" || basket.distance == "") {
                                    Button(action: {
                                        showingEditBasketInfoSheet.toggle()
                                        print("Show info")
                                    }, label: {
                                        Label("Basket Info", systemImage: "info.circle.fill")
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color("Teal"))
                                            .foregroundStyle(Color.white)
                                            .cornerRadius(20)
                                    })
                                    Spacer()
//                                }
                                Button(action: {
                                    print("Save Basket")
                                    AddBasketAndTeeTip.hasAddedALocation = true
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
                    .frame(height: 350)
                }
                VStack() {
                    Spacer()
                    HStack(alignment: .bottom) {
                        if sheetIsUp {
                            CurrentBasketInfoView(basket: basket, alignment: .leading)
                                .padding(8)
                                .background(.regularMaterial)
                                .cornerRadius(12)
                                .matchedGeometryEffect(id: "CurrentHoleView", in: animation)
                        }
                        Spacer()
                        Button {
                            showFullMapToggle.toggle()
                            print("Toggle map")
                        } label: {
                            Image(systemName: "map.fill")
                                .frame(width: 45, height: 45)
                                .background(.regularMaterial)
                                .background(showFullMapToggle ? Color("Teal") : .clear)
                                .cornerRadius(22.5)
                        }
                        
                    }
                    TipView(AddBasketAndTeeTip())
                    Spacer()
                        .frame(height: 416)
                }
                .padding(.horizontal, 8.0)
            }else {
                ResultsView(game: game)
                    .onAppear {
                        showingScoreSheet = false
                        if game.endDate == nil {
                            game.endDate = Date()
                        }
                    }
            }
            
            VStack {
                BasketPickerView(game: game, showingScoreSheet: $showingScoreSheet, scrollPosition: $scrollPosition)
                    .environment(mapManager)
                Spacer()
            }
        }
        .frame(maxHeight: .infinity)
        .navigationTitle(game.course?.name ?? "Course")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(){
            print("Inital set map")
            mapManager.updateMapCamera(currentBasket: game.currentBasket, locationManager: locationManager)
            sharePlayManager.addGameToSharedActivity(game: game)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if groupStateObserver.isEligibleForGroupSession && sharePlayManager.gameModel?.uuid == game.uuid {
                    Button(action: {
                        sharePlayManager.startSharing(game: game)
                    }) {
                        Image(systemName: "shareplay")
                            .symbolEffect(.variableColor.cumulative.dimInactiveLayers.nonReversing, options: .repeating)
                    }
                    
                }else {
                    Button(action: {
                        isActivitySharingSheetPresented = true
                        sharePlayManager.gameModel = game
                    }) {
                        Image(systemName: "shareplay")
                    }
                }
                
            }
        }
        .sheet(isPresented: $showingScoreSheet, content: {
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
                .sheet(isPresented: $showingEditBasketInfoSheet) {
                    if let currentBasket = game.currentBasket {
                        EditBasketInfoSheet(basket: currentBasket, showingEditBasketInfoSheet: $showingEditBasketInfoSheet)
                            .presentationDetents([.height(150)])
                    }else {
                        Text("Hi?")
                    }
                }
        })
        .onChange(of: game.currentHoleIndex) {
            mapManager.updateMapCamera(currentBasket: game.currentBasket, locationManager: locationManager)
        }
        .onAppear {
            print("Start Tracking Heading")
            locationManager.startTrackingHeading()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    scrollPosition = game.currentHoleIndex+1
                }
            }
        }
        .onDisappear {
            print("Stop Tracking Heading")
            locationManager.stopTrackingHeading()
        }
//        .task {
//            for await session in SharePlayActivity.sessions() {
//                game.configureGroupSession(session)
//            }
//        }
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
            if basket.par != "" {
                Text("Par \(basket.par)")
                    .font(.body)
                    .foregroundStyle(Color("Pink"))
            }
            if basket.distance != "" {
                HStack(spacing: 4.0) {
                    Image(systemName: "location.fill")
                    Text("\(basket.distance) Feet")
                }
                .font(.subheadline)
                .foregroundStyle(Color("Navy"))
            }
        }
    }
}

struct BasketPickerView: View {
    @Environment(LocationManager.self) var locationManager
    @EnvironmentObject var sharePlayManager: SharedActivityManager
    @Environment(MapManager.self) private var mapManager

    var game: Game
    
    @Binding var showingScoreSheet: Bool
    @Binding var scrollPosition: Int
    var body: some View {
        ScrollViewReader { sp in
            ScrollView(.horizontal) {
                HStack {
                    ForEach(game.course?.sortedBaskets ?? []) {
                        basket in
                        if let number = basket.number {
                            Button(action: {
                                Task {
                                    await AddBasketAndTeeTip.selectedABasket.donate()
                                }
                                withAnimation {
                                    game.currentHoleIndex = number - 1
                                    mapManager.updateMapCamera(currentBasket: game.currentBasket, locationManager: locationManager)
                                    sharePlayManager.send(game)
                                }
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
                            .id(basket.number)
                        }
                    }
                    Button(action: {
                        game.currentHoleIndex = game.course?.baskets?.count ?? 0
//                        showingScoreSheet = false
                        sharePlayManager.send(game)
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
                    .id((game.course?.baskets?.count ?? 99)+1)
                }
            }
            .onChange(of: scrollPosition) {
                sp.scrollTo(scrollPosition)
            }
            .padding(8)
            .background(.regularMaterial)
    //                .shadow(radius: 12)
            .cornerRadius(12)
            .padding(12)
        }
    }
}
struct PlayerScoresListView: View {
    @Query var scores: [PlayerScore]
    var game: Game
    @State private var isAnimateCountDown = false
    @EnvironmentObject var sharePlayManager: SharedActivityManager
    @StateObject var groupStateObserver = GroupStateObserver()
    
    init(game: Game) {
        let currentBasket = game.currentBasket?.number
        let gameUUID = game.uuid
        _scores = Query(filter: #Predicate<PlayerScore> {  $0.basket?.number  == currentBasket && $0.game?.uuid == gameUUID })
        
        self.game = game //.init(initialValue: game)
    }
    
    var body: some View {
        VStack {
            List(scores.sorted(by: {$1.player?.name ?? "" > $0.player?.name ?? ""})) {
                playerScore in
                HStack {
                    if let player = playerScore.player {
                        PlayerProfileCircleView(player: player, size: 53)
                        Text(player.name)
                            .font(.headline)
                            .foregroundStyle(Color("Navy"))
                        Spacer()
                        Button(action: {
                            isAnimateCountDown = true
                            withAnimation {
                                playerScore.decrementScore()
                            }
                            sharePlayManager.send(game)
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
                            .contentTransition(.numericText(countsDown: isAnimateCountDown))
                        
                        Button(action: {
                            isAnimateCountDown = false
                            withAnimation {
                                if let currentBasket = game.currentBasket, let par = Int(currentBasket.par) {
                                    playerScore.incrementScore(par: par)
                                }else {
                                    playerScore.score += 1
                                }
                            }
                            sharePlayManager.send(game)
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
            if let session = sharePlayManager.session, groupStateObserver.isEligibleForGroupSession && sharePlayManager.gameModel?.uuid == game.uuid {
                Spacer()

                HStack {
                    Image(systemName: "shareplay")
                    Text("\(session.activeParticipants.count) Connected")
                }
                .foregroundStyle(Color("Pink"))
            }
        }
    }
}


extension PresentationDetent {
    static let full = Self.height(400)
    static let dismissed = Self.height(120)
}

struct EditBasketInfoSheet: View {
    @State var basket: Basket
    @Binding var showingEditBasketInfoSheet: Bool
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                VStack(alignment: .leading){
                    TextField("Par", text: $basket.par, prompt: Text("Par"))
                        .keyboardType(.numberPad)
                        .foregroundStyle(Color("Navy"))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .multilineTextAlignment(.center)
                        .frame(width: 85, height: 50)
                        .background(Color(UIColor.secondarySystemFill))
                        .cornerRadius(12)
                    Text("Par")
                        .font(.subheadline)
                        .foregroundStyle(Color("Teal"))
                }
                Spacer()
                VStack(alignment: .leading){
                    TextField("Disntance (Feet)", text: $basket.distance, prompt: Text("Distance"))
                        .keyboardType(.numberPad)
                        .foregroundStyle(Color("Navy"))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .multilineTextAlignment(.center)
                        .frame(width: 85, height: 50)
                        .background(Color(UIColor.secondarySystemFill))
                        .cornerRadius(12)
                    Text("Distance (Ft)")
                        .font(.subheadline)
                        .foregroundStyle(Color("Teal"))
                }
            }
            .padding(16)
        }
        .overlay(alignment: .topTrailing ) {
            Button(action: {
                showingEditBasketInfoSheet = false
            }, label: {
                Text("Done")
                    .padding(12)
            })
        }
        .overlay(alignment: .top) {
            Text("Edit Basket Details")
                .padding(.top, 12)
                .font(.headline)
                .foregroundColor(Color("Pink"))
        }
    }
}

#Preview {
    MainActor.assumeIsolated {
        return  NavigationStack {
            GameView(game: Game())
                .environment(LocationManager())
                .environmentObject(SharedActivityManager())
                .modelContainer(GamesPreviewContainer)
        }
    }
}
