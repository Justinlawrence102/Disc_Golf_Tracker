//
//  AddBasketAndTeeTip.swift
//  OneDisc
//
//  Created by Justin Lawrence on 9/27/23.
//

import Foundation
import TipKit

struct AddBasketAndTeeTip: Tip {
    @Parameter
    static var hasAddedALocation: Bool = false
    static let selectedABasket = Event(id: "openedMultipleBaskets")

    var rules: [Rule] {
        #Rule(Self.$hasAddedALocation) { $0 == false }
        #Rule(Self.selectedABasket) {$0.donations.count >= 3}
    }
    
    var title: Text {
        Text("Save Basket and Tee Location")
            .foregroundStyle(Color("Teal"))
    }
    
    var message: Text? {
        Text("Swipe down on the Score List save basket and tees. The next time you use play this course, you will have a detailed map!")
    }
    var image: Image? {
        Image(systemName: "arrow.down.circle.fill")
    }
    
}
