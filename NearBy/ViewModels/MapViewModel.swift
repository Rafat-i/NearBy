//
//  MapViewModel.swift
//  NearBy
//
//  Created by Rafat on 2026-04-13.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

enum TransportMode: String, CaseIterable, Identifiable {
    case automobile = "Driving"
    case cycling    = "Cycling"
    case walking    = "Walking"
    case any        = "Best"

    var id: String { rawValue }

    var mkType: MKDirectionsTransportType {
        switch self {
        case .automobile: return .automobile
        case .cycling:    return .any
        case .walking:    return .walking
        case .any:        return .any
        }
    }

    var icon: String {
        switch self {
        case .automobile: return "car.fill"
        case .cycling:    return "bicycle"
        case .walking:    return "figure.walk"
        case .any:        return "arrow.triangle.swap"
        }
    }

    var color: Color {
        switch self {
        case .automobile: return .blue
        case .cycling:    return .orange
        case .walking:    return .green
        case .any:        return .purple
        }
    }
}

struct SearchSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let source: Source

    enum Source {
        case firebase
        case mapKit
    }
}

final class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate, ObservableObject {
    @Published var suggestions: [MKLocalSearchCompletion] = []

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }
}

@MainActor
final class MapViewModel: ObservableObject {

    @Published var places: [Place] = []
    @Published var isLoading: Bool = true
    @Published var selectedPlace: Place?

    @Published var searchText: String = ""
    @Published var isSearchBarFocused: Bool = false
    @Published var destination: CLLocationCoordinate2D?
    @Published var route: MKRoute?
    @Published var distance: Double = 0
    @Published var timeDuration: Double = 0
    @Published var isSearching: Bool = false
    @Published var errorMessage: String?

    @Published var selectedTransport: TransportMode = .automobile
    @Published var zoomLevel: Double = 2_000
    @Published var didAutoCenter: Bool = false

    let completerDelegate = SearchCompleterDelegate()
    let completer = MKLocalSearchCompleter()

    var onClearSearch: (() -> Void)?
    var onRouteReady: ((MKRoute) -> Void)?
    var currentUserLocation: CLLocationCoordinate2D?

    var combinedSuggestions: [SearchSuggestion] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        let query = searchText.lowercased()

        let firebaseSuggestions: [SearchSuggestion] = places
            .filter { $0.name.lowercased().contains(query) }
            .prefix(3)
            .map { SearchSuggestion(title: $0.name, subtitle: $0.address, source: .firebase) }

        let mapKitSuggestions: [SearchSuggestion] = completerDelegate.suggestions
            .prefix(5)
            .map { SearchSuggestion(title: $0.title, subtitle: $0.subtitle, source: .mapKit) }

        var seen = Set<String>()
        var merged: [SearchSuggestion] = []
        for s in firebaseSuggestions + mapKitSuggestions {
            let key = s.title.lowercased()
            if !seen.contains(key) {
                seen.insert(key)
                merged.append(s)
            }
        }
        return Array(merged.prefix(6))
    }

    func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "education":               return "graduationcap.fill"
        case "parks":                   return "tree.fill"
        case "entertainment":           return "theatermasks.fill"
        case "restaurants", "cafes":    return "fork.knife"
        case "shopping":                return "cart.fill"
        case "libraries":               return "book.fill"
        default:                        return "mappin.circle.fill"
        }
    }

    func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "education":     return .orange
        case "parks":         return .green
        case "entertainment": return .purple
        case "restaurants":   return .red
        case "cafes":         return .brown
        case "shopping":      return .pink
        case "libraries":     return .blue
        default:              return .gray
        }
    }

    func loadPlaces() {
        isLoading = true
        FirebaseService.shared.fetchNearbyPlaces { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let fetchedPlaces):
                self.places = fetchedPlaces
            case .failure(let error):
                self.errorMessage = "Failed to load places: \(error.localizedDescription)"
            }
        }
    }

    func setupCompleter(region: MKCoordinateRegion?) {
        completer.delegate = completerDelegate
        completer.resultTypes = [.address, .pointOfInterest, .query]
        if let region { completer.region = region }
    }

    func updateCompleterRegion(_ location: CLLocationCoordinate2D) {
        completer.region = MKCoordinateRegion(
            center: location,
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
    }

    func selectSuggestion(_ suggestion: SearchSuggestion) {
        searchText = suggestion.title
        isSearchBarFocused = false
        completer.queryFragment = ""
        runSearch()
    }

    func runSearch() {
        Task { @MainActor in
            errorMessage = nil
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

            let targetCoord: CLLocationCoordinate2D
            if let existing = destination, query.isEmpty {
                targetCoord = existing
            } else {
                guard !query.isEmpty else { return }
                guard let userLocation = currentUserLocation else {
                    errorMessage = "User location is not available yet"
                    return
                }
                isSearching = true
                defer { isSearching = false }
                do {
                    targetCoord = try await searchCoordinate(for: query, near: userLocation)
                    destination = targetCoord
                    let newRoute = try await calculateRoute(from: userLocation, to: targetCoord, transport: selectedTransport)
                    applyRoute(newRoute)
                } catch {
                    errorMessage = error.localizedDescription
                }
                return
            }

            guard let userLocation = currentUserLocation else {
                errorMessage = "User location is not available yet"
                return
            }
            isSearching = true
            defer { isSearching = false }
            do {
                let newRoute = try await calculateRoute(from: userLocation, to: targetCoord, transport: selectedTransport)
                applyRoute(newRoute)
            } catch {
                if selectedTransport != .any {
                    do {
                        let fallback = try await calculateRoute(from: userLocation, to: targetCoord, transport: .any)
                        applyRoute(fallback)
                        errorMessage = "\(selectedTransport.rawValue) not available — showing best route."
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func clearSearch() {
        searchText         = ""
        destination        = nil
        route              = nil
        distance           = 0
        timeDuration       = 0
        errorMessage       = nil
        isSearchBarFocused = false
        completer.queryFragment = ""
        onClearSearch?()
    }

    func applyRoute(_ newRoute: MKRoute) {
        route        = newRoute
        distance     = newRoute.distance
        timeDuration = newRoute.expectedTravelTime
        errorMessage = nil
        onRouteReady?(newRoute)
    }

    private func searchCoordinate(for query: String, near userLocation: CLLocationCoordinate2D) async throws -> CLLocationCoordinate2D {
        try await withCheckedThrowingContinuation { continuation in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
            MKLocalSearch(request: request).start { response, error in
                if let error { continuation.resume(throwing: error); return }
                guard let coordinate = response?.mapItems.first?.placemark.coordinate else {
                    continuation.resume(throwing: NSError(
                        domain: "Search", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "No results found for: \(query)"]
                    ))
                    return
                }
                continuation.resume(returning: coordinate)
            }
        }
    }

    private func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, transport: TransportMode) async throws -> MKRoute {
        try await withCheckedThrowingContinuation { continuation in
            let request = MKDirections.Request()
            request.source        = MKMapItem(placemark: MKPlacemark(coordinate: source))
            request.destination   = MKMapItem(placemark: MKPlacemark(coordinate: destination))
            request.transportType = transport.mkType
            MKDirections(request: request).calculate { response, error in
                if let error { continuation.resume(throwing: error); return }
                guard let route = response?.routes.first else {
                    continuation.resume(throwing: NSError(
                        domain: "Directions", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "No \(transport.rawValue.lowercased()) route found"]
                    ))
                    return
                }
                continuation.resume(returning: route)
            }
        }
    }
}
