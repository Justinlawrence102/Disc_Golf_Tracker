//
//  Item.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 8/23/23.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Player {
    var name: String = ""
    
    @Attribute(.externalStorage)
    var image: Data?
    var lastPlay: Date?
    var color: String = "C7F465"
    var numGames: Int?
    
    @Relationship(deleteRule: .cascade, inverse: \PlayerScore.player)
    var scores: [PlayerScore]?
    
//    @Transient update doesn't propagate to view, so .ephemeral seems to be working instead https://developer.apple.com/forums/thread/731651
    
    @Attribute(.ephemeral) var isSelected: Bool = false
    
    init() {
        name = ""
        color = "C7F465"
    }
    init(name: String, color: String) {
        self.name = name
        self.color = color
        self.numGames = 0
    }
    
    func getColor()-> Color {
        return Color(UIColor(hex: color) ?? UIColor(named: "Pink")!)
    }
}

