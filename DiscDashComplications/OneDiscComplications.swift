//
//  OneDiscComplications.swift
//  OneDiscComplications
//
//  Created by Justin Lawrence on 9/23/23.
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> GameEntry {
        let tempGame = Game()
        tempGame.startDate = Date()
        return GameEntry(date: Date(), currentGame: tempGame)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (GameEntry) -> Void) {
        completion(GameEntry(date: Date()))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<GameEntry>) -> Void) {
        var currentGame: Game?
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())
        do {
            let modelContext = ModelContext(PersistantData.container)
            
            let date = Date()
            let cal = Calendar.current
            let startOfDay = cal.startOfDay(for: date)
            let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay)!
            var currentGameFetch = FetchDescriptor<Game>(predicate: #Predicate {$0.endDate == nil && ($0.startDate >= startOfDay && $0.startDate < endOfDay) }, sortBy: [SortDescriptor(\.startDate)])
            currentGameFetch.fetchLimit = 1
            let currentGames = try modelContext.fetch(currentGameFetch)
            print("Fetching...")
            print(currentGames.count)
            currentGame = currentGames.first
        } catch let error {
            print(error)
        }
        
        let entry = GameEntry(date: Date(), currentGame: currentGame)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate ?? Date()))
        completion(timeline)
    }
}

struct GameEntry: TimelineEntry {
    let date: Date
    var currentGame: Game?
}

struct OneDiscComplicationsEntryView : View {
    var entry: Provider.Entry
    @Environment (\.widgetRenderingMode) var renderingMode
    
    var body: some View {
        if let game = entry.currentGame {
            HStack {
                VStack(alignment: .leading) {
                    if let currentBasket = game.currentBasket {
                        Text("Hole \(currentBasket.number ?? 0)")
                            .font(.headline)
                            .foregroundStyle(Color("Teal"))
                        if currentBasket.par != "" {
                            Text("Par \(currentBasket.par)")
                                .font(.caption)
                                .foregroundStyle(Color("Pink"))
                        }
                        if currentBasket.distance != "" {
                            Label("\(currentBasket.distance) Ft", systemImage: "location.fill")
                                .font(.caption)
                                .foregroundStyle(Color("Navy"))
                        }
                    }
                }
                Spacer()
                ForEach(game.getResults(limit3: true)) {
                    player in
                    Divider()
                    VStack {
                        if renderingMode == .fullColor {
//                            Text(player.name.prefix(2))
//                                .font(.headline)
                            if let player = player.player {
                                PlayerProfileCircleView(player: player, size: 25)
                            }
                        }else {
                            Text(player.name.prefix(2))
                                .font(.headline)
                        }
                       
                        Text("\(player.score)")
                            .fontDesign(.rounded)
                            .font(.subheadline)
                            .foregroundStyle(Color("Navy"))
                    }
                }
            }
        }else {
            VStack {
                VStack(alignment: .leading) {
                    Text("OneDisc")
                        .font(.headline)
                        .foregroundStyle(Color("Pink"))
                    Text("Tap to start a game.")
                        .font(.caption2)
                        .fontWeight(.regular)
                        .foregroundStyle(Color("Navy"))
                }
            }
        }
    }
}

@main
struct OneDiscComplications: Widget {
    let kind: String = "scoreCard-widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) {
            entry in
                        OneDiscComplicationsEntryView(entry: entry)
                .containerBackground(.white, for: .widget)
        }
        .configurationDisplayName("Score Card")
        .description("Shows a snapshot of the score card of your current game")
        .supportedFamilies([.accessoryRectangular])
    }
}

#Preview(as: .accessoryRectangular) {
    OneDiscComplications()
} timeline: {
    GameEntry(date: .now)}
