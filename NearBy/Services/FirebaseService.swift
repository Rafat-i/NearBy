//
//  FirebaseService.swift
//  NearBy
//
//  Created by Rafat on 2026-02-07.
//


import Foundation
import FirebaseFirestore

class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    
    func fetchNearbyPlaces(completion: @escaping (Result<[Place], Error>) -> Void) {
        db.collection("places").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let places = documents.compactMap { doc -> Place? in
                try? doc.data(as: Place.self)
            }
            
            completion(.success(places))
        }
    }
    

    func addSamplePlaces() {
        let samplePlaces: [[String: Any]] = [
            [
                "name": "LaSalle College",
                "category": "Education",
                "latitude": 45.4915,
                "longitude": -73.5815,
                "address": "2000 Sainte-Catherine St W, Montreal",
                "rating": 4.5,
                "phone": "(514) 939-2006"
            ],
            [
                "name": "McGill University",
                "category": "Education",
                "latitude": 45.5048,
                "longitude": -73.5772,
                "address": "845 Sherbrooke St W, Montreal",
                "rating": 4.8,
                "phone": "(514) 398-4455"
            ],
            [
                "name": "Mount Royal Park",
                "category": "Parks",
                "latitude": 45.5071,
                "longitude": -73.5875,
                "address": "1260 Chemin Remembrance, Montreal",
                "rating": 4.7
            ],
            [
                "name": "Bell Centre",
                "category": "Entertainment",
                "latitude": 45.4961,
                "longitude": -73.5695,
                "address": "1909 Avenue des Canadiens-de-Montréal",
                "rating": 4.6,
                "phone": "(514) 932-2582"
            ]
        ]
        
        for place in samplePlaces {
            db.collection("places").addDocument(data: place) { error in
                if let error = error {
                    print("Error adding place: \(error)")
                } else {
                    print("Added place: \(place["name"] ?? "")")
                }
            }
        }
    }
}
