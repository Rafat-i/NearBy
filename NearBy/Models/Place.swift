//
//  Place.swift
//  NearBy
//
//  Created by Ace of Heart on 2026-02-07.
//

import Foundation

struct Place: Identifiable{
    var id: String
    var name: String
    var category: Category
    var address: String
    let latitude: Double
    let longitude: Double
    var rating: Double
    var phone: String
    var photoUrl: [String]
    
    init(id: String, name: String, category: Category, address: String, latitude: Double, longitude: Double, rating: Double, phone: String, photoUrl: [String]) {
            self.id = id
            self.name = name
            self.category = category
            self.address = address
            self.latitude = latitude
            self.longitude = longitude
            self.rating = rating
            self.phone = phone
            self.photoUrl = photoUrl
        }
    
    func getCoordinates() -> (Double, Double) {
        return (latitude, longitude)
    }
}
