//
//  Category.swift
//  NearBy
//
//  Created by Ace of Heart on 2026-02-07.
//


import Foundation

struct Category: Identifiable, Codable {
    var id: String
    var name: String
    var iconName: String?
    var colorHex: String?
    
    init(id: String, name: String, iconName: String? = nil, colorHex: String? = nil) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
    }
}


extension Category {
    static let defaultCategories: [Category] = [
        Category(id: "restaurants", name: "Restaurants", iconName: "fork.knife", colorHex: "RestaurantColor"),
        Category(id: "cafes", name: "Cafés", iconName: "cup.and.saucer", colorHex: "CafeColor"),
        Category(id: "parks", name: "Parks", iconName: "tree", colorHex: "ParkColor"),
        Category(id: "shopping", name: "Shopping", iconName: "cart", colorHex: "ShoppingColor"),
        Category(id: "libraries", name: "Libraries", iconName: "book", colorHex: "LibraryColor"),
        Category(id: "education", name: "Education", iconName: "graduationcap", colorHex: "EducationColor"),
        Category(id: "entertainment", name: "Entertainment", iconName: "theatermasks", colorHex: "EntertainmentColor")
    ]
}
