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
}
