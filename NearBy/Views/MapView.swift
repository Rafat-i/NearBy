//
//  MapView.swift
//  NearBy
//
//  Created by Ace of Heart on 2026-02-06.
//


import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var places: [Place] = []
    @State private var isLoading = true
    @StateObject private var locationManager = LocationManager()
    
    @State private var searchText: String = ""
    @State private var destination: CLLocationCoordinate2D?
    @State private var route: MKRoute?
    @State private var isSearching: Bool = false
    @State private var errorMessage: String?
    
    @State private var zoomLevel: Double = 2000
    @State private var didAutoCenter: Bool = false
    @State private var currentCenter: CLLocationCoordinate2D?
    
    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                
                if let userLocation = locationManager.userLocation {
                    Annotation("You", coordinate: userLocation) {
                        ZStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 20, height: 20)
                            Circle()
                                .stroke(.white, lineWidth: 3)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
                
                if let destination {
                    Marker(searchText, coordinate: destination)
                        .tint(.red)
                }
                
                if let route {
                    MapPolyline(route.polyline)
                        .stroke(.blue, lineWidth: 5)
                }
                
                ForEach(places) { place in
                    Annotation(place.name, coordinate: place.coordinate) {
                        VStack {
                            Image(systemName: categoryIcon(for: place.category))
                                .resizable()
                                .foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .padding(8)
                                .background(categoryColor(for: place.category).gradient, in: .circle)
                                .shadow(radius: 3)
                        }
                    }
                }
            }
            .mapStyle(.standard)
            .onMapCameraChange { context in
                currentCenter = context.region.center
            }
            
            VStack {
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                        
                        TextField("Search for a place...", text: $searchText)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .submitLabel(.search)
                            .onSubmit {
                                runSearch()
                            }
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                    
                    Button {
                        if route != nil || isSearching {
                            clearSearch()
                        } else {
                            runSearch()
                        }
                    } label: {
                        if isSearching {
                            ProgressView()
                                .tint(.white)
                        } else if route != nil {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .semibold))
                        } else {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                    }
                    .frame(width: 50, height: 50)
                    .background(route != nil ? .red : .blue)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                    .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && route == nil)
                }
                .padding(.horizontal)
                .padding(.top, 60)
                
                Spacer()
                
                HStack {
                    Spacer()
                    zoomControls
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .navigationBarHidden(true)
        .safeAreaInset(edge: .bottom) {
            if let errorMessage {
                errorMessageView(errorMessage)
            }
        }
        .onAppear {
            loadPlaces()
        }
        .onReceive(locationManager.$userLocation) { newLocation in
            guard !didAutoCenter, route == nil, let loc = newLocation else { return }
            didAutoCenter = true
            cameraPosition = .camera(MapCamera(centerCoordinate: loc, distance: zoomLevel))
        }
    }
    
    private var searchBarSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Map")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 8)
            
            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search for a place...", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .submitLabel(.search)
                        .onSubmit {
                            runSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Button {
                    runSearch()
                } label: {
                    if isSearching {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                }
                .frame(width: 44, height: 44)
                .background(.blue)
                .cornerRadius(12)
                .disabled(isSearching || searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                if destination != nil || route != nil {
                    Button {
                        clearSearch()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .background(.ultraThinMaterial)
    }
    
    private var zoomControls: some View {
        VStack(spacing: 10) {
            Button(action: zoomIn) {
                Image(systemName: "plus.magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .shadow(radius: 4)
            
            Button(action: zoomOut) {
                Image(systemName: "minus.magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .shadow(radius: 4)
            
            Button(action: goToUserLocation) {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .shadow(radius: 4)
        }
    }
    
    private func errorMessageView(_ message: String) -> some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text(message)
                    .foregroundStyle(.red)
                    .font(.caption)
                Spacer()
                Button {
                    errorMessage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }
    
    
    private func loadPlaces() {
        isLoading = true
        FirebaseService.shared.fetchNearbyPlaces { result in
            isLoading = false
            switch result {
            case .success(let fetchedPlaces):
                self.places = fetchedPlaces
                print("Loaded \(fetchedPlaces.count) places from Firebase")
            case .failure(let error):
                print("Error loading places: \(error)")
                errorMessage = "Failed to load places: \(error.localizedDescription)"
            }
        }
    }
    
    private func runSearch() {
        Task {
            @MainActor in
            errorMessage = nil
            
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { return }
            
            guard let userLocation = locationManager.userLocation else {
                errorMessage = "User location is not available yet"
                return
            }
            
            isSearching = true
            defer { isSearching = false }
            
            do {
                let dest = try await searchCoordinate(for: query)
                destination = dest
                
                let newRoute = try await calculateRoute(from: userLocation, to: dest)
                route = newRoute
                
                let rect = newRoute.polyline.boundingMapRect
                let region = MKCoordinateRegion(rect)
                cameraPosition = .region(region)
                
                errorMessage = nil
                
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func clearSearch() {
        searchText = ""
        destination = nil
        route = nil
        errorMessage = nil
        
        if let userLocation = locationManager.userLocation {
            withAnimation {
                cameraPosition = .camera(MapCamera(centerCoordinate: userLocation, distance: zoomLevel))
            }
        }
    }
    
    private func searchCoordinate(for query: String) async throws -> CLLocationCoordinate2D {
        try await withCheckedThrowingContinuation { continuation in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            
            if let userLocation = locationManager.userLocation {
                request.region = MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
            }
            
            MKLocalSearch(request: request).start { response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let coordinate = response?.mapItems.first?.placemark.coordinate else {
                    continuation.resume(
                        throwing: NSError(
                            domain: "Search",
                            code: 0,
                            userInfo: [
                                NSLocalizedDescriptionKey: "No results found for: \(query)"
                            ]
                        )
                    )
                    return
                }
                
                continuation.resume(returning: coordinate)
            }
        }
    }
    
    private func calculateRoute(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> MKRoute {
        try await withCheckedThrowingContinuation { continuation in
            let request = MKDirections.Request()
            
            request.source = MKMapItem(
                placemark: MKPlacemark(coordinate: source)
            )
            
            request.destination = MKMapItem(
                placemark: MKPlacemark(coordinate: destination)
            )
            
            request.transportType = .automobile
            
            MKDirections(request: request).calculate { response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let route = response?.routes.first else {
                    continuation.resume(
                        throwing: NSError(
                            domain: "Directions",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "No route found"]
                        )
                    )
                    return
                }
                
                continuation.resume(returning: route)
            }
        }
    }
    
    
    private func zoomIn() {
        let center = currentCenter ?? locationManager.userLocation ?? CLLocationCoordinate2D(latitude: 45.501690, longitude: -73.567253)
        
        zoomLevel *= 0.8
        withAnimation {
            cameraPosition = .camera(
                MapCamera(centerCoordinate: center, distance: zoomLevel)
            )
        }
    }
    
    private func zoomOut() {
        let center = currentCenter ?? locationManager.userLocation ?? CLLocationCoordinate2D(latitude: 45.501690, longitude: -73.567253)
        
        zoomLevel *= 1.2
        withAnimation {
            cameraPosition = .camera(
                MapCamera(centerCoordinate: center, distance: zoomLevel)
            )
        }
    }
    
    private func goToUserLocation() {
        if let userLocation = locationManager.userLocation {
            withAnimation {
                cameraPosition = .camera(
                    MapCamera(centerCoordinate: userLocation, distance: zoomLevel)
                )
            }
        }
    }
    
    
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "education": return "graduationcap.fill"
        case "parks": return "tree.fill"
        case "entertainment": return "theatermasks.fill"
        case "restaurants", "cafes": return "fork.knife"
        case "shopping": return "cart.fill"
        case "libraries": return "book.fill"
        default: return "mappin.circle.fill"
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "education": return .orange
        case "parks": return .green
        case "entertainment": return .purple
        case "restaurants": return .red
        case "cafes": return .brown
        case "shopping": return .pink
        case "libraries": return .blue
        default: return .gray
        }
    }
}

#Preview {
    NavigationView {
        MapView()
    }
}
