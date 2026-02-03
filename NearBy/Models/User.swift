//
//  User.swift
//  NearBy
//
//  Created by Rafat on 2026-02-03.
//


import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    let email: String
    var username: String
    var favoriteCount: Int
    var visitedPlacesCount: Int
    
    init(id: String? = nil, email: String, username: String, favoriteCount: Int = 0, visitedPlacesCount: Int = 0) {
        self.id = id
        self.email = email
        self.username = username
        self.favoriteCount = favoriteCount
        self.visitedPlacesCount = visitedPlacesCount
    }
}
