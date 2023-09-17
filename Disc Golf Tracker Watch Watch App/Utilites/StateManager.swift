//
//  StateManager.swift
//  Disc Golf Tracker Watch Watch App
//
//  Created by Justin Lawrence on 9/17/23.
//

import Foundation

class StateManager: ObservableObject {
    @Published var selectedGame: Game?
    @Published var tabSelection: Int = 2
    @Published var showCreateGameSheet: Bool = false
}
