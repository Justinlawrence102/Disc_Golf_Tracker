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
    @State var game: Game

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @Namespace private var animation
    
    @State var mapManager = MapManager()
    
    @State var showingEditBasketInfoSheet = false
    @State var showDeleteGameAlert = false

    @State var showingScoreSheet = true
    @State private var selectedDetent = PresentationDetent.full
    @State var sheetIsUp = true //this is used for the animation of the hole, par, distance popover
    @State var isActivitySharingSheetPresented = false
    @StateObject var groupStateObserver = GroupStateObserver()
    @State private var showFullMapToggle = false

    @State var scrollPosition = 0
    
    var sortedBasketsList: [Basket] {
      return (game.course?.baskets ?? []).sorted(by: {$1.number ?? 0 > $0.number ?? 0})
    }

    @Environment(LocationManager.self) var locationManager
    @Environment(SharedActivityManager.self) var sharePlayManager
    
    @Binding var selectedGame: Game?
    

    init(game: Game, selectedGame: Binding<Game?>) {
        _game = State(initialValue: game)
        _selectedGame = selectedGame
    }
    var body: some View {
        ZStack {
            if let basket = game.currentBasket {
                ZStack {
                    GameMapView(cameraPosition: $mapManager.cameraPosition, showFullMapToggle: showFullMapToggle, sortedBasketsList: sortedBasketsList, basket: basket)
                        .overlay(alignment: .bottom, content: {
                            VStack(spacing: 12) {
                                TopOfSheetDetailsView(animation: animation, sheetIsUp: sheetIsUp, basket: basket, showFullMapToggle: $showFullMapToggle)
                                    .padding(.horizontal, 8.0)
                                ManageBasketDetailsView(animation: animation, sheetIsUp: sheetIsUp, basket: basket, game: game, showingEditBasketInfoSheet: $showingEditBasketInfoSheet)
                                    .frame(minHeight: 390, alignment: .top)
                                    .background(Gradient(colors: [Color(UIColor.systemBackground).opacity(0), Color(UIColor.systemBackground).opacity(01)]))
                            }
                        })
                }
            }else {
                ResultsView(game: game)
                    .onAppear {
                        print("Hiding")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingScoreSheet = false
                        }
                        if game.endDate == nil {
                            game.endDate = Date()
                        }
                    }
            }
          
            VStack {
                Spacer()
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Gradient(colors: [Color(UIColor.systemBackground).opacity(0.6), Color(UIColor.systemBackground).opacity(0)]))
                Spacer()
            }
            VStack {
                BasketPickerView(game: game, showingScoreSheet: $showingScoreSheet, scrollPosition: $scrollPosition)
                    .environment(mapManager)
                Spacer()
            }
        }
//        .overlay(alignment: .top, content: {
//            Spacer()
//                .frame(maxWidth: .infinity)
//                .frame(height: 80)
//                .background(Gradient(colors: [Color(UIColor.systemBackground).opacity(0.6), Color(UIColor.systemBackground).opacity(0)]))
//        })
        .onChange(of: selectedGame, {
            old, new in
            if selectedGame == nil {
                showingScoreSheet = false
            }
//            if !navigationPath.contains(where: {$0.uuid == game.uuid}) {
//                showingScoreSheet = false
//            }
        })
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
                Menu {
                    if groupStateObserver.isEligibleForGroupSession && sharePlayManager.gameModel?.uuid == game.uuid {
                        Button(action: {
                            sharePlayManager.startSharing(game: game)
                        }) {
                            Label("Shareplay", systemImage: "shareplay")
                                .symbolEffect(.variableColor.cumulative.dimInactiveLayers.nonReversing, options: .repeating)
                        }
                        
                    }else {
                        Button(action: {
                            isActivitySharingSheetPresented = true
                            sharePlayManager.gameModel = game
                        }) {
                            Label("Shareplay", systemImage: "shareplay")
                        }
                    }
                    Button(action: {
                        game.resetScores()
                        game.calculateResults(context: modelContext)
                    }) {
                        Label("Recalculate Scores", systemImage: "arrow.counterclockwise")
                    }
                    Button(role: .destructive, action: {
                        showDeleteGameAlert.toggle()
                    }) {
                        Label("Delete Game", systemImage: "trash")
                    }
                } label: {
                    Label( "Options", systemImage: "ellipsis")
                }
                
            }
        }
        .sheet(isPresented: $showingScoreSheet, content: {
            PlayerScoresListView(game: game)
                .presentationDetents([.height(400), .height(150)], selection: $selectedDetent)
                .presentationBackgroundInteraction(
                    .enabled
                )
                .interactiveDismissDisabled()
//                .background(Color(UIColor.systemBackground).opacity(0.7))
                .onChange(of: selectedDetent, {
                    withAnimation(.spring()) {
                        sheetIsUp.toggle()
                    }
                })
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
            withAnimation {
                mapManager.updateMapCamera(currentBasket: game.currentBasket, locationManager: locationManager)
            }
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
            showingScoreSheet = false
        }
        .alert("Delete Game", isPresented: $showDeleteGameAlert) {
            Button("Delete", role: .destructive) {
                let gameId = game.uuid
                do {
                    try modelContext.delete(model: Game.self, where: #Predicate<Game> { $0.uuid == gameId}, includeSubclasses: false)
                    dismiss.callAsFunction()
                }catch {
                    print("Could not delete!")
                }
            }
            Button("Cancel", role: .cancel) { }
        }message: {
            Text("Are you sure you want to delete this game from \(game.formattedStartDate)?")
        }
        
//        .task {
//            for await session in SharePlayActivity.sessions() {
//                game.configureGroupSession(session)
//            }
//        }
    }
}

