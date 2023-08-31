//
//  PlayerListView.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 8/23/23.
//

import SwiftUI
import SwiftData

struct PlayerListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var players: [Player]

    @State var selectedPlayer: Player?
    @State var selectedNewPlayer = false
    var body: some View {
        NavigationStack { //NavigationSplitView
            List(players, id: \.self) { player in
                ZStack {
                    NavigationLink(value: player) {
                        HStack {
                                PlayerProfileCircleView(player: player)
                        
                            VStack(alignment: .leading) {
                                Text(player.name)
                                    .font(.headline)
                                if let lastPlay = player.lastPlay {
                                    Text(String(lastPlay.timeIntervalSince1970))
                                        .font(.subheadline)
                                }
                            }
                            .foregroundStyle(Color("Navy"))
                        }
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        selectedNewPlayer = false
                        selectedPlayer = player
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button {
                        modelContext.delete(player)
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .tint(.red)
                    }
                }
            }
            .navigationDestination(for: Player.self) { player in
                Text("Details")
                    .navigationTitle(player.name)
                    .navigationBarTitleDisplayMode(.inline)
                
            }
            .navigationTitle("Players")
            .toolbar {
                Button(action: {
                    selectedNewPlayer = true
                    selectedPlayer = Player()
                }) {
                    Label("New Player", systemImage: "plus")
                }
            }
        }
        .tint(Color("Teal"))
        .sheet(item: $selectedPlayer) { item in
            CreatePlayerView(player: item, isNewPerson: selectedNewPlayer)
                .presentationDetents([.medium])
                .interactiveDismissDisabled()
        }
    }
}

struct CreatePlayerView: View {
    @Environment(\.modelContext) private var playerContext
    @Environment(\.dismiss) private var dismiss
    @State var player: Player
    
    var isNewPerson: Bool

    var playerColors: [String] = [ "C7F465", "FE6B6B", "4ECDC4", "58636D", "059EDF", "F2F2F7", "FF003D", "FF9900", "FDD608", "00AE26", "0906A7", "6507AE" ]
    

    var items: [GridItem] {
        Array(repeating: .init(.adaptive(minimum: 120)), count: playerColors.count/2)
    }
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button(action: {
                        dismiss.callAsFunction()
                    }) {
                        Text("Cancel")
                            .font(.body)
                            .foregroundStyle(Color("Teal"))
                    }
                    Text("New Player")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("Pink"))
                        .frame(maxWidth: .infinity)

                    Button(action: {
                        if isNewPerson {
                            playerContext.insert(player)
                            player.scores = []
                        }else {
                            do {
                                try playerContext.save()
                            }catch {print("Could not save")}
                        }
                        dismiss.callAsFunction()
                    }) {
                        Text(isNewPerson ? "Save" : "Update")
                            .font(.body)
                            .foregroundStyle(Color("Teal"))
                            .fontWeight(.semibold)
                    }
                }
                .padding(12.0)
                Spacer()
            }
            ScrollView {
                VStack(alignment: .leading) {
                    ZStack {
                        if let playerImage = player.image, let image = UIImage(data: playerImage) {
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .background(Color(UIColor(hex: player.color)!))
                                    .cornerRadius(40)
                        }else {
                            Image(systemName: "figure.disc.sports")
                                .frame(width: 80, height: 80)
                                .background(Color(UIColor(hex: player.color)!))
                                .cornerRadius(40)
                                .foregroundStyle(Color("Teal"))
                                .font(.title)
                        }
                    }
                    .padding(.top)
                    .frame(maxWidth: .infinity)
                    TextField(
                           "Name",
                           text: $player.name
                       )
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .foregroundStyle(Color("Navy"))
                    .cornerRadius(12)
                    .padding([.leading, .bottom, .trailing])

                    
                    Text("Photo")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("Navy"))
                    ScrollView(.horizontal) {
                        HStack(spacing: 12.0){
                            Button(action: {
                                print("Tapped Camera")
                            }, label: {
                                Image(systemName: "camera.fill")
                                    .frame(width: 75, height: 75)
                                    .background(Color("Teal"))
                                    .cornerRadius(37.5)
                                    .tint(.white)
                                    .font(.title)
                            })
                            Button(action: {
                                print("Tapped Clipbard")
                            }, label: {
                                Image(systemName: "doc.on.clipboard")
                                    .frame(width: 75, height: 75)
                                    .background(Color("Teal"))
                                    .cornerRadius(37.5)
                                    .tint(.white)
                                    .font(.title)
                            })
                            Button(action: {
                                print("Tapped Contacts")
                            }, label: {
                                Image(systemName: "person.crop.circle.fill")
                                    .frame(width: 75, height: 75)
                                    .background(Color("Teal"))
                                    .cornerRadius(37.5)
                                    .tint(.white)
                                    .font(.title)
                            })
                            Button(action: {
                                if let img = UIImage(named: "Boy") {
                                    player.image = img.pngData()!
                                }
                            }, label: {
                                Image("Boy")
                                    .resizable()
                                    .frame(width: 75, height: 75)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(37.5)
                                    .tint(.white)
                                    .font(.title)
                            })
                            Button(action: {
                                if let img = UIImage(named: "Girl") {
                                    player.image = img.pngData()!
                                }
                            }, label: {
                                Image("Girl")
                                    .resizable()
                                    .frame(width: 75, height: 75)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(37.5)
                                    .tint(.white)
                                    .font(.title)
                            })
                        }
                    }
                    Text("Color")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("Navy"))

                    LazyVGrid(columns: items) {
                        ForEach(playerColors, id: \.self) { color in
                            Button(action: {
                                player.color = color
                            }, label: {
                                ZStack {
                                    if player.color == color {
                                        Circle()
                                            .foregroundStyle(Color(UIColor.systemGray3))
                                            .cornerRadius(25)
                                            .frame(width: 55)
                                    }
                                    Circle()
                                        .frame(width: 45)
                                        .foregroundStyle(Color(UIColor(hex: color)!))
                                }
                                .frame(height: 55)
                            })
                        }
                    }
                    Spacer()
                }
                .scrollClipDisabled(true)
                .padding([.leading, .bottom, .trailing], 12.0)
            }
            .padding(.top, 40)
        }
    }
}

#Preview {
    PlayerListView()
        .modelContainer(previewContainer)
//    CreatePlayerView()
}

struct PlayerProfileCircleView: View {
    var player: Player
    var body: some View {
        if let playerImage = player.image, let image = UIImage(data: playerImage) {
            Image(uiImage: image)
                .resizable()
                .frame(width: 50, height: 50)
                .background(player.getColor())
                .cornerRadius(25)
        }else {
            Image(systemName: "figure.disc.sports")
                .frame(width: 50, height: 50)
                .background(player.getColor())
                .cornerRadius(25)
                .foregroundStyle(Color("Teal"))
                .font(.title3)
        }
    }
}
