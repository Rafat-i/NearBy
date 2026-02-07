//
//  Category.swift
//  NearBy
//
//  Created by Ace of Heart on 2026-02-07.
//

import Foundation

enum GeneralCategory{
    case food, drink, things2do, shopping, services
}

//restaurant, coffee, bars, brunch, dessert, gas, hotels, atms, pharmacies, hospitalsNclinics, parking, barber, gym, groceries, beauty, apparel, electronics, cinema, arcade, libraries, museums, parks, convini, sports
struct Category : Identifiable{
    
    let id: UUID = UUID()
    var name: String
    var type: GeneralCategory
    var icon: String
    var hexColor: String
    
    internal init(name: String, type: GeneralCategory, icon: String, hexColor: String) {
        self.name = name
        self.type = type
        self.icon = icon
        self.hexColor = hexColor
    }
}