struct TopOfSheetDetailsView: View {
    let animation: Namespace.ID
    
    var sheetIsUp: Bool
    var basket: Basket
    @Binding var showFullMapToggle: Bool
    var body: some View {
        HStack(alignment: .bottom) {
            if sheetIsUp {
                CurrentBasketInfoView(basket: basket, alignment: .leading)
                    .padding(8)
                    .glassEffect(in: .rect(cornerRadius: 12))
                    .matchedGeometryEffect(id: "CurrentHoleView", in: animation)
            }
            Spacer()
            Button {
                showFullMapToggle.toggle()
                print("Toggle map")
            } label: {
                Image(systemName: "map.fill")
                    .font(.title)
                    .foregroundStyle(showFullMapToggle ? .white: Color("Teal") )
            }
            .buttonStyle(.glassProminent)
            .tint(showFullMapToggle ? Color("Teal") : .clear)
            
        }
        TipView(AddBasketAndTeeTip())
    }
}

struct ManageBasketDetailsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) var locationManager
    
    let animation: Namespace.ID
    
    var sheetIsUp: Bool
    var basket: Basket
    var game: Game
    
    @Binding var showingEditBasketInfoSheet: Bool

    @State var showingAddTeeAlert = false
    @State var showingAddBasketAlert = false

    var body: some View {
        VStack(spacing: 12.0) {
            if !sheetIsUp {
                CurrentBasketInfoView(basket: basket, alignment: .center)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .glassEffect(in: .rect(cornerRadius: 12))
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
                    .glassEffect(in: .rect(cornerRadius: 12))
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
                    .glassEffect(in: .rect(cornerRadius: 12))
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
                    Text("\(basket.distance) \(Locale.current.measurementSystem == .us ? "Feet" : "Meters")")
                }
                .font(.subheadline)
                .foregroundStyle(Color("Navy"))
            }
        }
    }
}

struct BasketPickerView: View {
    @Environment(LocationManager.self) var locationManager
    @Environment(SharedActivityManager.self) var sharePlayManager
    @Environment(MapManager.self) private var mapManager

    var game: Game
    
    @Binding var showingScoreSheet: Bool
    @Binding var scrollPosition: Int
    var body: some View {
        ScrollViewReader { sp in
            GlassEffectContainer(content: {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(game.course?.sortedBaskets ?? []) {
                            basket in
                            if let number = basket.number {
                                Button(action: {
                                    //                                AddBasketAndTeeTip.selectedABasket.sendDonation()
                                    withAnimation {
                                        game.currentHoleIndex = number - 1
                                    }
                                    sharePlayManager.send(game)
                                    print("Change Basket")
                                    showingScoreSheet = true
                                }, label: {
                                    Text(String(number))
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .fontDesign(.rounded)
                                        .foregroundStyle(game.currentHoleIndex + 1 == number ? Color.white : Color("Navy"))
                                        .padding(.horizontal, 25)
                                    //                                            .cornerRadius(12)
                                })
//                                .buttonStyle(.glass)
                                .buttonStyle(.glassProminent)
//                                .buttonStyle(.borderedProminent)
                                .tint(game.currentHoleIndex + 1 == number ? Color("Teal") : game.currentHoleIndex < number ? Color(uiColor: .systemBackground) : Color("Lime"))
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
                            //                                    .cornerRadius(12)
                        })
//                        .buttonStyle(.glass)
                        .buttonStyle(.glassProminent)
//                        .buttonStyle(.borderedProminent)
//                        .tint(Color("Teal"))
                        .tint(game.currentHoleIndex  == game.course?.baskets?.count ?? 0 ? Color("Teal") : Color(uiColor: .systemBackground))
                        .id((game.course?.baskets?.count ?? 99)+1)
                    }
                    
                }
                .scrollIndicators(.hidden)
            })
            .onChange(of: scrollPosition) {
                sp.scrollTo(scrollPosition)
            }
            .padding(8)
            .glassEffect()
            .clipShape(Capsule())
            .padding(12)
        }
    }
}
struct PlayerScoresListView: View {
    @Query var scores: [PlayerScore]
    var game: Game
    @State private var isAnimateCountDown = false
    @Environment(SharedActivityManager.self) var sharePlayManager
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
                .listRowBackground(Color.clear)
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
    static let dismissed = Self.height(150)
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
                    TextField("Disntance (\(Locale.current.measurementSystem == .us ? "Feet" : "Meters"))", text: $basket.distance, prompt: Text("Distance"))
                        .keyboardType(.numberPad)
                        .foregroundStyle(Color("Navy"))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .multilineTextAlignment(.center)
                        .frame(width: 85, height: 50)
                        .background(Color(UIColor.secondarySystemFill))
                        .cornerRadius(12)
                    Text("Distance (\(Locale.current.measurementSystem == .us ? "Ft" : "M"))")
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

struct CustomListsSettings_Previews: PreviewProvider {

    static var previews: some View {
        @State var selectedGame: Game? = Game()
        NavigationStack {
            GameView(game: Game(), selectedGame: $selectedGame)
                .environment(LocationManager())
                .environment(SharedActivityManager())
                .modelContainer(GamesPreviewContainer)
        }
    }
}

//#Preview {
//    MainActor.assumeIsolated {
//        return  NavigationStack {
//            GameView(game: Game(), navigationPath: <#Binding<Bool>#>)
//                .environment(LocationManager())
//                .environment(SharedActivityManager())
//                .modelContainer(GamesPreviewContainer)
//        }
//    }
//}
