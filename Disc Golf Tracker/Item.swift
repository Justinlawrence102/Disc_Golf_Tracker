//
//  Item.swift
//  DiscDash
//
//  Created by Justin Lawrence on 9/23/23.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
