//
//  Filters.swift
//  NearBy
//
//  Created by Ace of Heart on 2026-02-27.
//

import Foundation
import Combine

class MapFilter: ObservableObject {
    @Published var places: [Place] = []
    @Published var selectedCategory: Category? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var filteredPlaces: [Place] {
        guard let selected = selectedCategory else {
            return places
        }
        return places.filter { $0.category.lowercased() == selected.name.lowercased() }
    }
    
    func loadPlaces() {
        self.isLoading = true
        self.errorMessage = nil
        
        FirebaseService.shared.fetchNearbyPlaces { result in
            self.isLoading = false
            switch result {
            case .success(let fetchedPlaces):
                self.places = fetchedPlaces
                print("Loaded \(fetchedPlaces.count) places from Firebase")
            case .failure(let error):
                print("Error loading places: \(error)")
            }
        }
    }
}
