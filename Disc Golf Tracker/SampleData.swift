//
//  SampleData.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 8/25/23.
//

import Foundation

import SwiftUI
import SwiftData
@MainActor
let previewContainer: ModelContainer = {
    do {
        
        let container = try ModelContainer(for: Player.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        container.mainContext.insert(Player(name: "Justin", color: "C7F465"))
        container.mainContext.insert(Player(name: "Allison", color: "C7F465"))

        return container
    } catch {
        fatalError ("Failed to create container")
    }
}( )


@MainActor
let allCoursesPreviewContainer: ModelContainer = {
    do {
        
        let container = try ModelContainer(for: Course.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
        let testCourse = Course(name: "Sample")
        container.mainContext.insert(testCourse)
        let basket1 = Basket(number: 1, course: testCourse)
        container.mainContext.insert(basket1)
        
        container.mainContext.insert(Course(name: "Test 1"))
        container.mainContext.insert(Course(name: "Test 2"))

        return container
    } catch {
        fatalError ("Failed to create container")
    }
}( )

@MainActor
let CoursePreviewContainer: ModelContainer = {
    do {
        
        let container = try ModelContainer(for: Course.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
        let sampleCourse = Course(name: "Sample Course")
        sampleCourse.latitude = 28.62041
        sampleCourse.longitude = -81.36625
        container.mainContext.insert(sampleCourse)
        let basket1 = Basket(number: 1, course: sampleCourse)
        basket1.par = "3"
        basket1.distance = "500"
        container.mainContext.insert(basket1)
        
        let basket2 = Basket(number: 2, course: sampleCourse)
        basket2.par = "4"
        basket2.distance = "650"
        container.mainContext.insert(basket2)
        

        return container
    } catch {
        fatalError ("Failed to create container")
    }
}( )

@MainActor
let GamesPreviewContainer: ModelContainer = {
    do {
        
        let container = try ModelContainer(for: Game.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
        let sampleCourse = Course(name: "Sample Course")
        sampleCourse.latitude = 28.62041
        sampleCourse.longitude = -81.36625
        container.mainContext.insert(sampleCourse)
        let basket1 = Basket(number: 1, course: sampleCourse)
        basket1.par = "3"
        basket1.distance = "500"
        container.mainContext.insert(basket1)
        
        let basket2 = Basket(number: 2, course: sampleCourse)
        basket2.par = "4"
        basket2.distance = "650"
        container.mainContext.insert(basket2)
        
        let game = Game()
        game.course = sampleCourse
        container.mainContext.insert(game)
        
        let player = Player(name: "Sample Player", color: "C7F465")
        container.mainContext.insert(player)
        
        let playerScore = PlayerScore(player: player, game: game, basket: basket1)
        container.mainContext.insert(playerScore)
        
        let playerScore2 = PlayerScore(player: player, game: game, basket: basket2)
        container.mainContext.insert(playerScore2)
        
        let player2 = Player(name: "Sample Player2", color: "C70465")
        container.mainContext.insert(player2)
        
        let playerScore3 = PlayerScore(player: player2, game: game, basket: basket1)
        container.mainContext.insert(playerScore3)
        let playerScore4 = PlayerScore(player: player2, game: game, basket: basket2)
        container.mainContext.insert(playerScore4)
        

        return container
    } catch {
        fatalError ("Failed to create container")
    }
}( )
