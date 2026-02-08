//
//  Place.swift
//  NearBy
//
//  Created by Ace of Heart on 2026-02-07.
//

import Foundation
import CoreLocation
import FirebaseFirestore

struct Place: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var category: String
    var address: String
    var latitude: Double
    var longitude: Double
    var rating: Double
    var phone: String?
    var photoURL: String?
    var website: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(id: String? = nil, name: String, category: String, address: String, latitude: Double, longitude: Double, rating: Double = 0.0, phone: String? = nil, photoURL: String? = nil, website: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.rating = rating
        self.phone = phone
        self.photoURL = photoURL
        self.website = website
    }
}
