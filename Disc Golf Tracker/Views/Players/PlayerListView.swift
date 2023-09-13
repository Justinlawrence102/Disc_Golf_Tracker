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

    @Query(filter: #Predicate<Player> { !$0.isSharedGame}) private var players: [Player]
//    @Query private var players: [Player]

    @State var selectedPlayer: Player?
    @State var selectedNewPlayer = true
    var body: some View {
        NavigationStack { //NavigationSplitView
            List(players, id: \.self) { player in
                ZStack {
                    NavigationLink(value: player) {
                        HStack {
                                PlayerProfileCircleView(player: player, size: 50)
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

#Preview {
    PlayerListView()
        .modelContainer(previewContainer)
}

struct PlayerProfileCircleView: View {
    var player: Player
    var size: CGFloat
    var body: some View {
        if let playerImage = player.image, let image = UIImage(data: playerImage) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .background(player.getColor())
                .cornerRadius(size/2)
        }else {
            Image(systemName: "figure.disc.sports")
                .frame(width: size, height: size)
                .background(player.getColor())
                .cornerRadius(size/2)
                .foregroundStyle(Color("Teal"))
                .font(.title3)
        }
    }
}
