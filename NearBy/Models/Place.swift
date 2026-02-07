//
//  Place.swift
//  NearBy
//
//  Created by Ace of Heart on 2026-02-07.
//

import Foundation

enum Category {
//    case restaurant, coffee, bars, brunch, dessert, gas, hotels, atms, pharmacies, hospitalsNclinics, parking, barber, gym, groceries, beauty, apparel, electronics, cinema, arcade, libraries, museums, parks, convini, sports
//    OR
    case food, drink, things2do, shopping, services
    
}

struct Place: Identifiable{
    var id: String
    var name: String
    var category: Category
    var address: String
    let latitude: Double
    let longitude: Double
    var rating: Double
    var distance: Double
    var phone: String
//    var hours: String
    var photoUrl: [String]
    
    init(id: String, name: String, category: Category, address: String, latitude: Double, longitude: Double, rating: Double, distance: Double, phone: String, photoUrl: [String]) {
            self.id = id
            self.name = name
            self.category = category
            self.address = address
            self.latitude = latitude
            self.longitude = longitude
            self.rating = rating
            self.distance = distance
            self.phone = phone
            self.photoUrl = photoUrl
        }
    
    func getCoordinates() -> (Double, Double) {
        return (latitude, longitude)
    }
}
